PROCEDURE                               Qualitytest (Res OUT VARCHAR2)
IS
   W_Model      VARCHAR2 (20 BYTE);
   W_Benche     VARCHAR2 (20 BYTE);
   W_Sampling   VARCHAR2 (20 BYTE);
   W_Count1     VARCHAR2 (20 BYTE);
   W_Count2     VARCHAR2 (20 BYTE);
   W_Rate       VARCHAR2 (20 BYTE);
   E_Null       EXCEPTION;


   CURSOR Sampling
   IS
      SELECT Model_Name, Benche_Station, Sampling_Station
        FROM Sfis1.C_Samtest_T;
BEGIN
   OPEN Sampling;
    delete from Sfis1.C_Samtestrate_T;
    commit;
   LOOP
      FETCH Sampling
      INTO W_Model, W_Benche, W_Sampling;

      EXIT WHEN Sampling%NOTFOUND;

     
         SELECT COUNT (Serial_Number)
           INTO W_Count1
           FROM Sfism4.R_Sn_Detail_T
          WHERE     In_Station_Time > TRUNC (SYSDATE)                               
                AND Group_Name = W_Benche
                AND Model_Name = W_Model;

         SELECT COUNT (Serial_Number)
           INTO W_Count2
           FROM Sfism4.R_Sn_Detail_T
          WHERE     In_Station_Time > TRUNC (SYSDATE)
                AND Group_Name = W_Sampling
                AND Model_Name = W_Model;

         IF W_Count1 > 0
         THEN
            SELECT  TRUNC((W_Count2/W_Count1)*100) INTO W_Rate FROM DUAL;

            INSERT INTO Sfis1.C_Samtestrate_T
                 VALUES (W_Model,
                         W_Rate,
                         W_Benche,
                         W_Sampling,
                         W_Count1,
                         W_Count2);
                         
        
         END IF;
      
   END LOOP;

   CLOSE Sampling;

   Res := 'OK!';
EXCEPTION
   WHEN OTHERS
   THEN
      Res := 'OTHER ERROR' ;
END;