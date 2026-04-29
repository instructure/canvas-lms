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

module Types
  class LearnerDashboardTabType < Types::BaseEnum
    graphql_name "LearnerDashboardTabType"
    description "Available tabs on the learner dashboard"
    value "dashboard"
    value "courses"
  end
end

class Mutations::UpdateLearnerDashboardTabSelection < Mutations::BaseMutation
  argument :tab, Types::LearnerDashboardTabType, required: true

  field :tab, Types::LearnerDashboardTabType, null: false

  def resolve(input:) # rubocop:disable GraphQL/UnusedArgument
    current_user.set_preference(:learner_dashboard_tab_selection, input[:tab])
    { tab: input[:tab] }
  end
end
