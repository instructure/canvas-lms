# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Types
  class RubricAssessmentRatingType < ApplicationObjectType
    description "An assessment for a specific criteria in a rubric"

    # This can actually have a nil id (:sigh:), so we cannot use the LegacyIDInterface here
    field :_id, ID, "legacy canvas id", method: :id, null: true

    field :comments, String, null: true
    field :comments_html, String, null: true
    field :artifact_attempt, Integer, null: false
    def artifact_attempt
      object[:artifact_attempt] || 0
    end

    field :rubric_assessment_id, ID, null: false

    field :criterion, RubricCriterionType, <<~MD, null: true
      The rubric criteria that this assessment is for
    MD
    def criterion
      Loaders::IDLoader.for(Rubric).load(object[:rubric_id]).then do |rubric|
        rubric.criteria.find { |c| c[:id] == object[:criterion_id] }
      end
    end

    field :description, String, null: true

    field :outcome, LearningOutcomeType, null: true
    def outcome
      return nil unless object[:learning_outcome_id]

      Loaders::IDLoader.for(LearningOutcome).load(object[:learning_outcome_id])
    end

    field :points, Float, null: true
  end
end
