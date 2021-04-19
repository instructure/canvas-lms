# frozen_string_literal: true

# Copyright (C) 2018 - present Instructure, Inc.
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

module QuizzesNext
  class Service
    def self.enabled_in_context?(context)
      context&.feature_enabled?(:quizzes_next) || context&.root_account&.feature_allowed?(:quizzes_next)
    end

    def self.active_lti_assignments_for_course(course, selected_assignment_ids: nil)
      scope = course.assignments.active.type_quiz_lti
      scope = scope.where(:id => selected_assignment_ids) if selected_assignment_ids
      scope.to_a
    end

    def self.assignment_duplicated?(assignment_hash)
      assignment_hash.key?(:original_assignment_id)
    end

    def self.assignment_not_in_export?(assignment_hash)
      assignment_hash[:$canvas_assignment_id] == Canvas::Migration::ExternalContent::Translator::NOT_FOUND
    end
  end
end
