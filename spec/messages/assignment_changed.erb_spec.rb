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

describe 'assignment_changed' do
  before :once do
    assignment_model(:title => "Quiz 1")
  end

  let(:notification_name) { :assignment_changed }
  let(:asset) { @assignment }

  context ".email" do
    let(:path_type) { :email }
    it "should render" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.subject).to match(/Quiz 1/)
      expect(msg.body).to match(/Quiz 1/)
      expect(msg.body).to match(Regexp.new(@course.name))
      expect(msg.body).to match(/#{HostUrl.protocol}:\/\//)
      expect(msg.body).to match(/courses\/#{@assignment.context_id}\/assignments\/#{@assignment.id}/)
    end
  end

  context ".sms" do
    let(:path_type) { :sms }
    it "should render" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.body).to match(/Quiz 1/)
      expect(msg.body).to match(Regexp.new(@course.name))
    end
  end

  context ".summary" do
    let(:path_type) { :summary }
    it "should render" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.subject).to match(/Quiz 1/)
      expect(msg.subject).to match(Regexp.new(@course.name))
    end
  end
end