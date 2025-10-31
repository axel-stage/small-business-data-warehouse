/*============================================
  Data Definition Language: Build erp tables
============================================*/
create schema if not exists bronze;

drop table if exists bronze.erp_loc_a101;
create table bronze.erp_loc_a101 (
    cid    varchar(500),
    cntry  varchar(500)
);

drop table if exists bronze.erp_cust_az12;
create table bronze.erp_cust_az12 (
    cid    varchar(500),
    bdate  date,
    gen    varchar(500)
);

drop table if exists bronze.erp_px_cat_g1v2;
create table bronze.erp_px_cat_g1v2 (
    id           varchar(500),
    cat          varchar(500),
    subcat       varchar(500),
    maintenance  varchar(500)
);