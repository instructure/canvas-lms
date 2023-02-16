# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
require_relative "../helpers/groups_common"

describe "group navigation" do
  include_context "in-process server selenium tests"

  before do
    course_with_teacher_logged_in
    @group_category = @course.group_categories.create!(name: "Group Category")
    @group_1 = @course.groups.create!(group_category: @group_category, name: "group 1")
    @group_2 = @course.groups.create!(group_category: @group_category, name: "group 2")
  end

  context "as a teacher" do
    it "able to change groups on the homepage" do
      get "/groups/#{@group_1.id}"

      force_click("[data-testid='group-selector']")
      fj("li:contains('group 2')").click
      expect(fj("nav#breadcrumbs:contains('group 2')")).to be_present
    end

    it "able to change groups on non-homepage" do
      get "/groups/#{@group_1.id}/users"

      force_click("[data-testid='group-selector']")
      fj("li:contains('group 2')").click
      expect(fj("nav#breadcrumbs:contains('group 2')")).to be_present
    end
  end
end
