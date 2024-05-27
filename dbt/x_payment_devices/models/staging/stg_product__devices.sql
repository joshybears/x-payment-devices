-- stg_product__devices.sql

{{ config(materialized='view') }}
-- add uniques /not nulls?

with

source as (

    select * from {{ source('product','devices') }}

),

renamed as (

    select
        -- ids
        id as device_id,
        store_id as store_id,

        -- int
        type as type

    from source

)

select * from renamed