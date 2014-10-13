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

describe 'group_membership_rejected.sms' do
  it "should render" do
    course_model(:reusable => true)
    user_model
    @group = @course.groups.create!(:name => "student group")
    @object = @group.add_user(@user)
    expect(@object.user).to eql(@user)
    expect(@object.group).to eql(@group)
    expect(@object.group.context).to eql(@course)
    generate_message(:group_membership_rejected, :sms, @object)
  end
end
