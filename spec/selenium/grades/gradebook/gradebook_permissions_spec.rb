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
require_relative "../pages/gradebook_page"

# NOTE: We are aware that we're duplicating some unnecessary testcases, but this was the
# easiest way to review, and will be the easiest to remove after the feature flag is
# permanently removed. Testing both flag states is necessary during the transition phase.
shared_examples "Gradebook - permissions" do |ff_enabled|
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

  context "as an admin" do
    let(:course) { Course.create! }

    it "displays for admins" do
      admin_logged_in

      Gradebook.visit(course)
      expect_no_flash_message :error
    end
  end

  context "as a ta" do
    def disable_view_all_grades
      RoleOverride.create!(role: ta_role,
                           permission: "view_all_grades",
                           context: Account.default,
                           enabled: false)
    end

    it "does not show gradebook after course conclude if view_all_grades disabled", priority: "1" do
      disable_view_all_grades
      concluded_course = course_with_ta_logged_in
      concluded_course.conclude
      Gradebook.visit(@course)
      expect(f("#unauthorized_message")).to be_displayed
    end
  end
end

describe "Gradebook - permissions" do
  it_behaves_like "Gradebook - permissions", true
  it_behaves_like "Gradebook - permissions", false
end
