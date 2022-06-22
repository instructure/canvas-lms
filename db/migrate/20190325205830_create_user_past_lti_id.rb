# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

class CreateUserPastLtiId < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    create_table :user_past_lti_ids do |t|
      t.references :user, foreign_key: true, index: true, null: false
      t.integer :context_id, null: false, limit: 8
      t.string :context_type, null: false, limit: 255
      t.string :user_uuid, null: false, limit: 255
      t.text :user_lti_id, null: false
      t.string :user_lti_context_id, limit: 255, index: true
    end
    add_index :user_past_lti_ids, %w[user_id context_id context_type], name: "user_past_lti_ids_index", unique: true
  end
end
