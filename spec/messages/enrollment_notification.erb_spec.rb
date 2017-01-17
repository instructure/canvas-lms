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

describe 'enrollment_notification' do
  before :once do
    course_with_student(active_all: true)
  end

  let(:notification_name) { :enrollment_notification }
  let(:asset) { @enrollment }

  include_examples "a message"

  context ".email" do
    let(:path_type) { :email }

    context "creation_pending student" do
      before :once do
        @student.communication_channels.create!(path: 'jacob@instructure.com')
      end

      let(:asset) { @enrollment }

      it "should render" do
        generate_message(:enrollment_notification, :email, asset)
      end
    end
  end
end
