# frozen_string_literal: true

#
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

module Moderation
  def create_moderation_selections_for_assignment(assignment, student_ids, student_context)
    assignment = Assignment.find(assignment) unless assignment.is_a?(AbstractAssignment)
    return unless assignment.moderated_grading

    # Add selections for students in Student IDs
    already_moderated_ids = assignment.moderated_grading_selections.pluck(:student_id)
    to_add_ids = student_ids - already_moderated_ids

    to_add_ids.each do |student_id|
      assignment.moderated_grading_selections.create! student_id:
    end

    # Delete selections not in Student IDs but in the context of students to be considered
    extra_moderated_ids = assignment.moderated_grading_selections.pluck(:student_id) - student_ids
    extra_moderated_ids &= student_context if student_context.any?
    assignment.moderated_grading_selections.where(student_id: extra_moderated_ids).destroy_all
  end
end
