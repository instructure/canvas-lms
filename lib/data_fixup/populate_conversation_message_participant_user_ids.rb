#
# Copyright (C) 2012 - present Instructure, Inc.
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

module DataFixup::PopulateConversationMessageParticipantUserIds
  def self.run
    ConversationMessageParticipant.where(:user_id => nil).find_ids_in_ranges do |min, max|
      scope = ConversationMessageParticipant.joins(:conversation_participant)
      scope.where(:user_id => nil, :conversation_message_participants => { :id => min..max }).
          update_all("user_id=conversation_participants.user_id")
    end
  end
end
