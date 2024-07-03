# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

class UpdateAutoCaptionStatusConstraint < ActiveRecord::Migration[7.0]
  tag :predeploy
  disable_ddl_transaction!

  def change
    remove_check_constraint :media_objects, name: "chk_auto_caption_status_enum", if_exists: true

    DataFixup::NullOutAutoCaptionStatus.run
    add_check_constraint :media_objects, "auto_caption_status IN ('complete', 'processing', 'failed_initial_validation', 'failed_handoff', 'failed_request', 'non_english_captions', 'failed_captions', 'failed_to_pull')", name: "chk_auto_caption_status_enum", validate: false

    validate_check_constraint :media_objects, name: "chk_auto_caption_status_enum"
  end
end
