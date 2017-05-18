#
# Copyright (C) 2015 - present Instructure, Inc.
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

class AddLtiMessageHandlerIdToLtiResourcePlacements < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :lti_resource_placements, :message_handler_id, :bigint
    add_foreign_key :lti_resource_placements, :lti_message_handlers, column: :message_handler_id
    add_index :lti_resource_placements,
              [:placement, :message_handler_id], unique: true,
              where: 'message_handler_id IS NOT NULL',
              name: 'index_resource_placements_on_placement_and_message_handler'
  end

  def self.down
    remove_column :lti_resource_placements, :message_handler_id
  end
end
