/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		-- Datawarehouse.bronze.crm_cust_info
		PRINT '=============================';
		PRINT 'lOADING BRONZE LAYER'
		PRINT '=============================';
	
		PRINT '-----------------------------';
		PRINT 'lOAIND CRM TABLE';
		PRINT '-----------------------------';
		
		SET @batch_start_time = GETDATE();
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE Datawarehouse.bronze.crm_cust_info;
		
		PRINT '>> Inserting Data Into: bronze.crm_cust_info';
		BULK INSERT Datawarehouse.bronze.crm_cust_info
		FROM '/opt/projects/sql-datawarehouse-project/datasets/source_crm/cust_info.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> lOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + 'seconds';
		PRINT '------------------------------------------------------------------------------------';
		
		SET @start_time = GETDATE();
		--Datawarehouse.bronze.crm_prd_info
		PRINT '>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE Datawarehouse.bronze.crm_prd_info;
		
		PRINT '>> Inserting Data Into: bronze.crm_prd_info';
		BULK INSERT Datawarehouse.bronze.crm_prd_info
		FROM '/opt/projects/sql-datawarehouse-project/datasets/source_crm/prd_info.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> lOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + 'seconds';
		PRINT '------------------------------------------------------------------------------------';
		
		SET @start_time = GETDATE();
		--Datawarehouse.bronze.crm_sales_details
		PRINT '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE Datawarehouse.bronze.crm_sales_details;
		
		PRINT '>> Inserting Data Into: bronze.crm_sales_details';
		BULK INSERT Datawarehouse.bronze.crm_sales_details
		FROM '/opt/projects/sql-datawarehouse-project/datasets/source_crm/sales_details.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> lOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + 'seconds';
		PRINT '------------------------------------------------------------------------------------';
		
		PRINT '-----------------------------';
		PRINT 'lOAIND ERP TABLE';
		PRINT '-----------------------------';
		
		SET @start_time = GETDATE();
		--Datawarehouse.bronze.erp_cust_az12
		PRINT '>> Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE Datawarehouse.bronze.erp_cust_az12;
		
		PRINT '>> Inserting Data Into: bronze.erp_cut_az12';
		BULK INSERT Datawarehouse.bronze.erp_cust_az12
		FROM '/opt/projects/sql-datawarehouse-project/datasets/source_erp/CUST_AZ12.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> lOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + 'seconds';
		PRINT '------------------------------------------------------------------------------------';
		
		SET @start_time = GETDATE();
		--Datawarehouse.bronze.erp_loc_a101
		PRINT '>> Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE Datawarehouse.bronze.erp_loc_a101;
		
		PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
		BULK INSERT Datawarehouse.bronze.erp_loc_a101
		FROM '/opt/projects/sql-datawarehouse-project/datasets/source_erp/LOC_A101.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> lOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + 'seconds';
		PRINT '------------------------------------------------------------------------------------';
		
		SET @start_time = GETDATE();
		--Datawarehouse.bronze.erp_px_cat_g1v2
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE Datawarehouse.bronze.erp_px_cat_g1v2;
		
		PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
		BULK INSERT Datawarehouse.bronze.erp_px_cat_g1v2
		FROM '/opt/projects/sql-datawarehouse-project/datasets/source_erp/PX_CAT_G1V2.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> lOAD DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + 'seconds';
		PRINT '------------------------------------------------------------------------------------';
		
		SET @batch_end_time = GETDATE();
		PRINT '=============================';
		PRINT 'lOADING BRONZE LAYER IS COMPLETED';
		PRINT '>>> TOTAL LOAD DURATION: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS VARCHAR) + 'seconds';
		
	END TRY
	BEGIN CATCH
		PRINT '=============================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'ERROR MESSAGE ' + ERROR_MESSAGE();
		PRINT 'ERROR MESSAGE ' + CAST(ERROR_NUMBER() AS VARCHAR);
		PRINT 'ERROR MESSAGE ' + CAST(ERROR_STATE() AS VARCHAR);
		PRINT '=============================';
	END CATCH
END
