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

describe 'appointment_group_updated' do
  include MessagesCommon

  before :once do
    course_with_student(:active_all => true)
    @cat = @course.group_categories.create(:name => 'teh category')
    appointment_group_model(:contexts => [@course], :sub_context => @cat)
  end

  let(:notification_name) { :appointment_group_updated }
  let(:asset) { @appointment_group }
  let(:message_data) { { user: @user } }

  context ".email" do
    let(:path_type) { :email }
    it "should render" do
      msg = generate_message(notification_name, path_type, asset, message_data)
      expect(msg.subject).to include('some title')
      expect(msg.body).to include('some title')
      expect(msg.body).to include(@course.name)
      expect(msg.body).to include("/appointment_groups/#{@appointment_group.id}")
    end

    it "should render for groups" do
      msg = generate_message(notification_name, path_type, asset, message_data)
      expect(msg.body).to include(@cat.name)
    end
  end

  context ".sms" do
    let(:path_type) { :sms }
    it "should render" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.body).to include('some title')
    end
  end

  context ".summary" do
    let(:path_type) { :summary }
    it "should render" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.subject).to include('some title')
      expect(msg.body).to include('some title')
    end
  end

  context ".twitter" do
    let(:path_type) { :twitter }
    it "should render" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.body).to include('some title')
    end
  end
end
