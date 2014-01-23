ad_page_contract {
    Displays information about a specific task.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 13 July 2000
    @cvs-id $Id$
} {
    task_id:integer,notnull
    {action:array {}}
    {attributes:array {}}
    {assignments:array,multiple {}}
    {msg:html {}}
    {vertical:integer 0}
    {return_url ""}
    {force_return_url 0}
    {autoprocess_p 0}
} -properties {
    case_id
    context
    task:onerow
    task_html
    user_id
    return_url
    export_form_vars
    extreme_p 
}

# ---------------------------------------------------------
# Defaults & Security

# We don't force the user to authentify, is that right?
set user_id [ad_get_user_id]
set current_url [im_url_with_query]

# ToDo: NOTE! We need to add some double-click protection here.

set the_action [array names action]
if { [llength $the_action] > 1 } {
    ad_return_error "Invalid input" "More than one action was requested"
    ad_script_abort
} 

if {[llength $the_action] == 1 && $autoprocess_p == 1 } {

    callback workflow_task_before_update -task_id $task_id -action $the_action -msg $msg -attributes [array get attributes]

    set journal_id [wf_task_action -user_id $user_id -msg $msg -attributes [array get attributes] -assignments [array get assignments] $task_id $the_action]

    callback workflow_task_after_update -task_id $task_id -action $the_action -msg $msg -attributes [array get attributes]

    # After a "finish" action we can go back to return_url directly.
    if {"finish" == $the_action} { ad_returnredirect $return_url }

    # Otherwise go back to the tasks's page
    ad_returnredirect "task?[export_url_vars task_id return_url]"

    ad_script_abort
}


# ---------------------------------------------------------
# Fire all message transitions before:

wf_sweep_message_transition_tcl



# ---------------------------------------------------------
# Get everything about the task


if {[catch {
    array set task [wf_task_info $task_id]
} err_msg]} {
    ad_return_complaint 1 "<li>
	<b>[lang::message::lookup "" acs-workflow.Task_not_found "Task not found:"]</b><p>
	[lang::message::lookup "" acs-workflow.Task_not_found_message "
		This error can occur if a system administrator has deleted a workflow.<br>
		This situation should not occur during normal operations.<p>
		Please contact your System Administrator
	"]
    "
    return
}

set task(add_assignee_url) "assignee-add?[export_url_vars task_id]"
set task(assign_yourself_url) "assign-yourself?[export_vars -url {task_id {return_url $current_url}}]"
set task(manage_assignments_url) "task-assignees?[export_vars -url {task_id {return_url $current_url}}]"
set task(cancel_url) "task?[export_vars -url {task_id return_url {action.cancel Cancel}}]"
set task(action_url) "task"
set task(return_url) $return_url

set task_name "undefined"
if {[info exists task(task_name)]} { set task_name $task(task_name)}

set context [list [list "case?case_id=$task(case_id)" "$task(object_name) case"] $task_name]
set panel_color "#dddddd"

set show_action_panel_p 1

# ---------------------------------------------------------
# Get "information panel" information - displayed on the left usually

template::multirow create panels header template_url bgcolor
set this_user_is_assigned_p $task(this_user_is_assigned_p)

db_multirow panels panels {} {
    set bgcolor $panel_color
    if {"t" == $overrides_both_panels_p} { set show_action_panel_p 0 }
}

# Only display the default-info-panel when we have nothing better
if { ${panels:rowcount} == 0 } {
    template::multirow append panels "Case" "task-default-info" $panel_color
}


# ---------------------------------------------------------
# Display instructions, if any

if { [db_string instruction_check ""] } {
    template::multirow append panels "Instructions" "task-instructions" $panel_color
}


# ---------------------------------------------------------
# Now for action panels -- these are always displayed at the far right

set show_action_form_p 0
if {$show_action_panel_p} {

    set override_action 0
    db_foreach action_panels {} {
        set override_action 1
        template::multirow append panels $header $template_url "#ffffff"
    }

    if { $override_action == 0 } {
        # We should show the action form formerly in task-action
        set show_action_form_p 1
    }
}

if {$show_action_form_p} {
    # This template expects the following properties:
    #   task:onerow
    #   task_attributes_to_set:multirow
    #   task_assigned_users:multirow
    #   task_roles_to_assign:multirow

    # "Approval Tasks" are identified by atleast one attribute
    # to be set during the transition
    set workflow_key $task(workflow_key)
    set transition_key $task(transition_key)
    set approval_attributes [db_list approval_attributes "
    	select	attribute_id
    	from	wf_transition_attribute_map tam
    	where	tam.workflow_key = :workflow_key and
    		tam.transition_key = :transition_key
    "]
    set approval_task_p 1
    if {[llength $approval_attributes] == 0} { set approval_task_p 0 }

    # Only use the approval_task logic if the current user
    # is assigned to the task.
    if {!$task(this_user_is_assigned_p)} { set approval_task_p 0 }

    # Show reassign links (Assign yourself / reassign)? 
    set reassign_p [im_permission $user_id wf_reassign_tasks]

    set header_html [im_box_header $task(task_name)]
    set form_id task-action

    ad_form -name $form_id \
        -export [list return_url {task_id $task(task_id)}] \
        -action "/acs-workflow/task" \
        -has_edit 1

    if {$approval_task_p} {

        if {0} {
            ds_comment "[template::multirow columns task_rols_to_assign]"
            <multiple name="task_roles_to_assign">
            <tr>
                <th align="right">#acs-workflow.lt_Assign_task_roles_to_#</th>
                <td>@task_roles_to_assign.assignment_widget;noquote@</td>
            </tr>
            </multiple>
        }

        template::multirow foreach task_attributes_to_set {
            if {[info exists attributes($attribute_name)]} {
                set value $attributes($attribute_name)
            }
            switch $datatype {
                boolean {
                    ad_form -extend -name $form_id -form {
                        {attributes.${attribute_name}:text(select) {value $value} {label "$pretty_name"} {options {{"[_ intranet-core.Yes]" "t"} {"[_ intranet-core.No]" "f"}}}}
                    }          
                }
                default {
                    ad_form -extend -name $form_id -form {
                        {attributes.${attribute_name}:text(text) {label "$pretty_name"} {value "$value"}}            
                    }
                }
            }
        }


        ad_form -extend -name $form_id -form {
            {msg:text(textarea),optional {label "[_ acs-workflow.Comment]"} {html {cols 20 rows 4}}}
            {action.finish:text(submit) {label "[_ acs-workflow.Task_done]"}}
            {task_start_date:text(inform) {label "[_ acs-workflow.Task_started]"} {value "[db_string timestamp {select now() from dual}]"}}
        } 
    } else {
        ad_form -extend -name $form_id -form {
            {action.start:text(submit) {label "[_ acs-workflow.Start_Task]"}}
        }
    }
     
    ad_form -extend -name $form_id -on_submit {
        
        # Quick check if the user was waiting to long to approve
        set estimated_minutes $task(estimated_minutes)
        if {$estimated_minutes eq ""} {
            set estimated_minutes 5
        }
        
        if {[db_string date_check "select 1 from dual where :task_start_date < now() - interval '$estimated_minutes minutes'" -default 0]} {
            form set_error $form_id task_start_date "[_ acs-workflow.Waited_too_long]"
            template::element::set_value $form_id task_start_date "[db_string timestamp {select now() from dual}]"
            break
        }

        set object_modify_date [db_string modify_date "select last_modified from acs_objects where object_id = $task(object_id)"]
        if {[db_string date_check "select 1 from dual where :object_modify_date >= :task_start_date" -default 0]} {
            form set_error $form_id task_start_date "[_ acs-workflow.Object_was_changed]"
            template::element::set_value $form_id task_start_date "[db_string timestamp {select now() from dual}]"
            break
        }
        
        callback workflow_task_on_submit -task_id $task_id -form_id $form_id -workflow_key $task(workflow_key)
        if {[exists_and_not_null error_field]} {
            form set_error $form_id $error_field $error_message
            break
        }
        
        if {$msg ne ""} {
            set msg "[lang::message::lookup "" acs-workflow.Comment_added "Comment added:"] $msg"
        }

        if {[llength $the_action] == 1 } {
    
            callback workflow_task_before_update -task_id $task_id -action $the_action -msg $msg -attributes [array get attributes]
            set journal_id [wf_task_action -user_id $user_id -msg $msg -attributes [array get attributes] -assignments [array get assignments] $task_id $the_action]
            callback workflow_task_after_update -task_id $task_id -action $the_action -msg $msg -attributes [array get attributes]

            # After a "finish" action we can go back to return_url directly.
            if {"finish" == $the_action} { ad_returnredirect $return_url }

            # Otherwise go back to the tasks's page
            ad_returnredirect "task?[export_url_vars task_id return_url]"
            ad_script_abort
        }
    }
}

set panel_width [expr {100/(${panels:rowcount})}]
set case_id $task(case_id)
set case_state [db_string case_state "select state from wf_cases where case_id = :case_id"]

# ---------------------------------------------------------
# "Extreme Actions" - cancel and/or suspend the case

set extreme_p 0

set wf_suspend_case_p [permission::permission_p -party_id $user_id -object_id [ad_conn subsite_id] -privilege "wf_suspend_case"]
set wf_cancel_case_p [permission::permission_p -party_id $user_id -object_id [ad_conn subsite_id] -privilege "wf_cancel_case"]

if { [string compare $case_state "active"] == 0 && ($wf_suspend_case_p || $wf_cancel_case_p) } {
    set extreme_p 1
    template::multirow create extreme_actions url title
    if { $wf_suspend_case_p } { template::multirow append extreme_actions "case-state-change?[export_url_vars case_id]&action=suspend" [lang::message::lookup "" intranet-workflow.Suspend_Case "Suspend Case"]}
    if { $wf_cancel_case_p } { template::multirow append extreme_actions "case-state-change?[export_url_vars case_id]&action=cancel" [lang::message::lookup "" intranet-workflow.Cancel_Case "Cancel Case"]}
}
 
# ---------------------------------------------------------
# Fire all message transitions after the action:

wf_sweep_message_transition_tcl

set export_form_vars [export_vars -form {task_id return_url}]

ad_return_template

