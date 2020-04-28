import glob
import os
import requests


for path in glob.glob("*.csv"):
    os.unlink(path)


with open("codelists.txt") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue

        print(line)
        project_id, codelist_id, version = line.split("/")
        url = f"http://smallweb1.ebmdatalab.net:8001/codelist/{project_id}/{codelist_id}/{version}/download.csv"

        rsp = requests.get(url)
        rsp.raise_for_status()

        with open(f"{project_id}-{codelist_id}.csv", "w") as f:
            f.write(rsp.text)
