# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../../helpers/gradebook_common"
require_relative "../pages/gradebook_cells_page"
require_relative "../pages/gradebook_page"

# NOTE: We are aware that we're duplicating some unnecessary testcases, but this was the
# easiest way to review, and will be the easiest to remove after the feature flag is
# permanently removed. Testing both flag states is necessary during the transition phase.
shared_examples "Gradebook" do |ff_enabled|
  include_context "in-process server selenium tests"
  include GradebookCommon

  before :once do
    # Set feature flag state for the test run - this affects how the gradebook data is fetched, not the data setup
    if ff_enabled
      Account.site_admin.enable_feature!(:performance_improvements_for_gradebook)
    else
      Account.site_admin.disable_feature!(:performance_improvements_for_gradebook)
    end
  end

  context "pass/fail assignment grading" do
    before :once do
      init_course_with_students 1
      @assignment = @course.assignments.create!(grading_type: "pass_fail", points_possible: 0)
      @assignment.grade_student(@students[0], grade: "pass", grader: @teacher)
    end

    before do
      user_session(@teacher)
    end

    it "allows pass grade on assignments worth 0 points", priority: "1" do
      Gradebook.visit(@course)
      expect(Gradebook::Cells.get_grade(@students[0], @assignment)).to eq "Complete"
    end

    it "displays pass/fail correctly when total points possible is changed", priority: "1" do
      @assignment.update(points_possible: 1)
      Gradebook.visit(@course)
      expect(Gradebook::Cells.get_grade(@students[0], @assignment)).to eq "Complete"
    end
  end
end

describe "Gradebook" do
  it_behaves_like "Gradebook", true
  it_behaves_like "Gradebook", false
end
