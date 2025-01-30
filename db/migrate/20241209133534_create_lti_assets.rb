# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class CreateLtiAssets < ActiveRecord::Migration[7.1]
  tag :predeploy

  def change
    create_table :lti_assets do |t|
      t.uuid :uuid, null: false, index: { unique: true }

      t.references :attachment, null: false, foreign_key: true
      t.references :submission, null: false, foreign_key: true
      t.index %i[attachment_id submission_id], unique: true

      t.string :workflow_state, limit: 255, null: false, default: "active"
      t.timestamps

      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.replica_identity_index
    end
  end
end
