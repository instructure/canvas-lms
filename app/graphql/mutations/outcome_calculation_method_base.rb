# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class Mutations::OutcomeCalculationMethodBase < Mutations::BaseMutation
  # the return data if the create/update is successful
  field :outcome_calculation_method, Types::OutcomeCalculationMethodType, null: true

  def self.outcome_calculation_method_log_entry(outcome_calculation_method, _ctx)
    outcome_calculation_method.context
  end

  protected

  def attrs(input)
    input.slice(:calculation_method, :calculation_int)
  end

  def context_taken?(record)
    error = record.errors.first
    error && error[0] == :context_id && error[1] == "has already been taken"
  end

  def check_permission(context)
    raise GraphQL::ExecutionError, "insufficient permission" unless context.grants_right? current_user, :manage_proficiency_calculations
  end

  def upsert(input, existing_record: nil, context: nil)
    record = existing_record || OutcomeCalculationMethod.find_by(context:)
    if record
      record.assign_attributes(workflow_state: "active", **attrs(input.to_h))
      record.assign_attributes(context:) unless context.nil?
    else
      record = OutcomeCalculationMethod.new(context:, **attrs(input.to_h))
    end
    if record.save
      { outcome_calculation_method: record }
    elsif existing_record.nil? && context_taken?(record)
      upsert(input, context:)
    else
      errors_for(record)
    end
  end
end
