PROCEDURE             Make_Feeder_Bom_Line(
--
-- This procedure is for MakeFeeder  and this request is asked by Yu XianJin on F20 site.
--2007-0712  By  ToTo Lee
--
PN	   	  		  			 IN VARCHAR2,
LineType 			     IN VARCHAR2,
MachineType 		 IN VARCHAR2,
LineNames 			   IN VARCHAR2,
EmpNo 			        IN VARCHAR2,
RES						    OUT VARCHAR2)
IS
--
BomNo  			   	 VARCHAR2(400);
LineName             VARCHAR2(100);
strLineNames             VARCHAR2(100);
MachineCode		   VARCHAR2(32);
FeederNo 			 VARCHAR2(16);
KeyPN				   VARCHAR2(32);
OutFlag  			     NUMBER;
InFlag					  NUMBER;
BomNoIndex            NUMBER;
MachineCodeIndex NUMBER ;


endIndex               NUMBER;
--
CURSOR  c_MachineCode(vLineName VARCHAR2)  IS
      SELECT DISTINCT MACHINE_CODE
        FROM sfis1.C_BOM_LINE_T
		WHERE LINE_TYPE=LineType
		AND LINE_NAME=vLineName
		AND MACHINE_TYPE=MachineType  ORDER BY MACHINE_CODE ASC;
--
CURSOR  c_BomNO  IS
      SELECT DISTINCT BOM_NO
        FROM sfis1.C_BOM_DESC_T
		WHERE  PRODUCT_NO=PN
		AND  MACHINE_TYPE=MachineType
		AND LINE_TYPE=LineType ORDER BY BOM_NO ASC;
--
CURSOR  c_FeederPN(vBomNo VARCHAR2)  IS
      SELECT DISTINCT FEEDER_NO
        FROM sfis1.C_BOM_DETAIL_T
		WHERE  BOM_NO=vBomNo ;

BEGIN
--
--prepare
--
strLineNames:=LineNames;
--
--The most out loop begin
LOOP --first
--
--Fetch each LineName in LineNames ,then repeat
endIndex:=0;
endIndex:=INSTR(strLineNames,',');
	LineName:=SUBSTR(strLineNames,0,endIndex-1);
	IF LineName IS NULL THEN
	   LineName:=strLineNames;
	   strLineNames:='';
	END IF;
	strLineNames:=SUBSTR(strLineNames,endIndex+1);
--End Fetch;

		   BomNoIndex:=0;
            OPEN  c_BomNo;  --second
   	 	    LOOP
    		FETCH   c_BomNO  INTO BomNO;
			EXIT WHEN  c_BomNO  %NOTFOUND;
			    --
				  --Main part begin: deal all the data in this part
				 -- firstPart :insert into sfism4.R_SN_DETAIL_T
				 --
				 BomNoIndex:=BomNoIndex+1;
				  MachineCodeIndex:=0;
			     OPEN  c_MachineCode(LineName) ;  -- third
                 LOOP
   	             FETCH  c_MachineCode  INTO MachineCode;
	             EXIT WHEN  c_MachineCode %NOTFOUND;
				--
				          MachineCodeIndex:=MachineCodeIndex+1;
						  IF MachineCodeIndex=BomNoIndex THEN  ---The longest if content
				                 DELETE sfism4.R_SMT_PROD_BOM_T WHERE PRODUCT_NO=PN AND LINE_NAME=LineName AND BOM_NO=BomNO;
					             COMMIT;
				                 INSERT INTO sfism4.R_SMT_PROD_BOM_T(PRODUCT_NO,VER,LINE_NAME,BOM_NO,EMP_NO)
				                 VALUES( PN, 'N/A', LineName, BomNO,	EmpNo  );
				                 COMMIT;
				                 --firstPart
				                  --
				                  -- secondPart:   insert into sfis1.C_SMT_BOM_T
				                  --
				                  OPEN  c_FeederPN(BomNo);   ---forth
				                  --prepare
				                  InFlag:=1;
				                    DELETE  sfis1.C_SMT_BOM_T WHERE BOM_NO=BomNo  AND MACHINE_CODE=MachineCode;
				                    -- end prepare
   	 	     	                   LOOP
    			                  FETCH  c_FeederPN  INTO FeederNo;
				                  EXIT WHEN  c_FeederPN   %NOTFOUND;
				                  SELECT KEY_PART_NO INTO KeyPN
							      FROM sfis1.C_BOM_DETAIL_T
			 				      WHERE BOM_NO=BomNo
							      AND  FEEDER_NO=FeederNo;
							     COMMIT;

							     INSERT INTO sfis1.C_SMT_BOM_T( BOM_NO, MACHINE_CODE,FEEDER_NO,KEY_PART_NO,KP_RELATION, EMP_NO,IMPORT_TIME)
				                 VALUES( BomNo, MachineCode, FeederNo, KeyPN,	InFlag, EmpNo,SYSDATE );
				                 COMMIT;
							     InFlag:=InFlag+1;

			                     END LOOP;
			                     CLOSE c_FeederPN ;		-- end forth
				                   ------------------------------------------
				                 --secondPart
				                 --end main part
			               END IF;  ----End of the longest if content
				END LOOP;
			    CLOSE c_MachineCode;   --end third
				---------------------------------------

			 END LOOP;
			 CLOSE c_BomNO; -- end second
			 ----------------------------------------------


EXIT WHEN strLineNames IS NULL;
END LOOP;  --end first
--
RES:=' OK';
--
-- error message
--
EXCEPTION
   WHEN OTHERS THEN   RES:=' ERROR';
END;