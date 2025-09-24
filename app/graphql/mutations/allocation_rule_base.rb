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

module Mutations
  class AllocationRuleBase < BaseMutation
    argument :applies_to_assessor, Boolean, required: false, default_value: true
    argument :assessee_ids, [ID], required: true, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User")
    argument :assessor_ids, [ID], required: true, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User")
    argument :must_review, Boolean, required: false, default_value: true
    argument :reciprocal, Boolean, required: false, default_value: false
    argument :review_permitted, Boolean, required: false, default_value: true

    field :allocation_rules, [Types::AllocationRuleType], null: true

    protected

    def validate_feature_flag!(course)
      unless course.feature_enabled?(:peer_review_allocation_and_grading)
        raise GraphQL::ExecutionError, I18n.t("peer_review_allocation_and_grading feature flag is not enabled for this course")
      end
    end

    def validate_id_arrays!(input)
      assessor_ids = input[:assessor_ids]
      assessee_ids = input[:assessee_ids]
      applies_to_assessor = input[:applies_to_assessor]
      reciprocal = input[:reciprocal]

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

    def validate_peer_review_counts!(allocation_rules, assignment, excluded_rule_ids = [])
      return unless assignment.peer_review_count && assignment.peer_review_count > 0

      rules_by_assessor = allocation_rules.group_by(&:assessor_id)

      rules_by_assessor.each do |assessor_id, rules|
        existing_required_count = assignment.allocation_rules
                                            .where(assessor_id:, must_review: true)
                                            .count

        new_required_count = rules.count(&:must_review) - excluded_rule_ids.count

        total_required_count = existing_required_count + new_required_count

        next unless total_required_count > assignment.peer_review_count

        raise GraphQL::ExecutionError, I18n.t(
          "Creating these rules would exceed the maximum number of required peer reviews (%{max_count}) for assessor %{assessor_id}. Current: %{existing_count}, Adding: %{new_count}, Total would be: %{total_count}",
          max_count: assignment.peer_review_count,
          assessor_id: assessor_id.to_s,
          existing_count: existing_required_count,
          new_count: new_required_count,
          total_count: total_required_count
        )
      end
    end

    def get_assignment(assignment_id)
      Assignment.active.find(assignment_id)
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, I18n.t("Assignment not found")
    end

    def process_allocation_rules(allocation_rules)
      if allocation_rules.all?(&:valid?)
        allocation_rules.each(&:save!)
        { allocation_rules: }
      else
        invalid_rule = allocation_rules.find { |rule| !rule.valid? }
        errors_for(invalid_rule)
      end
    end

    def create_new_rule(assignment, course, opts)
      return unless assignment && course && opts[:assessor_id] && opts[:assessee_id]

      AllocationRule.new(
        assignment:,
        course:,
        assessor_id: opts[:assessor_id],
        assessee_id: opts[:assessee_id],
        must_review: opts[:must_review],
        review_permitted: opts[:review_permitted],
        applies_to_assessor: opts[:applies_to_assessor]
      )
    end

    def create_or_find_new_rule(assignment, course, opts)
      return unless assignment && course && opts[:assessor_id] && opts[:assessee_id]

      AllocationRule.find_or_initialize_by(
        assignment:,
        course:,
        assessor_id: opts[:assessor_id],
        assessee_id: opts[:assessee_id],
        must_review: opts[:must_review],
        review_permitted: opts[:review_permitted],
        applies_to_assessor: opts[:applies_to_assessor]
      )
    end

    def find_reciprocal_rule(rule)
      AllocationRule.find_by(
        assignment: rule.assignment,
        assessor_id: rule.assessee_id,
        assessee_id: rule.assessor_id,
        must_review: rule.must_review,
        review_permitted: rule.review_permitted,
        applies_to_assessor: rule.applies_to_assessor
      )
    end
  end
end
