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

module Submissions
  class WhatIfGradesService < ApplicationService
    def initialize(current_user)
      super()
      @current_user = current_user
    end

    def update(submission, what_if_grade)
      raise "Invalid submission" unless submission

      if submission.update_column(:student_entered_score, what_if_grade)
        GradeCalculator.new(@current_user, submission.course, use_what_if_scores: true, emit_live_event: false).compute_scores
      else
        @submission.errors.add(:student_entered_score, "could not be updated")
      end
    end

    def reset_for_course(course)
      Submission.where(user: @current_user, course:).update_all(student_entered_score: nil, updated_at: Time.zone.now)
      GradeCalculator.new(@current_user, course, emit_live_event: false).compute_scores
    end
  end
end
