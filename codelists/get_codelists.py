import glob
import os
import requests


base_path = os.path.dirname(__file__)

for path in glob.glob(os.path.join(base_path, "*.csv")):
    os.unlink(path)


with open(os.path.join(base_path, "codelists.txt")) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue

        print(line)
        project_id, codelist_id, version = line.split("/")
        url = f"https://codelists.opensafely.org/codelist/{project_id}/{codelist_id}/{version}/download.csv"

        rsp = requests.get(url)
        rsp.raise_for_status()

        with open(os.path.join(base_path, f"{project_id}-{codelist_id}.csv"), "w") as f:
            f.write(rsp.text)
