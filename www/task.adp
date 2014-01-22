<master>
<property name=title>@task.task_name;noquote@</property>
<property name="context">@context;noquote@</property>

    <div class="component">
        <table width="100%">
		    <tr>
		        <td>
                    <div class="component_header_rounded" >
                        <div class="component_header">
                            <div class="component_title"><%=[lang::message::lookup "" intranet-workflow.Task "Task"]%>: @task.task_name@</div>
                            <div class="component_icons"></div>
                        </div>
                    </div>
                </td>
            </tr>
            <tr>
                <td>
                    <div class="component_body">
                        <table width="100%">
                            <tr>
                                <multiple name="panels">
						            <td valign="top">
	    							    <include src="@panels.template_url;noquote@" &="task" &="task_attributes_to_set" &="task_assigned_users" &="task_roles_to_assign" &="export_form_vars" &="return_url" \>
                                    </td>
                                </multiple>
                        
                                <if @show_action_form_p@ eq 1>
                                    <td valign="top">
                                        <if @task.state@ eq enabled and @approval_task_p@ ne 1>
                                            <if @task.this_user_is_assigned_p@ eq 1>
                                                @header_html;noquote@
                                                <formtemplate id="@form_id;noquote@"></formtemplate></font>
                                                <%= [im_box_footer] %>
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
                                                <p \>
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
                                                <formtemplate id="@form_id;noquote@"></formtemplate></font>
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
                                </td>
                            </if>
                        </tr>
                    </table>
                </div>	
            </td>
        </tr>
    </table>
</div>
<p>

<if @extreme_p@ eq 1> 

        <div class="component">
                <table width="100%">
                <tr>
                <td>
                <div class="component_header_rounded" >
                        <div class="component_header">
                                <div class="component_title"><%=[lang::message::lookup "" intranet-workflow.Admin_Actions "Admin actions"]%></div>
                                      <div class="component_icons"></div>
                                </div>
                        </div>
                </td>
                </tr>
                <tr>
                <td>
                        <div class="component_body">
				<table class="panel" width="100%">
					<tr><td>
						<ul class="admin_links">
						<multiple name="extreme_actions">
						    <li><a href="@extreme_actions.url@">@extreme_actions.title@</a></li>
						</multiple>
						</ul>
					</td></tr>
				</table>
                         </div>
                </td></tr>
                </table>
        </div>
</if>

<p>

<include src="journal" case_id="@case_id;noquote@">

</master>
