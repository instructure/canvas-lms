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

class AddAssignmentPostColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :assignments, :post_to_sis, :boolean
    add_column :assignments, :integration_id, :string

    # We used to add an index on integration_id here, but decided not
    # to add it at all after it'd already been migrated in some envs
  end

  def self.down
    if index_exists?(:assignments, :integration_id)
      remove_index :assignments, :integration_id
    end

    remove_column :assignments, :post_to_sis
    remove_column :assignments, :integration_id
  end
end
