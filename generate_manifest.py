import os
import xml.etree.ElementTree as XmlTree
from xml.dom import minidom

import requests

GITHUB_USERNAME = os.getenv("GITHUB_USERNAME")
PAT = os.getenv("PAT")

OUTPUT_FILE = "default.xml"


def fetch_repositories():
    url = "https://api.github.com/user/repos?per_page=100"
    headers = {"Authorization": f"token {PAT}"} if PAT else {}
    repositories = []
    while url:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        repositories.extend(response.json())
        url = response.links.get("next", {}).get("url")
    return repositories


def sort_and_group_repositories(user_name, repositories):
    grouped_repositories = {"personal": [], "user_dash": [], "organizations": []}

    for repository in repositories:
        full_name = repository["full_name"]
        owner_name, _ = full_name.split("/")

        if owner_name.lower() == user_name.lower():
            grouped_repositories["personal"].append(repository)
        elif owner_name.lower().startswith(user_name.lower() + "-"):
            grouped_repositories["user_dash"].append(repository)
        else:
            grouped_repositories["organizations"].append(repository)

    for key in grouped_repositories:
        grouped_repositories[key] = sorted(
            grouped_repositories[key], key=lambda repo: repo["full_name"].lower()
        )

    return grouped_repositories


def add_projects_to_manifest(parent, project_list):
    for repository in project_list:
        full_name = repository["full_name"]
        revision = repository.get("default_branch", "main")
        XmlTree.SubElement(
            parent,
            "project",
            {
                "name": full_name,
                "revision": revision,
            },
        )


def build_manifest(user_name, grouped_repositories):
    manifest = XmlTree.Element("manifest")
    XmlTree.SubElement(
        manifest, "remote", {"name": "origin", "fetch": "https://github.com/"}
    )
    XmlTree.SubElement(
        manifest, "default", {"remote": "origin", "revision": "main", "clone-depth": "1"}
    )

    personal_repositories = sorted(
        grouped_repositories["personal"],
        key=lambda repo: (
            repo["full_name"].split("/")[1].lower() != user_name.lower(),
            repo["full_name"].lower(),
        ),
    )
    add_projects_to_manifest(manifest, personal_repositories)

    user_dash_by_owner = {}
    for repository in grouped_repositories["user_dash"]:
        owner_name, _ = repository["full_name"].split("/")
        user_dash_by_owner.setdefault(owner_name, []).append(repository)

    for owner_name in sorted(user_dash_by_owner.keys(), key=str.lower):
        owner_repositories = sorted(
            user_dash_by_owner[owner_name],
            key=lambda repo: (
                repo["full_name"].split("/")[1].lower() != ".github",
                repo["full_name"].lower(),
            ),
        )
        add_projects_to_manifest(manifest, owner_repositories)

    organizations_by_owner = {}
    for repository in grouped_repositories["organizations"]:
        owner_name, _ = repository["full_name"].split("/")
        organizations_by_owner.setdefault(owner_name, []).append(repository)

    for owner_name in sorted(organizations_by_owner.keys(), key=str.lower):
        organization_repositories = sorted(
            organizations_by_owner[owner_name],
            key=lambda repo: (
                repo["full_name"].split("/")[1].lower() != ".github",
                repo["full_name"].lower(),
            ),
        )
        add_projects_to_manifest(manifest, organization_repositories)

    return manifest


def prettify(element):
    rough_xml = XmlTree.tostring(element, encoding="utf-8")
    parsed = minidom.parseString(rough_xml)
    return parsed.toprettyxml(indent="    ")


def save_manifest(user_name, repositories, file_name):
    grouped_repositories = sort_and_group_repositories(user_name, repositories)
    manifest = build_manifest(user_name, grouped_repositories)
    with open(file_name, "w", encoding="utf-8") as file:
        file.write(prettify(manifest))


if __name__ == "__main__":
    all_repositories = fetch_repositories()
    save_manifest(GITHUB_USERNAME, all_repositories, OUTPUT_FILE)
