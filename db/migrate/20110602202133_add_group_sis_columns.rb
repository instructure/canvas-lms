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

class AddGroupSisColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :groups, :sis_source_id, :string
    add_column :groups, :sis_name, :string
    add_column :groups, :sis_batch_id, :string

    add_column :group_memberships, :sis_batch_id, :string
  end

  def self.down
    remove_column :groups, :sis_source_id
    remove_column :groups, :sis_name
    remove_column :groups, :sis_batch_id

    remove_column :group_memberships, :sis_batch_id
  end
end
