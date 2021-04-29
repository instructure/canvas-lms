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
  def initialize(context_id, context_type)
    @context_id = context_id
    @context_type = context_type
  end

  def perform(outcome_ids)
    OutcomeFriendlyDescription.active.where(
      learning_outcome_id: outcome_ids,
      context_id: @context_id,
      context_type: @context_type,
    ).each do |friendly_description|
      fulfill(friendly_description.learning_outcome_id, friendly_description)
    end

    outcome_ids.each do |outcome_id|
      fulfill(outcome_id, nil) unless fulfilled?(outcome_id)
    end
  end
end
