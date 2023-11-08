----------------Create schemas
DISC;
--CONN sys/&Type_Sys_Password@&Type_Database_name as sysdba;
CONN sys/&SYS_PASSWORD@//&HOSTNAME:&PORT/&DATABASE_NAME as sysdba



DROP USER falcon CASCADE;
CREATE USER falcon IDENTIFIED BY falc;
COMMIT;								
GRANT resource to falcon;										
GRANT UNLIMITED TABLESPACE TO falcon;											
GRANT CONNECT TO falcon;										
GRANT CREATE VIEW, CREATE DATABASE LINK, CREATE SEQUENCE, QUERY REWRITE,
                ADMINISTER DATABASE TRIGGER, CREATE SESSION, ALTER SESSION, CREATE MATERIALIZED VIEW, 
                CREATE SYNONYM, CREATE TABLE TO falcon;
GRANT EXECUTE ON DBMS_SCHEDULER TO falcon;
GRANT CREATE JOB TO falcon;
GRANT CREATE USER TO falcon;					
DISC
CONN
falcon/falc@orcl
--------------Table
  CREATE TABLE CHECK_JOBS
   (	EFFECTED_DATE TIMESTAMP (6), 
	STATUS VARCHAR2(1) DEFAULT '0', 
	COMMENTS VARCHAR2(4000)
	) ;

  CREATE TABLE PROGRESS 
   (	TODAY DATE, 
	ACTION_TAKE NUMBER, 
	PROBABILITY NUMBER, 
	PK NUMBER PRIMARY KEY 
   ) ;

  CREATE TABLE PROGRESS_TRACKS 
   (	GET_JOB VARCHAR2(1) DEFAULT 'N'
   ) ;


CREATE TABLE USER_TABLES 
   (	USERID NUMBER PRIMARY KEY NOT NULL, 
	USERNAME VARCHAR2(30) UNIQUE, 
	PASSCODE VARCHAR2(10), 
	STATUS VARCHAR2(1) DEFAULT 'N', 
	PROID NUMBER, 
	FULL_NAME VARCHAR2(70), 
	DESIGNATION VARCHAR2(70), 
	COMPANY VARCHAR2(500), 
	EMAIL VARCHAR2(500), 
	CELL VARCHAR2(30), 
	ID_NO VARCHAR2(70) UNIQUE
   ) ;
   
  CREATE TABLE ROLE_TABLES
   (	ROLEID NUMBER PRIMARY KEY NOT NULL , 
	ROLENAME VARCHAR2(30), 
	ROLEDESC VARCHAR2(500)
   ) ;
   
 CREATE TABLE USERS_ROLE
   (	USERID NUMBER CONSTRAINT USER_RO_FK REFERENCES USER_TABLES(USERID), 
	ROLEID NUMBER CONSTRAINT ROLE_US_FK REFERENCES ROLE_TABLES(ROLEID)
   ) ;

 CREATE TABLE TEAMS
   (	TEAM_ID NUMBER PRIMARY KEY NOT NULL , 
	TEAM_NAME VARCHAR2(70) UNIQUE, 
	TEAM_LEADER NUMBER CONSTRAINT LEADER_USER_FK REFERENCES USER_TABLES(USERID), 
	SUB_LEADER NUMBER CONSTRAINT SUBLEADER_USER_FK REFERENCES USER_TABLES(USERID)
   ) ;

  CREATE TABLE TEAM_MEMBERS 
   (	TEAM_MEMBER_ID NUMBER PRIMARY KEY NOT NULL, 
	TEAM_ID NUMBER CONSTRAINT TEAM_FK REFERENCES TEAMS(TEAM_ID), 
	USERID NUMBER CONSTRAINT TEAM_MEMBER_FK REFERENCES  USER_TABLES(USERID)
   ) ;

  CREATE TABLE PROJECTS
   (	PROJECT_ID NUMBER PRIMARY KEY NOT NULL, 
	PROJECT_NAME VARCHAR2(30), 
	PROJECT_DESCRIPTION VARCHAR2(4000), 
	STATUS VARCHAR2(1) DEFAULT 'Y', 
	CHECK_IN DATE, 
	CHECK_OUT DATE, 
	COMMENTS VARCHAR2(1) DEFAULT 'N', 
	TEAM_ID NUMBER CONSTRAINT TEAM_PROJECT_FK REFERENCES TEAMS(TEAM_ID), 
	ROOT_ID NUMBER,
	CONSTRAINT PARENT_PROJECT_FK FOREIGN KEY (ROOT_ID) REFERENCES PROJECTS (PROJECT_ID)
   ) ;
   
   
   CREATE TABLE PROJECT_DETAILS 
   (	TASK_NAME VARCHAR2(4000), 
	START_FROM DATE, 
	END_TO DATE, 
	FORECAST DATE, 
	STATUS VARCHAR2(1) DEFAULT '0', 
	PROJECT_ID NUMBER CONSTRAINT PROJECT_FK REFERENCES PROJECTS(PROJECT_ID), 
	PERSON NUMBER DEFAULT 1, 
	PROID NUMBER PRIMARY KEY NOT NULL, 
	INS_BY NUMBER CONSTRAINT INSERT_BY_USERS REFERENCES USER_TABLES(USERID), 
	INS_DATE TIMESTAMP (6), 
	UPD_BY NUMBER CONSTRAINT UPDATE_BY_USERS REFERENCES  USER_TABLES(USERID), 
	UPD_DATE TIMESTAMP (6), 
	UPD_DONE TIMESTAMP (6), 
	STS_BY NUMBER CONSTRAINT STATUS_USER_BY REFERENCES  USER_TABLES(USERID), 
	TEAM_ID NUMBER CONSTRAINT TASK_TEAM_FK REFERENCES TEAMS(TEAM_ID), 
	APPROVAL VARCHAR2(1)
   ) ;
   
     ALTER TABLE USER_TABLES ADD CONSTRAINT TASK_TO_USERFK FOREIGN KEY (PROID) REFERENCES PROJECT_DETAILS (PROID) ;
    

  CREATE TABLE USER_TASKS 
   (	USERID NUMBER CONSTRAINT USER_TASK_FK REFERENCES  USER_TABLES(USERID), 
	PROID NUMBER CONSTRAINT TASK_FK REFERENCES PROJECT_DETAILS(PROID), 
	INS_BY NUMBER CONSTRAINT INSERT_BY_USER REFERENCES  USER_TABLES(USERID), 
	INS_DATE TIMESTAMP (6), 
	UPD_BY NUMBER CONSTRAINT UPDATE_BY_USER REFERENCES  USER_TABLES(USERID), 
	UPD_DATE TIMESTAMP (6), 
	TEAM_ID NUMBER CONSTRAINT TEAM_TASK_FK REFERENCES TEAMS(TEAM_ID), 
	 CONSTRAINT NO_MULTI_TASK_ON_AUSER UNIQUE (USERID, PROID)
   ) ;



  CREATE TABLE PROJECT_ATTACHMENTS 
   (	PROID NUMBER CONSTRAINT ATTCH_FK REFERENCES PROJECT_DETAILS(PROID), 
	NAME_FILE VARCHAR2(500), 
	ATTACHEMENT_FILE BLOB, 
	FILENAME VARCHAR2(4000), 
	MIMETYPE VARCHAR2(700), 
	CREATEDDATE DATE, 
	CHARSET VARCHAR2(800)
   ) ;
   
   
     CREATE TABLE PROJECT_STORES 
   (	TASK_NAME VARCHAR2(4000), 
	START_FROM DATE, 
	END_TO DATE, 
	FORECAST DATE, 
	STATUS VARCHAR2(1), 
	PROJECT_ID NUMBER, 
	PERSON NUMBER, 
	PROID NUMBER, 
	INS_BY NUMBER, 
	INS_DATE TIMESTAMP (6), 
	UPD_BY NUMBER, 
	UPD_DATE TIMESTAMP (6)
   ) ;
   
ALTER TABLE user_tables MODIFY (passcode VARCHAR2(4000));

---Role Data Insertion
   INSERT INTO ROLE_TABLES (roleid, rolename, roledesc)
   VALUES ('1000','Admin','Adding task, assigning task, creating team, creating project, modifying task, authorizing personnel, removing user''s tasks, adding new roles, controlling application users are their privileges.');

   
   INSERT INTO ROLE_TABLES (roleid, rolename, roledesc)
   VALUES ('1001','Contributor','Adding tasks, assigning tasks, creating teams, creating projects, modifying tasks are their privileges. Contributor can also apply ''DONE'' status directly without any approval from team leader.');

   
   INSERT INTO ROLE_TABLES (roleid, rolename, roledesc)
   VALUES ('1002','Reader','They can only change task status.
After changing status with ''DONE'', they need approval from team leader for actual DONE. Team leader can approve their completed tasks or can refuse their tasks. After undoing tasks, readers will receive submitted tasks in their TASK menu again.');

ALTER TABLE users_role ADD(team_id NUMBER CONSTRAINT role_for_team REFERENCES teams(team_id));
   
   commit;
   
   
   
   -----------------VIEWS
     CREATE or replace VIEW TOTAL_PERM  AS 
  select SUM(NVL(ROUND((((select EXTRACT(DAY FROM upd_done) from project_details pd where pd.proid=ut.proid and status= 1)
   - EXTRACT(DAY FROM ins_date)) / ((select EXTRACT(DAY FROM end_to) from project_details pd where pd.proid=ut.proid) - 
   EXTRACT(DAY FROM ins_date))) * 100,2),0.01)) val
FROM user_tasks ut
WHERE team_id IS NOT NULL;
/


---------------fUNCTION

create or replace FUNCTION GET_IDENTITY (p_username IN VARCHAR2, p_password IN VARCHAR2)
RETURN BOOLEAN
IS
v_user_count NUMBER;
BEGIN
SELECT COUNT(*) INTO v_user_count 
FROM user_tables 
WHERE lower(USERNAME) = lower(p_username) 
AND PASSCODE = p_password
AND STATUS = 'Y';
IF v_user_count > 0 THEN
RETURN TRUE;
ELSE
RETURN FALSE;
END IF;
END;
/


create or replace FUNCTION hr_duration(from_times timestamp,to_times timestamp ) return varchar2
is
--declare
v__out number;
v__excess number;
v__duration varchar2(10);
begin
for i in (SELECT to_char(TO_CHAR(to_times,'hh24mi') - TO_CHAR(from_times,'hh24mi'),'0999') tim from dual) loop
SELECT substr(i.tim,-2,2) into v__out from dual;
If v__out >= 60 then
v__excess := to_number(i.tim) - 40;
select to_char(v__excess,'09,99') into v__duration from dual;
return v__duration;
--dbms_output.put_line(v__excess);
--dbms_output.put_line(v__out);
elsif v__out < 60 then
v__excess := i.tim;
select to_char(v__excess,'09,99') into v__duration from dual;
return v__duration;
--dbms_output.put_line(v__excess);
--dbms_output.put_line(v__out);
else
null;
end if;
end loop;
EXCEPTION
WHEN NO_DATA_FOUND THEN
RETURN 'No Clock In Value Inserted';
WHEN OTHERS THEN
RETURN 'No Clock In Value Inserted';
end;
/

create or replace FUNCTION METE(p_number VARCHAR, p_parent VARCHAR, p_child VARCHAR) RETURN VARCHAR
IS
v___left VARCHAR2(4000);
v___right VARCHAR2(4000);
v___number VARCHAR2(4000);
BEGIN
SELECT p_number INTO v___number FROM DUAL WHERE p_number LIKE '%,%';
IF v___number IS NOT NULL THEN

select rtrim((select rtrim(p_number,(select substr(p_number,(select instr(p_number,',')from dual)+1) from dual)) from dual),',') 
into v___left
from dual;
select substr(p_number,(select instr(p_number,',')from dual)+1)
INTO v___right
from dual;

RETURN NVL(v___left,'0')||' '||p_parent||' '||NVL(v___right,'0')||' '||p_child;
ELSIF v___number IS NULL THEN
select substr(p_number,(select instr(p_number,',')from dual)+1) 
INTO v___right
from dual;
RETURN NVL(v___right,'0')||' '||p_parent;
END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
select substr(p_number,(select instr(p_number,',')from dual)+1) 
INTO v___right
from dual;
RETURN NVL(v___right,'0')||' '||p_parent;
END;
/

create or replace FUNCTION time_spell(p_days VARCHAR2) RETURN VARCHAR2 IS
v_y NUMBER;
v_yd NUMBER;
v_m NUMBER;
v_md NUMBER;
v_d NUMBER;
v_w NUMBER;
v_wd NUMBER;
v_days NUMBER;
v_yi NUMBER;
v_mi NUMBER;
v_wi  NUMBER;
BEGIN
SELECT p_days/365 INTO v_y FROM dual;
if v_y not like '%.%' then
SELECT trunc(v_y) INTO v_yi FROM dual;
select substr(v_y||'.0',(select instr(v_y||'.0','.') from dual)) INTO v_yd from dual;
SELECT v_yd * 12 INTO v_m FROM dual;
SELECT trunc(v_m) INTO v_mi FROM dual;
select substr(v_m,(select instr(v_m,'.') from dual)) INTO v_md from dual;
SELECT v_md * 30 INTO v_d FROM dual;
SELECT v_d / 7 INTO v_w FROM dual;
SELECT trunc(v_w) INTO v_wi FROM dual;
select substr(v_w,(select instr(v_w,'.') from dual)) INTO v_wd from dual;
SELECT round(v_wd * 7) INTO v_days FROM dual;
RETURN v_yi||' Year '||v_mi||' Month '||v_wi||' Week '||v_days||' Day ';
else
SELECT trunc(v_y) INTO v_yi FROM dual;
select substr(v_y,(select instr(v_y,'.') from dual)) INTO v_yd from dual;
SELECT v_yd * 12 INTO v_m FROM dual;
SELECT trunc(v_m) INTO v_mi FROM dual;
select substr(v_m,(select instr(v_m,'.') from dual)) INTO v_md from dual;
SELECT v_md * 30 INTO v_d FROM dual;
SELECT v_d / 7 INTO v_w FROM dual;
SELECT trunc(v_w) INTO v_wi FROM dual;
select substr(v_w,(select instr(v_w,'.') from dual)) INTO v_wd from dual;
SELECT round(v_wd * 7) INTO v_days FROM dual;
RETURN v_yi||' Year '||v_mi||' Month '||v_wi||' Week '||v_days||' Day ';
end if;
END;
/


CREATE OR REPLACE FUNCTION blob_to_clob(p_blob IN BLOB)
RETURN CLOB
IS
  v_clob CLOB;
  v_dest_offset INTEGER := 1;
  v_src_offset INTEGER := 1;
  v_lang_context INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
  v_warning INTEGER;
BEGIN
  -- Create a temporary CLOB
  DBMS_LOB.CREATETEMPORARY(v_clob, TRUE);

  -- Convert the BLOB to CLOB
  DBMS_LOB.CONVERTTOCLOB(v_clob, p_blob, DBMS_LOB.LOBMAXSIZE, v_dest_offset, v_src_offset, NLS_CHARSET_ID('AL32UTF8'), v_lang_context, v_warning);

  -- Return the CLOB
  RETURN v_clob;
END;
/

CREATE OR REPLACE FUNCTION binary_to_clob(binary_data RAW) RETURN CLOB IS
    v_clob CLOB;
BEGIN
    -- Create a temporary CLOB
    DBMS_LOB.CREATETEMPORARY(v_clob, TRUE);

    -- Write the converted binary data to the CLOB
    DBMS_LOB.WRITEAPPEND(v_clob, LENGTH(UTL_RAW.CAST_TO_VARCHAR2(binary_data)), UTL_RAW.CAST_TO_VARCHAR2(binary_data));

    RETURN v_clob;
EXCEPTION
    WHEN OTHERS THEN
        -- Handle exceptions, if necessary
        RETURN NULL;
END binary_to_clob;
/

create or replace FUNCTION encrypto (p_password VARCHAR2)
    RETURN VARCHAR2
AS
    v___src    VARCHAR2 (32767);
    v___cnt    INTEGER := 1;
    v___rw     VARCHAR2 (32767);
    v___asci   VARCHAR2 (32767);
    v___aln    VARCHAR2 (32767);
    v___hid    VARCHAR2 (32767);
    v___me     VARCHAR2 (32767);
    v___dv     VARCHAR2 (32767);
    v___ad     VARCHAR (32767);
BEGIN
    SELECT LENGTH (p_password) INTO v___src FROM DUAL;

    WHILE v___cnt <= v___src
    LOOP
        SELECT SUBSTR (p_password, v___cnt, 1) INTO v___rw FROM DUAL;

        v___asci := ASCII (v___rw);
        v___ad := v___asci || '2';
        v___dv := v___ad / 2;
        v___me := v___dv + 49;
        v___hid := v___me - 25;
        v___aln := v___aln || '0' || v___hid;
        v___cnt := v___cnt + 1;
    END LOOP;

    RETURN v___aln;
END;
/

-- CREATE OR REPLACE FUNCTION decrypto (p_password VARCHAR2)
--     RETURN VARCHAR2
-- IS
--     v___l      INTEGER;
--     v___strt   INTEGER := 1;
--     v___cnt    INTEGER := 1;
--     v___brl    VARCHAR2 (4);
--     v___rw     VARCHAR2 (32767);
--     v___clc    NUMBER;
--     v___ltr    VARCHAR2 (32767);
--     v___aln    VARCHAR (32767);
-- BEGIN
--     SELECT LENGTH (p_password) / 4
--       INTO v___l
--       FROM DUAL;

--     WHILE v___cnt <= v___l
--     LOOP
--         SELECT SUBSTR (p_password, v___strt, 4) INTO v___brl FROM DUAL;
        
--         v___clc := (((v___brl + 25) - 49) * 2);
--         v___rw := SUBSTR (v___clc, 1, LENGTH (v___clc) - 1);
--         v___ltr := CHR (v___rw);
--         v___aln := v___aln || v___ltr;
--         v___strt := v___strt + 4;
--         v___cnt := v___cnt + 1;
--     END LOOP;

--     RETURN v___aln;
-- END;

----------------PROCEDURE
create or replace PROCEDURE project_activity(p___in_days INTEGER DEFAULT 60) IS
Vbody CLOB;
Vbody_html CLOB;
BEGIN
FOR i IN (select distinct project_name, (SELECT count(ins_date) FROM project_details pd WHERE p.project_id = pd.project_id
and to_char(ins_date,'mm/dd/yyyy') between to_date(sysdate - p___in_days,'mm/dd/yyyy') and to_date(sysdate,'mm/dd/yyyy')
)tasks, (select team_name from teams t where t.team_id = p.team_id) team, (select lower(NVL((select email from user_tables ut where ut.userid=t.team_leader),'abc@abc.com')) team_leader from teams t where t.team_id = p.team_id) leader
from projects p
where sysdate - check_in >= p___in_days        --how old
AND status = 'Y')
LOOP
IF i.tasks <= 0 THEN
--send mail
Vbody := 'To view the content of this message, please use an HTML enabled mail client.'||utl_tcp.crlf;
Vbody_html := 'Your team '||i.team||' has '||i.tasks||' task(s) of this '||i.project_name||' project for last '||p___in_days||' day(s)'||utl_tcp.crlf;
apex_mail.send(
                p_to => i.leader,
                p_from => 'abc@abc.com',
                p_body_html => Vbody_html,
                p_subj => 'No Task is assigned in '||p___in_days||' day(s)',
                p_body => Vbody
                );
-----------
ELSIF i.tasks > 0 THEN
INSERT INTO check_jobs(effected_date,status,comments)
VALUES (CURRENT_TIMESTAMP,'5','Project_Activity Procedure');
null;
END IF;
END LOOP;
INSERT INTO check_jobs(effected_date,status,comments)
VALUES (CURRENT_TIMESTAMP,'5','Project_Activity Procedure');
END;
/

create or replace PROCEDURE project_closing AS
-------------closing incompleted project
        BEGIN
        FOR i IN (SELECT project_name check_in, check_out, status,comments,project_id FROM projects WHERE TO_date(sysdate,'mm/dd/yyyy') > to_char(check_out,'mm/dd/yyyy') AND 
        comments = 'N' and status= 'Y' )
        LOOP
        
        UPDATE projects SET status = 'N'
        WHERE project_id = i.project_id;
        END LOOP;
-------------------------remove pending,overdue,halt,cancel rows of inactive projects
    FOR j IN (SELECT project_id, check_out
    FROM projects
    where TO_CHAR(current_timestamp,'mm/dd/yyyy') > TO_DATE(check_out,'mm/dd/yyyy') AND status = 'Y') Loop
        if TO_CHAR(current_timestamp,'mm/dd/yyyy') > TO_DATE(j.check_out,'mm/dd/yyyy') then
            FOR i IN (
            SELECT * 
            FROM project_details
            WHERE project_id IN j.project_id
            AND status <> '1') LOOP
                -------------insert dump data into new table
                insert into project_stores(task_name, start_from, end_to, forecast, status, project_id, person, proid, ins_by, ins_date, upd_by, upd_date)
                values (i.task_name, i.start_from, i.end_to, i.forecast, i.status, i.project_id, i.person, i.proid, i.ins_by, i.ins_date, i.upd_by, i.upd_date);
                -------------delete dump data from used table
                delete from user_tasks
                where proid IN (SELECT proid FROM project_details WHERE project_id IN j.project_id AND status <> '1');
                delete from project_details
                where project_id IN j.project_id
                AND status <> '1';
            end loop;
        else null;
        end if;
    end loop;        
INSERT INTO check_jobs(effected_date,status,comments)
VALUES (CURRENT_TIMESTAMP,'3','Project Closing');

END;
/

create or replace PROCEDURE project_mail_to_assignee (p_primary_key VARCHAR2) IS
BEGIN
       DECLARE
            Vbody CLOB;
            Vbody_html CLOB;
            v_time VARCHAR2(100);
            receive_mail user_tables.email%type;
            v___assignee    varchar2(32767); 
            v___task_name varchar2(32767);
            v___task_inserted_date varchar2(32767); 
            v___contact_with varchar2(32767);
            v___deadline varchar2(32767); 
            v___remained_days varchar2(32767); 
            v___status varchar2(32767);
            v___submitted_date varchar2(32767); 
            v___assignor varchar2(32767);
            v___project_name varchar2(32767);
            BEGIN

select userid ,
(select task_name from project_details j where j.proid = i.proid)
,
to_char((select ins_date from project_details j where j.proid = i.proid),'dd-mon-yyyy hh12:mi:ss am') ,
(select listagg((select full_name||' Cell#'||cell from user_tables y where y.userid = p.userid),', ') within group (order by userid) from user_tasks p where p.proid = i.proid group by proid) ,
to_char((select end_to from project_details n where n.proid = i.proid),'dd-mon-yyyy') ,
trunc((select end_to from project_details n where n.proid = i.proid) - sysdate)+1||' Day' ,
decode((select status from project_details t where t.proid = i.proid),0,'Pending',1,'Done',2,'Overdue',3,'Halt',NULL) ,
to_char((SELECT forecast from project_details r where r.proid = i.proid),'dd-mon-yyyy') ,
(select full_name||', Designation: '||designation||', Company Name: '||company from user_tables u where u.userid = i.ins_by),
(select (select project_name from projects p where p.project_id = o.project_id) from project_details o where o.proid = i.proid),
(SELECT NVL(email,'abc@demo.com') FROM user_tables q WHERE q.userid = i.userid)
into v___assignee, v___task_name, v___task_inserted_date, v___contact_with, v___deadline, v___remained_days, v___status, v___submitted_date, v___assignor, v___project_name, receive_mail
from user_tasks i
where rowid = p_primary_key;

 
                Vbody := 'To view the content of this message, please use an HTML enabled mail client.'||utl_tcp.crlf;
                Vbody_html := '<strong><h2>'||'A Task Memorandum '||'</h2></strong><br>'
                ||'Project Name: '||v___project_name||'<br>'
                ||'Task Name: '||v___task_name||'<br>'
                ||'Task inserted: '||v___task_inserted_date||'<br>'
                ||'Contact with/ Team member: '||v___contact_with||'<br>'
                ||'Deadline: '||v___deadline||'<br>'
                ||'Remained: '||v___remained_days||'<br>'
                ||'Status: '||v___status||'<br>'
                ||'Submitted date: '||v___submitted_date||'<br>'
                ||'Assignor:'||v___assignor||'<br>'
                ||utl_tcp.crlf;
                apex_mail.send(
                p_to => receive_mail,
                p_from => 'abc@abc.com',
                p_body_html => Vbody_html,
                p_subj => 'A New Task is Assigned',
                p_body => Vbody
                );
        END;
END;
/

create or replace PROCEDURE project_overdue_notify AS
------------------------sending email when overdue goes 5 days long
        BEGIN

        FOR i IN (SELECT task_name, (SELECT project_name FROM projects p WHERE p.project_id = j.project_id) project_name, 
                        end_to, start_from, end_to - start_from total_days,
                        NVL((select (select email 
                                     from user_tables ut 
                                     where ut.userid=tm.team_leader) 
                             from teams tm 
                             where tm.team_id = j.team_id),
                             'abc@abc.com') team_leader_email
                  FROM project_details j
                  WHERE to_char(current_timestamp,'mm/dd/yyyy') = to_char(end_to + 5 ,'mm/dd/yyyy')) 
        LOOP
            DECLARE
            Vbody CLOB;
            Vbody_html CLOB;
            v_time VARCHAR2(100);
            receive_mail varchar2(250) := i.team_leader_email;
            BEGIN
                if to_char(current_timestamp,'mm/dd/yyyy') = to_char(i.end_to + 5,'mm/dd/yyyy') then
                Vbody := 'To view the content of this message, please use an HTML enabled mail client.'||utl_tcp.crlf;
                Vbody_html := 'The overdue of task listed: '||'<br>'
                ||'Project Name: '||i.project_name||'<br>'
                ||'Task Name: '||i.task_name||'<br>'
                ||'Project Started In: '||TO_CHAR(i.start_from,'FMDD-MON-YYYY')||'<br>'
                ||'Project Deadline: '||TO_CHAR(i.end_to,'FMDD-MON-YYYY')||'<br>'
                ||'Total Time Consume: '||TRUNC((sysdate - i.start_from)+1)||' Days'
                ||utl_tcp.crlf;
                apex_mail.send(
                p_to => receive_mail,
                p_from => 'abc@abc.com',
                p_body_html => Vbody_html,
                p_subj => 'Overdue Tasks',
                p_body => Vbody
                );
                else 
                null;
                end if;
            END;
        END LOOP;
                    INSERT INTO check_jobs(effected_date,status,comments)
                    VALUES (CURRENT_TIMESTAMP,'2','Overdue Notify by mailing Procedure');
EXCEPTION
WHEN NO_DATA_FOUND THEN
                    INSERT INTO check_jobs(effected_date,status,comments)
                    VALUES (CURRENT_TIMESTAMP,'2','Overdue Notify by mailing Procedure');

        END;
/

create or replace PROCEDURE project_progress (p___action IN NUMBER DEFAULT 0, p___probability OUT NUMBER) IS
v___probability NUMBER;
BEGIN
IF (p___action <= 0) OR (p___action IS NULL) THEN
p___probability := '10';
SELECT probability
INTO v___probability
FROM progress
ORDER BY PK DESC
FETCH FIRST 1 ROW ONLY;
p___probability := v___probability - p___probability;

DECLARE
V NUMBER;
BEGIN
SELECT MAX(PK)
INTO V
FROM progress;
IF V IS NULL THEN
V := 1;
ELSIF V IS NOT NULL
THEN 
V := V + 1;
ELSE NULL;
END IF;
INSERT INTO progress (PK,today, action_take, probability)
VALUES (V,sysdate,p___action,p___probability);
END;


ELSIF p___action > 0 THEN
SELECT probability
INTO v___probability
FROM progress
ORDER BY PK DESC
FETCH FIRST 1 ROW ONLY;
p___probability := v___probability + p___action;


DECLARE
V NUMBER;
BEGIN
SELECT MAX(PK)
INTO V
FROM progress;
IF V IS NULL THEN
V := 1;
ELSIF V IS NOT NULL
THEN 
V := V + 1;
ELSE NULL;
END IF;
INSERT INTO progress (PK,today, action_take, probability)
VALUES (V,sysdate,p___action,p___probability);
END;

ELSE NULL;
END IF;

EXCEPTION
WHEN NO_DATA_FOUND THEN
IF (p___action <= 0) OR (p___action IS NULL) THEN
p___probability := '-10';


DECLARE
V NUMBER;
BEGIN
SELECT MAX(PK)
INTO V
FROM progress;
IF V IS NULL THEN
V := 1;
ELSIF V IS NOT NULL
THEN 
V := V + 1;
ELSE NULL;
END IF;
INSERT INTO progress (PK,today, action_take, probability)
VALUES (V,sysdate,p___action,p___probability);
END;

ELSIF p___action > 0 THEN
p___probability := p___action;


DECLARE
V NUMBER;
BEGIN
SELECT MAX(PK)
INTO V
FROM progress;
IF V IS NULL THEN
V := 1;
ELSIF V IS NOT NULL
THEN 
V := V + 1;
ELSE NULL;
END IF;
INSERT INTO progress (PK,today, action_take, probability)
VALUES (V,sysdate,p___action,p___probability);
END;
ELSE NULL;
END IF;

END;
/

create or replace PROCEDURE project_status IS
BEGIN
----------------------convert pending to overdue
    FOR i IN (SELECT end_to, status FROM project_details WHERE to_char(current_timestamp,'mm/dd/yyyy') > to_char(end_to,'mm/dd/yyyy') AND status = '0')
    LOOP
    IF to_char(current_timestamp,'mm/dd/yyyy') > to_char(i.end_to,'mm/dd/yyyy') THEN
    UPDATE project_details SET status = '2'
    WHERE to_char(end_to,'mm/dd/yyyy') = to_char(i.end_to,'mm/dd/yyyy')
    AND status = i.status;
    COMMIT;
    ELSE
    NULL;
    END IF;
    END LOOP;
INSERT INTO check_jobs(effected_date,status,comments)
VALUES (CURRENT_TIMESTAMP,'1','Project_status Procedure');
END;
/

----------------TRIGGER
create or replace TRIGGER project_halt BEFORE UPDATE ON projects
FOR EACH ROW
WHEN (NEW.COMMENTS = 'Y')
BEGIN
IF UPDATING THEN
:NEW.status := 'N';

ELSE
null;
END IF;

END;
/

create or replace TRIGGER project_remove AFTER INSERT OR UPDATE OR DELETE ON projects
FOR EACH ROW
WHEN (new.status = 'N')
BEGIN
FOR i IN (
SELECT * 
FROM project_details
WHERE project_id = :new.project_id
AND status <> '1') LOOP

IF :new.status = 'N' then
-------------insert dump data into new table
insert into project_stores(task_name, start_from, end_to, forecast, status, project_id, person, proid, ins_by, ins_date, upd_by, upd_date)
values (i.task_name, i.start_from, i.end_to, i.forecast, i.status, i.project_id, i.person, i.proid, i.ins_by, i.ins_date, i.upd_by, i.upd_date);
-------------delete dump data from used table
delete from PROJECT_ATTACHMENTS
where proid IN (SELECT proid FROM project_details WHERE project_id = :new.project_id AND status <> '1');

delete from user_tasks
where proid IN (SELECT proid FROM project_details WHERE project_id = :new.project_id AND status <> '1');

delete from project_details
where project_id IN :new.project_id
AND status <> '1';

ELSIF :new.status <> 'N' then 
null;
end if;

end loop;
END;
/

create or replace TRIGGER project_task_approval BEFORE UPDATE OF approval ON project_details
FOR EACH ROW
--WHEN (OLD.status = '5')

BEGIN

IF UPDATING THEN
    IF :NEW.approval = '1' THEN
    UPDATE project_details
    SET status = '1'
    WHERE approval = :NEW.approval
    AND proid = :OLD.proid;
    ELSIF :NEW.approval = '0' THEN
    UPDATE project_details
    SET status = '0'
    WHERE approval = :NEW.approval
    AND proid = :OLD.proid;
    ELSE 
    NULL;
    END IF;
END IF;

END;
/

create or replace TRIGGER project_team_member_add AFTER INSERT OR UPDATE ON teams
FOR EACH ROW
DECLARE
    NEW_PK            VARCHAR2 (30) :=  NULL;
    v___team_leader   teams.team_leader%type;
    v___team_id       team_members.team_id%type;
    v___sub_leader    teams.sub_leader%type;
BEGIN
--------------------------------LEADER
 IF :new.team_leader is not null THEN 

    BEGIN
    FOR i IN (SELECT team_id, userid FROM team_members) LOOP
    IF :new.team_id = i.team_id AND :new.team_leader = i.userid THEN 
    NULL;
    ELSE
   
    v___team_id := :new.team_id;
    v___team_leader := :new.team_leader;
    END IF;
    END LOOP;
        SELECT MAX (team_member_id)
        INTO NEW_PK
        FROM team_members;    
        IF NEW_PK IS NULL THEN
            NEW_PK := 1000;
        ELSE
            NEW_PK := NEW_PK + 1;
        END IF;
        DELETE FROM team_members
        WHERE team_id = :new.team_id AND userid = :old.team_leader;
        INSERT INTO team_members (team_member_id, team_id, userid)
        VALUES (NEW_PK, v___team_id, v___team_leader);
    END;
 ELSE
 null;
 END IF;
 --------------------------------SUBLEADER
 IF :new.sub_leader is not null THEN
    BEGIN
    FOR i IN (SELECT team_id, userid FROM team_members) LOOP
        IF :new.team_id = i.team_id AND :new.sub_leader = i.userid THEN
        NULL;
        ELSE
        v___team_id := :new.team_id;
        v___sub_leader := :new.sub_leader;
        END IF;
    END LOOP;
            SELECT MAX (team_member_id)
            INTO NEW_PK
            FROM team_members;    
            IF NEW_PK IS NULL THEN
                NEW_PK := 1000;
            ELSE
                NEW_PK := NEW_PK + 1;
            END IF;
            DELETE FROM team_members
        WHERE team_id = :new.team_id AND userid = :old.sub_leader;
            INSERT INTO team_members (team_member_id, team_id, userid)
            VALUES (NEW_PK, v___team_id, v___sub_leader);    
    END;
 ELSE
 null;
 END IF;

END;
/

create or replace TRIGGER project_threshold BEFORE INSERT OR UPDATE ON project_details
FOR EACH ROW
DECLARE
v___last_date projects.check_out%TYPE;
v___project_name projects.project_name%TYPE;
BEGIN
SELECT check_out, project_name
INTO v___last_date, v___project_name
FROM projects
WHERE project_id = :old.project_id;
    IF v___last_date < :new.end_to THEN
    RAISE_APPLICATION_ERROR(-20005,'The boundary of project '''||v___project_name||''' has been crossed');
    ELSE
    null;
    END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
NULL;
END;
/

--CREATE OR REPLACE TRIGGER first_admin AFTER INSERT ON user_tables
--DECLARE
--PRAGMA AUTONOMOUS_TRANSACTION;
--v__user NUMBER;
--BEGIN
--select count(*)
--into v__user
--from user_tables;
--IF v__user = 1 THEN
--    IF INSERTING THEN
--        INSERT INTO users_role (roleid, userid)
--        VALUES ('1000','1000');
--    ELSE null;
--    END IF;

--ELSE null;
--END IF;
--END;
--/

create or replace TRIGGER first_admin AFTER INSERT ON user_tables
DECLARE
--PRAGMA AUTONOMOUS_TRANSACTION;
v__user NUMBER;
BEGIN
select count(*)
into v__user
from user_tables;
IF v__user = 1 THEN
    IF INSERTING THEN
        UPDATE user_tables
        SET STATUS = 'Y'
        WHERE userid = '1000';
        INSERT INTO users_role (roleid, userid)
        VALUES ('1000','1000');
    ELSE null;
    END IF;

ELSE null;
END IF;
END;
/



CREATE or replace TRIGGER project_role_strict BEFORE INSERT OR UPDATE OR DELETE ON ROLE_TABLES
BEGIN
IF INSERTING THEN
RAISE_APPLICATION_ERROR(-20004,'No new role is allowed');
ELSIF UPDATING THEN
RAISE_APPLICATION_ERROR(-20005,'No role changing is allowed');
ELSIF DELETING THEN
RAISE_APPLICATION_ERROR(-20006,'Removing role is not allowed');
END IF;
END;
/

create or replace trigger project_auth_placement after insert on team_members 
for each row 
declare 
v__users number; 
v__exist number; 
v__role users_role.roleid%type; 
begin 
if inserting then 
 select count(*) 
 into v__exist 
 from users_role 
 where userid = :new.userid and team_id = :new.team_id and roleid in ('1000','1001','1002'); 
 if v__exist > 0 then 
 null; 
 elsif v__exist <= 0 then  
        select roleid 
        into v__role 
        from users_role 
        where userid = :new.userid 
        order by roleid asc 
        fetch first 1 row only; 
        insert into users_role (userid, roleid, team_id) 
        values (:new.userid, v__role , :new.team_id); 
  end if; 
end if; 
exception 
when no_data_found then 
    if inserting then 
    select count(*) 
    into v__users 
    from user_tables; 
        if v__users > 0 then --other users already in this app
            if v__users > 1 then
             insert into users_role (userid, roleid, team_id) 
             values (:new.userid, '1002' , :new.team_id);    
            elsif v__users = 1 then --first user
                select count(*) 
                into v__exist 
                from users_role 
                where userid = :old.userid
                -- and team_id = :new.team_id 
                and roleid in ('1000'); 
                if v__exist > 0 then
                    update users_role
                    set team_id = :new.team_id
                    where userid = :old.userid
                    and roleid = '1000';
                else
                null;
                end if;
            end if; 
        elsif v__users <= 0 then    --it is first user 
            insert into users_role (userid, roleid, team_id) 
            values (:new.userid, '1000' , :new.team_id); 
        end if; 
    end if; 
when others then 
null; 
end; 
/

------------------JOB SCHEDULED
BEGIN
DBMS_SCHEDULER.CREATE_JOB (
Job_name=> 'PROJECT_STATUS_OVERDUE',
Job_type=> 'STORED_PROCEDURE',
Job_action => 'PROJECT_STATUS',
Start_date => SYSTIMESTAMP,
Repeat_interval=> 'FREQ=DAILY; BYHOUR=23; BYMINUTE=30',
Enabled => TRUE
);
END;
/

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
Job_name=> 'PROJECT_NOTIFY_MAILING',
Job_type=> 'STORED_PROCEDURE',
Job_action => 'PROJECT_OVERDUE_NOTIFY',
Start_date => SYSTIMESTAMP,
Repeat_interval=> 'FREQ=DAILY; BYHOUR=23; BYMINUTE=25',
Enabled => TRUE
);
END;
/

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
Job_name=> 'PROJECT_AUTOMATED_CLOSING',
Job_type=> 'STORED_PROCEDURE',
Job_action => 'PROJECT_CLOSING',
Start_date => SYSTIMESTAMP,
Repeat_interval=> 'FREQ=DAILY; BYHOUR=23; BYMINUTE=40',
Enabled => TRUE
);
END;
/

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
Job_name=> 'NOTIFY_PROJECT_NO_TASK',
Job_type=> 'STORED_PROCEDURE',
Job_action => 'PROJECT_ACTIVITY',
Start_date => SYSTIMESTAMP,
Repeat_interval=> 'FREQ=DAILY; BYHOUR=23; BYMINUTE=50',
Enabled => TRUE
);
END;
/

BEGIN
  DBMS_SCHEDULER.create_job (
    job_name        => 'SIX_MONTHS_STATUS',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN
FOR i IN (
SELECT TASK_NAME, STATUS FROM project_details WHERE status = 2 AND sysdate - end_to = 180) 
LOOP
UPDATE project_details
SET status = 3
WHERE status = i.status;
END LOOP;
    INSERT INTO check_jobs(effected_date,status,comments)
    VALUES (CURRENT_TIMESTAMP,''6'',''Replace Overdue to Halt'');
END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MONTHLY;BYMONTHDAY=6;BYHOUR=23;BYMINUTE=55;',
    enabled         => TRUE);
END;
/

BEGIN
   DBMS_SCHEDULER.CREATE_JOB (
      job_name         => 'JOB_CHECKER_DELETED',
      job_type         => 'PLSQL_BLOCK',
      job_action       => 'BEGIN
                            DELETE FROM CHECK_JOBS;
                                INSERT INTO check_jobs(effected_date,status,comments)
                                VALUES (CURRENT_TIMESTAMP,''7'',''Delete Completed'');
                            END;',
      start_date       => SYSTIMESTAMP,
      repeat_interval  => 'FREQ=YEARLY;BYDATE=1015;BYHOUR=0;BYMINUTE=0;',
      enabled          => TRUE);
END;
/

BEGIN
   DBMS_SCHEDULER.CREATE_JOB (
      job_name         => 'MY_JOB',
      job_type         => 'PLSQL_BLOCK',
      job_action       => '
DECLARE
v___track VARCHAR2(1);
BEGIN
SELECT get_job
INTO v___track
FROM progress_tracks
WHERE rowid = ''ALsb7EAABAACtGlAAA'';
IF v___track = ''N'' THEN
    BEGIN
    DECLARE
v___today NUMBER;
BEGIN
SELECT COUNT(today)
INTO v___today
FROM progress
WHERE TO_CHAR(today,''mm/dd/yyyy'') = TO_CHAR(sysdate,''mm/dd/yyyy'');
IF v___today >= 1 THEN
null;
ELSIF v___today < 1 THEN
    declare
    v number;
    prob number;
    begin
    select max(pk) into v from progress;
    if v is null then 
    v := 1;
    INSERT INTO progress (today,action_take,probability,pk)
    VALUES (sysdate,null,''-10'',v);
    INSERT INTO check_jobs(effected_date,status,comments)
    VALUES (CURRENT_TIMESTAMP,''4'',''Juncture'');
    elsif v is not null then
    v:= v + 1;
    select probability into prob from progress order by pk desc fetch first 1 row only; 
    prob := prob - 10;
    INSERT INTO progress (today,action_take,probability,pk)
    VALUES (sysdate,null,prob,v);
    INSERT INTO check_jobs(effected_date,status,comments)
    VALUES (CURRENT_TIMESTAMP,''4'',''Juncture'');
    end if;
    end;
END IF;
END;

    END;
ELSIF v___track = ''Y'' THEN
null;
END IF;
END;',
      start_date       => SYSTIMESTAMP,
      repeat_interval  => 'FREQ=DAILY; BYHOUR=23; BYMINUTE=45',
      enabled          => TRUE);
END;
/

ALTER TABLE project_details INMEMORY;
ALTER TABLE user_tasks INMEMORY;
ALTER TABLE project_attachments INMEMORY;
ALTER TABLE project_details INMEMORY PRIORITY HIGH;
ALTER TABLE user_tasks INMEMORY PRIORITY MEDIUM;
ALTER TABLE project_attachments INMEMORY PRIORITY LOW;


commit;
/