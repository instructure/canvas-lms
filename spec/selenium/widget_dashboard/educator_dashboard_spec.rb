# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require_relative "page_objects/widget_dashboard_page"

describe "educator dashboard", :ignore_js_errors, custom_timeout: 30 do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage

  before :once do
    @course = course_factory(active_all: true, course_name: "Test Course")
    @teacher = user_factory(active_all: true, name: "Test Teacher")
    @course.enroll_teacher(@teacher, enrollment_state: :active)
    Account.default.enable_feature!(:educator_dashboard)
  end

  before do
    user_session(@teacher)
  end

  it "renders all three educator placeholder widgets" do
    go_to_dashboard

    expect(widget_container("educator-announcement-creation")).to be_displayed
    expect(widget_container("educator-todo-list")).to be_displayed
    expect(widget_container("educator-content-quality")).to be_displayed
  end
end
