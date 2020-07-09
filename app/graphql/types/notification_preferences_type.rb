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
  class NotificationPreferencesType < ApplicationObjectType
    graphql_name "NotificationPreferences"

    field :channels, [CommunicationChannelType], null: true do
      argument :channel_id, ID, required: false, default_value: nil
    end
    def channels(channel_id:)
      return object[:channels] unless channel_id
      object[:channels].select { |cc| cc.id == channel_id.to_i }
    end

    field :send_scores_in_emails, Boolean, null: true do
      argument :user_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('User')
    end
    def send_scores_in_emails(user_id:)
      user = User.find(user_id)
      # send_scores_in_emails can be nil and we want the default to be false if unset
      user.preferences[:send_scores_in_emails] == true
    end
  end
end
