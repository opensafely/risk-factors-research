# Factors associated with COVID-19-related hospital death

This is the code and configuration for our paper, _OpenSAFELY: factors associated with 
COVID-19-related hospital death in the linked electronic health records of 17 million adult 
NHS patients_

* The paper is [here]()
* Raw model outputs, including charts, crosstabs, etc, are in `released_analysis_results/`
* If you are interested in how we defined our covarates, take a look at the [study definition](analysis/study_definition.py); this is written in `python`, but non-programmers should be able to understand what is going on there
* If you are interested in how we defined our code lists, look in the [codelists folder](./codelists/). A new tool 
called OpenSafely Codelists was developed to allow codelists to be versioned and hosted online at [codelists.opensafely.org](codelists.opensafely.org)
The tool allows agreed codelists to be pulled into a repository by running a python command. More information available in
the [README~~~~](https://github.com/ebmdatalab/opensafely-risk-factors-research/blob/master/codelists/README.md) of the codelist folder
* Developers and epidemiologists interested in the code should review
[DEVELOPERS.md](./DEVELOPERS.md).

# About the OpenSAFELY framework

The OpenSAFELY framework is a new secure analytics platform for
electronic health records research in the NHS.

Instead of requesting access for slices of patient data and
transporting them elsewhere for analysis, the framework supports
developing analytics against dummy data, and then running against the
real data *within the same infrastructure that the data is stored*.
Read more at [OpenSAFELY.org](https://opensafely.org).

The framework is under fast, active development to support rapid
analytics relating to COVID19; we're currently seeking funding to make
it easier for outside collaborators to work with our system.
