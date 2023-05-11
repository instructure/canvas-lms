# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class CreateMicrosoftSyncPartialSyncChanges < ActiveRecord::Migration[6.0]
  tag :predeploy

  def change
    create_table :microsoft_sync_partial_sync_changes do |t|
      t.references :course, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.string :enrollment_type, null: false

      t.timestamps

      t.index %i[course_id user_id enrollment_type],
              unique: true,
              name: "index_microsoft_sync_partial_sync_changes_course_user_enroll"

      t.index [:root_account_id, :id],
              unique: true,
              name: "index_microsoft_sync_partial_sync_changes_replica_identity"
    end
    set_replica_identity(:microsoft_sync_partial_sync_changes, :index_microsoft_sync_partial_sync_changes_replica_identity)
  end
end
