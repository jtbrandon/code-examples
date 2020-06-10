DROP USER yleo_tax_specs CASCADE;
CREATE USER yleo_tax_specs IDENTIFIED BY asdfasdf;
GRANT connect, resource, debug connect session, create session to yleo_tax_specs;
