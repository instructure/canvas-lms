#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe 'new_announcement' do
  include MessagesCommon

  before :once do
    announcement_model
  end

  let(:notification_name) { :new_announcement }
  let(:asset) { @a }

  context ".email" do
    let(:path_type) { :email }
    it "should render" do
      generate_message(notification_name, path_type, asset)
      expect(@message.subject).to eq "value for title: value for name"
      expect(@message.url).to match(/\/courses\/\d+\/announcements\/\d+/)
      expect(@message.body).to match(/\/courses\/\d+\/announcements\/\d+/)
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
      expect(@message.subject).to eq "value for title: value for name"
      expect(@message.url).to match(/\/courses\/\d+\/announcements\/\d+/)
      expect(@message.body.strip).to eq "value for message"
    end
  end

  context ".twitter" do
    let(:path_type) { :twitter }
    it "should render" do
      generate_message(notification_name, path_type, asset)
      expect(@message.subject).to eq "Canvas Alert"
      expect(@message.url).to match(/\/courses\/\d+\/announcements\/\d+/)
      expect(@message.body).to include("Canvas Alert - Announcement: value for title")
    end
  end
end
