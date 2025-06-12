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
#
module Outcomes
  # Calculates and persists outcome rollups for a single student in a course.
  #
  # Usage:
  #   Outcomes::StudentOutcomeRollupCalculationService.call(course: course, student: student)
  class StudentOutcomeRollupCalculationService < ApplicationService
    # @param course [Course] the course whose outcomes to roll up
    # @param student [User] the student for whom to calculate rollups
    def initialize(course:, student:)
      super()
      @course  = course
      @student = student
    end

    # Runs the full calculation and persists the calculation.
    #
    # @return [Array<OutcomeRollup>] the created or updated rollup records
    def call
      # TODO: implement fetch data, generate rollups, persist, return rollups
      []
    end

    private

    # @return [Array<LearningOutcome>]
    def load_course_outcomes
      # TODO: load course.learning_outcomes
      []
    end

    # @return [Array<OutcomeRollup>]
    def generate_student_rollups
      # TODO: fetch_canvas_results, fetch_outcomes_service_results, combine_results, map to OutcomeRollup
      []
    end

    # @return [Array<LearningOutcomeResult>]
    def fetch_canvas_results
      # TODO: fetch results from Canvas
      []
    end

    # @return [Array<LearningOutcomeResult>]
    def fetch_outcomes_service_results
      # TODO: fetch results from Outcomes Service
      []
    end

    # @param canvas_results [Array<LearningOutcomeResult>]
    # @param outcomes_service_results [Array<LearningOutcomeResult>]
    # @return [Array<LearningOutcomeResult>]
    def combine_results
      # TODO: merge result sets
      []
    end

    # @param rollups [Array<OutcomeRollup>]
    def store_rollups(rollups)
      # TODO: upsert OutcomeRollup records
    end
  end
end
