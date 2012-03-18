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

def discussion_topic_model(opts={})
  @context ||= course_model(:reusable => true)
  @topic = @context.discussion_topics.create!(valid_discussion_topic_attributes.merge(opts))
end

def valid_discussion_topic_attributes
  {
    :title => "value for title",
    :message => "value for message"
  }
end

def group_assignment_discussion(opts = {})
  course = opts[:course] || course_model(:reusable => true)
  assignment_model(:course => course, :group_category => 'Project Group', :submission_types => 'discussion_topic', :title => 'Group Assignment Discussion')
  group_model(:name => 'Project Group 1', :group_category => @group_category, :context => course)
  @root_topic = DiscussionTopic.find_by_assignment_id(@assignment.id)
  @root_topic.refresh_subtopics
  @topic = @group.discussion_topics.find_by_root_topic_id(@root_topic.id)
end
