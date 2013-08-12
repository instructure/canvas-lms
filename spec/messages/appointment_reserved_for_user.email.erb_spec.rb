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

describe 'appointment_reserved_for_user.email' do
  it "should render" do
    user = user_model
    appointment_participant_model(:participant => user)

    generate_message(:appointment_reserved_for_user, :email, @event,
                     :data => {:updating_user => @teacher})

    @message.subject.should include('some title')
    @message.body.should include('some title')
    @message.body.should include(@teacher.name)
    @message.body.should include(user.name)
    @message.body.should include(@course.name)
    @message.body.should include("/appointment_groups/#{@appointment_group.id}")
  end

  it "should render for groups" do
    user = user_model
    @course = course_model
    cat = group_category
    @group = cat.groups.create(:context => @course)
    @group.users << user
    appointment_participant_model(:participant => @group, :course => @course)

    generate_message(:appointment_reserved_for_user, :email, @event,
                     :data => {:updating_user => @teacher})

    @message.subject.should include('some title')
    @message.body.should include('some title')
    @message.body.should include(@teacher.name)
    @message.body.should include(user.name)
    @message.body.should include(@group.name)
    @message.body.should include(@course.name)
    @message.body.should include("/appointment_groups/#{@appointment_group.id}")
  end
end
