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

class Loaders::OutcomeFriendlyDescriptionLoader < GraphQL::Batch::Loader
  VALID_CONTEXT_TYPES = ['Course', 'Account'].freeze

  def initialize(context_id, context_type)
    @context_id = context_id
    @context_type = context_type
  end

  def context_queries
    queries = []

    if @course
      queries << OutcomeFriendlyDescription.sanitize_sql([
        "context_type = 'Course' AND context_id = ?", @course.id
      ])
    end

    queries << OutcomeFriendlyDescription.sanitize_sql([
      "context_type = 'Account' AND context_id IN (?)", @account.account_chain_ids
    ])

    '(' + queries.join(') OR (') + ')'
  end

  def valid_context?
    return false unless VALID_CONTEXT_TYPES.include?(@context_type)

    @context = @context_type.constantize.active.find_by(id: @context_id)
    return false unless @context

    if @context.is_a?(Course)
      @course = @context
      @account = @context.account
    else
      @account = @context
    end
    true
  end

  def nullify_resting(outcome_ids)
    outcome_ids.each do |outcome_id|
      fulfill(outcome_id, nil) unless fulfilled?(outcome_id)
    end
  end

  def perform(outcome_ids)
    unless valid_context?
      nullify_resting(outcome_ids)
      return
    end

    account_order = @account.account_chain_ids

    # get all friendly description for the course and all parent accounts once
    # sort by course, then the account parent order in account_chain_ids
    # and fulfill every friendly description
    friendly_descriptions = OutcomeFriendlyDescription.active.where(
      learning_outcome_id: outcome_ids
    ).where(context_queries).to_a.sort_by do |friendly_description|
      friendly_description.context_type == 'Course' ? 0 : account_order.index(friendly_description.context_id) + 1
    end

    friendly_descriptions.each do |friendly_description|
      outcome_id = friendly_description.learning_outcome_id
      fulfill(outcome_id, friendly_description) unless fulfilled?(outcome_id)
    end

    nullify_resting(outcome_ids)
  end
end
