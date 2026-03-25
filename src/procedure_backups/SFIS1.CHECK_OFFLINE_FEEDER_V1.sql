PROCEDURE       CHECK_OFFLINE_FEEDER_V1
(
 EMP   	  		  IN		VARCHAR2,
 MACHINE  		  IN		VARCHAR2,
 TBL			  IN		VARCHAR2,
 VEH			  IN		VARCHAR2,
 PPN			  IN		VARCHAR2,
 RES			  OUT		VARCHAR2
) IS

V_COUNT1		  NUMBER;
V_COUNT2		  NUMBER;

e_NULL			  EXCEPTION;

BEGIN
    IF TBL <> 'N/A' AND VEH = 'N/A' THEN
		SELECT COUNT(*)
		INTO   V_COUNT1
		FROM   SFISM4.R_OFFLINE_LOG_T
		WHERE  MACHINE_CODE = MACHINE
			   AND TABLE_NO = TBL
			   AND PRODUCT_NO = PPN
			   AND FLAG = '0'
			   AND CREATE_DT = (SELECT MAX(CREATE_DT)
			   	   			    FROM   SFISM4.R_OFFLINE_LOG_T
								WHERE  MACHINE_CODE = MACHINE
									   AND TABLE_NO = TBL
									   AND PRODUCT_NO = PPN);
		IF V_COUNT1 = 0 THEN
		    RES:='NO SCAN ERROR 1';
			RAISE e_NULL;
		END IF;
	END IF;

	IF TBL <> 'N/A' AND VEH <> 'N/A' THEN
		SELECT COUNT(*)
		INTO   V_COUNT2
		FROM   SFISM4.R_OFFLINE_LOG_T
		WHERE  MACHINE_CODE = MACHINE
			   AND TABLE_NO = TBL
			   AND VEHICLE_NO = VEH
			   AND PRODUCT_NO = PPN
			   AND FLAG = '0'
			   AND CREATE_DT = (SELECT MAX(CREATE_DT)
			   	   			    FROM   SFISM4.R_OFFLINE_LOG_T
								WHERE  MACHINE_CODE = MACHINE
									   AND TABLE_NO = TBL
									   AND VEHICLE_NO = VEH
									   AND PRODUCT_NO = PPN);
		IF V_COUNT2 = 0 THEN
			RES:='NO SCAN ERROR 2';
			RAISE e_NULL;
		END IF;

		UPDATE SFISM4.R_OFFLINE_LOG_T
		SET	   FLAG = '1',
			   LAST_EDIT_BY = EMP,
			   LAST_EDIT_DT = SYSDATE
		WHERE  MACHINE_CODE = MACHINE
			   AND TABLE_NO = TBL
			   AND VEHICLE_NO = VEH
			   AND PRODUCT_NO = PPN
			   AND FLAG = '0'
			   AND CREATE_DT = (SELECT MAX(CREATE_DT)
			   	   			    FROM   SFISM4.R_OFFLINE_LOG_T
								WHERE  MACHINE_CODE = MACHINE
									   AND TABLE_NO = TBL
									   AND VEHICLE_NO = VEH
									   AND PRODUCT_NO = PPN);
	END IF;
	RES:='OK';
EXCEPTION
	WHEN e_NULL THEN
		INSERT INTO SFISM4.R_OFFLINE_LOG_ERROR_T
		(
		    MACHINE_CODE,
			TABLE_NO,
			VEHICLE_NO,
			PRODUCT_NO,
			ERROR_MES,
			CREATE_BY,
			CREATE_DT
		)
		VALUES
		(
		    MACHINE,
			TBL,
			VEH,
			PPN,
			RES,
			EMP,
			SYSDATE
		);
	WHEN OTHERS THEN
		ROLLBACK;
		RES:='OTHER ERROR '||SUBSTR(SQLERRM,1,10);
		INSERT INTO SFISM4.R_OFFLINE_LOG_ERROR_T
		(
		    MACHINE_CODE,
			TABLE_NO,
			VEHICLE_NO,
			PRODUCT_NO,
			ERROR_MES,
			CREATE_BY,
			CREATE_DT
		)
		VALUES
		(
		    MACHINE,
			TBL,
			VEH,
			PPN,
			RES,
			EMP,
			SYSDATE
		);
END;
/***************************************************************
*    Create Tag:Steven Hu20090615
*    Review Tag:
*    Revise Tag:
*    Revise Log:
*    Review Tag:
*    Input Parameters:
* 		 EMP: 員工號
* 		 MACHINE: 機臺號
*		 TBL:TABLE號
*		 VEH:臺車號
*		 PPN:產品料號
*    Output Parameters：
* 		 RES: 存儲過程執行結果
*	 Description: SMT高速機線外上料后物料上線時比對機臺號，TABLE號，臺車號，產品料號的對應關系
*    Version: V1.0
***************************************************************/
