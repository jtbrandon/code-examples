#RUN from build 
CREATE USER %DBUSER%  IDENTIFIED BY asdfasdf default tablespace users temporary tablespace temp;
GRANT connect, resource, create session to %DBUSER%;
GRANT unlimited TABLESPACE to %DBUSER%;
EXIT