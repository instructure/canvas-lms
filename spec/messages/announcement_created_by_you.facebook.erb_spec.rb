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

describe 'announcement_created_by_you.facebook' do
  it "should render" do
    announcement_model
    @object = @a
    @message = generate_message(:announcement_created_by_you, :facebook, @object)
    @message.subject.should == "Canvas Alert"
    @message.url.should match(/\/courses\/\d+\/announcements\/\d+/)
    @message.body.should match(/\/courses\/\d+\/announcements\/\d+/)
  end
end
