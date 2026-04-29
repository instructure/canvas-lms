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
    value "self_assessment"
  end

  class RubricAssessmentType < ApplicationObjectType
    description "An assessment for a rubric"

    implements Interfaces::LegacyIDInterface

    field :artifact_attempt, Integer, null: false
    def artifact_attempt
      object.artifact_attempt || 0
    end

    field :assessment_type, AssessmentType, null: false

    field :is_current_user, Boolean, null: false
    def is_current_user
      object.assessor_id == current_user&.id
    end

    field :score, Float, null: true

    field :updated_at, Types::DateTimeType, null: true

    field :user, UserType, null: true
    def user
      load_association(:user)
    end

    field :assessor, UserType, null: true
    def assessor
      if object.grants_right?(current_user, session, :read_assessor)
        return load_association(:assessor)
      end

      assignment = nil
      if object.rubric_association&.association_object.is_a?(Assignment)
        assignment = object.rubric_association.association_object
      elsif object.artifact.is_a?(Submission)
        assignment = object.artifact.assignment
      elsif object.artifact.is_a?(ModeratedGrading::ProvisionalGrade)
        assignment = object.artifact.submission.assignment
      end

      if assignment&.moderated_grading? && object.assessor_id
        grader_identities = assignment.grader_identities
        grader_identity = grader_identities.find { |grader| grader[:user_id] == object.assessor_id }
        anonymous_identity = Assignments::GraderIdentities.anonymize_grader_identity(grader_identity)

        if anonymous_identity
          return User.new(name: anonymous_identity[:name], short_name: anonymous_identity[:name])
        end
      end

      nil
    end

    field :assessment_ratings, [RubricAssessmentRatingType], <<~MD, null: true
      The assessments for the individual criteria in this rubric
    MD
    def assessment_ratings
      # Need to gimmy the rubric_id in here, so that the RubricAssessmentRating
      # criterions can associate back to the criterions on the rubric. It's all
      # sorts of terrible.
      return if object.data.nil?

      # Use the rubric from the rubric_association if available,
      # otherwise fall back to the rubric_id stored on the assessment.
      load_association(:rubric_association).then do |rubric_association|
        rubric_id = rubric_association&.rubric_id || object.rubric_id

        object.data.map do |assessment_rating|
          assessment_rating[:rubric_assessment_id] = object.id
          assessment_rating[:rubric_id] = rubric_id
          assessment_rating[:artifact_attempt] = object.artifact_attempt
          assessment_rating
        end
      end
    end

    field :rubric_association, RubricAssociationType, null: true
    def rubric_association
      load_association(:rubric_association)
    end
  end
end
