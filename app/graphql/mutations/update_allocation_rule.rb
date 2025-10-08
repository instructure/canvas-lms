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

class Mutations::UpdateAllocationRule < Mutations::AllocationRuleBase
  argument :rule_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("AllocationRule")

  def resolve(input:)
    allocation_rule = get_allocation_rule(input[:rule_id])
    assignment = allocation_rule.assignment
    course = assignment.course

    validate_feature_flag!(course)
    verify_authorized_action!(assignment, :update)
    validate_id_arrays!(input)

    updated_rules = if input[:reciprocal]
                      update_reciprocal_rules(allocation_rule, input, assignment, course)
                    else
                      update_regular_rules(allocation_rule, input, assignment, course)
                    end

    process_allocation_rules(updated_rules)
  end

  private

  def get_allocation_rule(rule_id)
    AllocationRule.active.find(rule_id)
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, I18n.t("Allocation rule not found")
  end

  def update_reciprocal_rules(original_rule, input, assignment, course)
    shared_opts = {
      must_review: input[:must_review],
      review_permitted: input[:review_permitted],
      applies_to_assessor: input[:applies_to_assessor]
    }
    assess_opts = {
      assessor_id: input[:assessor_ids].first,
      assessee_id: input[:assessee_ids].first,
    }
    updated_rule = update_rule_fields(original_rule, shared_opts.merge(assess_opts))

    reciprocal_opts = {
      assessor_id: input[:assessee_ids].first,
      assessee_id: input[:assessor_ids].first,
    }
    reciprocal_rule = create_or_find_new_rule(assignment, course, shared_opts.merge(reciprocal_opts))

    [updated_rule, reciprocal_rule]
  end

  def update_regular_rules(original_rule, input, assignment, course)
    opts = {
      must_review: input[:must_review],
      review_permitted: input[:review_permitted],
      applies_to_assessor: input[:applies_to_assessor]
    }
    update_opts = {
      assessor_id: input[:assessor_ids].first,
      assessee_id: input[:assessee_ids].first
    }
    original_rule = update_rule_fields(original_rule, opts.merge(update_opts))
    allocation_rules = [original_rule]

    target_id = input[:applies_to_assessor] ? input[:assessor_ids].first : input[:assessee_ids].first
    subjects = input[:applies_to_assessor] ? input[:assessee_ids][1..] : input[:assessor_ids][1..]

    subjects.each do |subject_id|
      assess_opts = {
        assessor_id: input[:applies_to_assessor] ? target_id : subject_id,
        assessee_id: input[:applies_to_assessor] ? subject_id : target_id,
      }
      allocation_rules << create_or_find_new_rule(assignment, course, opts.merge(assess_opts))
    end

    allocation_rules
  end

  # Update the fields with the new values. Validation is handled during save in process_allocation_rules
  def update_rule_fields(rule, opts)
    rule.assessor_id = opts[:assessor_id]
    rule.assessee_id = opts[:assessee_id]
    rule.must_review = opts[:must_review]
    rule.review_permitted = opts[:review_permitted]
    rule.applies_to_assessor = opts[:applies_to_assessor]

    rule
  end

  def get_related_rule_ids(original_rule, is_reciprocal)
    rule_ids = [original_rule.id]

    if is_reciprocal
      reciprocal_rule = find_reciprocal_rule(original_rule)
      rule_ids << reciprocal_rule.id if reciprocal_rule
    end

    rule_ids
  end
end
