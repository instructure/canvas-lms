# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../pages/admin_account_page"
require_relative "../pages/course_page"
require_relative "../../../factories/analytics_2_tool_factory"

describe "analytics in Canvas" do
  include_context "in-process server selenium tests"
  include AdminSettingsPage
  include CourseHomePage
  include Factories

  context "account nav menu" do
    before do
      @admin = account_admin_user(active_all: true)
      user_session(@admin)
    end

    it "with Analytics 1 enabled, displays the account analytics nav menu item" do
      skip unless defined? Analytics
      # enable Analytics 1
      @admin.account.update(allowed_services: "+analytics")
      visit_admin_settings_tab(@admin.account.id)

      expect(admin_left_nav_menu.text).to include("Analytics")
      expect(analytics_menu_item.attribute("href")).to include("/accounts/#{@admin.account.id}/analytics")
    end

    it "with Analytics 1 disabled, does not display account analytics nav menu item" do
      # Analytics1.0 is disabled
      @admin.account.update(allowed_services: "")
      visit_admin_settings_tab(@admin.account.id)

      expect(admin_left_nav_menu.text).not_to include("Analytics")
    end
  end

  context "Analytics 2.0 LTI installed" do
    before :once do
      @admin = account_admin_user(active_all: true)
      # Analytics1.0 is enabled for all tests by default
      @admin.account.update(allowed_services: "+analytics")
      # add the analytics 2 LTI to the account
      analytics_2_tool_factory
      @tool_id = @admin.account.context_external_tools.first.id
      # create a course, @teacher and student in course
      @course = course_with_teacher(
        account: @admin.account,
        course_name: "A New Course",
        name: "Teacher1",
        active_all: true
      ).course
      @student = student_in_course(
        course: @course,
        name: "First Student",
        active_all: true
      ).user
    end

    describe "course menu for teacher role" do
      before do
        user_session(@teacher)
      end

      it "with FF enabled, displays Analytics 2 menu in course nav menu" do
        @course.root_account.enable_feature!(:analytics_2)
        visit_course_home_page(@course.id)

        expect(course_nav_menu.text).to include("Analytics 2")
        expect(course_nav_analytics2_link.attribute("href")).to include("/courses/#{@course.id}/external_tools/#{@tool_id}")
        expect(course_nav_menu.text).not_to include("View Course Analytics")
      end
    end

    describe "course people page for teacher role" do
      context "with A2 FF enabled" do
        before do
          user_session(@teacher)
          @course.root_account.enable_feature!(:analytics_2)
        end

        it "displays Analytics 2 link in manage user menu" do
          visit_course_people_page(@course.id)
          manage_user_link(@student.name).click

          expect(manage_user_options_list.text).to include("Analytics 2")
          expect(manage_user_analytics_2_link.attribute("href"))
            .to include("/courses/#{@course.id}/external_tools/#{@tool_id}?launch_type=student_context_card&student_id=#{@student.id}")
        end
      end

      context "with A2 FF disabled" do
        before do
          user_session(@teacher)
          @course.root_account.disable_feature!(:analytics_2)
        end

        it "displays Analytics 1 link in manage user menu" do
          skip unless defined? Analytics
          visit_course_people_page(@course.id)
          manage_user_link(@student.name).click

          expect(manage_user_options_list.text).to include("Analytics")
          expect(manage_user_options_list.text).not_to include("Analytics 2")
          expect(manage_user_analytics_1_link.attribute("href")).to include("/courses/#{@course.id}/analytics/users/#{@student.id}")
        end
      end
    end

    # unskip in ADMIN-2959
    # describe "student role" do
    #   before :each do
    #     @course.root_account.enable_feature!(:analytics_2)
    #     user_session(@student)
    #   end

    #   it "with FF enabled, displays Analytics 2 link on course nav" do
    #     visit_course_home_page(@course.id)

    #     expect(course_nav_menu.text).to include('Analytics 2')
    #   end

    #   it "with FF enabled, displays Analytics 2 link on self profile page" do
    #     visit_course_people_page(@course.id, @student.id)

    #     expect(user_profile_page_actions.text).to include('Analytics 2')
    #     expect(user_profile_actions_analytics_2_link.attribute('href')).
    #     to include("/courses/#{@course.id}/external_tools/#{@tool_id}?launch_type=student_context_card&student_id=#{@student.id}")
    #   end
    # end

    describe "permission disabled for teacher role" do
      # no permissions are required for analytics 2 for course home page links
      # view_all_grades permission is required in analytics 2 for student tray and user analytics
      context "with A2 FF enabled" do
        before do
          @course.root_account.enable_feature!(:analytics_2)
          @course.account.role_overrides.create!(permission: :view_all_grades, role: teacher_role, enabled: false)
          user_session(@teacher)
        end

        it "does not display any Analytics link on manage user menu" do
          visit_course_people_page(@course.id)
          manage_user_link(@student.name).click

          expect(manage_user_options_list.text).not_to include("Analytics 2")
        end
      end

      context "with A2 FF disabled" do
        before do
          @course.account.role_overrides.create!(permission: :view_analytics, role: teacher_role, enabled: false)
          @course.root_account.disable_feature!(:analytics_2)
          user_session(@teacher)
        end

        it "does not display any Analytics link on course home page" do
          visit_course_home_page(@course.id)

          expect(course_options.text).not_to include("View Course Analytics")
          expect(course_nav_menu.text).not_to include("View Course Analytics")
        end

        it "does not display any Analytics link on manage user menu" do
          visit_course_people_page(@course.id)
          manage_user_link(@student.name).click

          expect(manage_user_options_list.text).not_to include("Analytics")
        end
      end
    end
  end
end
