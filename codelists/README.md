# Codelists

Some covariates used in the study were created from codelists of clinical conditions or numerical values available on a patient's records. 

This folder contains csv files for each covariate with a list of included read codes. 

Read codes are coded thesaurus of clinical terms, and have been used for a long time in clinical records. This study uses patients from TPP 
practices. TPP use a Read Code system called CTV3 or Read Code Version 3. Most of the lists of readcodes were developed in this 
study from Read Code Version 2 (from previous studies performed by LSHTM Electronic Health Records Group). For the purpose of
this study, these were mapped across to CTV3. In order to make sure no codes were lost, relevant SNOWMED codes were 
identified and mapped into CTV3. Additionally Quality Outcome Framework (QOF) codes were included, which are already in 
CTV3 were manually identified by researchers.  The CTV3 code list for each covariate was examined by researchers and signed off, manually 
altered to exclude irrelevant codes and signed off by both a researcher and a clinician. Definition 
of the covariate and discussion of development process of this definition and 
what codes to include are recorded within Git issues and can be access by clicking on the covariate name in the table below. 

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
