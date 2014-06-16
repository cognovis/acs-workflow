
<!-- ----------------------------------------------------------------------
     "Approval Tasks" - An ugly but useful logic:

     Shows the action panels for "started" transitions already 
     while the transition is still in status "enabed". 
     This option saves users the click to "start task" for 
     approval type of tasks. These tasks are normally very short
     (just approve or not...), so the usual start-task logic
     doesn't make much sense.
---------------------------------------------------------------------- -->

<if @task.state@ eq enabled and @approval_task_p@ ne 1>
    <if @task.this_user_is_assigned_p@ eq 1>
        <form action="@task.action_url@" method="post">
            @export_form_vars;noquote@
            <table>
                <tr><th align="right">#acs-workflow.Action_1#</th>
                    <td><input type="submit" name="action.start" value="Start task" /></td>
                </tr>
            </table>
        </form>

        <if @task_assigned_users:rowcount@ gt 1>
            <h4><%=[lang::message::lookup "" Other_Assignees "Other assignees:"]%></h4>
            <ul>
                <multiple name="task_assigned_users">
                    <if @task_assigned_users.user_id@ ne @user_id@>
                        <li><a href="/shared/community-member?user_id=@task_assigned_users.user_id@">@task_assigned_users.name@</a></li>
                    </if>
                </multiple>
	        </ul>
        </if>
        <else>
            <%=[lang::message::lookup "" acs-workflow.You_Are_The_Only_Person "You're the only person assigned to this task."]%> 
        </else>
    </if>
    <else>
	    <%=[lang::message::lookup "" acs-workflow.Task_Has_Not_Been_Started_Yet "This task has not been started yet."]%>	        
        <if @task_assigned_users:rowcount@ gt 0>
            <h4><%=[lang::message::lookup "" intranet-workflow.Currrent_assignees "Current Assignees"]%></h4>
            <ul>
                <multiple name="task_assigned_users">
                    <li><a href="/shared/community-member?user_id=@task_assigned_users.user_id@">@task_assigned_users.name@</a></li>
                </multiple>
	        </ul>
        </if>
    </else>
    <p>

    <if @reassign_p@ >
    	<ul class="admin_links">
            <if @task.this_user_is_assigned_p@ ne 1>
        	    <li><a href="@task.assign_yourself_url@"><%=[lang::message::lookup "" acs-workflow.Assign_Yourself "assign yourself"]%></a></li>
            </if>
	        <li><a href="@task.manage_assignments_url@"><%=[lang::message::lookup "" acs-workflow.Reassign "reassign"]%></a></li>
        </ul>
    </if>

    <if @task.deadline_pretty@ not nil>
        <p>
        <if @task.days_till_deadline@ lt 1>
            <font color="red"><strong>#acs-workflow.lt_Deadline_is_taskdeadl#</strong></font>
        </if>
        <else>
            #acs-workflow.lt_Deadline_is_taskdeadl#
        </else>
    </if>
</if>

<if @task.state@ eq finished>
    <if @task.this_user_is_assigned_p@ eq 1>
        #acs-workflow.lt_You_finished_this_tas#
	    <p>
        <a href="@return_url@">#acs-workflow.Go_back#</a>
    </if>
    <else>
        #acs-workflow.lt_This_task_was_complet# <a href="/shared/community-member?user_id=@task.holding_user@">@task.holding_user_name@</a>
        #acs-workflow.lt_at_taskfinished_date_#
    </else>
</if>
<else>
    <if @task.state@ eq started or @approval_task_p@>
        <if @task.this_user_is_assigned_p@ eq 1>
            @header_html;noquote@
            <formtemplate id="@form_id;noquote@"></formtemplate>
            <%= [im_box_footer] %>
        </if>
        <else>
            <table>
                <tr><th>#acs-workflow.Held_by#</th><td><a href="/shared/community-member?user_id=@task.holding_user@">@task.holding_user_name@</a></td></tr>
                <tr><th>#acs-workflow.Since#</th><td>@task.started_date_pretty@</td></tr>
                <tr><th>#acs-workflow.Timeout#</th><td>@task.hold_timeout_pretty@</td></tr>
            </table>
        </else>
    </if>
</else>

<if @task.state@ eq canceled>
    <if @task.this_user_is_assigned_p@ eq 1>
        #acs-workflow.lt_You_canceled_this_tas#
        <p>
        <a href="@return_url@">#acs-workflow.Go_back#</a>
    </if>
    <else>
        #acs-workflow.lt_This_task_has_been_ca# <a href="/shared/community-member?user_id=@task.holding_user@">@task.holding_user_name@</a>
        #acs-workflow.lt_on_taskcanceled_date_#
    </else>
</if>

