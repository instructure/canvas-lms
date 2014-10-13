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

describe 'appointment_group_deleted.email' do
  it "should render" do
    course_with_student(:active_all => true)
    appointment_group_model(:contexts => [@course])

    generate_message(:appointment_group_deleted, :email, @appointment_group,
                     :user => @user, :data => {:cancel_reason => "because"})

    expect(@message.subject).to include('some title')
    expect(@message.body).to include('some title')
    expect(@message.body).to include('because')
    expect(@message.body).to include(@course.name)
  end
end
