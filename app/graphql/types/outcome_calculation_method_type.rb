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

module Types
  class OutcomeCalculationMethodType < ApplicationObjectType
    description 'Customized calculation method'

    implements GraphQL::Types::Relay::Node
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :calculation_method, String, null: false
    field :calculation_int, Integer, null: true
    field :context_type, String, null: false
    field :context_id, Integer, null: false

    field :locked, Boolean, null: false
    def locked
      !object.context.grants_right?(current_user, :manage_proficiency_calculations)
    end
  end
end
