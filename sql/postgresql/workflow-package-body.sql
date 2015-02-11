-- /packages/acs-workflow/sql/postgresql/workflow-package-body.sql

-- create or replace package body workflow 
-- function create_workflow


-- added
select define_function_args('workflow__create_workflow','workflow_key,pretty_name,pretty_plural;null,description;null,table_name,id_column;case_id');

--
-- procedure workflow__create_workflow/6
--
CREATE OR REPLACE FUNCTION workflow__create_workflow(
   create_workflow__workflow_key varchar,
   create_workflow__pretty_name varchar,
   create_workflow__pretty_plural varchar, -- default null
   create_workflow__description varchar,   -- default null
   create_workflow__table_name varchar,
   create_workflow__id_column varchar      -- default 'case_id'

) RETURNS varchar AS $$
DECLARE
	v_num_rows				integer;
	v_workflow_key				varchar;
BEGIN
	select count(*) into v_num_rows from pg_class
	where relname = lower(create_workflow__table_name);

	if v_num_rows = 0 then
		raise EXCEPTION '-20000: The table "%"must be created before calling workflow.create_workflow.', create_workflow__table_name;
	end if;

	if substr(create_workflow__workflow_key, length(create_workflow__workflow_key) - 2, 3) != '_wf' then
		v_workflow_key := create_workflow__workflow_key || '_wf';
	else
		v_workflow_key := create_workflow__workflow_key;
	end if;

	PERFORM acs_object_type__create_type (
		v_workflow_key, 
		create_workflow__pretty_name, 
		create_workflow__pretty_plural,
		'workflow',
		create_workflow__table_name,
		create_workflow__id_column,
		null,
		'f',
		null,
		null
	);

	insert into wf_workflows (
		workflow_key, description
	) values (
		v_workflow_key, create_workflow__description
	);

	return v_workflow_key;
	
END;
$$ LANGUAGE plpgsql;


/* Note: The workflow-specific cases table must be dropped before calling this proc */


-- added
select define_function_args('workflow__drop_workflow','workflow_key');

--
-- procedure workflow__drop_workflow/1
--
CREATE OR REPLACE FUNCTION workflow__drop_workflow(
   drop_workflow__workflow_key varchar
) RETURNS integer AS $$
DECLARE
	v_table_name				varchar;	
	v_num_rows				integer;	
	attribute_rec				record;
BEGIN
	select table_name into v_table_name from acs_object_types
	where	object_type = drop_workflow__workflow_key;

	select case when count(*) = 0 then 0 else 1 end into v_num_rows from pg_class
	where	relname = lower(v_table_name);

	if v_num_rows > 0 then
		raise EXCEPTION '-20000: The table "%" must be dropped before calling workflow__drop_workflow.', v_table_name;
	end if;

	select case when count(*) = 0 then 0 else 1 end into v_num_rows from wf_cases
	where	workflow_key = drop_workflow__workflow_key;

	if v_num_rows > 0 then
		raise EXCEPTION '-20000: You must delete all cases of workflow "%" before dropping the workflow definition.', drop_workflow__workflow_key;
	end if;

	/* Delete all the auxillary stuff */
	delete from wf_context_task_panels where workflow_key = drop_workflow__workflow_key;
	delete from wf_context_assignments where workflow_key = drop_workflow__workflow_key;
	delete from wf_context_role_info where workflow_key = drop_workflow__workflow_key; 
	delete from wf_context_transition_info where workflow_key = drop_workflow__workflow_key; 
	delete from wf_context_workflow_info where workflow_key = drop_workflow__workflow_key;
	delete from wf_arcs where workflow_key = drop_workflow__workflow_key;
	delete from wf_places where workflow_key = drop_workflow__workflow_key;
	delete from wf_transition_role_assign_map where workflow_key = drop_workflow__workflow_key;
	delete from wf_transitions where workflow_key = drop_workflow__workflow_key;
	delete from wf_roles where workflow_key = drop_workflow__workflow_key;

	/* Drop all attributes */
	for attribute_rec in 
		select attribute_id, attribute_name 
		from acs_attributes 
		where object_type = drop_workflow__workflow_key
	LOOP
		/* there is no on delete cascade, so we have to manually 
		* delete all the values 
		*/

		delete from acs_attribute_values where attribute_id = attribute_rec.attribute_id;

		PERFORM workflow__drop_attribute (
			drop_workflow__workflow_key,
			attribute_rec.attribute_name
		);
	end loop;

	/* Delete the workflow */
	delete from wf_workflows where workflow_key = drop_workflow__workflow_key;
	
	PERFORM acs_object_type__drop_type (
		drop_workflow__workflow_key,
		'f'
	);

	return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure delete_cases


-- added
select define_function_args('workflow__delete_cases','workflow_key');

--
-- procedure workflow__delete_cases/1
--
CREATE OR REPLACE FUNCTION workflow__delete_cases(
   delete_cases__workflow_key varchar
) RETURNS integer AS $$
DECLARE
	case_rec				record; 
BEGIN
	for case_rec in 
		select case_id 
		from wf_cases 
		where workflow_key = delete_cases__workflow_key
	LOOP
		PERFORM workflow_case__delete(case_rec.case_id);
	end loop;

	return 0; 
END;
$$ LANGUAGE plpgsql;


-- function create_attribute


-- added
select define_function_args('workflow__create_attribute','workflow_key,attribute_name,datatype,pretty_name,pretty_plural;null,table_name;null,column_name;null,default_value;null,min_n_values;1,max_n_values;1,sort_order;null,storage;generic');

--
-- procedure workflow__create_attribute/12
--
CREATE OR REPLACE FUNCTION workflow__create_attribute(
   create_attribute__workflow_key varchar,
   create_attribute__attribute_name varchar,
   create_attribute__datatype varchar,
   create_attribute__pretty_name varchar,
   create_attribute__pretty_plural varchar, -- default null
   create_attribute__table_name varchar,    -- default null
   create_attribute__column_name varchar,   -- default null
   create_attribute__default_value varchar, -- default null
   create_attribute__min_n_values integer,  -- default 1
   create_attribute__max_n_values integer,  -- default 1
   create_attribute__sort_order integer,    -- default null
   create_attribute__storage varchar        -- default 'generic'

) RETURNS integer AS $$
DECLARE
	v_attribute_id				integer;	
BEGIN
	v_attribute_id := acs_attribute__create_attribute(
		create_attribute__workflow_key,
		create_attribute__attribute_name,
		create_attribute__datatype,
		create_attribute__pretty_name,
		create_attribute__pretty_plural,
		create_attribute__table_name,
		create_attribute__column_name,
		create_attribute__default_value,
		create_attribute__min_n_values,
		create_attribute__max_n_values,
		create_attribute__sort_order,
		create_attribute__storage,
		'f'
	);

	return v_attribute_id;
	
END;
$$ LANGUAGE plpgsql;


-- procedure drop_attribute


-- added
select define_function_args('workflow__drop_attribute','workflow_key,attribute_name');

--
-- procedure workflow__drop_attribute/2
--
CREATE OR REPLACE FUNCTION workflow__drop_attribute(
   drop_attribute__workflow_key varchar,
   drop_attribute__attribute_name varchar
) RETURNS integer AS $$
DECLARE
	v_attribute_id			integer;	
BEGIN
	select attribute_id into v_attribute_id
	from	acs_attributes
	where	object_type = drop_attribute__workflow_key
		and	attribute_name = drop_attribute__attribute_name;

	PERFORM acs_attribute__drop_attribute (
		drop_attribute__workflow_key,
		drop_attribute__attribute_name
	);

	return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure add_place


-- added
select define_function_args('workflow__add_place','workflow_key,place_key,place_name,sort_order');

--
-- procedure workflow__add_place/4
--
CREATE OR REPLACE FUNCTION workflow__add_place(
   add_place__workflow_key varchar,
   add_place__place_key varchar,
   add_place__place_name varchar,
   add_place__sort_order integer
) RETURNS integer AS $$
DECLARE
	v_sort_order			integer; 
BEGIN
	if add_place__sort_order is null then
		select coalesce(max(sort_order)+1, 1)
		into v_sort_order
		from wf_places
		where workflow_key = add_place__workflow_key;
	else
		v_sort_order := add_place__sort_order;
	end if;
	insert into wf_places (workflow_key, place_key, place_name, sort_order)
	values (add_place__workflow_key, add_place__place_key,add_place__place_name, add_place__sort_order);

	return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure delete_place


-- added
select define_function_args('workflow__delete_place','workflow_key,place_key');

--
-- procedure workflow__delete_place/2
--
CREATE OR REPLACE FUNCTION workflow__delete_place(
   delete_place__workflow_key varchar,
   delete_place__place_key varchar
) RETURNS integer AS $$
DECLARE
BEGIN
	delete from wf_places
	where	workflow_key = delete_place__workflow_key 
	and	place_key = delete_place__place_key;

	return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure add_role


-- added
select define_function_args('workflow__add_role','workflow_key,role_key,role_name,sort_order');

--
-- procedure workflow__add_role/4
--
CREATE OR REPLACE FUNCTION workflow__add_role(
   add_role__workflow_key varchar,
   add_role__role_key varchar,
   add_role__role_name varchar,
   add_role__sort_order integer
) RETURNS integer AS $$
DECLARE
	v_sort_order			integer;
BEGIN
	if add_role__sort_order is null then
		select coalesce(max(sort_order)+1, 1)
		into v_sort_order
		from wf_roles
		where workflow_key = add_role__workflow_key;
	else
		v_sort_order := add_role__sort_order;
	end if;
	insert into wf_roles (
		workflow_key, role_key, role_name, sort_order
	) values (
		add_role__workflow_key, add_role__role_key, add_role__role_name, v_sort_order
	);
	return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure move_role_up


-- added
select define_function_args('workflow__move_role_up','workflow_key,role_key');

--
-- procedure workflow__move_role_up/2
--
CREATE OR REPLACE FUNCTION workflow__move_role_up(
   move_role_up__workflow_key varchar,
   move_role_up__role_key varchar
) RETURNS integer AS $$
DECLARE
	v_this_sort_order			integer;
	v_prior_sort_order			integer;
BEGIN
	select sort_order into v_this_sort_order
	from	wf_roles
	where	workflow_key = move_role_up__workflow_key
		and role_key = move_role_up__role_key;

	select max(sort_order) into v_prior_sort_order
	from wf_roles
	where workflow_key = move_role_up__workflow_key
		and sort_order < v_this_sort_order;

	if not found then
		/* already at top of sort order */
		return 0;
	end if;

	/* switch the sort orders around */
	update wf_roles
	set sort_order = (case when role_key=move_role_up__role_key then v_prior_sort_order else v_this_sort_order end)
	where workflow_key = move_role_up__workflow_key
		and sort_order in (v_this_sort_order, v_prior_sort_order);

	return 0;
END;
$$ LANGUAGE plpgsql;


-- procedure move_role_down


-- added
select define_function_args('workflow__move_role_down','workflow_key,role_key');

--
-- procedure workflow__move_role_down/2
--
CREATE OR REPLACE FUNCTION workflow__move_role_down(
   move_role_down__workflow_key varchar,
   move_role_down__role_key varchar
) RETURNS integer AS $$
DECLARE
	v_this_sort_order			integer;
	v_next_sort_order			integer;
BEGIN
	select sort_order
		into v_this_sort_order
		from wf_roles
	where workflow_key = move_role_down__workflow_key
		and role_key = move_role_down__role_key;

	select min(sort_order)
	into v_next_sort_order
	from wf_roles
	where workflow_key = move_role_down__workflow_key
	and sort_order > v_this_sort_order;

	if not found then
		/* already at bottom of sort order */
		return 0;
	end if;

	/* switch the sort orders around */
	update wf_roles
	set sort_order = (case when role_key=move_role_down__role_key then v_next_sort_order else v_this_sort_order end)
	where workflow_key = move_role_down__workflow_key
		and sort_order in (v_this_sort_order, v_next_sort_order);

	return 0;
END;
$$ LANGUAGE plpgsql;


-- procedure delete_role


-- added
select define_function_args('workflow__delete_role','workflow_key,role_key');

--
-- procedure workflow__delete_role/2
--
CREATE OR REPLACE FUNCTION workflow__delete_role(
   delete_role__workflow_key varchar,
   delete_role__role_key varchar
) RETURNS integer AS $$
DECLARE
BEGIN
	/* First, remove all references to this role from transitions */
	update wf_transitions
	set role_key = null
	where workflow_key = delete_role__workflow_key
	and role_key = delete_role__role_key;

	delete from wf_roles
	where	workflow_key = delete_role__workflow_key
	and	role_key = delete_role__role_key;

	return 0;
END;
$$ LANGUAGE plpgsql;


-- procedure add_transition


-- added
select define_function_args('workflow__add_transition','workflow_key,transition_key,transition_name,role_key,sort_order,trigger_type;user');

--
-- procedure workflow__add_transition/6
--
CREATE OR REPLACE FUNCTION workflow__add_transition(
   add_transition__workflow_key varchar,
   add_transition__transition_key varchar,
   add_transition__transition_name varchar,
   add_transition__role_key varchar,
   add_transition__sort_order integer,
   add_transition__trigger_type varchar -- default 'user'

) RETURNS integer AS $$
DECLARE
	v_sort_order				integer;
BEGIN
	if add_transition__sort_order is null then
		select coalesce(max(sort_order)+1, 1)
		into v_sort_order
		from wf_transitions
		where workflow_key = add_transition__workflow_key;
	else
		v_sort_order := add_transition__sort_order;
	end if;
	insert into wf_transitions (
		workflow_key, 
		transition_key, 
		transition_name, 
		role_key,
		sort_order, 
		trigger_type
	) values (
		add_transition__workflow_key, 
		add_transition__transition_key, 
		add_transition__transition_name,
		add_transition__role_key,
		v_sort_order, 
		add_transition__trigger_type
	);

	return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure delete_transition


-- added
select define_function_args('workflow__delete_transition','workflow_key,transition_key');

--
-- procedure workflow__delete_transition/2
--
CREATE OR REPLACE FUNCTION workflow__delete_transition(
   delete_transition__workflow_key varchar,
   delete_transition__transition_key varchar
) RETURNS integer AS $$
DECLARE
BEGIN
	delete from wf_transitions
	where	workflow_key = delete_transition__workflow_key
	and	transition_key = delete_transition__transition_key;

	return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure add_arc


-- added
select define_function_args('workflow__add_arc','workflow_key,transition_key,place_key,direction,guard_callback;null,guard_custom_arg;null,guard_description;null');

--
-- procedure workflow__add_arc/7
--
CREATE OR REPLACE FUNCTION workflow__add_arc(
   add_arc__workflow_key varchar,
   add_arc__transition_key varchar,
   add_arc__place_key varchar,
   add_arc__direction varchar,
   add_arc__guard_callback varchar,   -- default null
   add_arc__guard_custom_arg varchar, -- default null
   add_arc__guard_description varchar -- default null

) RETURNS integer AS $$
DECLARE
BEGIN
	insert into wf_arcs (workflow_key, transition_key, place_key, direction,
	guard_callback, guard_custom_arg, guard_description)
	values (add_arc__workflow_key, add_arc__transition_key, add_arc__place_key, add_arc__direction,
	add_arc__guard_callback, add_arc__guard_custom_arg, add_arc__guard_description);

	return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure add_arc


--
-- procedure workflow__add_arc/6
--
CREATE OR REPLACE FUNCTION workflow__add_arc(
   add_arc__workflow_key varchar,
   add_arc__from_transition_key varchar,
   add_arc__to_place_key varchar,
   add_arc__guard_callback varchar,
   add_arc__guard_custom_arg varchar,
   add_arc__guard_description varchar
) RETURNS integer AS $$
DECLARE
BEGIN
	perform workflow__add_arc (
		add_arc__workflow_key,
		add_arc__from_transition_key,
		add_arc__to_place_key,
		'out',
		add_arc__guard_callback,
		add_arc__guard_custom_arg,
		add_arc__guard_description
	);

	return 0;
END;
$$ LANGUAGE plpgsql;


-- procedure add_arc


--
-- procedure workflow__add_arc/3
--
CREATE OR REPLACE FUNCTION workflow__add_arc(
   add_arc__workflow_key varchar,
   add_arc__from_place_key varchar,
   add_arc__to_transition_key varchar
) RETURNS integer AS $$
DECLARE
BEGIN
	perform workflow__add_arc(
		add_arc__workflow_key,
		add_arc__to_transition_key,
		add_arc__from_place_key,
		'in',
		null,
		null,
		null
	);	

	return 0;
END;
$$ LANGUAGE plpgsql;


-- procedure delete_arc


-- added
select define_function_args('workflow__delete_arc','workflow_key,transition_key,place_key,direction');

--
-- procedure workflow__delete_arc/4
--
CREATE OR REPLACE FUNCTION workflow__delete_arc(
   delete_arc__workflow_key varchar,
   delete_arc__transition_key varchar,
   delete_arc__place_key varchar,
   delete_arc__direction varchar
) RETURNS integer AS $$
DECLARE
BEGIN
	delete from wf_arcs
	where	workflow_key = delete_arc__workflow_key
	and	transition_key = delete_arc__transition_key
	and	place_key = delete_arc__place_key
	and	direction = delete_arc__direction;

	return 0; 
END;
$$ LANGUAGE plpgsql;



-- procedure add_trans_attribute_map


-- added

--
-- procedure workflow__add_trans_attribute_map/4
--
CREATE OR REPLACE FUNCTION workflow__add_trans_attribute_map(
   p_workflow_key varchar,
   p_transition_key varchar,
   p_attribute_id integer,
   p_sort_order integer
) RETURNS integer AS $$
DECLARE
	v_num_rows			integer;
	v_sort_order			integer;
BEGIN
	select count(*)
		into v_num_rows
		from wf_transition_attribute_map
	where workflow_key = p_workflow_key
		and transition_key = p_transition_key
		and attribute_id = p_attribute_id;

	if v_num_rows > 0 then
		return 0;
	end if;
	if p_sort_order is null then
		select coalesce(max(sort_order)+1, 1)
		into v_sort_order
		from wf_transition_attribute_map
		where workflow_key = p_workflow_key
		and transition_key = p_transition_key;
	else
		v_sort_order := p_sort_order;
	end if;
	insert into wf_transition_attribute_map (
		workflow_key,
		transition_key,
		attribute_id,
		sort_order
	) values (
		p_workflow_key,
		p_transition_key,
		p_attribute_id,
		v_sort_order
	);
	return 0;
END;
$$ LANGUAGE plpgsql;



-- procedure add_trans_attribute_map


-- added
select define_function_args('workflow__add_trans_attribute_map','workflow_key,transition_key,attribute_name,sort_order');

--
-- procedure workflow__add_trans_attribute_map/4
--
CREATE OR REPLACE FUNCTION workflow__add_trans_attribute_map(
   p_workflow_key varchar,
   p_transition_key varchar,
   p_attribute_name varchar,
   p_sort_order integer
) RETURNS integer AS $$
DECLARE
	v_attribute_id			integer;
BEGIN
	select attribute_id
		into v_attribute_id
		from acs_attributes
	where object_type = p_workflow_key
		and attribute_name = p_attribute_name;

	perform workflow__add_trans_attribute_map (
		p_workflow_key,
		p_transition_key,
		v_attribute_id,
		p_sort_order
	);

	return 0;

END;
$$ LANGUAGE plpgsql;


-- procedure delete_trans_attribute_map


-- added

--
-- procedure workflow__delete_trans_attribute_map/3
--
CREATE OR REPLACE FUNCTION workflow__delete_trans_attribute_map(
   p_workflow_key varchar,
   p_transition_key varchar,
   p_attribute_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
	delete
		from wf_transition_attribute_map
	where workflow_key = p_workflow_key
		and transition_key = p_transition_key
		and attribute_id = p_attribute_id;

	return 0;
END;
$$ LANGUAGE plpgsql;

-- procedure delete_trans_attribute_map


-- added
select define_function_args('workflow__delete_trans_attribute_map','workflow_key,transition_key,attribute_name');

--
-- procedure workflow__delete_trans_attribute_map/3
--
CREATE OR REPLACE FUNCTION workflow__delete_trans_attribute_map(
   p_workflow_key varchar,
   p_transition_key varchar,
   p_attribute_name varchar
) RETURNS integer AS $$
DECLARE
	v_attribute_id			integer;
BEGIN
	select attribute_id
		into v_attribute_id
		from acs_attributes
	where object_type = p_workflow_key
		and attribute_name = p_attribute_name;

	delete from wf_transition_attribute_map
	where workflow_key = p_workflow_key
		and transition_key = p_transition_key
		and attribute_id = v_attribute_id;

	return 0;
END;
$$ LANGUAGE plpgsql;


-- procedure add_trans_role_assign_map


-- added
select define_function_args('workflow__add_trans_role_assign_map','workflow_key,transition_key,assign_role_key');

--
-- procedure workflow__add_trans_role_assign_map/3
--
CREATE OR REPLACE FUNCTION workflow__add_trans_role_assign_map(
   p_workflow_key varchar,
   p_transition_key varchar,
   p_assign_role_key varchar
) RETURNS integer AS $$
DECLARE
	v_num_rows			integer;
BEGIN
	select count(*)
		into v_num_rows
		from wf_transition_role_assign_map
	where workflow_key = p_workflow_key
		and transition_key = p_transition_key
		and assign_role_key = p_assign_role_key;

	if v_num_rows = 0 then
		insert into wf_transition_role_assign_map (
		workflow_key,
		transition_key,
		assign_role_key
		) values (
		p_workflow_key,
		p_transition_key,
		p_assign_role_key
		);
	end if;

	return 0;
END;
$$ LANGUAGE plpgsql;

-- procedure delete_trans_role_assign_map


-- added
select define_function_args('workflow__delete_trans_role_assign_map','workflow_key,transition_key,assign_role_key');

--
-- procedure workflow__delete_trans_role_assign_map/3
--
CREATE OR REPLACE FUNCTION workflow__delete_trans_role_assign_map(
   p_workflow_key varchar,
   p_transition_key varchar,
   p_assign_role_key varchar
) RETURNS integer AS $$
DECLARE
BEGIN
	delete from wf_transition_role_assign_map
	where workflow_key = p_workflow_key
		and transition_key = p_transition_key
		and assign_role_key = p_assign_role_key;

	return 0;
END;
$$ LANGUAGE plpgsql;



create sequence workflow_session_id;

create table previous_place_list (
		session_id	integer,
		rcnt		integer,
		constraint previous_place_list_pk
		primary key (session_id, rcnt),
		ky		varchar(100)
);

create table target_place_list (
		session_id	integer,
		rcnt		integer,
		constraint target_place_list_pk
		primary key (session_id, rcnt),
		ky		varchar(100)
);

create table guard_list (
		session_id	integer,
		rcnt		integer,
		constraint quard_list_pk 
		primary key (session_id, rcnt),
		ky		varchar(100)
);



-- added
select define_function_args('workflow__simple_p','workflow_key');

--
-- procedure workflow__simple_p/1
--
CREATE OR REPLACE FUNCTION workflow__simple_p(
   simple_p__workflow_key varchar
) RETURNS boolean AS $$
DECLARE
	v_session_id			integer;
	retval				boolean;
BEGIN
	v_session_id := nextval('workflow_session_id');
	retval := __workflow__simple_p(simple_p__workflow_key, v_session_id);

	delete from previous_place_list where session_id = v_session_id;
	delete from target_place_list where session_id = v_session_id;
	delete from guard_list where session_id = v_session_id;

	return retval;

END;
$$ LANGUAGE plpgsql;

-- function simple_p



-- added
select define_function_args('__workflow__simple_p','workflow_key,v_session_id');

--
-- procedure __workflow__simple_p/2
--
CREATE OR REPLACE FUNCTION __workflow__simple_p(
   simple_p__workflow_key varchar,
   v_session_id integer
) RETURNS boolean AS $$
DECLARE

	-- previous_place_list		t_place_table; 
	-- target_place_list		t_place_table; 
	-- guard_list			t_guard_table; 
	guard_list_1			varchar;
	guard_list_2			varchar;
	target_place_list_1		varchar;
	target_place_list_2		varchar;
	previous_place_list_i		varchar;
	v_row_count			integer default 0;	
	v_count				integer;	
	v_count2			integer;	
	v_place_key			wf_places.place_key%TYPE;
	v_end_place			wf_places.place_key%TYPE;
	v_transition_key		wf_transitions.transition_key%TYPE;
	v_rownum			integer;
	v_target			record;
BEGIN

	/* Let us do some simple checks first */

	/* Places with more than one arc out */
	select count(*) into v_count
	from	wf_places p
	where	p.workflow_key = simple_p__workflow_key
	and	1 < (select count(*) 
			from	wf_arcs a
			where	a.workflow_key = p.workflow_key
			and	a.place_key = p.place_key
			and	direction = 'in');
	raise notice 'query 1';
	if v_count > 0 then
		return 'f';
	end if;

	/* Transitions with more than one arc in */
	select count(*) into v_count
	from	wf_transitions t
	where	t.workflow_key = simple_p__workflow_key
	and	1 < (select count(*)
			from	wf_arcs a
			where	a.workflow_key = t.workflow_key
			and	a.transition_key = t.transition_key
			and	direction = 'in');

	raise notice 'query 2';
	if v_count > 0 then
		return 'f';
	end if;

	/* Transitions with more than two arcs out */
	select count(*) into v_count
	from	wf_transitions t
	where	t.workflow_key = simple_p__workflow_key
	and	2 < (select count(*)
			from	wf_arcs a
			where	a.workflow_key = t.workflow_key
			and	a.transition_key = t.transition_key
			and	direction = 'out');

	raise notice 'query 3';
	if v_count > 0 then
		return 'f';
	end if;

	/* Now we do the more complicated checks.
	* We keep a list of visited places because I could not think
	* of a nicer way that was not susceptable to infinite loops.
	*/


	v_place_key := 'start';
	v_end_place := 'end';

	loop
		exit when v_place_key = v_end_place;

		-- previous_place_list(v_row_count) := v_place_key;
		insert into previous_place_list 
		(session_id,rcnt,ky) 
		values 
		(v_session_id,v_row_count,v_place_key);
	raise notice 'query 4';

		select distinct transition_key into v_transition_key
		from	wf_arcs
		where	workflow_key = simple_p__workflow_key
		and	place_key = v_place_key
		and	direction = 'in';
	raise notice 'query 5';

		select count(*) into v_count
		from wf_arcs
		where workflow_key = simple_p__workflow_key
		and	transition_key = v_transition_key
		and	direction = 'out';
	raise notice 'query 6';

		if v_count = 1 then
			select distinct place_key into v_place_key
			from wf_arcs
			where workflow_key = simple_p__workflow_key
			and	transition_key = v_transition_key
			and	direction = 'out';
	raise notice 'query 7';

		else if v_count = 0 then
			/* deadend! */
			return 'f';

		else
			/* better be two based on our earlier test */

			v_rownum := 1;
			for v_target in 
				select place_key,guard_callback
				from	wf_arcs
				where	workflow_key = simple_p__workflow_key
				and	transition_key = v_transition_key
				and	direction = 'out'
			LOOP
			-- target_place_list(v_target.rownum) := v_target.place_key;
	raise notice 'query 8';
			insert into target_place_list (session_id,rcnt,ky) 
			values (v_session_id,v_rownum,v_target.place_key);
	raise notice 'query 9';

			-- guard_list(v_target.rownum) := v_target.guard_callback; 
			insert into guard_list (session_id,rcnt,ky) 
			values (v_session_id,v_rownum,v_target.guard_callback);
			v_rownum := v_rownum + 1;
	raise notice 'query 10';
			end loop;
	
			/* Check that the guard functions are the negation of each other 
			* by looking for the magic entry "#" (exactly once)
			*/
			select ky into guard_list_1 from guard_list 
			where session_id = v_session_id and rcnt = 1;
	raise notice 'query 11';

			select ky into guard_list_2 from guard_list 
			where session_id = v_session_id and rcnt = 2;
	raise notice 'query 12';

			if ((guard_list_1 != '#' and guard_list_2 != '#') or
			(guard_list_1 = '#' and guard_list_2 = '#')) then
			return 'f';
			end if;
	
			/* Check that exactly one of the targets is in the previous list */

			v_count2 := 0;
			select ky into target_place_list_1 from target_place_list 
			where session_id = v_session_id and rcnt = 1;
	raise notice 'query 13';

			select ky into target_place_list_2 from target_place_list 
			where session_id = v_session_id and rcnt = 2;			
	raise notice 'query 14';

			for i in 0..v_row_count LOOP
				select ky into previous_place_list_i 
				from previous_place_list where session_id = v_session_id 
				and rcnt = i;
			if target_place_list_1 = previous_place_list_i then
				v_count2 := v_count2 + 1;
				v_place_key := target_place_list_2;
			end if;
			if target_place_list_2 = previous_place_list_i then
				v_count2 := v_count2 + 1;
				v_place_key := target_place_list_1;
			end if;
			end loop;
	raise notice 'query 15';

			if v_count2 != 1 then
			return 'f';
			end if;

		end if; end if;

		v_row_count := v_row_count + 1;

	end loop;

	/* if we got here, it must be okay */
	return 't';

	
END;
$$ LANGUAGE plpgsql;


