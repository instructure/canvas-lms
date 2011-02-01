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

# <% content_for :page_title do %><%= @user.name %>, <%= @context.name %><% end %>

# <% content_for :primary_nav do %>
  # <%= render :partial => 'shared/context/primary_nav', :locals => {:view => 'communication'} %>
# <% end %>

# <% content_for :secondary_nav do %>
  # <%= render :partial => 'shared/context/communication_secondary_nav', :locals => {:view => 'roster'} %>
# <% end %>

# <% content_for :page_header do %>
  # <h1><%= @user.name %></h1>
# <% end %>

# <% content_for :page_subhead do %>
  # <h2><%= @context.name %></h2>
# <% end %>

# <% content_for :stylesheets do %>
  # <%= stylesheet_link_tag "forum" %>
# <% end %>

# <% content_for :right_side do %>
  # <b><%= @user.name %></b>
  # <% if can_do(@enrollment, @current_user, :read_grades) %>
    # <a href="<%= context_url(@context, :controller => :gradebooks, :action => :grade_summary, :id => @user.id) %>">Grades for <%= @user.name %></a>
  # <% end %>
# <% end %>

# <h2>Recent Forum Messages</h2>
# <%= render :partial => "discussion_topics/entry", :collection => @entries[0,5], :locals => {:out_of_context => true} %>