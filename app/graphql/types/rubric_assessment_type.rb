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
  class AssessmentType < BaseEnum
    graphql_name "AssessmentType"
    description "The type of assessment"
    value "grading"
    value "peer_review"
    value "provisional_grade"
  end

  class RubricAssessmentType < ApplicationObjectType
    description "An assessment for a rubric"

    implements Interfaces::LegacyIDInterface

    field :artifact_attempt, Integer, null: false
    def artifact_attempt
      object.artifact_attempt || 0
    end

    field :assessment_type, AssessmentType, null: false

    field :score, Float, null: true

    field :user, UserType, null: true
    def user
      load_association(:user)
    end

    field :assessor, UserType, null: true
    def assessor
      return nil unless object.grants_right?(current_user, session, :read_assessor)

      load_association(:assessor)
    end

    field :assessment_ratings, [RubricAssessmentRatingType], <<~MD, null: false
      The assessments for the individual criteria in this rubric
    MD
    def assessment_ratings
      # Need to gimmy the rubric_id in here, so that the RubricAssessmentRating
      # criterions can associate back to the criterions on the rubric. It's all
      # sorts of terrible.
      object.data.map do |assessment_rating|
        assessment_rating[:rubric_assessment_id] = object.id
        assessment_rating[:rubric_id] = object.rubric_id
        assessment_rating[:artifact_attempt] = object.artifact_attempt
        assessment_rating
      end
    end

    field :rubric_association, RubricAssociationType, null: true
    def rubric_association
      load_association(:rubric_association)
    end
  end
end
