{{ config(
    materialized='table',
    post_hook=[
        "ALTER TABLE {{ this }} ADD CONSTRAINT pk_dim_product PRIMARY KEY (product_sku)",
        "ALTER TABLE {{ this }} CLUSTER BY (product_sku)"
    ]
) }}

WITH ranked_products AS (
    SELECT
        product_sku,
        product_name,
        ROW_NUMBER() OVER (PARTITION BY product_sku ORDER BY happened_at) AS name_rank
    FROM {{ ref('stg_product__transactions') }}
)
SELECT
    product_sku,
    product_name
FROM ranked_products
WHERE name_rank = 1