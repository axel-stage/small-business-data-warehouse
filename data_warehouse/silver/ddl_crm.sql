/*===============================================
  build crm tables in silver layer
===============================================*/
create schema if not exists silver;

drop table if exists silver.crm_customer_info;
create table silver.crm_customer_info (
    cst_id                  bigint,
    cst_key                 varchar(1000),
    cst_firstname           varchar(1000),
    cst_lastname            varchar(1000),
    cst_martial_status      varchar(100),
    cst_gender              varchar(100),
    cst_create_date         date,
    dwh_create_date         timestamp(2)    default     current_timestamp
);

drop table if exists silver.crm_product_info;
create table silver.crm_product_info (
    prd_id                  bigint,
    prd_key                 varchar(1000),
    prd_category_id         varchar(1000),
    prd_name                varchar(1000),
    prd_line                varchar(1000),
    prd_price               int,
    prd_price_start         date,
    prd_price_end           date,
    dwh_create_date         timestamp(2)    default     current_timestamp
);

drop table if exists silver.crm_sales_details;
create table silver.crm_sales_details (
    sls_ord_num             varchar(100),
    sls_prd_key             varchar(100),
    sls_cst_id              int,
    sls_order_date          date,
    sls_ship_date           date,
    sls_due_date            date,
    sls_sales               int,
    sls_quantity            int,
    sls_price               int,
    dwh_create_date         timestamp(2)    default     current_timestamp
);
