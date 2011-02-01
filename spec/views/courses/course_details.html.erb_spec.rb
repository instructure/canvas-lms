#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

# <% content_for :page_title do %>Course Details<% end %>

# <% content_for :page_header do %>
  # <h1>Course Details</h1>
# <% end %>

# <% content_for :page_subhead do %>
  # <h2><%= @context.name %></h2>
# <% end %>

# <% content_for :primary_nav do %>
  # <%= render :partial => 'shared/context/primary_nav', :locals => {:view => 'home'} %>
# <% end %>

# <% content_for :secondary_nav do %>
  # <%= render :partial => 'shared/context/context_secondary_nav', :locals => {:view => 'details'}%>
# <% end %>

# <% students = @context.detailed_enrollments.select{|e| e.type == 'StudentEnrollment'}.sort_by{|e| e.user.sortable_name rescue "a" } %>
# <% teachers = @context.detailed_enrollments.select{|e| e.type == 'TeacherEnrollment'}.sort_by{|e| e.user.sortable_name rescue "a" } %>
# <% tas = @context.detailed_enrollments.select{|e| e.type == 'TaEnrollment'}.sort_by{|e| e.user.sortable_name rescue "a" } %>
# <% observers = @context.detailed_enrollments.select{|e| e.type == 'ObserverEnrollment'}.sort_by{|e| e.user.sortable_name rescue "a" } %>
# <% content_for :right_side do %>
  # <a href="#" class="edit_course_link"><%= image_tag "edit.png" %> Edit Course Details</a><br/>
  # <a href="#" class="add_users_link"><%= image_tag "add.png" %> Add Users</a>
  # <table class="summary" style="margin-top: 20px;">
    # <thead>
      # <tr>
        # <th colspan="2">Current Users</th>
      # </tr>
    # </thead>
      # <tr>
        # <td>Students:</td>
        # <td class="student_count"><%= students.empty? ? "None" : students.length %></td>
      # </tr>
      # <tr>
        # <td>Teachers:</td>
        # <td class="teacher_count"><%= teachers.empty? ? "None" : teachers.length %></td>
      # </tr>
      # <tr>
        # <td>TA's:</td>
        # <td class="ta_count"><%= tas.empty? ? "None" : tas.length %></td>
      # </tr>
      # <tr>
        # <td>Observers:</td>
        # <td class="ta_count"><%= observers.empty? ? "None" : observers.length %></td>
      # </tr>
  # </table>
# <% end %>

# <script>
# var enrollments = {
  # updateCounts: function() {
    # var students = $(".student_enrollments .user:visible").length;
    # var teachers = $(".teacher_enrollments .user:visible").length;
    # var tas = $(".ta_enrollments .user:visible").length;
    # $(".student_count").text(students);
    # $(".teacher_count").text(teachers);
    # $(".ta_count").text(tas);
  # }
# };
# $(document).ready(function() {
  # $(document).fragmentChange(function(event, hash) {
    # if(hash == "#add_students") {
      # $(".add_users_link").click();
      # $("#enroll_users_form select[name='enrollment_type']").val("StudentEnrollment");
    # } else if(hash == "#add_tas") {
      # $(".add_users_link").click();
      # $("#enroll_users_form select[name='enrollment_type']").val("TaEnrollment");
    # }
  # });
  # $(".edit_course_link").click(function(event) {
    # event.preventDefault();
    # $("#course_form").addClass('editing')
      # .find(":text:first").focus().select();
  # });
# //  $(".date_entry").datepicker();
  # $("#course_form").find(".cancel_button").click(function() {
    # $("#course_form").removeClass('editing');
    # $(".course_form_more_options").hide();
  # }).end().find(":text:not(.date_entry)").keycodes('esc', function() {
    # $(this).parents("#course_form").find(".cancel_button:first").click();
  # });
  # $("#course_form").formSubmit({
    # processData: function(data) {
      # if(data['course[start_at]']) {
        # data['course[start_at]'] += " 12:00am";
      # }
      # if(data['course[conclude_at]']) {
        # data['course[conclude_at]'] += " 11:55pm";
      # }
      # return data;
    # },
    # beforeSubmit: function() {
      # $(this).loadingImage().removeClass('editing');
      # $(".course_form_more_options").hide();
    # },
    # success: function(data) {
      # $(this).loadingImage('remove');
      # var course = data.course;
      # course.start_at = $.parseFromISO(course.start_at).datetime_formatted;
      # course.conclude_at = $.parseFromISO(course.conclude_at).datetime_formatted;
      # $("#course_form").fillTemplateData({data: course});
    # }
  # });
  # $("#enroll_users_form").formSubmit({
    # beforeSubmit: function() {
      # $(this).loadingImage();
    # },
    # success: function(data) {
      # $(this).loadingImage('remove');
      # for(var idx in data) {
        # var obj = data[idx];
        # for(var key in obj) {
          # var enrollment = obj[key];
          # var $list = $(".user_list." + key + "s");
          # $list.find(".none").remove();
          # var $enrollment = $("#enrollment_blank").clone(true).attr('id', '').show();
          # enrollment.invitation_sent_at = "Just Now";
          # try {
            # enrollment.name = enrollment.user.name;
            # enrollment.pseudonym_id = enrollment.user.pseudonym.id;
            # enrollment.communication_channel_id = enrollment.user.pseudonym.communication_channel.id;
          # } catch(e) {}
          # $enrollment.fillTemplateData({
            # textValues: ['name'],
            # id: 'enrollment_' + enrollment.id,
            # hrefValues: ['id', 'pseudonym_id', 'communication_channel_id'],
            # data: enrollment
          # })
          # $enrollment.addClass('pending');
          # var $before = null;
          # $list.find(".user").each(function() {
            # var name = $(this).getTemplateData({textValues: ['name']}).name;
            # if(name && name.toLowerCase() > enrollment.name.toLowerCase()) {
              # $before = $(this);
              # return false;
            # }
          # })
          # if($before) {
            # $before.before($enrollment);
          # } else {
            # $list.append($enrollment);
          # }
          # $enrollment.animate({'backgroundColor': '#FFEE88'}, 1000).animate({'display': 'block'}, 2000).animate({'backgroundColor': '#FFFFFF'}, 2000, function() {
            # $(this).css('backgroundColor', '');
          # });
          # enrollments.updateCounts();
        # }
      # }
    # }
  # }).hide();
  # $(".add_users_link").click(function(event) {
    # event.preventDefault();
    # $("#enroll_users_form").show();
    # $("html,body").scrollTo($("#enroll_users_form"));
    # $("#enroll_users_form").find("textarea").focus().select();
  # });
  # $("#enroll_users_form .cancel_button").click(function() {
    # $("#enroll_users_form").hide();
  # });
  # $(".unenroll_user_link").click(function(event) {
    # event.preventDefault();
    # event.stopPropagation();
    # $(this).parents(".user").confirmDelete({
      # message: "Are you sure you want to remove this user?",
      # url: $(this).attr('href'),
      # success: function() {
        # $(this).fadeOut(function() {
          # enrollments.updateCounts();
        # });
      # }
    # })
  # });
  # $(".course_info").attr('title', 'Click to Edit').click(function() {
    # $(".edit_course_link:first").click();
    # var $obj = $(this).parents("td").find(".course_form");
    # if($obj.length) {
      # $obj.focus().select();
    # }
  # })
  # $(".course_form_more_options_link").click(function(event) {
    # event.preventDefault();
    # $(".course_form_more_options").slideToggle();
  # });
  # $(".user_list").delegate('mouseover', '.user', function(event) {
    # var title = $(this).attr('title');
    # var pending_message = "This user has not yet accepted their invitataion";
    # if(title != pending_message) {
      # $(this).data('real_title', title);
    # }
    # if($(this).hasClass('pending')) {
      # $(this).attr('title', pending_message)
        # .css('cursor', 'pointer');
    # } else {
      # $(this).attr('title', $(this).data('real_title') || "User")
        # .css('cursor', '');
    # }
  # });
  # $("#enrollment_dialog .cancel_button").click(function() {
    # $("#enrollment_dialog").dialog('close');
  # });
  # $(".user_list").delegate('click', '.user', function(event) {
    # if($(this).hasClass('pending')) {
      # var data = $(this).getTemplateData({textValues: ['name', 'invitation_sent_at']});
      # $("#enrollment_dialog .re_send_invitation_link").attr('href', $(this).find(".re_send_confirmation_url").attr('href'));
      # $("#enrollment_dialog").data('user', $(this));
      # data.re_send_invitation_link = "Re-Send Invitation";
      # $("#enrollment_dialog").fillTemplateData({
        # data: data
      # });
      # $("#enrollment_dialog").dialog('close').dialog({
        # autoOpen: false,
        # title: "Enrollment Details"
      # }).dialog('open');
    # }
  # });
  # $("#enrollment_dialog .re_send_invitation_link").click(function(event) {
    # event.preventDefault();
    # var $link = $(this);
    # $link.text("Re-Sending Invitation...");
    # var url = $link.attr('href');
    # $.ajaxJSON(url, 'POST', {}, function(data) {
      # $("#enrollment_dialog").fillTemplateData({data: {invitation_sent_at: "Just Now"}});
      # $link.text("Invitation Sent!");
      # var $user = $("#enrollment_dialog").data('user');
      # if($user) {
        # $user.fillTemplateData({data: {invitation_sent_at: "Just Now"}});
      # }
    # }, function(data) {
      # $link.text("Invitation Failed.  Please try again.");
    # });
  # });
  # $(".date_entry").date_field();
  # $.scrollSidebar();
# })
# </script>
# <h2>Course Details</h2>
# <% form_for @context, :html => {:id => "course_form"} do |f| %>
# <table class="formtable" style="margin-left: 20px;">
  # <tr>
    # <td><%= f.label :name, "Name:" %></td>
    # <td>
      # <%= f.text_field :name, :class => "course_form" %>
      # <span class="course_info"><%= @context.name %></span>
    # </td>
  # </tr>
  # <tr>
    # <td><%= f.label :start_at, "Starts:" %></td>
    # <td>
      # <span class="course_form"><%= f.text_field :start_at, :class => "date_entry" %></span>
      # <span class="course_info start_at"><%= datetime_string(@context.start_at) || "No Date Set" %></span>
    # </td>
  # </tr><tr>
    # <td><%= f.label :conclude_at, "Ends:" %></td>
    # <td>
      # <span class="course_form"><%= f.text_field :conclude_at, :class => "date_entry" %></span>
      # <span class="course_info conclude_at"><%= datetime_string(@context.conclude_at) || "No Date Set" %></span>
    # </td>
  # </tr><tr>
    # <td style="vertical-align: top;">Visibility:</td>
    # <td>
      # <span class="course_form">
        # <%= f.check_box :is_public %>
        # <%= f.label :is_public, "This Course is Public" %>
        # <span style='font-size: 0.8em; padding-left: 5px;'>(student data will remain private)</span>      
      # </span>
      # <span class="course_info is_public">Private</span?
    # </td>
  # </tr><tr>
    # <td></td>
    # <td>
      # <a href="#" class="course_form course_form_more_options_link">more options</a>
      # <div class="course_form_more_options" style="display: none; padding-left: 20px;">
        # <%= f.check_box :publish_grades_immediately %>
        # <%= f.label :publish_grades_immediately, "Publish Grades Immediately" %><br/>
        # <%= f.check_box :allow_student_wiki_edits %>
        # <%= f.label :allow_student_wiki_edits, "Let Students edit Wiki Pages" %><br/>
        # <%= f.check_box :allow_student_assignment_edits %>
        # <%= f.label :allow_student_assignment_edits, "Let Students edit Assignment Descriptions" %><br/>
      # </div>
    # </td>
  # </tr><tr>
    # <td colspan="2" style="text-align: right;">
      # <span class="course_form">
        # <input type="submit" value="Update Course Details"/>
        # <input type="button" value="Cancel" class="cancel_button">
      # </span>
    # </td>
  # </tr>
# </table>
# <% end %>
# <% content_for :stylesheets do %>
# <style>
# #course_form .course_form {
  # display: none;
# }
# #course_form.editing .course_form {
  # display: inline;
# }
# #course_form.editing .course_info {
  # display: none;
# }
# #course_form .date_entry {
  # width: 100px;
# }
# ul.user_list {
  # list-style: none;
  # padding-left: 0px;
  # margin-top: 0px;
  # max-height: 300px;
  # overflow: auto;
# }
# ul.user_list li.user {
  # padding-left: 10px;
  # color: #444;
  # line-height: 1.5em;
  # -moz-border-radius: 5px;
# }
# ul.user_list li.user:hover {
  # background-color: #eee;
# }
# ul.user_list li.user .links {
  # float: right;
  # padding-right: 20px;
  # visibility: hidden;
# }
# ul.user_list li.user:hover .links {
  # float: right;
  # padding-right: 20px;
  # visibility: visible;
# }
# ul.user_list li.user.pending {
  # color: #888;
  # font-style: italic;
# }
# </style>
# <% end %>
# <h2 style="margin-top: 10px;">Current Users</h2>
# <table style="width: 100%;">
  # <tr>
    # <td style="vertical-align: top; padding-right: 30px;">
      # <h3>Students</h3>
      # <ul class="user_list student_enrollments">
        # <% if students.empty? %>
          # <li class="none">No Students Enrolled</li>
        # <% else %>
          # <% students.each do |e| %>
          # <li class="user <%= "pending" if e.pending? %>" title="<%= e.user.name %>: <%= e.user.email %>">
            # <span class="links">
              # <a href="<%= context_url(@context, :controller => :courses, :action => :unenroll_user, :id => e.id) %>" class="unenroll_user_link" title="Remove User from Course">&#215;</a>
              # <a href="<%= re_send_confirmation_url(e.user.pseudonym.id, e.user.pseudonym.communication_channel.id, :enrollment_id => e.id) rescue "#" %>" class="re_send_confirmation_url" style="display: none;">&nbsp;</a>
            # </span>
            # <span class="name"><%= e.user.last_name_first %></span>
            # <span class="invitation_sent_at" style="display: none;"><%= datetime_string(e.updated_at) || "&nbsp;" %></span>
            # <span class="clear"></span>
          # </li>
          # <% end %>
        # <% end %>
        # <li style="display: none;" class="user" id="enrollment_blank">
          # <span class="links">
            # <a href="<%= context_url(@context, :controller => :courses, :action => :unenroll_user, :id => "{{ id }}") %>" class="unenroll_user_link" title="Remove User from Course">&#215;</a>
            # <a href="<%= re_send_confirmation_url("{{ pseudonym_id }}", "{{ communication_channel_id }}", :enrollment_id => "{{ id }}") rescue "#" %>" class="re_send_confirmation_url" style="display: none;">&nbsp;</a>
          # </span>
          # <span class="name"></span>
          # <span class="invitation_sent_at" style="display: none;">&nbsp;</span>
          # <span class="clear"></span>
        # </li>
      # </ul>
      # <h3>Observers</h3>
      # <ul class="user_list observer_enrollments">
        # <% if observers.empty? %>
          # <li class="none">No Observers Enrolled</li>
        # <% else %>
          # <% observers.each do |e| %>
          # <li class="user <%= "pending" if e.pending? %>" title="<%= e.user.name %>: <%= e.user.email %>">
            # <span class="links">
              # <a href="<%= context_url(@context, :controller => :courses, :action => :unenroll_user, :id => e.id) %>" class="unenroll_user_link" title="Remove User from Course">&#215;</a>
              # <a href="<%= re_send_confirmation_url(e.user.pseudonym.id, e.user.pseudonym.communication_channel.id, :enrollment_id => e.id) rescue "#" %>" class="re_send_confirmation_url" style="display: none;">&nbsp;</a>
            # </span>
            # <span class="name"><%= e.user.last_name_first %></span>
            # <span class="invitation_sent_at" style="display: none;"><%= datetime_string(e.updated_at) || "&nbsp;" %></span>
            # <span class="clear"></span>
          # </li>
          # <% end %>
        # <% end %>
      # </ul>
    # </td><td style="vertical-align: top;">
      # <h3>Teachers</h3>
      # <ul class="user_list teacher_enrollments">
        # <% if teachers.empty? %>
          # <li class="none">No Teachers Assigned</li>
        # <% else %>
          # <% teachers.each do |e| %>
          # <li class="user <%= "pending" if e.pending? %>" title="<%= e.user.name %>: <%= e.user.email %>">
            # <span class="links">
              # <a href="<%= context_url(@context, :controller => :courses, :action => :unenroll_user, :id => e.id) %>" class="unenroll_user_link" title="Remove User from Course">&#215;</a>
              # <a href="<%= re_send_confirmation_url(e.user.pseudonym.id, e.user.pseudonym.communication_channel.id, :enrollment_id => e.id) rescue "#" %>" class="re_send_confirmation_url" style="display: none;">&nbsp;</a>
            # </span>
            # <span class="name"><%= e.user.last_name_first %></span>
            # <span class="invitation_sent_at" style="display: none;"><%= datetime_string(e.updated_at) || "&nbsp;" %></span>
            # <span class="clear"></span>
          # </li>
          # <% end %>
        # <% end %>
      # </ul>
      # <h3>TA's</h3>
      # <ul class="user_list ta_enrollments">
        # <% if tas.empty? %>
          # <li class="none">No TA's Assigned</li>
        # <% else %>
          # <% tas.each do |e| %>
          # <li class="user <%= "pending" if e.pending? %>" title="<%= e.user.name %>: <%= e.user.email %>">
            # <span class="links">
              # <a href="<%= context_url(@context, :controller => :courses, :action => :unenroll_user, :id => e.id) %>" class="unenroll_user_link" title="Remove User from Course">&#215;</a>
              # <a href="<%= re_send_confirmation_url(e.user.pseudonym.id, e.user.pseudonym.communication_channel.id, :enrollment_id => e.id) rescue "#" %>" class="re_send_confirmation_url" style="display: none;">&nbsp;</a>
            # </span>
            # <span class="name"><%= e.user.last_name_first %></span>
            # <span class="invitation_sent_at" style="display: none;"><%= datetime_string(e.updated_at) || "&nbsp;" %></span>
            # <span class="clear"></span>
          # </li>
          # <% end %>
        # <% end %>
      # </ul>
    # </td>
  # </tr>
# </table>
# <% form_tag course_enroll_users_url(@context), {:id => "enroll_users_form", :style => "display: none;"} do |form| %>
# <div>
  # Add More 
  # <select name="enrollment_type">
    # <option value="StudentEnrollment">Students</option>
    # <option value="TeacherEnrollment">Teachers</option>
    # <option value="TaEnrollment">TA's</option>
    # <option value="ObserverEnrollment">Observers</option>
  # </select>
# </div>
# <div style="margin-top: 5px;">
  # <span style="font-size: 0.8em;">Copy and paste a list of email addresses to add
    # users to this course.</span>
  # <textarea name="user_emails" style="width: 100%; height: 100px; margin-top: 5px;"></textarea>
# </div>
# <div style="text-align: right;">
  # <input type="submit" value="Add Users"/>
  # <input type="button" value="Cancel" class="cancel_button"/>
# </div>
# <% end %>
# <div style="text-align: center; display: none;" id="enrollment_dialog">
  # <span class="name">User</span><br/> hasn't yet accepted the invitation to join the course.  The invitation was sent:
  # <div style="margin: 10px;" class="invitation_sent_at">Just Now</div>
  # <div style="margin: 15px 10px; font-weight: bold;">
    # <a href="#" class="re_send_invitation_link">Re-Send Invitation</a>
  # </div>
  # <div style="text-align: right;">
    # <input type="button" value="Ok, Thanks" class="cancel_button"/>
  # </div>
# </div>