# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class PeerReview::AdhocOverrideCommonService < ApplicationService
  include PeerReview::Validations
  include PeerReview::DateOverrider

  def initialize(
    peer_review_sub_assignment: nil,
    override: nil
  )
    super()

    @peer_review_sub_assignment = peer_review_sub_assignment
    @override = override || {}
  end

  private

  def build_override_students(override, student_ids)
    override.changed_student_ids = Set.new
    existing_student_ids = override.assignment_override_students.pluck(:user_id)

    (student_ids.to_set - existing_student_ids.to_set).each do |user_id|
      override.assignment_override_students.build(user_id:)
      override.changed_student_ids << user_id
    end
  end

  def find_student_ids_in_course(student_ids)
    @peer_review_sub_assignment.course.all_students.where(id: student_ids).pluck(:id).uniq
  end

  def override_title(student_ids)
    AssignmentOverride.title_from_student_count(student_ids.count)
  end

  def fetch_student_ids
    @override.fetch(:student_ids, nil)
  end

  def fetch_unassign_item
    @override.fetch(:unassign_item, false)
  end
end
