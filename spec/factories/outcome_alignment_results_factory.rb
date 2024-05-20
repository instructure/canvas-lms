# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module Factories
  def create_outcome(args = {})
    args[:short_description] ||= Time.zone.now.to_s
    args[:context] ||= @course
    @outcome = LearningOutcome.create!(**args)
    @outcome
  end

  def create_alignment
    @assignment = assignment_model context: @course
    @alignment = @outcome.align(@assignment, @course)
    @assignment
  end

  def create_alignment_with_rubric(args = {})
    rubric = outcome_with_rubric context: @course, outcome: @outcome
    @assignment = if args[:assignment].nil?
                    assignment_model context: @course
                  else
                    args[:assignment]
                  end
    @alignment = @outcome.align(@assignment, @course)
    @rubric_association = rubric.associate_with(@assignment, @course, purpose: "grading")
    @assignment
  end

  def create_learning_outcome_result(user, score, args = {})
    title = "#{user.name}, #{@assignment.name}"
    mastery = (score || 0) >= @outcome.mastery_points
    submitted_at = args[:submitted_at] || time

    LearningOutcomeResult.create!(
      learning_outcome: @outcome,
      user:,
      context: @course,
      alignment: @alignment,
      associated_asset: @assignment,
      association_type: "Assignment",
      association_id: @assignment.id,
      title:,
      score:,
      possible: @outcome.points_possible,
      mastery:,
      created_at: submitted_at,
      updated_at: submitted_at,
      submitted_at:,
      assessed_at: submitted_at
    )
  end

  def create_learning_outcome_result_from_rubric(user, score, args = {})
    title = "#{user.name}, #{@assignment.name}"
    mastery = (score || 0) >= @outcome.mastery_points
    submitted_at = args[:submitted_at] || time

    association_object = rubric_association_model({ association_object: @assignment })
    rubric_assessment_model(user:, context: @course, rubric_association: association_object)

    LearningOutcomeResult.create!(
      artifact: @rubric_assessment,
      learning_outcome: @outcome,
      user:,
      context: @course,
      alignment: @alignment,
      association_id: association_object.id,
      association_type: "RubricAssociation",
      title:,
      score:,
      possible: @outcome.points_possible,
      mastery:,
      created_at: submitted_at,
      updated_at: submitted_at,
      submitted_at:,
      assessed_at: submitted_at
    )
  end

  # Mocks calls to the OS endpoints:
  #
  #   - retrieving data from the Canvas' LearningOutcomeResult table
  #   - transforming this data into a collection of AuthoritativeResult hash objects
  def authoritative_results_from_db
    LearningOutcomeResult.all.map do |lor|
      {
        user_uuid: lor.user.uuid,
        points: lor.score,
        points_possible: lor.possible,
        external_outcome_id: lor.learning_outcome.id,
        attempts: nil,
        associated_asset_type: nil,
        associated_asset_id: lor.alignment.content_id,
        artifact_type: nil,
        artifact_id: nil,
        submitted_at: lor.submitted_at
      }
    end
  end
end
