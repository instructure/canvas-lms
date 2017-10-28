#
# Copyright (C) 2017 - present Instructure, Inc.
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

class CreateLtiLinks < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    create_table :lti_links do |t|
      t.string :resource_link_id, null: false
      t.string :vendor_code, null: false
      t.string :product_code, null: false
      t.string :resource_type_code, null: false
      t.integer :linkable_id, limit: 8
      t.string :linkable_type
      t.text :custom_parameters
      t.text :resource_url

      t.timestamps
    end

    add_index :lti_links, [:linkable_id, :linkable_type]
    add_index :lti_links, :resource_link_id, unique: true
  end
end
