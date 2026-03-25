PROCEDURE                   check_diagsbygroup (
   sn        IN       VARCHAR,
   mydiag    IN       VARCHAR,
   bois      IN       VARCHAR,
   mygroup   IN       VARCHAR,
   emp       IN       VARCHAR,
   res       OUT      VARCHAR
)
AS
   v_group          VARCHAR (25);
   v_model_name     VARCHAR (25);
   v_route          NUMBER;
   count1           NUMBER;
   count2           NUMBER;
   count3           NUMBER;
   count4           NUMBER;
   v_diag           VARCHAR (100);
   p_diag           VARCHAR (100);
   v_diagres        VARCHAR2 (50);
   v_diagcheckres   VARCHAR2 (50);
   e_null           EXCEPTION;
BEGIN
   --res := 'OK';
   v_group := mygroup;
   v_diag := mydiag;

   SELECT model_name, special_route
     INTO v_model_name, v_route
     FROM sfism4.r_wip_tracking_t
    WHERE serial_number = sn;

   SELECT COUNT (*)
     INTO count4
     FROM web.c_diag_config_t
    WHERE model_name = v_model_name;

   --  IF count4 > 0
    -- THEN
   SELECT COUNT (*)
     INTO count1
     FROM sfism4.r_link_t
    WHERE flag = 'DIAG' AND group_name = 'FLASHROM' AND serial_number = sn;

   IF count4 > 0
   THEN
      IF v_diag <> 'N/A'
      THEN
         sfis1.check_diags_version_t (sn,
                                      v_diag,
                                      bois,
                                      v_group,
                                      v_diagcheckres
                                     );

         IF v_diagcheckres <> 'OK'
         THEN
            res := 'DIAG CHECK ERROR:' || v_diagcheckres;
            RAISE e_null;
         END IF;

         -------------- when  group_name ='FLASHROM',the first test station  begin------
         IF UPPER (TRIM (v_group)) <> 'FLASHROM'
         THEN
            IF count1 > 0
            THEN
               SELECT key_value
                 INTO p_diag
                 FROM sfism4.r_link_t
                WHERE flag = 'DIAG'
                  AND group_name = 'FLASHROM'
                  AND serial_number = sn
                  AND create_dt =
                         (SELECT MAX (create_dt)
                            FROM sfism4.r_link_t
                           WHERE flag = 'DIAG'
                             AND group_name = 'FLASHROM'
                             AND serial_number = sn);

               IF p_diag <> v_diag
               THEN
                  res := 'diag ERROR:' || v_diag || '<>' || p_diag;
                  RAISE e_null;
               END IF;
            END IF;
         END IF;

         sfism4.datalink (emp, sn, v_diag, v_group, 'DIAG', v_diagres);

         IF v_diagres <> 'OK'
         THEN
            res := 'DIAG DATA_LINK ERROR:' || v_diagres;
            RAISE e_null;
         END IF;

         res := v_diagres;
      ELSE
--------------'************DIAG ='N/A' begin ********************----------------
---------------**************************************************------------------
         res := 'OK';
       /*
         IF count1 = 0
         THEN
            res := 'OK';
         ELSE
            SELECT step_sequence
              INTO count2
              FROM sfis1.c_route_control_t
             WHERE route_code = v_route
               AND group_name = v_group
               AND state_flag = 0
               AND ROWNUM = 1;

            SELECT step_sequence
              INTO count3
              FROM sfis1.c_route_control_t
             WHERE route_code = v_route
               AND group_name = 'FLASHROM'
               AND state_flag = 0
               AND ROWNUM = 1;

            IF count2 > count3
            THEN
               res := 'FLASHROM have check DIAGS ,please add';
               RAISE e_null;
            ELSE
               res := 'OK';
            END IF;
         END IF;

      */
      END IF;
   ELSE
      IF v_diag <> 'N/A'
      THEN
         sfis1.check_diags_version_t (sn,
                                      v_diag,
                                      bois,
                                      v_group,
                                      v_diagcheckres
                                     );

         IF v_diagcheckres <> 'OK'
         THEN
            res := 'DIAG CHECK ERROR2:' || v_diagcheckres;
            RAISE e_null;
         END IF;

         sfism4.datalink (emp, sn, v_diag, v_group, 'DIAG', v_diagres);

         IF v_diagres <> 'OK'
         THEN
            res := 'DIAG DATA_LINK ERROR2:' || v_diagres;
            RAISE e_null;
         END IF;
      ELSE
         res := 'OK';
      END IF;
   END IF;
EXCEPTION
   WHEN e_null
   THEN
      NULL;
END;