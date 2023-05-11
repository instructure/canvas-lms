# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../views_helper"

describe "users/user_dashboard" do
  it "renders" do
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

  it "shows announcements to users with no enrollments" do
    user_factory
    view_context
    assign(:courses, [])
    assign(:enrollments, [])
    assign(:group_memberships, [])
    assign(:topics, [])
    assign(:upcoming_events, [])
    assign(:stream_items, [])
    assign(:announcements, [AccountNotification.create(message: "hi",
                                                       start_at: Time.zone.today - 1.day,
                                                       end_at: Time.zone.today + 2.days,
                                                       user: User.create!,
                                                       subject: "My Global Announcement",
                                                       account: Account.default)])
    render "users/user_dashboard"
    expect(response.body).to match(/My\sGlobal\sAnnouncement/)
    expect(response.body).to match(/(This\sis\sa\smessage\sfrom\s<b>Default\sAccount)/)
  end

  it "shows announcements (site_admin) to users with no enrollments" do
    user_factory
    view_context
    assign(:courses, [])
    assign(:enrollments, [])
    assign(:group_memberships, [])
    assign(:topics, [])
    assign(:upcoming_events, [])
    assign(:stream_items, [])
    assign(:announcements, [AccountNotification.create(message: "hi",
                                                       start_at: Time.zone.today - 1.day,
                                                       end_at: Time.zone.today + 2.days,
                                                       user: User.create!,
                                                       subject: "My Global Announcement",
                                                       account: Account.site_admin)])
    render "users/user_dashboard"
    expect(response.body).to match(/(This\sis\sa\smessage\sfrom\s<b>Canvas\sAdministration)/)
  end
end
