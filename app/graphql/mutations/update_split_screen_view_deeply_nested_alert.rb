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

class Mutations::UpdateSplitScreenViewDeeplyNestedAlert < Mutations::BaseMutation
  graphql_name "UpdateSplitScreenViewDeeplyNestedAlert"

  argument :split_screen_view_deeply_nested_alert, Boolean, required: true

  field :user, Types::UserType, null: false
  def resolve(input:)
    current_user.set_preference(:split_screen_view_deeply_nested_alert, input[:split_screen_view_deeply_nested_alert].to_s)

    {
      user: current_user
    }
  end
end
