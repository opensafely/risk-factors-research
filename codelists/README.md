# Codelists

Some covariates used in the study were created from codelists of clinical conditions or numerical values available on a patient's records. 

This folder contains csv files for each covariate with a list of included Read codes. 

Read codes are coded thesaurus of clinical terms, and have been used for a long time in clinical records. This study uses patients from TPP practices. TPP use a Read code system called CTV3 or Read Code Version 3. Most codelists in this study were developed from from lists used in previous studies performed by LSHTM Electronic Health Records Group, which are coded in Read Code Version 2. For the purpose of this study, these were mapped to CTV3.

Each Read 2 term maps to a CTV3 code, but the CTV3 hierarchy contains additional codes that may not have a Read 2 equivalent. To address this, relevant SNOWMED codes were identified and mapped into CTV3, and CTV3 Quality Outcome Framework (QOF) cluster codes were included where available. The converted CTV3 code lists for each covariate were then manually reviewed by researchers to exclude irrelevant codes and signed off by both a researcher and a clinician.

Codelists are hosted on OpenCodelists.  The script `get_codelists.py` in this directory will fetch all the codelists identified in `codelists.txt` from OpenCodelists.  As such, codelists should not be added or edited by hand.  Instead:

* Go to http://smallweb1.ebmdatalab.net:8001/admin/
* Create or update the codelist.
  * Copy/paste the CSV data into the `csv_data field`
  * Set the `version_str` to today's date in `YYYY-MM-DD`
  * Click "Save"
* Update `codelists/codelists.txt`
* From the `codelists` directory in this repo, run `python get_codelists.py` (or ask a developer to do this)
* Check the git diff for sense
* Commit the changes and make a PR
