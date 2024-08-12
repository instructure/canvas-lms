# frozen_string_literal: true

#
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

require "spec_helper"

describe DataFixup::ResetFileVerifiers do
  it "resets uuid for all non-deleted files" do
    attachment = attachment_model
    deleted_attachment = attachment_model(workflow_state: :deleted, deleted_at: Time.zone.now, file_state: "deleted")
    former_uuid = attachment.uuid
    former_deleted_uuid = deleted_attachment.uuid
    DataFixup::ResetFileVerifiers.run
    attachment.reload
    deleted_attachment.reload
    new_uuid = attachment.uuid
    expect(new_uuid).not_to eq(former_uuid)
    expect(new_uuid).not_to be_nil
    expect(deleted_attachment.reload.uuid).to eq(former_deleted_uuid)
  end
end
