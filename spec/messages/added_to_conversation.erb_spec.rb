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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'added_to_conversation' do
  include MessagesCommon

  before :once do
    course_with_teacher
    student1 = student_in_course.user
    student2 = student_in_course.user
    student3 = student_in_course.user
    conversation = @teacher.initiate_conversation([student1, student2])
    conversation.add_message("some message")
    @event = conversation.add_participants([student3])
  end

  let(:notification_name) { :added_to_conversation }
  let(:asset) { @event }

  context ".email" do
    let(:path_type) { :email }
    it "should render" do
      generate_message(notification_name, path_type, asset)
    end
  end

  context ".sms" do
    let(:path_type) { :sms }
    it "should render" do
      generate_message(notification_name, path_type, asset)
    end
  end

  context ".summary" do
    let(:path_type) { :summary }
    it "should render" do
      generate_message(notification_name, path_type, asset)
    end
  end

  context ".twitter" do
    let(:path_type) { :twitter }
    it "should render" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.body).to be_present
    end
  end
end
