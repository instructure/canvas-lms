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

describe 'appointment_canceled_by_user.email' do
  include MessagesCommon

  it "should render" do
    user = user_model
    course_with_student(course: @course, active_enrollment: true)
    appointment_participant_model(:participant => user, :updating_user => @user)
    generate_message(:appointment_canceled_by_user, :email, @event,
                     :user => @user, :data => {:updating_user => user,
                                               :cancel_reason => "because"})

    expect(@message.subject).to include('some title')
    expect(@message.body).to include('some title')
    expect(@message.body).to include('because')
    expect(@message.body).to include(user.name)
    expect(@message.body).to include(@course.name)
    expect(@message.body).to include("/appointment_groups/#{@appointment_group.id}")
  end

  it "should render for groups" do
    user = user_model
    @course = course_model
    cat = group_category
    user_model
    @group = cat.groups.create(:context => @course)
    @group.users << user << @user
    appointment_participant_model(:participant => @group, :course => @course, :updating_user => @user)
    @event.cancel_reason = 'just because'

    generate_message(:appointment_canceled_by_user, :email, @event,
                     :user => @user, :data => {:updating_user => user,
                                               :cancel_reason => "just because"})
    expect(@message.subject).to include('some title')
    expect(@message.body).to include('some title')
    expect(@message.body).to include('just because')
    expect(@message.body).to include(user.name)
    expect(@message.body).to include(@group.name)
    expect(@message.body).to include(@course.name)
    expect(@message.body).to include("/appointment_groups/#{@appointment_group.id}")
  end
end
