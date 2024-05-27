{{ config(
    materialized='table',
    post_hook=[
        "ALTER TABLE {{ this }} ADD CONSTRAINT pk_dim_store PRIMARY KEY (store_id)",
        "ALTER TABLE {{ this }} CLUSTER BY (store_id, customer_id, created_date)"
    ]
) }}


SELECT
    store_id,
    customer_id,
    name,
    address,
    city,
    country,
    typology,
    created_date,
    created_at
FROM {{ ref('stg_product__stores') }}