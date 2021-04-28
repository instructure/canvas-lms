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

class Mutations::ImportOutcomes < Mutations::BaseMutation
  graphql_name 'ImportOutcomes'

  argument :group_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('LearningOutcomeGroup')
  argument :outcome_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('LearningOutcome')
  argument :source_context_id, ID, required: false
  argument :source_context_type, String, required: false
  argument :target_context_id, ID, required: true
  argument :target_context_type, String, required: true

  VALID_CONTEXTS = %w[Account Course].freeze

  def resolve(input:)
    source_context = nil
    if input[:source_context_type].present?
      if input[:source_context_id].present?
        source_context =
          begin
            context_class(input[:source_context_type]).find_by(id: input[:source_context_id])
          rescue NameError
            return validation_error(
              I18n.t('invalid value'), attribute: 'sourceContextType'
            )
          end

        if source_context.nil?
          raise GraphQL::ExecutionError, I18n.t('no such source context')
        end
      else
        return validation_error(
          I18n.t('sourceContextId required if sourceContextType provided'),
          attribute: 'sourceContextId'
        )
      end
    elsif input[:source_context_id].present?
      return validation_error(
        I18n.t('sourceContextType required if sourceContextId provided'),
        attribute: 'sourceContextType'
      )
    end

    target_context =
      begin
        context_class(input[:target_context_type]).find_by(id: input[:target_context_id])
      rescue NameError
        return validation_error(
          I18n.t('invalid value'), attribute: 'targetContextType'
        )
      end

    if target_context.nil?
      raise GraphQL::ExecutionError, I18n.t('no such target context')
    end

    verify_authorized_action!(target_context, :manage_outcomes)

    if (group_id = input[:group_id].presence)
      # Import the entire group into the given context
      group = LearningOutcomeGroup.active.find_by(id: group_id)
      if group.nil?
        raise GraphQL::ExecutionError, I18n.t('group not found')
      end

      # If optional source context provided, then check that
      # matches the group's context
      if source_context && source_context != group.context
        raise GraphQL::ExecutionError, I18n.t('source context does not match group context')
      end

      # source has to be global or in an associated account
      source_context = group.context
      unless !source_context || target_context.associated_accounts.include?(source_context)
        raise GraphQL::ExecutionError, I18n.t('invalid context for group')
      end

      # source can't be a root group
      if group.learning_outcome_group_id.nil?
        raise GraphQL::ExecutionError, I18n.t('cannot import a root group')
      end

      # TODO: OUT-4153 Import group into context
      return {}
    elsif (outcome_id = input[:outcome_id].presence)
      # Import the selected outcome into the given context

      # verify the outcome is eligible to be linked into the context
      unless target_context.available_outcome(outcome_id, allow_global: true)
        raise GraphQL::ExecutionError, I18n.t(
          "Outcome %{outcome_id} is not available in context %{context_type}#%{context_id}",
          outcome_id: outcome_id,
          context_id: target_context.id.to_s,
          context_type: target_context.class.name,
        )
      end

      # TODO: OUT-4153 Import outcomes into context
      return {}
    end

    validation_error(
      I18n.t('Either groupId or outcomeId values are required')
    )
  end

  private

  def context_class(context_type)
    raise NameError unless VALID_CONTEXTS.include? context_type

    context_type.constantize
  end
end


