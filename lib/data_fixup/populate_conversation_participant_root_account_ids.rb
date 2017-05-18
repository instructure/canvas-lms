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

class DataFixup::PopulateConversationParticipantRootAccountIds
  def self.run
    scope = ConversationParticipant.where(:root_account_ids => nil)
    scope = scope.joins(:conversation).where("conversations.root_account_ids IS NOT NULL")
    scope.find_ids_in_ranges do |min, max|
      scope.where(:conversation_participants => { :id => min..max }).
          update_all("root_account_ids=conversations.root_account_ids")
    end
  end
end
