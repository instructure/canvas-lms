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

    class AllocationError
      attr_accessor :message, :attribute, :attribute_id, :assignment

      def initialize(message:, attribute: nil, attribute_id: nil, assignment: nil)
        @message = message
        @attribute = attribute
        @attribute_id = attribute_id
        @assignment = assignment
      end

      def root_account_id
        @assignment&.root_account_id
      end

      def shard
        @assignment&.shard
      end

      def asset_string
        "allocation_error_#{object_id}"
      end
    end

    AllocationErrorType = Class.new(GraphQL::Schema::Object) do
      graphql_name "AllocationError"
      description "An error that occurred while processing an allocation rule"

      field :assignment_id, ID, null: false
      field :attribute, String, null: true
      field :attribute_id, String, null: true
      field :message, String, null: false

      def assignment_id
        object.assignment&.id&.to_s
      end
    end

    field :allocation_errors, [AllocationErrorType], null: true
    field :allocation_rules, [Types::AllocationRuleType], null: true

    protected

    def validate_feature_flag!(course)
      unless course.feature_enabled?(:peer_review_allocation)
        raise GraphQL::ExecutionError, I18n.t("peer_review_allocation feature flag is not enabled for this course")
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

      if assessor_ids.length > 50
        raise GraphQL::ExecutionError, I18n.t("A maximum of 50 assessors can be provided at once")
      end
      if assessee_ids.length > 50
        raise GraphQL::ExecutionError, I18n.t("A maximum of 50 assessees can be provided at once")
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
        invalid_rules = allocation_rules.reject(&:valid?)
        all_allocation_errors = []

        invalid_rules.each do |invalid_rule|
          rule_errors = allocation_errors_for(invalid_rule)
          all_allocation_errors.concat(rule_errors[:allocation_errors])
        end

        {
          allocation_errors: all_allocation_errors
        }
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

      existing_rule = AllocationRule.active.find_by(
        assignment:,
        assessor_id: opts[:assessor_id],
        assessee_id: opts[:assessee_id],
        must_review: opts[:must_review],
        review_permitted: opts[:review_permitted]
      )

      if existing_rule && existing_rule.applies_to_assessor != opts[:applies_to_assessor]
        # Update applies_to_assessor if it differs. The applies_to_assessor field does not affect the
        # review relationship, but rather the wording of the relationship.
        existing_rule.applies_to_assessor = opts[:applies_to_assessor]
      end

      existing_rule || create_new_rule(assignment, course, opts)
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

    def get_attribute_id(allocation_rule, attribute)
      case attribute
      when :assessor_id
        allocation_rule.assessor_id.to_s
      when :assessee_id
        allocation_rule.assessee_id.to_s
      else
        nil
      end
    end

    private

    def allocation_errors_for(allocation_rule)
      {
        allocation_errors: allocation_rule.errors.entries.map do |error|
          AllocationError.new(
            message: error.message,
            attribute: error.attribute.to_s,
            attribute_id: get_attribute_id(allocation_rule, error.attribute),
            assignment: allocation_rule.assignment
          )
        end
      }
    end
  end
end
