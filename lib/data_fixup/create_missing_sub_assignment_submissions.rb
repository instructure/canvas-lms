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

module DataFixup
  module CreateMissingSubAssignmentSubmissions
    def self.run
      SubAssignment.active
                   .joins(:parent_assignment)
                   .where(assignments: { context_type: "Course" })
                   .preload(:parent_assignment)
                   .find_each do |sub_assignment|
        process_sub_assignment(sub_assignment)
      end
    end

    def self.process_sub_assignment(sub_assignment)
      students = sub_assignment.parent_assignment.students_with_visibility

      students.find_each do |student|
        next if sub_assignment.all_submissions.where(user: student).exists?

        begin
          sub_assignment.find_or_create_submission(student)
        rescue ActiveRecord::RecordNotUnique
          next
        rescue => e
          Rails.logger.error(
            "DataFixup::CreateMissingSubAssignmentSubmissions - " \
            "Error creating submission for SubAssignment #{sub_assignment.id}, " \
            "User #{student.id}: #{e.message}"
          )
          next
        end
      end
    end
  end
end
