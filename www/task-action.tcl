# This template expects the following properties:
#   task:onerow
#   task_attributes_to_set:multirow
#   task_assigned_users:multirow
#   task_roles_to_assign:multirow

set user_id [ad_conn user_id]
set form_id "task-action"
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



ad_form -name $form_id \
    -export [list return_url {task_id $task(task_id)}] \
    -action "/acs-workflow/task" \
    -has_edit 1

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
    set attributes.${attribute_name} $value
    switch $datatype {
        boolean {
            ad_form -extend -name $form_id -form {
                {attributes.${attribute_name}:text(select) {label "$pretty_name"} {options {{"[_ intranet-core.Yes]" "t"} {"[_ intranet-core.No]" "f"}}}}
            }          
        }
        default {
            ad_form -extend -name $form_id -form {
                {attributes.${attribute_name}:text(text) {label "$pretty_name"} {value "$value"}}            
            }
        }
    }
}

set header_html [im_box_header $task(task_name)]

ds_comment "[array get task]"
ad_form -extend -name $form_id -form {
    {msg:text(textarea),optional {label "[_ acs-workflow.Comment]"} {html {cols 20 rows 4}}}
    {action.finish:text(submit) {label "[_ acs-workflow.Task_done]"}}

    } -on_submit {
        form set_error $form_id msg "ERROR"
    }

ad_return_template

