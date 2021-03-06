import os
import requests
import click
import re
from tqdm import tqdm
from prettytable import PrettyTable, MARKDOWN
import zipfile
from dateutil import parser

def get_packages(baseUrl="https://mlds.ihtsdotools.org"):
    r = requests.get(f"{baseUrl}/api/releasePackages")
    packages = r.json()
    files = []
    for package in packages:
        s = sorted(package["releaseVersions"], key=lambda release: parser.parse(release["createdAt"]))
        latest = s[-1]
        file = {
            "package": package["name"],
            "id": package["releasePackageId"],
            "member": package["member"]["key"],
            "latest": latest["createdAt"],
            "file": [i for i in latest["releaseFiles"] if ".zip" in i["label"] and ".zip.md5" not in i["label"]]
        }
        
        if len(file["file"]) > 1:
            print("Warning: ", package["name"], 
            "more than 1 .zip file")

        if len(file["file"]) > 0:
            file["url"] = f'{baseUrl}{file["file"][0]["clientDownloadUrl"]}'
            files.append(file)
    return files


def download_progress(url: str, folder: str, session: requests.Session):
    resp = session.get(
        url, stream=True)
    print(resp.status_code)
    if resp.status_code != 200:
        if resp.status_code == 500:
            click.echo(
            "SNOMED Internal server error. Please try after sometime")
        else:
            click.echo(
                "Authentication Failed. Please check your username and password.")
        exit(1)
    total = int(resp.headers.get('content-length', 0))
    d = resp.headers.get('content-disposition')
    file = re.findall("filename=(.+)", d)[0]
    file = file.replace('"', "")
    fname = os.path.join(folder, file)
    with open(fname, 'wb') as file, tqdm(
        desc=fname,
        total=total,
        unit='iB',
        unit_scale=True,
        unit_divisor=1024,
    ) as bar:
        for data in resp.iter_content(chunk_size=1024):
            size = file.write(data)
            bar.update(size)


def unzip_file(filename: str, extract_folder="extracts"):
    with zipfile.ZipFile(filename, 'r') as snomed_zip_file:
        snomed_zip_file.extractall(extract_folder)


def get_to_download(filename: str):
    with open(filename, 'r') as f:
        return f.read()


@click.command()
@click.option('--dir', default="downloads")
def extract(dir):
    extract_folder = os.path.join(dir,"extracts")
    for allfiles in os.listdir(dir):
        if allfiles.split('.')[-1] == 'zip':
            file_path = os.path.join(dir, allfiles)
            click.echo(f"Extracting {file_path}")
            unzip_file(file_path, extract_folder)


@click.command()
@click.option('--members', '-m', default="*")
def list(members):
    packages = get_packages()
    headers = [
        "id",
        "package",
        "latest",
        "member",
    ]
    if members == "*" or members == "":
        rows = rows = [[p[header] for header in headers] for p in packages]
    else:
        rows = [[p[header] for header in headers]
                for p in packages if p["member"] in members + " IHTSDO"]
    table = PrettyTable(headers)
    table.set_style(MARKDOWN)
    table.align = "l"
    table.add_rows(rows)
    click.echo(table.get_string(sortby="member"))
    
    


@click.group()
def cli():
    pass


@click.command()
@click.argument('filename', type=click.Path(exists=True))
@click.option('--directory', '-d', help='Output directory', default="downloads")
@click.option('--username', '-u', help='Usually email id.', required=True, prompt=True)
@click.option('--password', '-p', help="Password to login", required=True, prompt=True, hide_input=True)
def download(filename, directory, username, password):
    os.makedirs(directory, exist_ok=True)
    packages = get_packages()
    to_download = get_to_download(filename)
    to_download = [package for package in packages if str(
        package["id"]) in to_download]
    session = requests.Session()
    session.auth = (username, password)
    for file in to_download:
        download_progress(file["url"], directory, session)


if __name__ == '__main__':
    cli.add_command(download)
    cli.add_command(list)
    cli.add_command(extract)
    cli(auto_envvar_prefix='MLDS')
