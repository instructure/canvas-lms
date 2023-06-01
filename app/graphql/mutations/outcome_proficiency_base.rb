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

class Mutations::OutcomeProficiencyRatingCreate < GraphQL::Schema::InputObject
  argument :color, String, required: true
  argument :description, String, required: true
  argument :mastery, Boolean, required: true
  argument :points, Float, required: true
end

class Mutations::OutcomeProficiencyBase < Mutations::BaseMutation
  # the return data if the create/update is successful
  field :outcome_proficiency, Types::OutcomeProficiencyType, null: true

  def self.outcome_proficiency_log_entry(outcome_proficiency, _ctx)
    outcome_proficiency.context
  end

  protected

  def attrs(input)
    {
      outcome_proficiency_ratings: input[:proficiency_ratings].map do |rating|
        OutcomeProficiencyRating.new(**rating)
      end
    }
  end

  def context_taken?(record)
    error = record.errors.first
    error && error[0] == :context_id && error[1] == "has already been taken"
  end

  def check_permission(context)
    raise GraphQL::ExecutionError, "insufficient permission" unless context.grants_right? current_user, :manage_proficiency_scales
  end

  def upsert(input, existing_record: nil, context: nil)
    record = existing_record || OutcomeProficiency.find_by(context:)
    if record
      record.assign_attributes(workflow_state: "active")
      record.replace_ratings(input[:proficiency_ratings])
      record.assign_attributes(context:) unless context.nil?
    else
      record = OutcomeProficiency.new(context:, **attrs(input.to_h))
    end
    if record.save
      { outcome_proficiency: record }
    elsif existing_record.nil? && context_taken?(record)
      upsert(input, context:)
    else
      errors_for(record)
    end
  end
end
