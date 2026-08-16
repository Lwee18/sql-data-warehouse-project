/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;	
	BEGIN TRY
		
		PRINT '=============================';
		PRINT 'lOADING SILVER LAYER'
		PRINT '=============================';
	
		PRINT '-----------------------------';
		PRINT 'lOAIND CRM TABLE';
		PRINT '-----------------------------';
		
		SET @batch_start_time = GETDATE();
		SET @start_time = GETDATE();
		
		PRINT '>> Truncating Table: Datawarehouse.silver.crm_cust_info';
		TRUNCATE TABLE Datawarehouse.silver.crm_cust_info;
		PRINT '>> Insert Data Into: Datawarehouse.silver.crm_cust_info';
		INSERT 	INTO  Datawarehouse.silver.crm_cust_info (cst_id,cst_key,cst_firstname,cst_lastname,cst_marital_status,cst_gndr,cst_create_date)
		select 
			cst_id,
			cst_key,
			TRIM(t.cst_firstname) as cst_firstname,
			TRIM(t.cst_lastname) as cst_lastname,
			CASE WHEN UPPER(TRIM(cst_marital_status))='S' THEN 'Single'
				 WHEN UPPER(TRIM(cst_marital_status))='M' THEN 'Married'
				 ELSE 'n/a' 
			END  cst_marital_status,
			CASE WHEN UPPER(TRIM(cst_gndr))='F' THEN 'Female'
				 WHEN UPPER(TRIM(cst_gndr))='M' THEN 'Male'
				 ELSE 'n/a' 
			END  cst_gndr,
			t.cst_create_date 
		from (
			select 
				* ,
				ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
			from Datawarehouse.bronze.crm_cust_info  where cst_id IS NOT NULL) t
		where flag_last = 1;
		
		SET @end_time = GETDATE();
		PRINT '>> lOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + 'seconds';
		PRINT '------------------------------------------------------------------------------------';
		
		
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: Datawarehouse.silver.crm_prd_info';
		truncate table Datawarehouse.silver.crm_prd_info;
		PRINT '>> Insert Data Into: Datawarehouse.silver.crm_prd_info';
		insert into Datawarehouse.silver.crm_prd_info (
			prd_id       ,
			cat_id 	     ,
			prd_key      ,
			prd_nm       ,
			prd_cost     ,
			prd_line     ,
			prd_start_dt ,
			prd_end_dt   
		)
		select 
			prd_id,
			REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
			SUBSTRING(prd_key,7,LEN(prd_key)) as prd_key,
			prd_nm,
			ISNULL(prd_cost,0),
			CASE UPPER(TRIM(prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'	
				WHEN 'T' THEN 'Touring'
				ELSE 'n/a'
			END prd_line,
			CAST(prd_start_dt AS DATE) AS prd_start_dt,
			CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
		from Datawarehouse.bronze.crm_prd_info
		where prd_id is NOT NULL;
		SET @end_time = GETDATE();
		PRINT '>> lOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + 'seconds';
		PRINT '------------------------------------------------------------------------------------';
		
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: Datawarehouse.silver.crm_sales_details';
		truncate table Datawarehouse.silver.crm_sales_details;
		PRINT '>> Insert Data Into: Datawarehouse.silver.crm_sales_details';
		INSERT  INTO Datawarehouse.silver.crm_sales_details (
			sls_ord_num ,
			sls_prd_key ,
			sls_cust_id ,
			sls_order_dt ,
			sls_ship_dt ,
			sls_due_dt ,
			sls_sales ,
			sls_quantity ,
			sls_price 
		
		)
		SELECT 
			sls_ord_num ,
			sls_prd_key ,
			sls_cust_id ,
			CASE WHEN sls_order_dt = 0 or len(sls_order_dt) != 8 THEN NULL
				 ELSE CAST(CAST (sls_order_dt AS VARCHAR) AS DATE) 
			END AS sls_order_dt,
			
			CASE WHEN sls_ship_dt = 0 or len(sls_ship_dt) != 8 THEN NULL
				 ELSE CAST(CAST (sls_ship_dt AS VARCHAR) AS DATE) 
			END AS sls_ship_dt,
			
			CASE WHEN sls_due_dt = 0 or len(sls_due_dt) != 8 THEN NULL
				 ELSE CAST(CAST (sls_due_dt AS VARCHAR) AS DATE) 
			END AS sls_due_dt,
			
			CASE WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price)
				 THEN sls_quantity * ABS(sls_price)
				 ELSE sls_sales
			END AS sls_sales,
		
			sls_quantity ,
			
			CASE WHEN sls_price <=0 OR sls_price IS NULL  
				 THEN sls_sales / NULLIF(sls_quantity,0)
				 ELSE sls_price
			END AS sls_price 
		from Datawarehouse.bronze.crm_sales_details ;
		SET @end_time = GETDATE();
		PRINT '>> lOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + 'seconds';
		PRINT '------------------------------------------------------------------------------------';
		
		PRINT '-----------------------------';
		PRINT 'lOAIND ERP TABLE';
		PRINT '-----------------------------';
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: Datawarehouse.silver.erp_cust_az12';
		truncate table Datawarehouse.silver.erp_cust_az12;
		PRINT '>> Insert Data Into: Datawarehouse.silver.erp_cust_az12';
		INSERT INTO Datawarehouse.silver.erp_cust_az12 (cid,bdate,gen)
		select 
			CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
				 ELSE cid
			END AS cid,
			CASE WHEN bdate > GETDATE() THEN NULL
				 ELSE bdate
			END AS bdate,
			 CASE
		        WHEN UPPER(TRIM(REPLACE(REPLACE(gen, CHAR(13), ''), CHAR(10), '')))
		             IN ('F', 'FEMALE')
		            THEN 'Female'
		
		        WHEN UPPER(TRIM(REPLACE(REPLACE(gen, CHAR(13), ''), CHAR(10), '')))
		             IN ('M', 'MALE')
		            THEN 'Male'
		
		       ELSE 'n/a'
		    END AS gen
		from Datawarehouse.bronze.erp_cust_az12 ;
		
		SET @end_time = GETDATE();
		PRINT '>> lOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + 'seconds';
		PRINT '------------------------------------------------------------------------------------';
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: Datawarehouse.silver.erp_loc_a101';
		truncate table Datawarehouse.silver.erp_loc_a101;
		PRINT '>> Insert Data Into: Datawarehouse.silver.erp_loc_a101';
		INSERT INTO Datawarehouse.silver.erp_loc_a101 (
				cid,
				cntry
		)
		SELECT
		    REPLACE(cid, '-', '') AS cid,
		    CASE
		        WHEN TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), '')) = 'DE'
		            THEN 'Germany'
		
		        WHEN TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), ''))
		             IN ('US', 'USA')
		            THEN 'United States'
		
		        WHEN TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), '')) = ''
		             OR cntry IS NULL
		            THEN 'n/a'
		
		        ELSE TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), ''))
		    END AS cntry
		FROM Datawarehouse.bronze.erp_loc_a101;
		SET @end_time = GETDATE();
		PRINT '>> lOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + 'seconds';
		PRINT '------------------------------------------------------------------------------------';
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: Datawarehouse.silver.erp_px_cat_g1v2';
		truncate table Datawarehouse.silver.erp_px_cat_g1v2;
		PRINT '>> Insert Data Into: Datawarehouse.silver.erp_px_cat_g1v2';
		INSERT INTO Datawarehouse.silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT 
			id,
			cat,
			subcat,
			naintenance 
		FROM Datawarehouse.bronze.erp_px_cat_g1v2;
		SET @end_time = GETDATE();
		PRINT '>> lOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + 'seconds';
		PRINT '------------------------------------------------------------------------------------';
		
		SET @batch_end_time = GETDATE();
		PRINT '=============================';
		PRINT 'lOADING SILVER LAYER IS COMPLETED';
		PRINT '>>> TOTAL LOAD DURATION: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS VARCHAR) + 'seconds';


	END TRY
	BEGIN CATCH
		PRINT '=============================';
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER'
		PRINT 'ERROR MESSAGE ' + ERROR_MESSAGE();
		PRINT 'ERROR MESSAGE ' + CAST(ERROR_NUMBER() AS VARCHAR);
		PRINT 'ERROR MESSAGE ' + CAST(ERROR_STATE() AS VARCHAR);
		PRINT '=============================';
	END CATCH
END
