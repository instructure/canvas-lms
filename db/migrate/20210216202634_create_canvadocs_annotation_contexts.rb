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

class CreateCanvadocsAnnotationContexts < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    create_table :canvadocs_annotation_contexts do |t|
      t.belongs_to :attachment, foreign_key: true, limit: 8, index: true, null: false
      t.belongs_to :submission, foreign_key: true, limit: 8, index: true, null: false
      t.belongs_to :root_account, index: true, foreign_key: { to_table: :accounts }, limit: 8, null: false

      t.string :launch_id, null: false
      t.integer :submission_attempt
      t.timestamps

      t.index(
        [:attachment_id, :submission_attempt, :submission_id],
        name: "index_attachment_attempt_submission",
        unique: true
      )
    end
  end
end
