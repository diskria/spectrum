import os
import xml.etree.ElementTree as XmlTree
from dataclasses import dataclass, field
from xml.dom import minidom

import requests

GITHUB_USERNAME = os.getenv("GITHUB_USERNAME")
PAT = os.getenv("PAT")

DEFAULT_BRANCH = "main"
OUTPUT_FILE = "default.xml"


def repo_sort_key(repo):
    return repo["full_name"].lower()


def prettify(element):
    rough_xml = XmlTree.tostring(element, encoding="utf-8")
    parsed = minidom.parseString(rough_xml)
    return parsed.toprettyxml(indent="    ")


@dataclass
class RepoGroups:
    profile: list = field(default_factory=list)
    domains: list = field(default_factory=list)
    brands: list = field(default_factory=list)

    def sort_all(self):
        for group in (self.profile, self.domains, self.brands):
            group.sort(key=repo_sort_key)


def fetch_repos():
    url = "https://api.github.com/user/repos?per_page=100"
    headers = {"Authorization": f"token {PAT}"} if PAT else {}
    repos = []
    while url:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        repos.extend(response.json())
        url = response.links.get("next", {}).get("url")
    return repos


def group_repos(user_name, repos):
    repo_groups = RepoGroups()

    for repo in repos:
        owner, _ = repo["full_name"].split("/")

        if owner == user_name:
            repo_groups.profile.append(repo)
        elif owner.startswith(user_name + "-"):
            repo_groups.domains.append(repo)
        else:
            repo_groups.brands.append(repo)

    repo_groups.sort_all()

    return repo_groups


def add_projects_to_manifest(parent, owner_name, projects):
    parent.append(XmlTree.Comment(f" region start {owner_name} "))
    for repo in projects:
        full_name = repo["full_name"]
        revision = repo.get("default_branch", DEFAULT_BRANCH)

        attrs = {"name": full_name}
        if revision != DEFAULT_BRANCH:
            attrs["revision"] = revision

        XmlTree.SubElement(parent, "project", attrs)
    parent.append(XmlTree.Comment(f" endregion {owner_name} "))


def build_manifest(user_name, repo_groups: RepoGroups):
    root = XmlTree.Element("manifest")
    XmlTree.SubElement(
        root, "remote",
        {"name": "origin", "fetch": "https://github.com/"}
    )
    XmlTree.SubElement(
        root, "default",
        {"remote": "origin", "revision": DEFAULT_BRANCH, "clone-depth": "1"},
    )

    profile_repos = sorted(
        repo_groups.profile, key=repo_sort_key
    )
    if profile_repos:
        add_projects_to_manifest(root, user_name, profile_repos)

    domain_map = {}
    for repo in repo_groups.domains:
        owner, _ = repo["full_name"].split("/")
        domain_map.setdefault(owner, []).append(repo)

    for domain_name in sorted(domain_map.keys(), key=str.lower):
        repos = sorted(domain_map[domain_name], key=repo_sort_key)
        add_projects_to_manifest(root, domain_name, repos)

    brand_map = {}
    for repo in repo_groups.brands:
        owner, _ = repo["full_name"].split("/")
        brand_map.setdefault(owner, []).append(repo)

    for brand_name in sorted(brand_map.keys(), key=str.lower):
        repos = sorted(brand_map[brand_name], key=repo_sort_key)
        add_projects_to_manifest(root, brand_name, repos)

    return root


def save_manifest(user_name, repos, file_name):
    grouped_repos = group_repos(user_name, repos)
    manifest = build_manifest(user_name, grouped_repos)
    with open(file_name, "w", encoding="utf-8") as file:
        file.write(prettify(manifest))


if __name__ == "__main__":
    all_repos = fetch_repos()
    save_manifest(GITHUB_USERNAME, all_repos, OUTPUT_FILE)
