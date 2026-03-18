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

class PeerReview::Jobs::Workers::AllocationRuleConverterWorker
  PROGRESS_TAG = "peer_review_allocation_conversion"

  def self.start_job(assignment, type, should_delete: false)
    unless ["AllocationRule", "AssessmentRequest"].include?(type)
      raise ArgumentError, "Type must be 'AllocationRule' or 'AssessmentRequest'"
    end

    validate_feature_flag(assignment, type, should_delete)

    progress = Progress.create!(context: assignment, tag: PROGRESS_TAG)
    progress.process_job(self, :perform, { max_attempts: 3, preserve_method_args: true }, assignment, type, should_delete)
  end

  def self.perform(assignment, type, should_delete)
    job_progress = Progress.find_by(context_type: "Assignment", context_id: assignment.id, tag: PROGRESS_TAG, workflow_state: ["queued", "running"])
    raise "No job progress found for assignment #{assignment.id}" unless job_progress

    job_progress.update!(workflow_state: "running", completion: 0)

    resources_scope = if should_delete && type == "AllocationRule"
                        assignment.allocation_rules.active
                      else
                        get_resources_to_process(assignment, type)
                      end

    num_resources_to_process = resources_scope.count
    num_resources_processed = 0

    resources_scope.find_in_batches(batch_size: 25) do |batch|
      if should_delete
        delete_resources(batch)
      else
        convert_resources(batch)
      end

      num_resources_processed += batch.size
      process_progress = (num_resources_to_process.zero? ? 100 : ((num_resources_processed.to_f / num_resources_to_process) * 100).round)
      job_progress.update!(completion: process_progress)
    end

    # Clean up any leftover allocation rules when converting from AllocationRules
    cleanup_leftover_allocation_rules(assignment) if !should_delete && type == "AllocationRule"

    job_progress.update!(workflow_state: "completed", completion: 100)
  end

  def self.validate_feature_flag(assignment, type, should_delete)
    course = assignment.context
    ff_enabled = course.feature_enabled?(:peer_review_allocation_and_grading)

    # When working with AssessmentRequests (converting from or deleting), FF must be enabled
    # When working with AllocationRules (converting from or deleting), FF must be disabled
    if type == "AssessmentRequest"
      unless ff_enabled
        raise ArgumentError, "Feature flag peer_review_allocation_and_grading must be enabled to #{should_delete ? "delete" : "convert"} AssessmentRequests"
      end

      # PeerReviewSubAssignment must exist to indicate the FF toggle job has completed
      unless assignment.peer_review_sub_assignment.present?
        raise ArgumentError, "PeerReviewSubAssignment must exist before #{should_delete ? "deleting" : "converting"} AssessmentRequests"
      end
    else
      if ff_enabled
        raise ArgumentError, "Feature flag peer_review_allocation_and_grading must be disabled to #{should_delete ? "delete" : "convert"} AllocationRules"
      end

      # PeerReviewSubAssignment must NOT exist (indicates old flow)
      if assignment.peer_review_sub_assignment.present?
        raise ArgumentError, "PeerReviewSubAssignment must not exist when #{should_delete ? "deleting" : "converting"} AllocationRules"
      end
    end
  end

  def self.get_resources_to_process(assignment, type)
    if type == "AllocationRule"
      assignment.allocation_rules.active.where(must_review: true, review_permitted: true)
    else
      # This timestamp comparison identifies legacy peer reviews from the old manual flow
      # that existed before the assignment adopted the new allocation-based flow
      AssessmentRequest.for_assignment(assignment.id)
                       .incomplete
                       .where(assessment_requests: { created_at: ...assignment.peer_review_sub_assignment.created_at })
    end
  end

  def self.convert_resources(resources)
    resources.each do |resource|
      PeerReview::AllocationRuleConverterService.call(resource)
    end
  end

  def self.delete_resources(resources)
    resources.each(&:destroy)
  end

  def self.cleanup_leftover_allocation_rules(assignment)
    assignment.allocation_rules.active.in_batches.destroy_all
  end
end
