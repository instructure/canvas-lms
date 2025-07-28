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

class AddSubmissionAttemptToLtiAsset < ActiveRecord::Migration[7.2]
  tag :predeploy
  disable_ddl_transaction!

  def change
    change_table :lti_assets, bulk: true do |t|
      t.integer :submission_attempt
      t.change_null :attachment_id, true
    end
    add_check_constraint :lti_assets,
                         "(attachment_id IS NULL) != (submission_attempt IS NULL)",
                         name: "chk_attachment_id_or_submission_attempt_filled",
                         if_not_exists: true,
                         validate: false
    validate_constraint :lti_assets, "chk_attachment_id_or_submission_attempt_filled"

    add_index :lti_assets,
              %i[submission_id attachment_id],
              unique: true,
              algorithm: :concurrently,
              where: "submission_id IS NOT NULL and attachment_id IS NOT NULL",
              name: "index_lti_assets_unique_submission_id_and_attachment_id",
              if_not_exists: true

    add_index :lti_assets,
              %i[submission_id submission_attempt],
              unique: true,
              algorithm: :concurrently,
              where: "submission_id IS NOT NULL and submission_attempt IS NOT NULL",
              name: "index_lti_assets_unique_submission_id_and_submission_attempt",
              if_not_exists: true

    remove_index :lti_assets,
                 [:attachment_id, :submission_id],
                 unique: true,
                 algorithm: :concurrently,
                 where: "submission_id IS NOT NULL",
                 if_exists: true
  end
end
