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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/users/user_dashboard" do
  it "should render" do
    course_with_student
    view_context
    assign(:courses, [@course])
    assign(:enrollments, [@enrollment])
    assign(:group_memberships, [])
    assign(:topics, [])
    assign(:upcoming_events, [])
    assign(:stream_items, [])

    render "users/user_dashboard"
    expect(response).not_to be_nil
  end

  it "should show announcements to users with no enrollments" do
    user_factory
    view_context
    assign(:courses, [])
    assign(:enrollments, [])
    assign(:group_memberships, [])
    assign(:topics, [])
    assign(:upcoming_events, [])
    assign(:stream_items, [])
    assign(:announcements, [AccountNotification.create(:message => 'hi', :start_at => Date.today - 1.day,
                                                          :end_at => Date.today + 2.days,
                                                          :subject => "My Global Announcement", :account => Account.default)])
    render "users/user_dashboard"
    expect(response.body).to match /My Global Announcement/
  end
end
