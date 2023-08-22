# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class Mutations::SetFriendlyDescription < Mutations::BaseMutation
  graphql_name "SetFriendlyDescription"

  argument :description, String, required: true
  argument :outcome_id,
           ID,
           required: true,
           prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("LearningOutcome")
  argument :context_id, ID, required: true
  argument :context_type, String, required: true

  field :outcome_friendly_description, Types::OutcomeFriendlyDescriptionType, null: true

  VALID_CONTEXTS = %w[Account Course].freeze

  def self.outcome_friendly_description_log_entry(outcome_friendly_description, _context)
    outcome_friendly_description.context
  end

  def resolve(input:)
    description = input[:description]
    outcome_id = input[:outcome_id]
    context_id = input[:context_id]
    context_type = input[:context_type]

    context = get_context(context_type, context_id)
    outcome = get_outcome(outcome_id)

    validate!(context, outcome)

    friendly_description = OutcomeFriendlyDescription.find_or_initialize_by(
      context:,
      learning_outcome: outcome
    )

    if description.present?
      friendly_description.workflow_state = "active"
      friendly_description.description = description
      friendly_description.save!

    else
      friendly_description.destroy if friendly_description.persisted?
      friendly_description.description = ""
    end

    {
      outcome_friendly_description: friendly_description
    }
  end

  private

  def validate!(context, outcome)
    verify_authorized_action!(context, :manage_outcomes)

    unless context.available_outcome(outcome.id, allow_global: true)
      raise GraphQL::ExecutionError, I18n.t(
        "Outcome %{outcome_id} is not available in context %{context_type}#%{context_id}",
        outcome_id: outcome.id.to_s,
        context_id: context.id.to_s,
        context_type: context.class.name
      )
    end
  end

  def get_context(context_type, context_id)
    unless VALID_CONTEXTS.include?(context_type)
      raise GraphQL::ExecutionError, I18n.t("Invalid context type")
    end

    context_type.constantize.find_by(id: context_id).tap do |context|
      unless context
        raise GraphQL::ExecutionError, I18n.t(
          "No such context for %{context_type}#%{context_id}",
          context_type:,
          context_id: context_id.to_s
        )
      end
    end
  end

  def get_outcome(outcome_id)
    LearningOutcome.active.find_by(id: outcome_id).tap do |outcome|
      unless outcome
        raise GraphQL::ExecutionError, I18n.t(
          "No such outcome for id %{id}", { id: outcome_id }
        )
      end
    end
  end
end
