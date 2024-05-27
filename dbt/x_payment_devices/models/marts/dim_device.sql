{{ config(
    materialized='table',
    post_hook=[
        "ALTER TABLE {{ this }} ADD CONSTRAINT pk_dim_device PRIMARY KEY (device_id)",
        "ALTER TABLE {{ this }} ADD CONSTRAINT fk_dim_device_store FOREIGN KEY (store_id) REFERENCES {{ ref('dim_store') }}(store_id)",
        "ALTER TABLE {{ this }} CLUSTER BY (device_id, store_id)"
    ]
) }}


SELECT
    device_id,
    store_id,
    type
FROM {{ ref('stg_product__devices') }}