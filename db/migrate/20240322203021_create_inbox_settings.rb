# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

class CreateInboxSettings < ActiveRecord::Migration[7.0]
  tag :predeploy

  def change
    create_table :inbox_settings do |t|
      t.string :user_id, index: true, null: false
      t.boolean :use_signature, default: false, null: false
      t.string :signature, limit: 255
      t.boolean :use_out_of_office, default: false, null: false
      t.datetime :out_of_office_first_date
      t.datetime :out_of_office_last_date
      t.string :out_of_office_subject, limit: 255
      t.string :out_of_office_message, limit: 255
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.replica_identity_index
      t.timestamps
    end
  end
end
