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

# <% show_settings ||= false %>
# function instructureEmbedShowSettings(option) {
  # var content = document.getElementById('instructure_embedded_page_content');
  # var settings = document.getElementById('instructure_embedded_page_display_settings');
  # var student_view = document.getElementById('instructure_embedded_page_student_view');
  # if(option == "hide") {
    # content.style.display = "block";
    # settings.style.display = "none";
    # student_view.style.display = "none";
  # } else {
    # content.style.display = "none";
    # settings.style.display = "block";
    # student_view.style.display = "none";
  # } 
# }
# function instructureEmbedShowStudentView(option) {
  # var content = document.getElementById('instructure_embedded_page_content');
  # var settings = document.getElementById('instructure_embedded_page_display_settings');
  # var student_view = document.getElementById('instructure_embedded_page_student_view');
  # if(option == "hide") {
    # content.style.display = "block";
    # settings.style.display = "none";
    # student_view.style.display = "none";
  # } else {
    # content.style.display = "none";
    # settings.style.display = "none";
    # student_view.style.display = "block";
  # } 
# }
# function instructureEmbedOptionUpdated(obj) {
  # var assignment = document.getElementById('instructure_embedded_form_assignment');
  # var assignment_choice = document.getElementById('instructure_embedded_form_assignment_choice');
  # if(obj.options[obj.selectedIndex].value == "assignment") {
    # assignment.style.display = "block";
    # if(assignment_choice.selectedIndex == assignment_choice.options.length - 1) {
      # assignment_choice.selectedIndex = 0;
    # }
  # } else {
    # assignment.style.display = "none";
  # }
# }
# function instructureEmbedAssignmentOptionUpdated(obj) {
  # var new_assignment = document.getElementById('instructure_embedded_form_new_assignment');
  # // instead, show a popup window with the option to set up information
# }
# document.write('\
# <div id="instructure_embedded_page_display_settings" style="margin-top: 30px; <%= @page.page_type == 'nothing' ? "" : "display: none;" %>">\
# <img src="http://localhost:3000/images/logo_small.png" style="float: left;"/>\
# <div style="float: left;">\
  # <h2><%= @context.name %></h2>\
  # <% if @page.page_type == "nothing" %>\
  # Right now this page is set to show nothing.  Want to change that?\
  # <% elsif @page.page_type == "gradebook" %>\
  # Right now this page will show course grades.  You can change that if you like.\
  # <% elsif @page.page_type == "assignment" %>\
  # This page is linked to <i>"<%= @assignment.title rescue "" %>"</i>.  Want something else?\
  # <% end %>\
  # <div style="text-align: left; margin-top: 10px;">\
    # <% form_for :embedded_course_page, :url => { :controller => :gradebooks, :course_id => @context.id, :action => :update_embedded_page, :host => 'localhost:3000' } do |form| %>\
    # <%= form.hidden_field :url, :value => @page.url %>\
    # <div style="margin: 5px 0px;">\
      # <select name="embedded_course_page[page_type]" onchange="instructureEmbedOptionUpdated(this);" id="instructure_embedded_form_page_display_choice">\
        # <option selected value="nothing">Don\'t Show Anything</option>\
        # <option value="gradebook">Show Grades / Gradebook</option>\
        # <option value="assignment">This is an Assignment</option>\
      # </select>\
    # </div>\
    # <div id="instructure_embedded_form_assignment" style="display: none; margin-left: 20px;">\
      # <div style="margin: 5px 0px;">\
        # Which Assignment? \
        # <select name="assignment_id" onchange="instructureEmbedAssignmentOptionUpdated(this);" id="instructure_embedded_form_assignment_choice">\
          # <% @assignments.each do |assignment| %>\
          # <option value="<%= assignment.id %>"><%= assignment.title %></option>\
          # <% end %>\
          # <option value="new">New Assignment</option>\
        # </select>\
      # </div>\
    # </div>\
    # <div style="margin: px 0px;">\
      # <input type="submit" value="Update"/>\
      # <% if !show_settings %>\
      # <input type="button" value="Cancel" onclick="instructureEmbedShowSettings(\'hide\');"/>\
      # <% end %>\
    # </div>\
    # <% end %>\
  # </div>\
# </div>\
# </div>\
# ');

# var display_choice = document.getElementById('instructure_embedded_form_page_display_choice');
# display_choice.value = "<%= @page.page_type %>"; // or whatever the current choice is :-)
# instructureEmbedOptionUpdated(display_choice);
# <% if @page.page_type == 'assignment' %> // if page is an assignment, set the assignment by default
# var assignment_choice = document.getElementById('instructure_embedded_form_assignment_choice');
# assignment_choice.value = "<%= @page.type_id %>";
# <% end %>
# document.write('<div style="clear: both;"></div>');