/*===============================================
  build erp tables in silver layer
===============================================*/
create schema if not exists silver;

drop table if exists silver.erp_customer_az12;
create table silver.erp_customer_az12 (
    cid                     varchar(100),
    bdate                   date,
    gender                  varchar(100),
    dwh_create_date         timestamp(2)    default     current_timestamp
);

drop table if exists silver.erp_loc_a101;
create table silver.erp_loc_a101 (
    cid                     varchar(100),
    country                 varchar(1000),
    dwh_create_date         timestamp(2)    default     current_timestamp
);

drop table if exists silver.erp_px_cat_g1v2;
create table silver.erp_px_cat_g1v2 (
    id                      varchar(100),
    category                varchar(100),
    subcategory             varchar(100),
    maintenance             varchar(100),
    dwh_create_date         timestamp(2)    default     current_timestamp
);
