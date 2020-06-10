# Run using build script
BEGIN
  FOR c IN (SELECT table_name, constraint_name FROM user_constraints WHERE constraint_type = 'R' AND table_name != 'VERSIONINFO')
  LOOP
    EXECUTE IMMEDIATE ('alter table ' || c.table_name || ' disable constraint ' || c.constraint_name);
  END LOOP;
  FOR c IN (SELECT table_name FROM user_tables WHERE table_name != 'VERSIONINFO')
  LOOP
    EXECUTE IMMEDIATE ('truncate table ' || c.table_name);
  END LOOP;
  FOR c IN (SELECT table_name, constraint_name FROM user_constraints WHERE constraint_type = 'R' AND table_name != 'VERSIONINFO')
  LOOP
    EXECUTE IMMEDIATE ('alter table ' || c.table_name || ' enable constraint ' || c.constraint_name);
  END LOOP;
END;
/
EXIT