#
# Copyright (C) 2011 - present Instructure, Inc.
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

class AddPositionToCommunicationChannelIndexes < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    remove_index :communication_channels, :column => %w(user_id)
    add_index    :communication_channels, %w(user_id position)

    remove_index :communication_channels, :column => %w(pseudonym_id)
    add_index    :communication_channels, %w(pseudonym_id position)
  end

  def self.down
    remove_index :communication_channels, :column => %w(user_id position)
    add_index    :communication_channels, %w(user_id)

    remove_index :communication_channels, :column => %w(pseudonym_id position)
    add_index    :communication_channels, %w(pseudonym_id)
  end
end
