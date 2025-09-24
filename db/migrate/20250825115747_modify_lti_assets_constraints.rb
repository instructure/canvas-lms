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

class ModifyLtiAssetsConstraints < ActiveRecord::Migration[7.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    check_sql = <<~SQL.squish
      (
        (attachment_id IS NOT NULL)::int +
        (submission_attempt IS NOT NULL)::int +
        (discussion_entry_version_id IS NOT NULL)::int
      ) <= 1
    SQL

    add_check_constraint :lti_assets,
                         check_sql,
                         name: "chk_one_asset_locator_present",
                         validate: false,
                         if_not_exists: true
    validate_constraint :lti_assets, "chk_one_asset_locator_present"

    remove_check_constraint :lti_assets, name: "chk_attachment_id_or_submission_attempt_filled", if_exists: true
  end

  def down
    add_check_constraint :lti_assets, "(attachment_id IS NULL) <> (submission_attempt IS NULL)", name: "chk_attachment_id_or_submission_attempt_filled", if_not_exists: true
    remove_check_constraint :lti_assets, name: "chk_one_asset_locator_present", if_exists: true
  end
end
