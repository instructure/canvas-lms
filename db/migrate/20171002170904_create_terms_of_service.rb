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
#
class CreateTermsOfService < ActiveRecord::Migration[4.2]
  tag :predeploy
  def change
    create_table :terms_of_services do |t|
      t.string :terms_type, null: false, :default => "default"
      t.boolean :passive, null: false, :default => true
      t.integer :terms_of_service_content_id, limit: 8
      t.integer :account_id, null: false, limit: 8
      t.timestamps
      t.string :workflow_state, null: false
    end
    add_index :terms_of_services, :account_id, unique: true
    add_foreign_key :terms_of_services, :terms_of_service_contents
    add_foreign_key :terms_of_services, :accounts
  end
end
