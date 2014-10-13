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

describe 'appointment_deleted_for_user.sms' do
  it "should render" do
    user = user_model(:name => 'bob')
    appointment_participant_model(:participant => user)

    generate_message(:appointment_deleted_for_user, :sms, @event,
                     :data => {:updating_user => @teacher,
                                       :cancel_reason => "just because"})

    expect(@message.body).to include('some title')
  end

  it "should render for groups" do
    user = user_model(:name => 'bob')
    @course = course_model
    cat = group_category
    @group = cat.groups.create(:context => @course)
    @group.users << user
    appointment_participant_model(:participant => @group, :course => @course)

    generate_message(:appointment_deleted_for_user, :sms, @event,
                     :data => {:updating_user => @teacher,
                                       :cancel_reason => "just because"})

    expect(@message.body).to include('some title')
  end
end
