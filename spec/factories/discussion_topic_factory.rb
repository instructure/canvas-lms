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
