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

module Outcomes
  module OutcomeFriendlyDescriptionResolver
    def context_queries(account, course)
      queries = []

      if course
        queries << OutcomeFriendlyDescription.sanitize_sql([
                                                             "context_type = 'Course' AND context_id = ?", course.id
                                                           ])
      end

      queries << OutcomeFriendlyDescription.sanitize_sql([
                                                           "context_type = 'Account' AND context_id IN (?)", account.account_chain_ids
                                                         ])

      "(" + queries.join(") OR (") + ")"
    end

    def resolve_friendly_descriptions(account, course, outcome_ids)
      account_order = account.account_chain_ids

      friendly_descriptions = OutcomeFriendlyDescription.active.where(
        learning_outcome_id: outcome_ids
      ).where(context_queries(account, course)).to_a.sort_by do |friendly_description|
        (friendly_description.context_type == "Course") ? 0 : account_order.index(friendly_description.context_id) + 1
      end
      friendly_descriptions.uniq(&:learning_outcome_id)
    end
  end
end
