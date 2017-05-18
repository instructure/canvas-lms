#
# Copyright (C) 2014 - present Instructure, Inc.
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

class FixDuplicateCommunicationChannels < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    CommunicationChannel.
        group(CommunicationChannel.by_path_condition(CommunicationChannel.arel_table[:path]), :path_type, :user_id).
        select([CommunicationChannel.by_path_condition(CommunicationChannel.arel_table[:path]).as('path'), :path_type, :user_id]).
        having("COUNT(*) > 1").find_each do |baddie|
      all = CommunicationChannel.where(user_id: baddie.user_id, path_type: baddie.path_type).
          by_path(baddie.path).order("CASE workflow_state WHEN 'active' THEN 0 WHEN 'unconfirmed' THEN 1 ELSE 2 END", :created_at).to_a
      keeper = all.shift
      DelayedMessage.where(communication_channel_id: all).delete_all
      # it has a dependent: :destroy, but that does them one by one, which could take forever
      NotificationPolicy.where(communication_channel_id: all).delete_all
      all.each(&:destroy_permanently!)
    end

    if connection.adapter_name == 'PostgreSQL'
      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      execute("CREATE UNIQUE INDEX#{concurrently} index_communication_channels_on_user_id_and_path_and_path_type ON #{CommunicationChannel.quoted_table_name} (user_id, LOWER(path), path_type)")
    else
      add_index :communication_channels, [:user_id, :path, :path_type], unique: true
    end
  end

  def self.down
    remove_index :communication_channels, [:user_id, :path, :path_type]
  end
end
