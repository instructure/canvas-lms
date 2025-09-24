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
  argument :assignment_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Assignment")

  def resolve(input:)
    assignment = get_assignment(input[:assignment_id])
    course = assignment.course

    validate_feature_flag!(course)
    verify_authorized_action!(assignment, :create)
    validate_id_arrays!(input)

    allocation_rules = create_allocation_rules(input, assignment, course)
    validate_peer_review_counts!(allocation_rules, assignment)

    process_allocation_rules(allocation_rules)
  end

  private

  def create_allocation_rules(input, assignment, course)
    allocation_rules = []
    shared_opts = {
      must_review: input[:must_review],
      review_permitted: input[:review_permitted],
      applies_to_assessor: input[:applies_to_assessor]
    }

    if input[:reciprocal]
      opts = {
        assessor_id: input[:assessor_ids].first,
        assessee_id: input[:assessee_ids].first,
      }
      reciprocal_opts = {
        assessor_id: input[:assessee_ids].first,
        assessee_id: input[:assessor_ids].first
      }

      new_rule = create_new_rule(assignment, course, opts.merge(shared_opts))
      allocation_rules << new_rule

      # Check if the reciprocal rule exists already. Otherwise create a new one
      find_reciprocal_rule(new_rule)
      allocation_rules << create_or_find_new_rule(assignment, course, reciprocal_opts.merge(shared_opts))
    else
      target_id = input[:applies_to_assessor] ? input[:assessor_ids].first : input[:assessee_ids].first
      subjects = input[:applies_to_assessor] ? input[:assessee_ids] : input[:assessor_ids]

      subjects.each do |subject_id|
        opts = {
          assessor_id: input[:applies_to_assessor] ? target_id : subject_id,
          assessee_id: input[:applies_to_assessor] ? subject_id : target_id
        }
        allocation_rules << create_or_find_new_rule(assignment, course, opts.merge(shared_opts))
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
