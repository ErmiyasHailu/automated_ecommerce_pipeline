# Automated E-Commerce Data Pipeline

## Project Overview

This project demonstrates an automated data engineering pipeline that extracts sample e-commerce data from the Fake Store API, loads the data into Snowflake, and prepares it for analysis using SQL transformations.

The project uses Python for API extraction and data loading, Snowflake as the cloud data warehouse, SQL for data transformations, and Apache Airflow for workflow orchestration.

**Note:** The Fake Store API provides mock data for demonstration purposes, not real customer transactions.

## Technologies Used

- **Python** – API extraction, JSON handling, and Snowflake data loading
- **REST API** – Fake Store API data source
- **Snowflake** – Cloud data warehouse
- **SQL** – Data cleaning, transformation, and analytical queries
- **Apache Airflow** – Workflow orchestration
- **Docker** – Running Airflow services in containers
- **Git and GitHub** – Version control and project management

## Data Pipeline Architecture

1. **Extract:** Python retrieves products, users, and carts from the Fake Store API.
2. **Store:** Extracted JSON data is saved locally as raw files.
3. **Load:** Python Snowflake Connector loads the raw data into Snowflake tables.
4. **Transform:** SQL cleans and transforms the raw data into structured analytical tables.
5. **Orchestrate:** Apache Airflow coordinates pipeline tasks and their execution order.

## Project Structure

```text
automated_ecommerce_pipeline/
│
├── airflow/
│   ├── dags/
│   │   └── first_dag.py
│   └── docker-compose.yaml
│
├── sql/
│   ├── transform_products.sql
│   ├── transform_users.sql
│   ├── transform_carts.sql
│   └── analytics_queries.sql
│
├── src/
│   ├── extract.py
│   ├── inspect_files.py
│   └── load.py
│
├── .gitignore
└── README.md
```

## Data Sources

The pipeline uses three Fake Store API endpoints:

- Products
- Users
- Carts

## SQL Transformations

SQL transformations are performed in Snowflake to:

- Clean product data.
- Prepare user data while excluding unnecessary sensitive fields.
- Flatten nested cart product information.
- Create structured analytical tables.
- Perform data quality checks.

## Data Quality

Data quality checks include:

- Checking for missing values.
- Identifying duplicate records.
- Validating required fields.
- Checking transformed data.

## Future Improvements

- Complete automated SQL execution through Airflow.
- Add automated pipeline monitoring and error handling.
- Improve data quality validation.
- Add scheduled pipeline execution.

## Purpose

This project demonstrates practical entry-level data engineering skills, including API ingestion, Python programming, cloud data warehousing, SQL transformations, and workflow orchestration.