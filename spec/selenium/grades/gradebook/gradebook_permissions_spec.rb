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

require_relative '../../helpers/gradebook_common'

describe "gradebook - permissions" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  context "as an admin" do

    let(:course) { Course.create! }

    it "should display for users with only :view_all_grades permissions" do
      user_logged_in

      role = custom_account_role('CustomAdmin', account: Account.default)
      RoleOverride.create!(role: role,
                           permission: 'view_all_grades',
                           context: Account.default,
                           enabled: true)
      AccountUser.create!(user: @user,
                          account: Account.default,
                          role: role)

      get "/courses/#{course.id}/gradebook"
      expect_no_flash_message :error
    end

    it "should display for users with only :manage_grades permissions" do
      user_logged_in
      role = custom_account_role('CustomAdmin', account: Account.default)
      RoleOverride.create!(role: role,
                           permission: 'manage_grades',
                           context: Account.default,
                           enabled: true)
      AccountUser.create!(user: @user,
                          account: Account.default,
                          role: role)

      get "/courses/#{course.id}/gradebook"
      expect_no_flash_message :error
    end
  end

  context "as a ta" do

    def disable_view_all_grades
      RoleOverride.create!(role: ta_role,
                            permission: 'view_all_grades',
                            context: Account.default,
                            enabled: false)
    end

    it "should not show gradebook after course conclude if view_all_grades disabled", priority: "1", test_id: 417601 do
      disable_view_all_grades
      concluded_course = course_with_ta_logged_in
      concluded_course.conclude
      get "/courses/#{@course.id}/gradebook"
      expect(f('#unauthorized_message')).to be_displayed
    end
  end
end
