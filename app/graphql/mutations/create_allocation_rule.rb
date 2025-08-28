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

class Mutations::CreateAllocationRule < Mutations::AllocationRuleBase
  def resolve(input:)
    assignment = get_assignment(input[:assignment_id])
    course = assignment.course

    unless course.feature_enabled?(:peer_review_allocation_and_grading)
      raise GraphQL::ExecutionError, I18n.t("peer_review_allocation_and_grading feature flag is not enabled for this course")
    end

    verify_authorized_action!(assignment, :create)

    validate_id_arrays!(input)

    allocation_rules = create_allocation_rules(input, assignment, course)

    # Add peer review count validation before checking individual rule validity
    validate_peer_review_counts!(allocation_rules, assignment)

    if allocation_rules.all?(&:valid?)
      allocation_rules.each(&:save!)
      { allocation_rules: }
    else
      invalid_rule = allocation_rules.find { |rule| !rule.valid? }
      errors_for(invalid_rule)
    end
  end

  private

  def validate_id_arrays!(input)
    assessor_ids = input[:assessor_ids]
    assessee_ids = input[:assessee_ids]
    applies_to_assessor = input[:applies_to_assessor]
    reciprocal = input[:reciprocal]

    # Only allow one assessor and assessee when creating reciprocal rules
    if reciprocal
      if assessor_ids.length > 1
        raise GraphQL::ExecutionError, I18n.t("Only one assessor is allowed when creating reciprocal rules")
      end
      if assessee_ids.length > 1
        raise GraphQL::ExecutionError, I18n.t("Only one assessee is allowed when creating reciprocal rules")
      end
    elsif applies_to_assessor
      if assessor_ids.length > 1
        raise GraphQL::ExecutionError, I18n.t("Only one assessor is allowed when rule applies to assessor")
      end
    elsif assessee_ids.length > 1
      raise GraphQL::ExecutionError, I18n.t("Only one assessee is allowed when rule applies to assessee")
    end

    if assessor_ids.empty?
      raise GraphQL::ExecutionError, I18n.t("At least one assessor is required")
    end
    if assessee_ids.empty?
      raise GraphQL::ExecutionError, I18n.t("At least one assessee is required")
    end
  end

  def validate_peer_review_counts!(allocation_rules, assignment)
    return unless assignment.peer_review_count && assignment.peer_review_count > 0

    rules_by_assessor = allocation_rules.group_by(&:assessor_id)

    rules_by_assessor.each do |assessor_id, rules|
      existing_required_count = assignment.allocation_rules
                                          .where(assessor_id:, must_review: true)
                                          .count

      new_required_count = rules.count(&:must_review)

      total_required_count = existing_required_count + new_required_count

      next unless total_required_count > assignment.peer_review_count

      assessor = User.find(assessor_id)
      raise GraphQL::ExecutionError, I18n.t(
        "Creating these rules would exceed the maximum number of required peer reviews (%{max_count}) for assessor %{assessor_id}. Current: %{existing_count}, Adding: %{new_count}, Total would be: %{total_count}",
        max_count: assignment.peer_review_count,
        assessor_id: assessor.id.to_s,
        existing_count: existing_required_count,
        new_count: new_required_count,
        total_count: total_required_count
      )
    end
  end

  def create_allocation_rules(input, assignment, course)
    assessor_ids = input[:assessor_ids]
    assessee_ids = input[:assessee_ids]
    reciprocal = input[:reciprocal]

    allocation_rules = []

    if reciprocal
      assessor_id = assessor_ids.first
      assessee_id = assessee_ids.first

      allocation_rules << AllocationRule.new(
        course:,
        assignment:,
        assessor_id:,
        assessee_id:,
        must_review: input[:must_review],
        review_permitted: input[:review_permitted],
        applies_to_assessor: input[:applies_to_assessor]
      )

      allocation_rules << AllocationRule.new(
        course:,
        assignment:,
        assessor_id: assessee_id,
        assessee_id: assessor_id,
        must_review: input[:must_review],
        review_permitted: input[:review_permitted],
        applies_to_assessor: input[:applies_to_assessor]
      )
    else
      assessor_ids.each do |assessor_id|
        assessee_ids.each do |assessee_id|
          allocation_rules << AllocationRule.new(
            course:,
            assignment:,
            assessor_id:,
            assessee_id:,
            must_review: input[:must_review],
            review_permitted: input[:review_permitted],
            applies_to_assessor: input[:applies_to_assessor]
          )
        end
      end
    end

    allocation_rules
  end

  def get_assignment(assignment_id)
    Assignment.active.find(assignment_id)
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, I18n.t("Assignment not found")
  end
end
