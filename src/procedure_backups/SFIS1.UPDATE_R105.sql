PROCEDURE UPDATE_R105(MYGROUP IN VARCHAR2, MO IN VARCHAR2) AS

p_DefaultGroup  VARCHAR2(16);
p_EndGroup      VARCHAR2(16);
p_Target  NUMBER;
p_Input   NUMBER;
p_Output  NUMBER;

BEGIN

   SELECT DEFAULT_GROUP, END_GROUP, TARGET_QTY, INPUT_QTY, OUTPUT_QTY
      INTO p_DefaultGroup, p_EndGroup, p_Target, p_Input, p_Output
      FROM SFISM4.R_MO_BASE_T
      WHERE MO_NUMBER = MO AND ROWNUM = 1;

   if (MYGROUP = p_DefaultGroup) then
      if (p_Input < p_Target) then
         UPDATE SFISM4.R_MO_BASE_T SET  INPUT_QTY=INPUT_QTY+1
            WHERE  MO_NUMBER = MO;
      end if;
   end if;

   if (MYGROUP = p_EndGroup) then

      p_Output:= p_Output + 1;

      if (p_Output >= p_Target) then

         UPDATE SFISM4.R_MO_BASE_T SET  OUTPUT_QTY=p_Target,
            CLOSE_FLAG='3', MO_CLOSE_DATE=SYSDATE
            WHERE  MO_NUMBER = MO;

      else

         UPDATE SFISM4.R_MO_BASE_T SET  OUTPUT_QTY=p_Output
            WHERE  MO_NUMBER = MO;

      end if;

   end if;
END;
