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
#

class CreateSubmissionDraft < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    create_table :submission_drafts do |t|
      t.references :submission, foreign_key: true, index: true, null: false
      t.integer :submission_attempt, index: true, null: false
    end

    # Attachments can be cross shard, so we can't use a proper foreign key for them
    create_table :submission_draft_attachments do |t|
      t.references :submission_draft, foreign_key: true, index: true, null: false
      t.integer :attachment_id, limit: 8, index: true, null: false
    end

    add_index :submission_draft_attachments,
              [:submission_draft_id, :attachment_id],
              name: "index_submission_draft_and_attachment_unique",
              unique: true
  end
end
