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

class AddCreatedAtToPageViewsIndex < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    remove_index :page_views, :column => :account_id
    add_index :page_views, [ :account_id, :created_at ]
  end

  def self.down
    remove_index :page_views, :column => [ :account_id, :created_at ]
    add_index :page_views, :account_id
  end
end
