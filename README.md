# x-payment-devices

## Project Overview

### Description
`x-payment-devices` is a small ELT project that gets product data for a company that provides payment devices for retail stores, uploads it onto a Snowflake, and allows tranformation via DBT. 

### Folder Structure
```
.
├── Pipfile
├── Pipfile.lock
├── README.md
├── dbt
│   ├── [redacted]
├── files
│   ├── device
│   │   └── device.xlsx
│   ├── store
│   │   └── store.xlsx
│   └── transaction
│       └── transaction.xlsx
├── loader
│   ├── loader.py
│   └── objects.py
```

- Pipfile / Pipfile.lock
  - Pipenv utility files
- README.md
  - Project and implementation details
- dbt
  - DBT folder containing data models/tests/documentation
- files
  - Provided data files
- loader
  - Scripts for loading data onto DB

## Setup and Execution Instructions

### Pipenv
In this project, we use Pipenv to install Python dependencies that we need, for both our ELT script and DBT.
1. Make sure you have Pipenv installed (https://pipenv.pypa.io/en/latest/installation.html)
2. Simply run `pipenv install` in the main directory
   - This will install all the libraries and dependencies that the project needs according to the Pipfile

### Data Loader
In this project, we use a Python script to upload data from local files into Snowflake.
1. Simply run `pipenv run python loader/loader.py` in the main directory
  - This will read through all of the files in the files/ directory per object specified and load them into Snowflake using PUT and COPY INTO

### DBT
In this project, we use Pipenv to install Python dependencies that we need, for both our ETL script and the visualization tool we use (Jupyter notebook).
1. Navigate to the main DBT directory (x-payment-devices/dbt/x_payment_devices)
2. To run all the models, `pipenv run dbt run` in this directory
3. To run data quality tests, `pipenv run dbt test` in this directory
3. To see data documentation, `pipenv run dbt docs generate` and then `pipenv run dbt docs serve` in this directory, then go to http://localhost:8080 on your browser

## Discussion

### Data Concerns and Assumptions

- In the transactions data, there are two columns with 'product_name' label, handled this by using just the first column.
- In the transactions data, product_sku + product_name are not groupable because there are multiple product name entries per SKU. Handled this by extracting a single product_name per SKU and using that for all instances of that SKU.
- Product SKUs have a preceding 'v' sometimes. Removed this in staging layer.
- Card numbers have irregular spacing. Removed spaces in staging layer.

### Orchestrator
- I've decided to not include an orchestrator with the solution. Reasoning:
  - Since the scope of the project appears to be limited to a specific set of data files and a defined loading process, we are keeping it simple with no orchestrator.
  - Manual execution for the project is feasible as we are dealing with a limited number of files and there is no need for scheduling/backfills.
  - Some modern orchestrators integrate Pandas, which we are discouraged to use for this project.
  - Certainly an orchestrator can be added to the project, if there is a need to adapt to additional complexity / volume. 

### Data Loading
- I've decided to create a Python script to upload data into Snowflake. (loader/loader.py)
  - Primarily because as an individual developer, the other loading options are not available to me, although it will be much better and scalable (copy from cloud storage, snowpipe, other data transfer services, third party ETL tools).
  - Functions are modular enough to ensure an easy transition to any other platform.
  - Ideally script should perform well, because we are using PUT and COPY INTO and not processing individual lines. Up to a certain extent. (File conversion worries me a bit!)
  - Definitely can be improved to use cloud native solutions or distributed processing.
  - Other data loading considerations follow:
    - Keeping track of files that have been processed
    - An additional historical layer, append data from load layer here
    - Make models incremental for events based tables

### Data Transformation and Modeling
1. Load Layer (LOAD)
  - This is where raw data lands from the ingestion process. Contains the following tables:
    - DEVICE
    - STORE
    - TRANSACTION

2. Staging Layer (ANALYTICS_STAGING)
  - In this layer, transformations are applied to clean the data such as renaming, typecasting, and categorizing. Models are also materialized as views so we can make sure we are getting fresh and updated data. Contains the following tables:
    - STG_PRODUCT__DEVICES
    - STG_PRODUCT__STORES
    - STG_PRODUCT__TRANSACTIONS
  - In this layer as well, we do basic tests to ensure that all data that lands in our WH is good and valid.
  - To protect personal information, ideally we would apply masking to the PII (card number and CVV) for transactions table, and also restrict access to load layer, if we were using the enterprise version.

3. Marts Layer (ANALYTICS_MARTS)
  - In this layer, the focus is on transforming the cleaned data from the staging layer into a more business-friendly format, organized into star schema entities. This involves creating fact and dimension tables to support analytical queries and reporting, while optimizing the data for performance and ease of use.
  - Contains the following tables:
    - dim_device
    - dim_product
    - dim_store
    - fact_transaction
  - In this layer as well, we do more comprehensive tests, as well as complete documentation for all fields.
  - We also define constraints for this layer, PKs and FKs.
  - We also define clusters for PKs, FKs, date fields.
  - Star Schema ER Diagram is available below to show table structures and the relationships between them

  ![Star Schema ER Diagram](/images/x-payment-devices-star.drawio.png)

  - An alternative implementation is described in below ER diagram (my first approach)

  ![ER Diagram](/images/x-payment-devices.drawio.png)

## Data Modeling Questions
1. Top 10 stores by transacted amount
```
SELECT 
    ds.store_id, ds.name, SUM(ft.amount) AS total_amount
FROM
    fact_transaction ft
JOIN 
    dim_store ds 
ON 
    ft.store_id = ds.store_id
WHERE
    ft.is_payment_completed
GROUP BY 
    1, 2
ORDER BY 
    3 DESC
LIMIT 10;
```

2. Top 10 products sold

```
SELECT 
    dp.product_sku, dp.product_name, COUNT(*) AS product_count
FROM 
    fact_transaction ft
JOIN 
    dim_product dp 
ON 
    ft.product_sku = dp.product_sku
WHERE
    ft.is_payment_completed
GROUP BY 
    1, 2
ORDER BY 
    3 DESC
LIMIT 10;
```

3. Average transacted amount per store typology and country
(Not necessary that transaction is successful)
```
SELECT 
    s.typology, s.country, AVG(ft.amount) AS avg_amount
FROM 
    fact_transaction ft
JOIN 
    dim_store s 
ON 
    ft.store_id = s.store_id
GROUP BY 
    1, 2
ORDER BY 
    3 DESC
```

4. Percentage of transactions per device type
(Not necessary that transaction is successful)
```
SELECT 
    d.type, COUNT(*) / (SELECT COUNT(*) FROM fact_transaction) AS percentage
FROM 
    fact_transaction ft
JOIN 
    dim_device d 
ON 
    ft.device_id = d.device_id
GROUP BY 
    1
```

5. Average time for a store to perform its 5 first transactions
```
WITH ranked_transactions AS (
    SELECT
        *,
        DENSE_RANK() OVER (PARTITION BY store_id ORDER BY happened_at ASC) AS transaction_rank
    FROM fact_transaction
),

five_first_transactions AS (
    SELECT
        *
    FROM
        ranked_transactions
    WHERE
        transaction_rank <= 5
),

timediff AS (
    SELECT
        store_id,
        TIMEDIFF(day, MIN(happened_at), MAX(happened_at)) as time_diff
    FROM
        five_first_transactions
    GROUP BY
        store_id
)

SELECT
    AVG(time_diff)
FROM
    timediff
```

## Thank you!

Thank you for taking the time to review my solution! I enjoyed the challenge quite a bit. :>