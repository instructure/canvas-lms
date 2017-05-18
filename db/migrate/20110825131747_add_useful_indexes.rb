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

class AddUsefulIndexes < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_index :courses, :uuid
    add_index :content_tags, [ :associated_asset_id, :associated_asset_type ], :name => 'index_content_tags_on_associated_asset'
    add_index :discussion_entries, :parent_id
    add_index :learning_outcomes, [ :context_id, :context_type ]
    add_index :role_overrides, :context_code
  end

  def self.down
    remove_index :courses, :uuid
    remove_index :content_tags, :name => 'index_content_tags_on_associated_asset'
    remove_index :discussion_entries, :parent_id
    remove_index :learning_outcomes, [ :context_id, :context_type ]
    remove_index :role_overrides, :context_code
  end
end
