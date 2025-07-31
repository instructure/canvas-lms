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

class AddSubmissionTypeToSubmissionTexts < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  tag :predeploy

  def change
    change_table :submission_texts, bulk: true do |t|
      t.string :submission_type unless column_exists?(:submission_texts, :submission_type)
    end

    change_column_null :submission_texts, :attachment_id, true

    add_index :submission_texts,
              :submission_id,
              algorithm: :concurrently,
              if_not_exists: true

    add_index :submission_texts,
              %i[submission_id attachment_id attempt],
              unique: true,
              name: "index_on_sub_attempt_attach",
              where: "attachment_id IS NOT NULL",
              algorithm: :concurrently,
              if_not_exists: true

    add_index :submission_texts,
              %i[submission_id attempt],
              unique: true,
              name: "index_on_sub_attempt",
              where: "attachment_id IS NULL",
              algorithm: :concurrently,
              if_not_exists: true

    remove_index :submission_texts,
                 column: %i[submission_id attachment_id attempt],
                 name: "index_on_sub_attach_attempt",
                 algorithm: :concurrently,
                 if_exists: true
  end
end
