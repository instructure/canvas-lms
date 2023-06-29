# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
describe DataFixup::FixMaybeAttachments do
  before do
    @video_attachment = attachment_model(content_type: "video/mp4", media_entry_id: "maybe", file_state: "available", workflow_state: "attached")
    @image_attachment = attachment_model(content_type: "image/png", media_entry_id: "maybe", file_state: "available", workflow_state: "attached")
    @audio_attachment = attachment_model(content_type: "audio/mp3", media_entry_id: "maybe", file_state: "available", workflow_state: "attached")
    @hidden_attachment = attachment_model(content_type: "audio/mp3", media_entry_id: "maybe", file_state: "hidden", workflow_state: "attached")
    @processed_attachment = attachment_model(content_type: "audio/mp3", media_entry_id: "something", file_state: "available", workflow_state: "attached")
    @unattached_attachment = attachment_model(content_type: "audio/mp3", media_entry_id: "maybe", file_state: "available", workflow_state: "unattached")
  end

  it "only affects Attachments with video and audio media_entry_id 'maybe' and workflow type is not unattached" do
    expect(DataFixup::FixMaybeAttachments.attachments).to include(@video_attachment, @audio_attachment)
  end

  it "includes hidden Attachments with video and audio media_entry_id 'maybe' and workflow type is not unattached" do
    expect(DataFixup::FixMaybeAttachments.attachments).to include(@hidden_attachment)
  end
end
