# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class PeerReview::AllocationRuleConverterService < ApplicationService
  def initialize(resource)
    super()
    @resource = resource
  end

  def call
    case @resource
    when AssessmentRequest
      convert_assessment_request_to_allocation_rule
    when AllocationRule
      convert_allocation_rule_to_assessment_request
    else
      raise ArgumentError, "Resource must be an AssessmentRequest or AllocationRule"
    end
  end

  private

  def convert_assessment_request_to_allocation_rule
    return nil unless @resource.workflow_state == "assigned"

    assignment = @resource.submission&.assignment
    raise ArgumentError, "Assignment is required" unless assignment.is_a?(Assignment)
    raise ArgumentError, "Assignment must have peer reviews enabled" unless assignment.peer_reviews?

    allocation_rule = AllocationRule.new(
      assessor_id: @resource.assessor_id,
      assessee_id: @resource.user_id,
      assignment_id: assignment.id,
      course_id: assignment.context_id,
      must_review: true,
      review_permitted: true,
      applies_to_assessor: true
    )

    result = if allocation_rule.save
               allocation_rule
             else
               Rails.logger.info("Skipped converting AssessmentRequest #{@resource.id} to AllocationRule: #{allocation_rule.errors.full_messages.join(", ")}")
               nil
             end

    # Delete the AssessmentRequest regardless of conversion success
    @resource.destroy

    result
  end

  def convert_allocation_rule_to_assessment_request
    assignment = @resource.assignment

    # Only convert "X must review Y" rules
    should_convert = @resource.must_review && @resource.review_permitted

    # Check if there's already a completed AssessmentRequest for this relationship
    if should_convert
      existing_completed = AssessmentRequest.completed_for_assignment(assignment.id)
                                            .where(
                                              assessor_id: @resource.assessor_id,
                                              user_id: @resource.assessee_id
                                            )
                                            .exists?

      should_convert = false if existing_completed
    end

    # Find the submissions
    assessee_submission = assignment.submissions.find_by(user_id: @resource.assessee_id)
    assessor_submission = assignment.submissions.find_by(user_id: @resource.assessor_id)

    # Skip conversion if submissions don't exist
    should_convert = false if !assessee_submission || !assessor_submission

    assessment_request = nil

    if should_convert
      assessment_request = assignment.assign_peer_review(@resource.assessor, @resource.assessee)
    end

    # Delete the AllocationRule whether converted or not
    @resource.destroy

    assessment_request
  end
end
