PROCEDURE          CHECK_START_LINE  --Create by  maggie chang on 20150626 for S000003611
(
 STATION_NUM            IN        VARCHAR2,
 DATA                    IN          VARCHAR2,
 W_STATION            IN        VARCHAR2,
 LINE                IN        VARCHAR2,
 RES                  OUT          VARCHAR2
) AS
e_NULL                  EXCEPTION;

BEGIN
    IF DATA<>'CHANGE LINE' THEN
        RES:='NO ERROR SCAN';
        RAISE e_NULL;
    END IF;

    RES:='OK';

EXCEPTION
    WHEN e_NULL THEN NULL;
    WHEN OTHERS THEN
        RES:='OTHER ERROR '||SUBSTR(SQLERRM,1,50);
END;