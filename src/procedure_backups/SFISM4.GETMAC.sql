PROCEDURE        GETMAC (V_INSN    IN     VARCHAR2,
                                           V_INMAC   IN     VARCHAR2,
                                           RES       OUT    VARCHAR2)
AS
   COUN              INT;
   P_SN             VARCHAR(30);
   TYPE_NAME        VARCHAR(30);
   MODEL_NAME       VARCHAR(30);
   LEFTSTR          VARCHAR(300);
   MACQTY            INT;
   MACLEN            INT;
   MAC_1            VARCHAR(30);
   MAC_2            VARCHAR(30);
   MAC_3            VARCHAR(30);
   MAC_4            VARCHAR(30);
   MAC_5            VARCHAR(30);
   E_NOSN           EXCEPTION;   
BEGIN

    SELECT COUNT(1) INTO COUN FROM SFISM4.R_MAC_T WHERE SERIAL_NUMBER=V_INSN;
    
    IF COUN>0 THEN
        RES:=V_INSN||'\nSN HAS Allot MAC!';
        RAISE E_NOSN;
    END IF;  

    SELECT COUNT(1) INTO COUN FROM SFISM4.R_WIP_TRACKING_T WHERE SERIAL_NUMBER=V_INSN;
        
    IF COUN=0 THEN
        RES:=V_INSN||'\nSN NOT EXISTS!';
        RAISE E_NOSN;
    END IF;
    
    IF INSTR(V_INMAC,'MAC;')>0 THEN
        TYPE_NAME := SUBSTR(V_INMAC,1,INSTR(V_INMAC,';')-1);
        
        LEFTSTR:=SUBSTR(V_INMAC,INSTR(V_INMAC,';')+1,LENGTH(V_INMAC)-INSTR(V_INMAC,';')+1);
        IF INSTR(LEFTSTR,';')>0 THEN
            MODEL_NAME :=SUBSTR(LEFTSTR,1,INSTR(LEFTSTR,';')-1);
            LEFTSTR:=SUBSTR(LEFTSTR,INSTR(LEFTSTR,';')+1,LENGTH(LEFTSTR)-INSTR(LEFTSTR,';')+1);
        ELSE
            V_INSN||'\nSTRING FORMAT ERROR!'||'--'||LEFTSTR;
            RAISE E_NOSN;          
        END IF;
       
        SELECT COUNT(1) INTO COUN FROM SFIS1.C_MAC_CONFIG WHERE TYPE=TYPE_NAME AND MODEL=MODEL_NAME;
        
        IF COUN=0 THEN
            RES:=V_INSN||'\nTYPE:'||TYPE_NAME||',MODEL:'||MODEL_NAME||' NOT CONFIG!';
            RAISE E_NOSN;  
        END IF;
        
        MAC_1:='';
        MAC_2:='';
        MAC_3:='';
        MAC_4:='';
        MAC_5:='';
        RES:=V_INSN||'\n0';

    
    
        SELECT QTY,LENGTH INTO MACQTY,MACLEN FROM SFIS1.C_MAC_CONFIG WHERE TYPE=TYPE_NAME AND MODEL=MODEL_NAME;
        
        IF INSTR(LEFTSTR,';',1,MACQTY-1)>0 THEN
            MAC_1:= SUBSTR(LEFTSTR,1,INSTR(LEFTSTR,';')-1);
            IF LENGTH(MAC_1)<>MACLEN THEN
                RES:=V_INSN||'\nMAC LENGTH ERROR!';
                RAISE E_NOSN;
            END IF;
        
    
            if LENGTH(MAC_1)>0 THEN
               
                SELECT COUNT(1) INTO COUN FROM sfism4.R_MAC_T WHERE  
                (MAC1=MAC_1
                OR MAC2=MAC_1
                OR MAC3=MAC_1
                OR MAC4=MAC_1
                OR MAC5=MAC_1);
           
            
                IF COUN>0 THEN
                    RES:=V_INSN||'\nMAC: '||to_char(MAC_1)||' already exists!';
                    RAISE E_NOSN;
                END if; 
            end if;
                      
            LEFTSTR:=SUBSTR(LEFTSTR,INSTR(LEFTSTR,';')+1,LENGTH(LEFTSTR)-INSTR(LEFTSTR,';')+1);
           
            IF LENGTH(LEFTSTR)>0 AND INSTR(LEFTSTR,';')>0 THEN
               MAC_2:= SUBSTR(LEFTSTR,1,INSTR(LEFTSTR,';')-1); 
               IF LENGTH(MAC_2)<>MACLEN THEN
                    RES:=V_INSN||'\nMAC2 LENGTH ERROR--1!';
                    RAISE E_NOSN;
               END IF;
            ELSE
               MAC_2:=LEFTSTR;
               IF LENGTH(MAC_2)<>MACLEN THEN
                    RES:=V_INSN||'\nMAC2 LENGTH ERROR--2!';
                    RAISE E_NOSN;
               END IF;
            END IF;
            
            if LENGTH(MAC_2)>0 THEN
                 SELECT COUNT(1) INTO COUN FROM sfism4.R_MAC_T WHERE  
                (MAC1=MAC_2
                OR MAC2=MAC_2
                OR MAC3=MAC_2
                OR MAC4=MAC_2
                OR MAC5=MAC_2);
            
                IF COUN>0 THEN
                    RES:=V_INSN||'\nMAC: '||to_char(MAC_2)||' already exists!';
                    RAISE E_NOSN;
                END if;
            end if; 
            
            LEFTSTR:=SUBSTR(LEFTSTR,INSTR(LEFTSTR,';')+1,LENGTH(LEFTSTR)-INSTR(LEFTSTR,';')+1);
            IF LENGTH(LEFTSTR)>0 AND INSTR(LEFTSTR,';')>0 THEN
               MAC_3:= SUBSTR(LEFTSTR,1,INSTR(LEFTSTR,';')-1); 
               IF LENGTH(MAC_3)<>MACLEN THEN
                    RES:=V_INSN||'\nMAC3 LENGTH ERROR--1!';
                    RAISE E_NOSN;
               END IF;
            ELSE
               MAC_3:=LEFTSTR;
               IF LENGTH(MAC_3)<>MACLEN THEN
                    RES:=V_INSN||'\nMAC3 LENGTH ERROR--2!'||LEFTSTR;
                    RAISE E_NOSN;
               END IF;
            END IF;
            
            if LENGTH(MAC_3)>0 THEN
                SELECT COUNT(1) INTO COUN FROM sfism4.R_MAC_T WHERE  
                (MAC1=MAC_3
                OR MAC2=MAC_3
                OR MAC3=MAC_3
                OR MAC4=MAC_3
                OR MAC5=MAC_3);
            
                IF COUN>0 THEN
                    RES:=V_INSN||'\nMAC: '||MAC_3||' already exists!';
                    RAISE E_NOSN;
                END if; 
            end if;
            
            LEFTSTR:=SUBSTR(LEFTSTR,INSTR(LEFTSTR,';')+1,LENGTH(LEFTSTR)-INSTR(LEFTSTR,';')+1);
            IF LENGTH(LEFTSTR)>0 AND INSTR(LEFTSTR,';')>0 THEN
               MAC_4:= SUBSTR(LEFTSTR,1,INSTR(LEFTSTR,';')-1); 
               IF LENGTH(MAC_4)<>MACLEN THEN
                    RES:=V_INSN||'\nMAC4 LENGTH ERROR--1!';
                    RAISE E_NOSN;
               END IF;
            ELSE
               MAC_4:=LEFTSTR;
               IF LENGTH(MAC_4)<>MACLEN THEN
                    RES:=V_INSN||'\nMAC4 LENGTH ERROR--2!'||LEFTSTR;
                    RAISE E_NOSN;
               END IF;
            END IF;
            
            if LENGTH(MAC_4)>0 THEN
                SELECT COUNT(1) INTO COUN FROM sfism4.R_MAC_T WHERE  
                (MAC1=MAC_4
                OR MAC2=MAC_4
                OR MAC3=MAC_4
                OR MAC4=MAC_4
                OR MAC5=MAC_4);
            
                IF COUN>0 THEN
                    RES:=V_INSN||'\nMAC: '||MAC_4||' already exists!';
                    RAISE E_NOSN;
                END if;
            end if ; 
            
            LEFTSTR:=SUBSTR(LEFTSTR,INSTR(LEFTSTR,';')+1,LENGTH(LEFTSTR)-INSTR(LEFTSTR,';')+1);
            IF LENGTH(LEFTSTR)>0 AND INSTR(LEFTSTR,';')>0 THEN
               MAC_5:= SUBSTR(LEFTSTR,1,INSTR(LEFTSTR,';')-1); 
               IF LENGTH(MAC_5)<>MACLEN THEN
                    RES:=V_INSN||'\nMAC5 LENGTH ERROR--1!';
                    RAISE E_NOSN;
               END IF;
            ELSE
               MAC_5:=LEFTSTR;
               IF LENGTH(MAC_5)<>MACLEN THEN
                    RES:=V_INSN||'\nMAC5 LENGTH ERROR--2!'||LEFTSTR;
                    RAISE E_NOSN;
               END IF;
            END IF;
            
            if LENGTH(MAC_5)>0 then
                SELECT COUNT(1) INTO COUN FROM sfism4.R_MAC_T WHERE  
                (MAC1=MAC_5 OR MAC2=MAC_5 OR MAC3=MAC_5 OR MAC4=MAC_5 OR MAC5=MAC_5);
            
                IF COUN>0 THEN 
                    RES:=V_INSN||'\nMAC: '||MAC_4||' already exists!';
                    RAISE E_NOSN;
                END if; 
             end if;
            
            INSERT INTO SFISM4.R_MAC_T(SERIAL_NUMBER,TYPE,MODEL,QTY,MAC1,MAC2,MAC3,MAC4,MAC5,REMARK,LASTEDITBY,LASTEDITDT)
            VALUES(V_INSN,TYPE_NAME,MODEL_NAME,MACQTY,MAC_1,MAC_2,MAC_3,MAC_4,MAC_5,V_INSN||V_INMAC,'TEST',SYSDATE);
        ELSE
            RES:=V_INSN||'\nMAC FORMAT ERROR!';
            RAISE E_NOSN;
        END IF; 
    END IF;
    
    EXCEPTION
        WHEN E_NOSN THEN NULL;
        WHEN OTHERS THEN
            RES:='MAC ERROR!';
    END;