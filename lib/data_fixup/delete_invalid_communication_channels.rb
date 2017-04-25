#
# Copyright (C) 2017 Instructure, Inc.
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

module DataFixup::DeleteInvalidCommunicationChannels
  def self.run
    scope = CommunicationChannel.where(path_type: CommunicationChannel::TYPE_EMAIL)
    scope.find_ids_in_ranges(batch_size: 10000) do |min_id, max_id|
      records = scope.where(id: min_id..max_id).pluck(:id, :path).reject do |id, path|
        EmailAddressValidator.valid?(path)
      end

      ids = records.map(&:first)
      if ids.present?
        CommunicationChannel.transaction do
          DelayedMessage.where(communication_channel_id: ids).delete_all
          NotificationPolicy.where(communication_channel_id: ids).delete_all
          CommunicationChannel.where(id: ids).delete_all
        end
      end
    end
  end
end
