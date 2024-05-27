-- stg_product__transactions.sql

{{ config(materialized='view') }}


with

source as (

    select * from {{ source('product', 'transactions') }}

),

renamed as (

    select
        -- ids
        id as transaction_id,
        device_id as device_id,

        -- strings
        product_name_1 as product_name,
        REPLACE(REPLACE(product_sku, 'v', ''), '.0', '') as product_sku, -- remove v
        status as status,
        REPLACE(REPLACE(card_number, ' ', ''), '.0', '') as card_number, -- remove spaces
        REPLACE(cvv, '.0', '') as cvv,

        -- numerics
        amount as amount,

        -- booleans
        case
            when status = 'accepted' then true
            else false
        end as is_payment_completed,

        -- dates
        date_trunc('day', CONVERT_TIMEZONE('UTC', created_at::timestamp_ntz))::DATE AS created_date,
        date_trunc('day', CONVERT_TIMEZONE('UTC', happened_at::timestamp_ntz))::DATE AS happened_date,

        -- timestamps
        CONVERT_TIMEZONE('UTC', created_at::timestamp_ntz) AS created_at,
        CONVERT_TIMEZONE('UTC', happened_at::timestamp_ntz) AS happened_at

    from source

)

select * from renamed