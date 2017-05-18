#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'conversation_message' do
  before :once do
    @teacher_enrollment = course_with_teacher
    user_enrollment = student_in_course
    conversation = @teacher.initiate_conversation([@user])
    @message = conversation.add_message("this
is
a
message")
    account = User.find(user_enrollment.user_id).account
    @message.context_type = account.class.to_s
    @message.context_id = account.id
  end

  let(:notification_name) { :conversation_message }
  let(:asset) { @message }

  include_examples "a message"

  context ".email" do
    let(:path_type) { :email }

    it "doesnt have trailing erb closures" do
      @message.stubs(:attachments).returns([
        stub("attachment",
             display_name: "FileName", readable_size: "1MB", id: 42,
             context: @teacher_enrollment.course, uuid: "abcdef123456")
      ])
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.html_body).not_to match(/%>/)
    end
  end
end