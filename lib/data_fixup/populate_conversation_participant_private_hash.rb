#
# Copyright (C) 2013 - present Instructure, Inc.
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

class DataFixup::PopulateConversationParticipantPrivateHash
  def self.run
    scope = ConversationParticipant.where(:private_hash => nil)
    scope = scope.joins(:conversation).where("conversations.private_hash IS NOT NULL")
    scope.find_ids_in_ranges do |min, max|
      scope.where(:conversation_participants => { :id => min..max }).
          update_all("private_hash=conversations.private_hash")
    end
  end
end
