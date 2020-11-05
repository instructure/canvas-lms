# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

class DiscussionTopic::ScopedToUser < ScopeFilter
  def scope
    concat_scope do
      scope_for_differentiated_assignments(@relation)
    end
  end

  private
  def scope_for_differentiated_assignments(scope)
    return scope if context.is_a?(Account)
    return DifferentiableAssignment.scope_filter(scope, user, context) if context.is_a?(Course)
    return scope if context.context.is_a?(Account)

    # group context owned by a course
    course = context.context
    course_scope = course.discussion_topics.active
    course_level_topic_ids = DifferentiableAssignment.scope_filter(course_scope, user, course).pluck(:id)
    if course_level_topic_ids.any?
      scope.where("discussion_topics.root_topic_id IN (?) OR discussion_topics.root_topic_id IS NULL OR discussion_topics.id IN (?)", course_level_topic_ids, course_level_topic_ids)
    else
      scope.where(root_topic_id: nil)
    end
  end
end

