# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module Courses
  module OffPace
    module Students
      class Validator < ApplicationService
        def initialize(student:, course_id:)
          raise ArgumentError, "student is required" if student.nil?
          raise ArgumentError, "course_id is required" if course_id.nil?

          super()
          @student = student
          @course_id = course_id
        end

        def call
          off_pace_submissions = student.submissions
                                        .where(submission_type: nil, course_id:)
                                        .joins(:assignment)
                                        .where(assignments: { due_at: ...current_time_midnight })
          off_pace_submissions.any?
        end

        private

        attr_reader :student, :course_id

        def current_time_midnight
          @current_time_midnight ||= Time.current.midnight
        end
      end
    end
  end
end
