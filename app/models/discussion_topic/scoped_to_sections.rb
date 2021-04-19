# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class DiscussionTopic::ScopedToSections < ScopeFilter
  # tl;dr this pattern isn't intended to be re-used
  #
  # DiscussionTopic::ScopedToUser is currently used in tandem with this class. The
  # functionality of this class _should_ belong in there. However, because ScopedToUser
  # is used by multiple classes for multiple contexts, we are opting to separate the
  # logic to this one class. This allows for a fix for filtering visible discussions
  # prior to pagination, whereas previously we were paginating prior to filtering.
  # That allowed for some pages to end up blank. See https://instructure.atlassian.net/browse/KNO-372
  def self.for(consumer, context, user, relation)
    raise "Invalid consumer #{consumer.class}" unless consumer.class == DiscussionTopicsController
    DiscussionTopic::ScopedToSections.new(context, user, relation)
  end

  def scope
    concat_scope do
      scope_for_user_sections(@relation)
    end
  end

  private
  def scope_for_user_sections(scope)
    return scope if context.grants_any_right?(user, :read_as_admin, :manage_grades, :manage_assignments, :manage_content)

    context.is_a?(Course) ? scope.visible_to_student_sections(user) : scope
  end
end

