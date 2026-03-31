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
#

describe DataFixup::AddAttachmentAssociationsToConversationMessages do
  before(:once) do
    @student = user_model
    @teacher = user_model
    @image = attachment_model(context: @student, folder: @student.conversation_attachments_folder)
    @video = attachment_model(context: @student, folder: @student.conversation_attachments_folder)
    conversation_model(sender: @student, recipients: [@teacher], body: "hi", attachment_ids: [@image.id, @video.id])
  end

  it "creates attachment associations for any attachment on conversation messages" do
    @message.attachment_associations.destroy_all

    DataFixup::AddAttachmentAssociationsToConversationMessages.new.run

    expect(@message.reload.attachment_associations.count).to eq 2
    expect(@message.attachment_associations.pluck(:user_id)).to eq [nil, nil]
    expect(@message.attachment_associations.pluck(:attachment_id)).to match_array [@image.id, @video.id]
    expect(@message.attachment_associations.pluck(:context_id)).to match_array [@message.id, @message.id]
    expect(@message.attachment_associations.pluck(:root_account_id)).to eq [@image.root_account_id, @video.root_account_id]
  end

  it "does not fail on attachments that don't exist anymore" do
    @message.update_columns(attachment_ids: "0,#{@video.id}")
    @message.attachment_associations.destroy_all

    DataFixup::AddAttachmentAssociationsToConversationMessages.new.run

    expect(@message.reload.attachment_associations.count).to eq 1
    expect(@message.attachment_associations.pluck(:user_id)).to eq [nil]
    expect(@message.attachment_associations.pluck(:attachment_id)).to match_array [@video.id]
    expect(@message.attachment_associations.pluck(:context_id)).to match_array [@message.id]
    expect(@message.attachment_associations.pluck(:root_account_id)).to eq [@video.root_account_id]
  end
end
