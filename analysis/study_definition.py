from datalab_cohorts import StudyDefinition, patients, codelist_from_csv, codelist


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

systolic_blood_pressure_codes = codelist(["2469."], system="ctv3")
diastolic_blood_pressure_codes = codelist(["246A."], system="ctv3")

## STUDY POPULATION
# Defines both the study population and points to the important covariates

study = StudyDefinition(
    # This line defines the study population
    population=patients.registered_with_one_practice_between(
        "2019-02-01", "2020-02-01"
    ),
    # The rest of the lines define the covariates with associated GitHub issues
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/33
    age=patients.age_as_of("2020-02-01"),
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/46
    sex=patients.sex(),
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/21
    chronic_respiratory_disease=patients.with_these_clinical_events(
        chronic_respiratory_disease_codes,
        return_first_date_in_period=True,
        include_month=True,
    ),
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/7
    chronic_cardiac_disease=patients.with_these_clinical_events(
        chronic_cardiac_disease_codes,
        return_first_date_in_period=True,
        include_month=True,
    ),
    # # https://github.com/ebmdatalab/tpp-sql-notebook/issues/12
    chronic_liver_disease=patients.with_these_clinical_events(
        chronic_liver_disease_codes,
        return_first_date_in_period=True,
        include_month=True,
    ),
    # # https://github.com/ebmdatalab/tpp-sql-notebook/issues/49
    ra_sle_psoriasis=patients.with_these_clinical_events(
        ra_sle_psoriasis_codes,
        return_first_date_in_period=True,
        include_month=True,
    ),
    # # https://github.com/ebmdatalab/tpp-sql-notebook/issues/31
    organ_transplant=patients.with_these_clinical_events(
        organ_transplant_codes,
        return_first_date_in_period=True,
        include_month=True,
    ),
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/10
    bmi=patients.most_recent_bmi(
        on_or_after="2010-02-01",
        minimum_age_at_measurement=16,
        include_measurement_date=True,
        include_month=True,
    ),

    # Blood pressure
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/35
    bp_sys=patients.mean_recorded_value(
        systolic_blood_pressure_codes,
        on_most_recent_day_of_measurement=True,
        on_or_before="2020-02-01",
        include_measurement_date=True,
        include_month=True,
    ),
    bp_dias=patients.mean_recorded_value(
        diastolic_blood_pressure_codes,
        on_most_recent_day_of_measurement=True,
        on_or_before="2020-02-01",
        include_measurement_date=True,
        include_month=True,
    ),

    # Geographic covariates
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/54
    stp=patients.registered_practice_as_of("2020-02-01", returning="stp_code"),
    msoa=patients.registered_practice_as_of("2020-02-01", returning="msoa_code"),
    # https://github.com/ebmdatalab/tpp-sql-notebook/issues/52
    imd=patients.address_as_of(
        "2020-02-01", returning="index_of_multiple_deprivation", round_to_nearest=100
    ),
    rural_urban=patients.address_as_of(
        "2020-02-01", returning="rural_urban_classification"
    ),

    # # Chronic kidney disease
    # # https://github.com/ebmdatalab/tpp-sql-notebook/issues/17
    # egfr=patients.with_these_clinical_events(
    #     egfr_codes,
    #     find_last_match_in_period=True,
    #     on_or_before="2020-02-01",
    #     returning="numeric_value",
    #     include_date_of_match=True
    #     include_month=True,
    # ),

    # # Asthma
    # # https://github.com/ebmdatalab/tpp-sql-notebook/issues/55
    # has_asthma=patients.satisfying(
    #     """
    #     recent_asthma_code OR (
    #       asthma_code_ever
    #       AND NOT copd_code_ever
    #       AND (recent_salbutamol_count >= 3 OR recent_ics)
    #     )
    #     """,
    #     recent_asthma_code=patients.with_these_clinical_events(
    #         asthma_codes,
    #         between=['2018-02-01', '2020-02-01']
    #     ),
    #     asthma_code_ever=patients.with_these_clinical_events(asthma_codes),
    #     copd_code_ever=patients.with_these_clinical_events(copd_codes),
    #     recent_salbutamol_count=patients.with_these_medications(
    #         salbutamol_codes,
    #         between=['2018-02-01', '2020-02-01'],
    #         returning="number_of_matches_in_period"
    #     ),
    #     recent_ics=patients.with_these_medications(
    #         ics_codes,
    #         between=['2018-02-01', '2020-02-01'],
    #     )
    # )
)
