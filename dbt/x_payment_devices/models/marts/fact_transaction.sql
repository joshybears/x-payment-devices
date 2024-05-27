{{ config(
    materialized='table',
    post_hook=[
        "ALTER TABLE {{ this }} ADD CONSTRAINT pk_fact_transaction PRIMARY KEY (transaction_id)",
        "ALTER TABLE {{ this }} ADD CONSTRAINT fk_fact_transaction_device FOREIGN KEY (device_id) REFERENCES {{ ref('dim_device') }}(device_id)",
        "ALTER TABLE {{ this }} ADD CONSTRAINT fk_fact_transaction_store FOREIGN KEY (store_id) REFERENCES {{ ref('dim_store') }}(store_id)",
        "ALTER TABLE {{ this }} ADD CONSTRAINT fk_fact_transaction_product FOREIGN KEY (product_sku) REFERENCES {{ ref('dim_product') }}(product_sku)",
        "ALTER TABLE {{ this }} CLUSTER BY (transaction_id, store_id, device_id, product_sku, happened_date)"
    ]
) }}


SELECT
    t.transaction_id AS transaction_id,
    t.device_id,
    d.store_id,
    t.product_sku,
    t.amount,
    t.status,
    t.card_number,
    t.cvv,
    t.is_payment_completed,
    t.created_date,
    t.happened_date,
    t.created_at,
    t.happened_at
FROM {{ ref('stg_product__transactions') }} t
JOIN {{ ref('stg_product__devices') }} d ON t.device_id = d.device_id