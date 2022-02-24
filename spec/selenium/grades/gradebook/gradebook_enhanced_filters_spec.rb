# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

require_relative "../pages/gradebook_page"
require_relative "../pages/gradebook_cells_page"
require_relative "../pages/gradebook_grade_detail_tray_page"
require_relative "../../helpers/gradebook_common"

describe "Enhanced Gradebook Filters" do
  describe "feature flag OFF" do
    include_context "in-process server selenium tests"
    include GradebookCommon
    include_context "late_policy_course_setup"

    before(:once) do
      Account.site_admin.disable_feature!(:enhanced_gradebook_filters)

      # create course with students, assignments, submissions and grades
      init_course_with_students(2)
      create_course_late_policy
      create_assignments
      make_submissions
      grade_assignments
    end

    before do
      user_session(@teacher)
      Gradebook.visit(@course)
    end

    it "Enhanced filters button is not visible", priority: "1" do
      expect(f("body")).not_to contain_jqcss('button:contains("Filters")')
    end
  end

  describe "feature flag ON" do
    include_context "in-process server selenium tests"
    include GradebookCommon
    include_context "late_policy_course_setup"

    before(:once) do
      Account.site_admin.enable_feature!(:enhanced_gradebook_filters)

      # create course with students, assignments, submissions and grades
      init_course_with_students(2)
      create_course_late_policy
      create_assignments
      make_submissions
      grade_assignments
    end

    before do
      user_session(@teacher)
      Gradebook.visit(@course)
    end

    it "Enhanced filters button is visible", priority: "1" do
      expect(fj('button:contains("Filters")')).to be_displayed
    end
  end
end
