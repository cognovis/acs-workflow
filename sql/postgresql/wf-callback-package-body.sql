
-- create or replace package body wf_callback
-- function guard_attribute_true


-- added
select define_function_args('wf_callback__guard_attribute_true','case_id,workflow_key,transition_key,place_key,direction,custom_arg');

--
-- procedure wf_callback__guard_attribute_true/6
--
CREATE OR REPLACE FUNCTION wf_callback__guard_attribute_true(
   guard_attribute_true__case_id integer,
   guard_attribute_true__workflow_key varchar,
   guard_attribute_true__transition_key varchar,
   guard_attribute_true__place_key varchar,
   guard_attribute_true__direction varchar,
   guard_attribute_true__custom_arg varchar
) RETURNS boolean AS $$
DECLARE

  v_value				varchar;
BEGIN
        v_value := workflow_case__get_attribute_value(
	    guard_attribute_true__case_id, 
	    guard_attribute_true__custom_arg
	);

	IF 't' = substring(v_value from 1 for 1) THEN return true; END IF;
	IF 'f' = substring(v_value from 1 for 1) THEN return false; END IF;

	return null;
END;
$$ LANGUAGE plpgsql;


-- function time_sysdate_plus_x


-- added
select define_function_args('wf_callback__time_sysdate_plus_x','case_id,transition_key,custom_arg');

--
-- procedure wf_callback__time_sysdate_plus_x/3
--
CREATE OR REPLACE FUNCTION wf_callback__time_sysdate_plus_x(
   time_sysdate_plus_x__case_id integer,
   time_sysdate_plus_x__transition_key varchar,
   time_sysdate_plus_x__custom_arg text
) RETURNS timestamptz AS $$
DECLARE
BEGIN
        return now() + (time_sysdate_plus_x__custom_arg || ' days')::interval;
     
END;
$$ LANGUAGE plpgsql;



