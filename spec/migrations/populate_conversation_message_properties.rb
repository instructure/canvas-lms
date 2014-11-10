#
# Copyright (C) 2011 Instructure, Inc.
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
require 'lib/data_fixup/populate_conversation_message_properties.rb'

describe 'DataFixup::PopulateConversationMessageProperties' do
  describe "run" do
    it "should work" do
      student_in_course
      u = @user

      c1 = u.initiate_conversation([User.create])
      m1 = c1.add_message("no attachment")

      c2 = u.initiate_conversation([User.create])
      a = attachment_model(:context => u, :folder => u.conversation_attachments_folder)
      m2 = c2.add_message("attachment!", :attachment_ids => [a.id])

      c3 = u.initiate_conversation([User.create])
      m3 = c3.add_message("forwarded attachment!", :forwarded_message_ids => [m2.id])

      c4 = u.initiate_conversation([User.create])
      m4 = c4.add_message("doubly forwarded attachment!", :forwarded_message_ids => [m3.id])

      c5 = u.initiate_conversation([User.create])
      mc = MediaObject.new
      mc.media_type = 'audio'
      mc.media_id = 'asdf'
      mc.context = mc.user = u
      mc.save
      m5 = c5.add_message("media_comment!", :media_comment => mc)

      c6 = u.initiate_conversation([User.create])
      m6 = c6.add_message("forwarded media_comment!", :forwarded_message_ids => [m5.id])

      c7 = u.initiate_conversation([User.create])
      m7 = c7.add_message("doubly forwarded media_comment!", :forwarded_message_ids => [m6.id])

      ConversationParticipant.update_all("has_attachments = (id = #{c2.id}), has_media_objects = (id = #{c5.id})")
      ConversationMessage.update_all("has_attachments = NULL, has_media_objects = NULL")

      DataFixup::PopulateConversationMessageProperties.run

      [c1, c2, c3, c4, c5, c6, c7].each(&:reload)
      [m1, m2, m3, m4, m5, m6, m7].each(&:reload)

      expect(c1.has_attachments?).to be_falsey
      expect(c1.has_media_objects?).to be_falsey
      expect(m1.read_attribute(:has_attachments)).to be_falsey
      expect(m1.read_attribute(:has_media_objects)).to be_falsey
      expect(m1.attachment_ids).to be_nil
      expect(m1.media_comment).to be_nil

      expect(c2.has_attachments?).to be_truthy
      expect(c2.has_media_objects?).to be_falsey
      expect(m2.read_attribute(:has_attachments)).to be_truthy
      expect(m2.read_attribute(:has_media_objects)).to be_falsey
      expect(m2.attachment_ids).to eql a.id.to_s

      expect(c3.has_attachments?).to be_truthy
      expect(c3.has_media_objects?).to be_falsey
      expect(m3.read_attribute(:has_attachments)).to be_truthy
      expect(m3.read_attribute(:has_media_objects)).to be_falsey
      expect(m3.attachment_ids).to be_nil # it's on the forwarded message

      expect(c4.has_attachments?).to be_truthy
      expect(c4.has_media_objects?).to be_falsey
      expect(m4.read_attribute(:has_attachments)).to be_truthy
      expect(m4.read_attribute(:has_media_objects)).to be_falsey
      expect(m4.attachment_ids).to be_nil

      expect(c5.has_attachments?).to be_falsey
      expect(c5.has_media_objects?).to be_truthy
      expect(m5.read_attribute(:has_attachments)).to be_falsey
      expect(m5.read_attribute(:has_media_objects)).to be_truthy
      expect(m5.media_comment).to eql mc

      expect(c6.has_attachments?).to be_falsey
      expect(c6.has_media_objects?).to be_truthy
      expect(m6.read_attribute(:has_attachments)).to be_falsey
      expect(m6.read_attribute(:has_media_objects)).to be_truthy
      expect(m6.media_comment).to be_nil

      expect(c7.has_attachments?).to be_falsey
      expect(c7.has_media_objects?).to be_truthy
      expect(m7.read_attribute(:has_attachments)).to be_falsey
      expect(m7.read_attribute(:has_media_objects)).to be_truthy
      expect(m7.media_comment).to be_nil
    end
  end
end
