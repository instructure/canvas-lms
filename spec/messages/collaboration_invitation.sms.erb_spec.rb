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

describe 'collaboration_invitation.sms' do
  it "should render" do
    course_with_student
    @collaboration = @course.collaborations.create!(:user => @user, :title => "my collab")
    @object = @collaboration.collaborators.create!(:user => @user)
    expect(@object.collaboration).not_to be_nil
    expect(@object.collaboration.context).not_to be_nil
    expect(@object.user).not_to be_nil
    generate_message(:collaboration_invitation, :sms, @object)
  end
end
