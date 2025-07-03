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

class CreateSubmissionTexts < ActiveRecord::Migration[7.0]
  tag :predeploy

  def change
    create_table :submission_texts do |t|
      t.references :submission, null: false, foreign_key: true, index: false
      t.references :attachment, null: false, foreign_key: true, index: true
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false

      t.text :text, null: false, limit: 16_777_215
      t.integer :attempt, null: false, check: { constraint_name: "chk_attempt_positive", expression: "attempt > 0" }
      t.boolean :contains_images, null: false, default: false
      t.timestamps

      t.index %i[submission_id attachment_id attempt], unique: true, name: "index_on_sub_attach_attempt"
      t.replica_identity_index
    end
  end
end
