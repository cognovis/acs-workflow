ad_library {
 Initialization code for the acs-workflow package 
 (to run once on server startup).

 @cvs-id $Id$
}

# normal rhythm: Every 15 minutes
# ad_schedule_proc -thread t 900 wf_sweep_time_events


set interval [parameter::get \
		       -package_id [apm_package_id_from_key "acs-workflow"] \
		       -parameter SweepTimeEventsInterval -default 303]


# for debugging: every 1 minute
ad_schedule_proc -thread t $interval wf_sweep_time_events

ad_proc -public -callback workflow_task_before_update {
    {-task_id:required}
    {-action:required}
    {-msg ""}
    {-attributes ""}
} {
    This callback allows you to execute action before the action is run in a workflow task 

@param task_id ID of the Task being executed
@param action The action which is being performed. "finish" is a special action, finishing this task for the user
@param msg Message provided as comment by the user
@param attributes Returns a list of {key value} pairs from the task.
} -

ad_proc -public -callback workflow_task_after_update {
    {-task_id:required}
    {-action:required}
    {-msg ""}
    {-attributes ""}
} {
    This callback allows you to execute action before the action is run in a workflow task 

@param task_id ID of the Task being executed
@param action The action which is being performed. "finish" is a special action, finishing this task for the user
@param msg Message provided as comment by the user
@param attributes Returns a list of {key value} pairs from the task.
} -


ad_proc -public -callback workflow_task_on_submit {
    {-task_id:required}
    {-form_id:required}
    {-workflow_key:required}
} {
    This callback allows you to execute action before the action is submitted

} -