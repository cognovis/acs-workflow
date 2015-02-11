--
-- acs-workflow/sql/sample-article-drop.sql
--
-- Drops the article-authoring workflow.
--
-- @author Kevin Scaldeferri (kevin@theory.caltech.edu)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id: sample-article-drop.sql,v 1.1.1.1 2005/04/27 22:50:59 cvs Exp $
--

CREATE OR REPLACE FUNCTION inline_0 () RETURNS integer AS $$
BEGIN
    perform workflow__delete_cases('article_wf');
    return 0;
END;
$$ LANGUAGE plpgsql;

drop table wf_article_cases;


select inline_0 ();

drop function inline_0 ();



CREATE OR REPLACE FUNCTION inline_0 () RETURNS integer AS $$
BEGIN
    perform workflow__drop_workflow('article_wf');
    return 0;
END;
$$ LANGUAGE plpgsql;


select inline_0 ();

drop function inline_0 ();

drop function wf_article_callback__notification(integer,varchar,integer,integer,varchar,varchar);

