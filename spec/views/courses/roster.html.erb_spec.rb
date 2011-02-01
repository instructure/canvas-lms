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

# <% content_for :page_title do %><%= @context.name %><% end %>

# <% content_for :primary_nav do %>
  # <%= render :partial => 'shared/context/primary_nav', :locals => {:view => 'communication'} %>
# <% end %>

# <% content_for :secondary_nav do %>
  # <%= render :partial => 'shared/context/communication_secondary_nav', :locals => {:view => 'roster'} %>
# <% end %>

# <% content_for :page_header do %>
  # <h1><%= @context.name %></h1>
# <% end %>

# <% content_for :page_subhead do %>
  # <h2>Course Details</h2>
# <% end %>

# <% content_for :right_side do %>
  # <a href="#" class="message_link"><%= image_tag "email.png" %> Send a Message</a>
  # <div class="message_options" style="width: auto; margin: 10px; border: 1px solid #888; -moz-border-radius: 5px; padding: 5px 10px; position: relative; display: none;">
    # <a href="#" class="close_message_link" style="position: absolute; top: 0px; right: 5px;">&#215;</a>
    # <b>Send a Message</b>
    # <div style="padding-left: 10px; line-height: 1.7em;">
      # <div class="message_selected_recipients_link" style="display: none; margin-bottom: 15px; font-weight: bold;">
        # <a href="#" class="message_selected_recipients_link" style="display: none;"><%= image_tag "email.png" %> Message Selected Recipients</a>
      # </div>
      # <a href="#" class="message_all_students_link"><%= image_tag "email.png" %> Message All Students</a><br/>
      # <a href="#" class="message_all_teachers_link"><%= image_tag "email.png" %> Message Teachers &amp; TA's</a><br/>
    # </div>
  # </div>
# <% end %>

# <script type="text/javascript">
# $(document).ready(function() {
  # $(".message_link").click(function(event) {
    # event.preventDefault();
    # $(this).hide();
    # $(".message_options").show();
    # $("#select_recipients .selection_help").show();
    # $("#select_recipients .selector").show();
  # });
  # $(".recipient_name").click(function(event) {
    # if($(".message_options").css('display') != 'none') {
      # event.preventDefault();
      # var $obj = $(this).parents(".recipient").find(".recipient_selected");
      # $obj.attr('checked', !$obj.attr('checked')).change();
    # }
  # });
  # $(".close_message_link").click(function(event) {
    # event.preventDefault();
    # $(this).parents(".message_options").hide();
    # $(".message_link").show();
    # $("#select_recipients .selector").hide();
    # $("#select_recipients .selection_help").hide();
  # });
  # $(".recipient_selected").change(function(event) {
    # var selected = false;
    # $(".recipient_selected").each(function() {
      # if($(this).attr('checked')) {
        # selected = true;
        # return false;
      # }
    # });
    # $(".message_selected_recipients_link").showIf(selected);
  # }).change();
  # $(".select_all_recipients_link").click(function(event) {
    # event.preventDefault();
    # $(this).parents(".recipients").find(".recipient_selected").attr('checked', true).change();
  # });
  # $(".unselect_all_recipients_link").click(function(event) {
    # event.preventDefault();
    # $(this).parents(".recipients").find(".recipient_selected").attr('checked', false).change();
  # });
  # $(".message_all_students_link,.message_all_teachers_link,.message_selected_recipients_link").click(function(event) {
    # event.preventDefault();
    # if($("#select_recipients").css('display') == 'none') { return; }
    # var includeAllStudents = $(this).hasClass('message_all_students_link');
    # var includeAllTeachers = $(this).hasClass('message_all_teachers_link');
    # var recipients = [];
    # $("#select_recipients .student_recipients .recipient_selected").each(function() {
      # if(includeAllStudents || $(this).attr('checked')) {
        # recipients.push($(this).parents(".recipient").find(".recipient_name").text());
      # }
    # });
    # $("#select_recipients .teacher_recipients .recipient_selected").each(function() {
      # if(includeAllTeachers || $(this).attr('checked')) {
        # recipients.push($(this).parents(".recipient").find(".recipient_name").text());
      # }
    # });
    # if(recipients.length > 0) {
      # $("#select_recipients").hide();
      # $("#send_message_form .recipients").text(recipients.join(", "));
      # $("#send_message_form").show();
    # }
  # });
  # $("#send_message_form input[value='Cancel']").click(function() {
    # $("#send_message_form").hide();
    # $("#select_recipients").show();
  # });
# });
# </script>
# <table id="select_recipients" style="width: 100%;">
  # <tr>
    # <td style="width: 50%; vertical-align: top;" class="recipients student_recipients">
      # <h2>Students</h2>
      # <div style="font-size: 0.8em; padding-left: 20px; display: none;" class="selection_help">
      # <a href="#" class="select_all_recipients_link">Select All</a> | <a href="#" class="unselect_all_recipients_link">Unselect All</a>
      # </div>
      # <table>
      # <% @students.each do |student| %>
        # <tr class="recipient">
          # <td style="display: none;" class="selector"><input type="checkbox" class="recipient_selected" id="recipient_<%= student.id %>"/></td>
          # <td><a href="<%= context_url(@context, :user_url, student.id) %>" class="recipient_name"><%= student.name %></a></td>
        # </tr>
      # <% end %>
      # </table>
    # </td>
    # <td style="vertical-align: top;" class="recipients teacher_recipients">
      # <h2>Teachers &amp; TA's</h2>
      # <div style="font-size: 0.8em; padding-left: 20px; display: none;" class="selection_help">
      # <a href="#" class="select_all_recipients_link">Select All</a> | <a href="#" class="unselect_all_recipients_link">Unselect All</a>
      # </div>
      # <table>
      # <% @teachers.each do |teacher| %>
        # <tr class="recipient">
          # <td style="display: none;" class="selector"><input type="checkbox" class="recipient_selected" id="recipient_<%= teacher.id %>"/></td>
          # <td><a href="<%= context_url(@context, :user_url, teacher.id) %>" class="recipient_name"><%= teacher.name %></a></td>
        # </tr>
      # <% end %>
      # </table>
    # </td>
  # </tr>
# </table>
# <form style="display: none;" id="send_message_form" action=".">
# <table class="formtable" style="width: 100%;">
  # <tr>
    # <td colspan="2"><h2>Send a Message</h2></td>
  # </tr>
  # <tr>
    # <td style="vertical-align: top; font-weight: bold;">Recipients:</td>
    # <td class="recipients" style="font-size: 0.8em; text-align: left;"></td>
  # </tr>
  # <tr>
    # <td colspan="2" style="text-align: center;">
      # <textarea style="width: 90%; height: 200px;"></textarea>
    # </td>
  # </tr>
  # <% if can_do(@context.announcements.new, @current_user, :create) %>
  # <tr>
    # <td colspan="2">
      # <input type="checkbox" id="also_announcement"/>
      # <label for="also_announcement">Also post as an announcement</label>
    # </td>
  # </tr>
  # <% end %>
  # <tr>
    # <td colspan="2" style="text-align: right;">
      # <input type="submit" value="Send Message"/>
      # <input type="button" value="Cancel"/>
    # </td>
  # </tr>
# </table>
# </form>