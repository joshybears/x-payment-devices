-- stg_product__stores.sql

{{ config(materialized='view') }}

with

source as (

    select * from {{ source('product', 'stores') }}

),

renamed as (

    select
        -- ids
        id as store_id,
        customer_id as customer_id,

        -- strings
        name as name,
        address as address,
        city as city,
        country as country,
        typology as typology,

        -- dates
        date_trunc('day', CONVERT_TIMEZONE('UTC', created_at::timestamp_ntz))::DATE AS created_date,

        -- timestamps
        CONVERT_TIMEZONE('UTC', created_at::timestamp_ntz) AS created_at

    from source

)

select * from renamed