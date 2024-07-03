# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../common"

describe "PostMessage Listener" do
  include_context "in-process server selenium tests"

  before do
    course_with_teacher_logged_in
  end

  it "is handling toggleCourseNavigationMenu message", custom_timeout: 60 do
    # rubocop:disable Specs/NoExecuteScript
    get("/courses/#{@course.id}")

    body_classes = driver.find_element(:tag_name, "body").attribute("class")

    expect(body_classes).to include("course-menu-expanded")
    driver.execute_script('window.postMessage({subject: "toggleCourseNavigationMenu"}, "*")')

    body_classes = driver.find_element(:tag_name, "body").attribute("class")
    expect(body_classes).not_to include("course-menu-expanded")
    # rubocop:enable Specs/NoExecuteScript
  end
end
