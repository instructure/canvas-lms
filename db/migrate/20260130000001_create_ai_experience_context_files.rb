# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class CreateAiExperienceContextFiles < ActiveRecord::Migration[8.0]
  tag :predeploy

  def change
    create_table :ai_experience_context_files do |t|
      t.references :ai_experience, null: false, foreign_key: true
      t.references :attachment, null: false, foreign_key: true, index: true
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.integer :position
      t.timestamps
      t.replica_identity_index

      t.index [:ai_experience_id, :attachment_id], unique: true, name: "index_ai_exp_context_files_on_exp_and_attachment"
      t.index [:ai_experience_id, :position], name: "index_ai_exp_context_files_on_exp_and_position"
    end
  end
end
