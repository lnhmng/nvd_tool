PROCEDURE             CHECK_REWORK_MO_RMA (
  DATA      IN       VARCHAR2,
  RES       OUT      VARCHAR2
)
IS
  V_MO                VARCHAR2 (32);
  V_TYPE              VARCHAR2 (32);
  V_FLAG              VARCHAR2 (32);
  V_COUNT             NUMBER;
BEGIN  --Lyc 20230307
  V_MO:=DATA;

  SELECT COUNT(*) INTO V_COUNT FROM SFISM4.r_mo_base_t WHERE MO_NUMBER=V_MO;

  SELECT MO_TYPE,CLOSE_FLAG INTO V_TYPE,V_FLAG FROM SFISM4.r_mo_base_t WHERE MO_NUMBER=V_MO;

  RES := 'OK';
exception  
   WHEN OTHERS THEN 
    BEGIN 
        IF V_COUNT < 1 THEN
            RES := 'NO MO';
        ELSIF V_TYPE<>'REWORK' THEN
            RES := 'MO ERROR:NOT REWORK MO';
        ELSIF V_FLAG <>'2' THEN
            RES := 'MO ERROR:MO NOT OPEN OR CLOSED';
        END IF ;  
    END;
END;