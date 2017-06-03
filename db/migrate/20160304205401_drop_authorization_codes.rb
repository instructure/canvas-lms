#
# Copyright (C) 2016 - present Instructure, Inc.
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

class DropAuthorizationCodes < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    drop_table :authorization_codes
  end

  def down
    create_table "authorization_codes", :force => true do |t|
      t.string   "authorization_code"
      t.string   "authorization_service"
      t.integer  "account_id", :limit => 8
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "associated_account_id", :limit => 8
    end

    add_index "authorization_codes", ["account_id"], :name => "index_authorization_codes_on_account_id"
  end
end
