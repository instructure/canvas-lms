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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/discussion_topics/_entry" do
  it "should render" do
    course_with_teacher
    view_context(@course, @user)
    @topic = @course.discussion_topics.create!(:title => "some title")
    @topic.context
    assigns[:entries] = []
    assigns[:topic] = @topic
    render :partial => "discussion_topics/entry", :object => nil, :locals => {:topic => @topic}
  end
  
  it "should render with data" do
    course_with_teacher
    view_context(@course, @user)
    @topic = @course.discussion_topics.create!(:title => "some title")
    @topic.context
    @entry = @topic.discussion_entries.create!(:message => "some message")
    @entry.context
    assigns[:entries] = [@entry]
    assigns[:grouped_entries] = [@entry].group_by(&:parent_id)
    assigns[:topic] = @topic
    render :partial => "discussion_topics/entry", :object => @entry, :locals => {:topic => @topic}
  end
end
