#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'lib/data_fixup/fix_bulk_message_attachments.rb'

describe 'DataFixup::FixBulkMessageAttachments' do
  describe "up" do
    it "should work" do
      student_in_course(:active_all => true)
      attachment = attachment_model(:context => @user, :folder => @user.conversation_attachments_folder)
      root_message = Conversation.build_message @user, "hi all", :attachment_ids => [attachment.id]
      
      ConversationBatch.generate(root_message, 20.times.map{ user }, :sync)

      # ensure they aren't linked to the attachment
      AttachmentAssociation.where("context_id<>?", root_message).delete_all

      DataFixup::FixBulkMessageAttachments.run

      # yay
      expect(AttachmentAssociation.count).to eql 21
      ConversationMessage.all.each do |message|
        expect(message.attachments).to eq root_message.attachments
      end
    end
  end
end
