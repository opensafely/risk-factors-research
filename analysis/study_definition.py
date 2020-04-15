from datalab_cohorts import StudyDefinition, patients, codelist_from_csv


## CODE LISTS
# All codelist are held within the codelist/ folder.

chronic_respiratory_disease_codes = codelist_from_csv(
    "codelists/chronic_respiratory_disease.csv", system="ctv3", column="CTV3ID"
)

chronic_cardiac_disease_codes = codelist_from_csv(
    "codelists/chronic_cardiac_disease.csv", system="ctv3", column="CTV3ID"
)

chronic_liver_disease_codes = codelist_from_csv(
    "codelists/chronic_liver_disease.csv", system="ctv3", column="CTV3ID"
)

organ_transplant_codes = codelist_from_csv(
    "codelists/organ_transplant.csv", system="ctv3", column="CTV3ID"
)

ra_sle_psoriasis_codes = codelist_from_csv(
    "codelists/ra_sle_psoriasis.csv", system="ctv3", column="CTV3ID"
)

## STUDY POPULATION
# Defines both the study population and points to the important covariates

study = StudyDefinition(
    # This line defines the study population
    population=patients.all(), ########################### CHANGE FOR REAL DATA ANALYSIS ###########################

    # The rest of the lines define the covariates with associated GitHub issues
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/33
    age=patients.age_as_of("2020-02-01"),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/46
    sex=patients.sex(),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/52
    #imd= # still to be implemented

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/37
    #urban_rural= # still to be implemented

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/54
    #geographic_area= # still to be implemented

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/10
    bmi=patients.most_recent_bmi(
        on_or_after="2010-02-01",
        minimum_age_at_measurement=16,
        include_measurement_date=True,
        include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/6
    #smoking_status= # still to be implemented

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/27
    #ethnicity= # still to be implemented - this will be just the Read code for now then can be categorised with the list we're making.

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/21
    chronic_respiratory_disease=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes,
        return_first_date_in_period=True,
        include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/55
    #asthma= # still to be implemented

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/7
    chronic_cardiac_disease=patients.with_these_clinical_events(
        chronic_cardiac_disease_codes,
        return_first_date_in_period=True,
        include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/30
    diabetes=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, #################################### CHANGE TO CORRECT CODELIST WHEN READY ####################################
        return_first_date_in_period=True,
        include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/32
    lung_cancer=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, #################################### CHANGE TO CORRECT CODELIST WHEN READY ####################################
        return_first_date_in_period=True,
        include_month=True,
    ),
    haem_cancer=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, #################################### CHANGE TO CORRECT CODELIST WHEN READY ####################################
        return_first_date_in_period=True,
        include_month=True,
    ),
    other_cancer=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, #################################### CHANGE TO CORRECT CODELIST WHEN READY ####################################
        return_first_date_in_period=True,
        include_month=True,
    ),
    bone_marrow_transplant=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, #################################### CHANGE TO CORRECT CODELIST WHEN READY ####################################
        return_first_date_in_period=True,
        include_month=True,
    ),
    chemo_radio_therapy=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, #################################### CHANGE TO CORRECT CODELIST WHEN READY ####################################
        return_first_date_in_period=True,
        include_month=True,
    ),

    # # https://github.com/ebmdatalab/tpp-sql-notebook/issues/12
    chronic_liver_disease=patients.with_these_clinical_events(
        chronic_liver_disease_codes,
        return_first_date_in_period=True,
        include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/14
    neurological_condition=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, #################################### CHANGE TO CORRECT CODELIST WHEN READY ####################################
        return_first_date_in_period=True,
        include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/17
    chronic_kidney_disease=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, #################################### CHANGE TO CORRECT CODELIST WHEN READY ####################################
        return_first_date_in_period=True,
        include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/31
    organ_transplant=patients.with_these_clinical_events(
        organ_transplant_codes,
        return_first_date_in_period=True,
        include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/13
    dysplenia=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, #################################### CHANGE TO CORRECT CODELIST WHEN READY ####################################
        return_first_date_in_period=True,
        include_month=True,
    ),
    sickle_cell=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, #################################### CHANGE TO CORRECT CODELIST WHEN READY ####################################
        return_first_date_in_period=True,
        include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/36
    aplastic_anaemia=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, #################################### CHANGE TO CORRECT CODELIST WHEN READY ####################################
        return_first_date_in_period=True,
        include_month=True,
    ),
    hiv=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, #################################### CHANGE TO CORRECT CODELIST WHEN READY ####################################
        return_first_date_in_period=True,
        include_month=True,
    ),
    genetic_immunodeficiency=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, #################################### CHANGE TO CORRECT CODELIST WHEN READY ####################################
        return_first_date_in_period=True,
        include_month=True,
    ),
    immunosuppression_nos=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes, #################################### CHANGE TO CORRECT CODELIST WHEN READY ####################################
        return_first_date_in_period=True,
        include_month=True,
    ),

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/23
    #immunosuppressant_med=

    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/35
    #blood_pressure= #still to be implemented

    # # https://github.com/ebmdatalab/tpp-sql-notebook/issues/49
    ra_sle_psoriasis=patients.with_these_clinical_events(
        ra_sle_psoriasis_codes,
        return_first_date_in_period=True,
        include_month=True,
    ),
)
