#
# Copyright (C) 2015 Instructure, Inc.
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

module DataFixup::DeleteFacebookChannels
  def self.run
    # channels are indexed by path_type.
    # services are indexed by user_id, but aren't indexed by service.
    # so, use the channels to find users to find services
    CommunicationChannel.where(path_type: 'facebook').find_each do |cc|
      cc.destroy!
      UserService.where(user_id: cc.user_id, service: 'facebook').delete_all
    end
  end
end
