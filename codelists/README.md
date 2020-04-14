# Codelists

Some covariates used in the study were created from codelists of clinical conditions or numerical values available on a patient's records. 

This folder contains csv files for each covariate with a list of included Read codes. 

Read codes are coded thesaurus of clinical terms, and have been used for a long time in clinical records. This study uses patients from TPP practices. TPP use a Read code system called CTV3 or Read Code Version 3. Most codelists in this study were developed from from lists used in previous studies performed by LSHTM Electronic Health Records Group, which are coded in Read Code Version 2. For the purpose of this study, these were mapped to CTV3.

Each Read 2 term maps to a CTV3 code, but the CTV3 hierarchy contains additional codes that may not have a Read 2 equivalent. To address this, relevant SNOWMED codes were identified and mapped into CTV3, and CTV3 Quality Outcome Framework (QOF) cluster codes were included where available. The converted CTV3 code lists for each covariate were then manually reviewed by researchers to exclude irrelevant codes and signed off by both a researcher and a clinician.

The development process for each covariate is documented in Git issues. This includes discussion of what codes should be included for each covariate as well as final definitions of each. These can be found at the links in the list below. 

### Summary of Code Lists

- [Smoking status](https://github.com/ebmdatalab/tpp-sql-notebook/issues/6#issuecomment-610427063)
- [Ethnicity](https://github.com/ebmdatalab/tpp-sql-notebook/issues/27)  
- [Respiratory Disease (exc. asthma)](https://github.com/ebmdatalab/tpp-sql-notebook/issues/21)  
- [Asthma](https://github.com/ebmdatalab/tpp-sql-notebook/issues/55) 
- [Chronic Heart Disease](https://github.com/ebmdatalab/tpp-sql-notebook/issues/7#issuecomment-610307777) 
- [Diabetes Mellitus](https://github.com/ebmdatalab/tpp-sql-notebook/issues/30)
- [Cancer](https://github.com/ebmdatalab/tpp-sql-notebook/issues/32)
- [Chronic Liver Disease](https://github.com/ebmdatalab/tpp-sql-notebook/issues/12#issuecomment-610345584)
- Chronic Neurological Condition
- Chronic Kidney Disease
- [Organ Transplant Status](https://github.com/ebmdatalab/tpp-sql-notebook/issues/31#issuecomment-612122743)
- Splenectomy or Sickle Cell
- Conditions affecting Immunity
- Immunosuppressants 
- Blood pressure
- [Rheumatoid Arthritis / SLE / Psoriasis](https://github.com/ebmdatalab/tpp-sql-notebook/issues/49#issuecomment-611950089) 
