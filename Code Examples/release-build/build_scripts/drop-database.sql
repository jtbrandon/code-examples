#RUN WITH sqlplus system/asdfasdf '@setup-database.sql'
WHENEVER SQLERROR EXIT SQL.SQLCODE
declare
SID varchar(50);
serial varchar(50);
sqlstmt varchar2(4000);
u_count number;
user_name VARCHAR2 (50);

cursor v_cursor is SELECT sid,serial# FROM v$session  WHERE username IN ('%DBUSER%');
begin
   u_count :=0;
    user_name :='%DBUSER%';
        SELECT COUNT (1) INTO u_count FROM dba_users WHERE username = UPPER (user_name);
        	IF u_count != 0
            	THEN
					for vc in v_cursor
  					loop
    					SID :=   vc.sid;
     					serial := vc.serial#;
     					sqlstmt := 'ALTER SYSTEM KILL SESSION '''||SID||','||serial||'''';
     					execute immediate sqlstmt;
  					end loop;
                 	EXECUTE IMMEDIATE ('DROP USER '||user_name||' CASCADE');
            END IF;
            u_count := 0;
        EXCEPTION
        	WHEN OTHERS
            	THEN
                    DBMS_OUTPUT.put_line (SQLERRM);
                    DBMS_OUTPUT.put_line ('   ');
end;
/
EXIT
