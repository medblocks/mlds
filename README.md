# MDLS Downloading tool and Packaging tool

Scripts to downloads SNOMED release files from MLDS, index and publish a docker container. Uses [Hermes](https://github.com/wardle/hermes) for indexing and search capabilities.

## Installation

```sh
pip install -r requirements.txt
```

## Usage

List all the release files in a markdown table

```sh
python main.py list --members "IN, IHTSDO" > table.md
```

You can also view [table.md](./table.md), but it may not be up to date.

Get the `id` from the table and put them in a txt file - let's say `release.txt`.

```sh
python main.py download --username <username> --password <password> release.txt
```

## Environment Variables

Variable | Notes
|-----------|------|
MLDS_DOWNLOAD_USERNAME | Username/Email to login
MLDS_DOWNLOAD_PASSWORD | Password to login
MLDS_DOWNLOAD_DIRECTORY | Output download directory
MLDS_LIST_MEMBERS | List of countries/members you want to include in the list command - eg: "IN, IHTSDO". Defaults to "*"