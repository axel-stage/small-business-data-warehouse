/*============================================
  Data Definition Language: Build crm tables
============================================*/
create schema if not exists bronze;

drop table if exists bronze.crm_cust_info;
create table bronze.crm_cust_info
(
    cst_id              int,
    cst_key             varchar(500),
    cst_firstname       varchar(500),
    cst_lastname        varchar(500),
    cst_marital_status  varchar(500),
    cst_gndr            varchar(500),
    cst_create_date     date
);

drop table if exists bronze.crm_prd_info;
create table bronze.crm_prd_info
(
    prd_id       int,
    prd_key      varchar(500),
    prd_nm       varchar(500),
    prd_cost     int,
    prd_line     varchar(500),
    prd_start_dt timestamp,
    prd_end_dt   timestamp
);

drop table if exists bronze.crm_sales_details;
create table bronze.crm_sales_details (
    sls_ord_num  varchar(500),
    sls_prd_key  varchar(500),
    sls_cust_id  int,
    sls_order_dt int,
    sls_ship_dt  int,
    sls_due_dt   int,
    sls_sales    int,
    sls_quantity int,
    sls_price    int
);