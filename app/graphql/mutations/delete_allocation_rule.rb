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

class Mutations::DeleteAllocationRule < Mutations::BaseMutation
  argument :rule_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("AllocationRule")

  field :allocation_rule_id, ID, null: false

  def resolve(input:)
    record = get_allocation_rule(input[:rule_id])
    assignment = record.assignment
    course = assignment.course

    validate_feature_flag!(course)
    verify_authorized_action!(assignment, :delete)
    context[:deleted_models] ||= {}
    context[:deleted_models][:allocation_rule] = record
    record.destroy
    {
      allocation_rule_id: record.id
    }
  end

  def self.allocation_rule_id_log_entry(_entry, context)
    context[:deleted_models][:allocation_rule]
  end

  private

  def get_allocation_rule(rule_id)
    AllocationRule.active.find(rule_id)
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, I18n.t("Allocation rule not found")
  end

  def validate_feature_flag!(course)
    unless course.feature_enabled?(:peer_review_allocation_and_grading)
      raise GraphQL::ExecutionError, I18n.t("peer_review_allocation_and_grading feature flag is not enabled for this course")
    end
  end
end
