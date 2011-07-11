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

# <% content_for :auto_discovery do %>
  # <% if @context_enrollment %>
    # <%= auto_discovery_link_tag(:atom, feeds_course_format_url(@context_enrollment.feed_code, :atom), {:title => "Course Atom Feed"}) %>
  # <% elsif @context.available? %>
    # <%= auto_discovery_link_tag(:atom, feeds_course_format_url(@context.feed_code, :atom), {:title => "Course Atom Feed"}) %>
  # <% end %>
# <% end %>

# <% content_for :primary_nav do %>
  # <%= render :partial => 'shared/context/primary_nav', :locals => {:view => 'course'} %>
# <% end %>

# <% content_for :secondary_nav do %>
  # <%= render :partial => 'shared/context/context_secondary_nav', :locals => {:view => 'home'} %>
# <% end %>

# <% content_for :page_header do %>
  # <h1><%= @context.name %></h1>
# <% end %>

# <% content_for :page_subhead do %>
  # <h2>Course Details</h2>
# <% end %>

# <% content_for :right_side do %>
  # <div style="margin-bottom: 10px;">
    # <a href="#" class="wizard_popup_link" style="display: none;"><%= image_tag "check.png" %> Course Setup Checklist</a>
  # </div>
  # <%= render :partial => "shared/notification_list", :object => @message_types %>
  # <%= render :partial => "group_list", :object => @groups %>
  # <%= render :partial => "shared/event_list", :object => @upcoming_events, :locals => {:title => "Upcoming Events", :display_count => 3, :period => "the next week"} %>
  # <%= render :partial => "shared/event_list", :object => @recent_events, :locals => {:title => "Recent Events", :display_count => 3, :period => "the last 2 weeks"} %>
# <% end %>

# <% content_for :stylesheets do %>
  # <%= stylesheet_link_tag "forum" %>
  # <%= stylesheet_link_tag "conference" %>
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
  # $(".re_send_confirmation_link").click(function(event) {
    # event.preventDefault();
    # var $link = $(this);
    # $link.text("Re-Sending...");
    # $.ajaxJSON($link.attr('href'), 'POST', {}, function(data) {
      # $link.text("Done! Message may take a few minutes.");
    # }, function(data) {
      # $link.text("Request failed. Try again.");
    # });
  # });
  # $(".home_page_link").click(function(event) {
    # event.preventDefault();
    # var $link = $(this);
    # $(".floating_links").hide();
    # $("#course_messages").slideUp(function() {
      # $(".floating_links").show();
    # });
    # $("#home_page").slideDown().loadingImage();
    # $link.hide();
    # $.ajaxJSON($(this).attr('href'), 'GET', {}, function(data) {
      # $("#home_page").loadingImage('remove');
      # var body = $.trim(data.wiki_page.body);
      # if(body.length == 0) { body = "No Content"; }
      # $("#home_page_content").html(body);
      # $("html,body").scrollTo($("#home_page"));
    # });
  # });
  # $(".dashboard_view_link").click(function(event) {
    # event.preventDefault();
    # $(".floating_links").hide();
    # $("#course_messages").slideDown(function() {
      # $(".floating_links").show();
    # });
    # $("#home_page").slideUp();
    # $(".home_page_link").show();
  # });
  # $(".publish_course_in_wizard_link").click(function(event) {
    # event.preventDefault();
    # if($("#wizard_box:visible").lenght > 0) {
      # $("#wizard_box .option.publish_step").click();
    # } else {
      # $("#wizard_box").slideDown('slow', function() {
        # $(this).find(".option.publish_step").click();
      # });
    # }
  # });
# });
# </script>
# <% if @context.created? || @context.claimed? %>
  # <div style="font-size: 0.8em; text-align: center;">
  # <h2>This Course is Unpublished</h2>
  # <div>Only teachers can see this course until is is <a href="#" class="publish_course_in_wizard_link"><b>published</b></a></div>
  # </div>
# <% end %>
# <% if can_do(@context, @current_user, :manage) %>
  # <!--%= render :partial => "courses/course_reminders" %-->
# <% end %>
# <% if @pending_enrollment %>
  # <%= render :partial => "courses/enrollment_reminders" %>
# <% end %>
# <% if !@context_just_saved %>
# <div style="float: right; text-align: left;" class="floating_links">
  # <% if can_do(@context.announcements.new, @current_user, :create) %>
    # <div><a href="<%= context_url(@context, :controller => :announcements) %>#new"><%= image_tag "add.png" %> New Announcement</a></div>
  # <% end %>
  # <% if !@public_view %>
    # <div><a class="home_page_link" href="<%= context_url(@context, :wiki_pages_url) %>">
      # <% if home_page_updated? #false # if home page has changed %>
        # <%= image_tag "star.png", :title => "Changed recently" %> 
      # <% else %>
        # <%= image_tag "file.png" %> 
      # <% end %>
      # View Course Home Page</a>
    # </div>
  # <% end %>
# </div>
# <% end %>
# <div style="display: none;" id="home_page">
  # <div id="home_page_content">Loading...
  # </div>
  # <div style="margin-top: 20px; text-align: right;">
    # <a href="#" class="dashboard_view_link"><%= image_tag "back.png" %> Back to Dashboard View</a>
  # </div>
# </div>
# <div id="course_messages">
  # <div class="clear"></div>
  # <div id="topic_list">
    # <div id="no_topics_message" style="<%= @topics && @topics.length > 0 ? 'display: none;' : '' %>">
      # No messages
    # </div>
    # <% if @current_conferences && !@current_conferences.empty? %>
      # <%= render :partial => "shared/conference", :collection => @current_conferences, :locals => {:brief => true} %>
    # <% end %>
    # <%= render :partial => "shared/topic", :collection => @topics[0, 5], :locals => {:brief => true } %>
  # </div>
  # <% if @topics.length >= 5 %>
    # <div>
      # <a href="<%= context_url(@context, :controller => :discussion_topics, :action => :index) %>"><%= @topics.length - 5 %> more topics in the last 2 weeks.</a>
    # </div>
  # <% end %>
# </div>
# <% if @context.created? || @context.claimed? %>
  # <%= render :partial => "course_wizard_box" %>
# <% end %>
