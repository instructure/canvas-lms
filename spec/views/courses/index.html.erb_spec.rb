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

# <% content_for :page_title do %>Courses<% end %>

# <% content_for :auto_discovery do %>
  # <% if @current_user %>
      # <%= auto_discovery_link_tag(:atom, feeds_user_format_url(@current_user.feed_code, :atom), {:title => "Course Announcements Atom Feed"}) %>
  # <% end %>
# <% end %>

# <% content_for :primary_nav do %>
  # <%= render :partial => "shared/primary_nav", :locals => {:view => "courses"} %>
# <% end %>
# <% content_for :page_header do %>
  # <h1>Courses</h1>
# <% end %>

# <% content_for :page_subhead do %>
  # <h2>Course Details</h2>
# <% end %>

# <% content_for :right_side do %>
  # <%= render :partial => "shared/notification_list", :object => @message_types %>
  # <%= render :partial => "shared/event_list", :object => @upcoming_events, :locals => {:title => "Upcoming Events", :display_count => 3, :period => "the next week", :show_context => true} %>
  # <%= render :partial => "shared/event_list", :object => @recent_events, :locals => {:title => "Recent Events", :display_count => 3, :period => "the last 2 weeks", :show_context => true} %>
# <% end %>

# <% content_for :stylesheets do %>
  # <%= stylesheet_link_tag "forum" %>
# <% end %>


# <script>
  # $(document).ready(function() {
    # $(".show_events_link,.hide_events_link").click(function(event) {
      # event.preventDefault();
      # var $events = $(this).parents(".events_list");
      # var show = $(this).hasClass('show_events_link');
      # $events.find(".events tr.hideable").showIf(show).end()
        # .find(".show_events_link").showIf(!show).end()
        # .find(".hide_events_link").showIf(show);
    # });
    
  # });
# </script>
# <% if @pending_enrollments && !@pending_enrollments.empty? %>
  # <h2>Pending Invitations</h2>
  # <ul>
    # <% @pending_enrollments.each do |enrollment| %>
      # <li><%= link_to enrollment.course.name, course_url(enrollment.course, :invitation => enrollment.uuid) %></li>
    # <% end %>
  # </ul>
# <% end %>
# <h2>Current Courses</h2>
# <table class="courses">
  # <% @courses.each do |course| %>
    # <tr>
      # <td style="padding-bottom: 20px;">
        # <div class="name">
          # <% if course.created? || course.claimed? %>
            # <%= image_tag "star.png", :title => "This course hasn't been published yet", :alt => "Unpublished" %>
          # <% end %>
          # <%= link_to course.name, url_for (course) %>
        # </div>
      # </td><td style="vertical-align: bottom; padding-bottom: 20px;">
        # <div class="links">
          # <% if course.students.include?(@current_user) %>
            # <%= link_to "Grades", url_for([course, :grades]) %> |
          # <% end %>
          # <%= link_to "Forum", url_for([course, :discussion_topics]) %> |
          # <%= link_to "Calendar", url_for([course, :calendar]) %> | 
          # <%= link_to "Assignments", url_for([course, :assignments]) %> | 
          # <%= link_to "Materials", url_for([course, :files]) %>
        # </div>
      # </td>
    # </tr>
  # <% end %>
# </table>

# <h2>Past Courses</h2>
# <table class="courses">
  # <% @ended_courses.each do |course| %>
    # <tr>
      # <td style="padding-bottom: 20px;">
        # <div class="name">
          # <%= link_to course.name, url_for (course) %>
        # </div>
      # </td><td style="vertical-align: bottom; padding-bottom: 20px;">
        # <div class="links">
          # <% if course.students.include?(@current_user) %>
            # <%= link_to "Grades", url_for([course, :grades]) %> |
          # <% end %>
          # <%= link_to "Forum", url_for([course, :discussion_topics]) %> |
          # <%= link_to "Calendar", url_for([course, :calendar]) %> | 
          # <%= link_to "Assignments", url_for([course, :assignments]) %> | 
          # <%= link_to "Materials", url_for([course, :files]) %>
        # </div>
      # </td>
    # </tr>
  # <% end %>
# </table>
