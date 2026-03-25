PROCEDURE                      CHECK_PROGRAM_VERSION (
DATA                 IN VARCHAR2,
PROGRAM              IN VARCHAR2,
FLAG                 IN VARCHAR2,
RESERVEDATA          IN VARCHAR2,
RES                  OUT VARCHAR2
) AS
SN_COUNT             VARCHAR2(30);----SN count in SFISM4.R_PROGRAMVERSION_T
p_model              VARCHAR2(30);-- Get model_name from wip_tracking_t
Model_Cnt            Number(2,0);
PRO_COUNT            VARCHAR2(30);
p_FIRST_PRO          VARCHAR2(30);
p_LAST_PRO           VARCHAR2(30);
v_SNCNT              NUMBER(2,0);----SN count in SFISM4.R_WIP_TRACKING_T

STANDARDPRO_CNT      NUMBER(2,0);
STANDARD_PRO         VARCHAR2(30);
RECORDCNT            NUMBER(2,0);

version_str          VARCHAR2(30);
begin_pos            VARCHAR2(30);
charnum              VARCHAR2(30);
board_version        VARCHAR2(30);
cur_board_version    VARCHAR2(30);
cur_version_str      VARCHAR2(30);

e_NO_SN              EXCEPTION;
e_ERROR_PROVERSION   EXCEPTION;
e_NO_STANDARD_PRO    EXCEPTION;

BEGIN
   --CHECK THE SERIAL NUMBER EXSISTANCE  IN WIP_TRACKING_T
   SELECT COUNT(*)
   INTO v_SNCNT
   FROM SFISM4.R_WIP_TRACKING_T
   WHERE SERIAL_NUMBER=DATA;

   IF v_SNCNT=0 THEN
      RAISE e_NO_SN;
   END IF;

   --GET THE  MODEL_NAME BY SERIAL NUMBER  IN WIP_TRACKING_T
   select MODEL_NAME
   into p_model
   from sfism4.R_WIP_TRACKING_T
   where serial_number=DATA;

   --examine if THE  MODEL_NAME exist IN sfis1.C_PROGRAMVERSION_T
   select count(*)
   into  Model_Cnt
   from  sfis1.C_PROGRAMVERSION_T
   where MODEL_NAME=p_model;

   if Model_Cnt>0 then  -- if the model_name exist in sfis1.C_PROGRAMVERSION_T

      select PRODUCT_DESC
      into   version_str   ----for example  :  6;2:0E
      from   SFIS1.C_PROGRAMVERSION_T
      where  MODEL_NAME=p_model and rownum=1;

      ---version_str<>'NONE'  represent the product is MB
      if version_str<>'NONE' then
         begin_pos:=SUBSTR(version_str,1,INSTR(version_str,';')-1); --6
         version_str:=SUBSTR(version_str,INSTR(version_str,';')+1,LENGTH(version_str)-INSTR(version_str,';')); --2:0A
         charnum:=SUBSTR(version_str,1,INSTR(version_str,':')-1);  ----2
         board_version:=SUBSTR(version_str,INSTR(version_str,':')+1,LENGTH(version_str)-INSTR(version_str,':'));---0A

         cur_board_version:=SUBSTR(DATA,begin_pos,charnum);
         cur_version_str:=begin_pos ||';'||charnum||':'||cur_board_version;

         --examine if THE  MODEL_NAME,PRODUCT_DESC both exist IN sfis1.C_PROGRAMVERSION_T
         select Count(*)
         into STANDARDPRO_CNT
         from SFIS1.C_PROGRAMVERSION_T
         where MODEL_NAME=p_model and PRODUCT_DESC=cur_version_str;

         if  STANDARDPRO_CNT=0 then
                raise e_NO_STANDARD_PRO;
         end if;

         select PROGRAM_VERSION
         into STANDARD_PRO
         from SFIS1.C_PROGRAMVERSION_T
         where MODEL_NAME=p_model and PRODUCT_DESC=cur_version_str;
      end if;

      ---version_str='NONE'  represent the product is Graphic Card
      if version_str='NONE' then
         select PROGRAM_VERSION
         into STANDARD_PRO
         from SFIS1.C_PROGRAMVERSION_T
         where MODEL_NAME=p_model and rownum=1;
      end if;

      ---trim(STANDARD_PRO);

      select Count(*)-- examine the sn's existance in sfism4.R_PROGRAMVERSION_T
         into SN_COUNT
      from sfism4.R_PROGRAMVERSION_T
      where SERIAL_NUMBER=DATA;

      if SN_COUNT=0 then
         -- if not exist then insert a new record
              insert into sfism4.R_PROGRAMVERSION_T(SERIAL_NUMBER,MODEL_NAME,PROGRAM_VERSION1,PROGRAM_VERSION2,RESERVE,TESTDATE)
           values(DATA,p_model,PROGRAM,'','',sysdate);
           commit;

         --check if the pro and model_name in the sfis1.C_PROGRAMVERSION_T
         select count(*)
         into RECORDCNT
         from sfis1.C_PROGRAMVERSION_T
         where MODEL_NAME=p_model and PROGRAM_VERSION=PROGRAM;

           if RECORDCNT=0 then
             RAISE e_ERROR_PROVERSION;
           end if;

           RES:='OK';
         end if;

         if SN_COUNT>0 then
           select    PROGRAM_VERSION1,PROGRAM_VERSION2
           into p_FIRST_PRO,p_LAST_PRO
           from sfism4.R_PROGRAMVERSION_T
           where SERIAL_NUMBER=DATA;

            if (p_FIRST_PRO is null) and (p_LAST_PRO is null) then
               update sfism4.R_PROGRAMVERSION_T
               set PROGRAM_VERSION1=PROGRAM,TESTDATE=sysdate
               WHERE SERIAL_NUMBER=DATA;
               commit;
            end if;

            if (p_FIRST_PRO is not null) or (p_LAST_PRO is not null) then
               update sfism4.R_PROGRAMVERSION_T
               set PROGRAM_VERSION2=PROGRAM,TESTDATE=sysdate
             WHERE SERIAL_NUMBER=DATA;
              commit;
           end if;

         --check if the pro and model_name in the sfis1.C_PROGRAMVERSION_T
         select count(*)
         into RECORDCNT
         from sfis1.C_PROGRAMVERSION_T
         where MODEL_NAME=p_model and PROGRAM_VERSION=PROGRAM;

           if RECORDCNT=0 then
             RAISE e_ERROR_PROVERSION;
           end if;

           RES:='OK';
         end if;
   end if;

   RES:='OK';


--------------------------------------------------------------------------------------
-- EXCEPTION HANDLE BLOCK
EXCEPTION
          WHEN e_NO_SN THEN
                 BEGIN
                         RES:='NO SN';
               END;
          WHEN e_ERROR_PROVERSION THEN
               BEGIN
                    RES:='FAIL:PROGRAM VERSION ERROR';
               END;
          WHEN e_NO_STANDARD_PRO THEN
               BEGIN
                    RES:='FAIL:STANDARD PROGRAM VERSION NO FOUND';
               END;
          WHEN OTHERS THEN
                 RES:='OTHER ERROR: '||SUBSTR(SQLERRM,1,60);
END;
/* ******************************************************
Revision:1.0
CREATED BY: Anthony Zhang
CREATE DATE: 05-17-2005

FOR: M/b Test Program Version Control
RES:
0- OK
1- Error
******************************************************** */