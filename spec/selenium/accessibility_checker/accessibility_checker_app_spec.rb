# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

describe "Accessibility Checker", :ignore_js_errors do
  include_context "in-process server selenium tests"

  context "As a teacher" do
    before do
      course_with_teacher_logged_in
    end

    context "Accessibility navigation tab" do
      it "displays the Accessibility tab when feature flags are enabled" do
        @course.account.enable_feature!(:a11y_checker)
        @course.enable_feature!(:a11y_checker_eap)

        get "/courses/#{@course.id}"

        accessibility_tab = f("#section-tabs a.accessibility")
        expect(accessibility_tab).to be_displayed
        expect(accessibility_tab.text).to eq("Accessibility")
      end

      it "does not display the Accessibility tab when account-level feature flag is disabled" do
        @course.account.disable_feature!(:a11y_checker)
        @course.enable_feature!(:a11y_checker_eap)

        get "/courses/#{@course.id}"

        expect(f("#section-tabs")).not_to contain_css("a.accessibility")
      end

      it "does not display the Accessibility tab when course-level feature flag is disabled" do
        @course.account.enable_feature!(:a11y_checker)
        @course.disable_feature!(:a11y_checker_eap)

        get "/courses/#{@course.id}"

        expect(f("#section-tabs")).not_to contain_css("a.accessibility")
      end

      it "navigates to the Accessibility page when tab is clicked" do
        @course.account.enable_feature!(:a11y_checker)
        @course.enable_feature!(:a11y_checker_eap)

        get "/courses/#{@course.id}"

        accessibility_tab = f("#section-tabs a.accessibility")
        expect_new_page_load { accessibility_tab.click }

        expect(driver.current_url).to include("/courses/#{@course.id}/accessibility")
      end
    end

    context "Check Accessibility button on course home" do
      it "displays the Check Accessibility button when feature flags are enabled" do
        @course.account.enable_feature!(:a11y_checker)
        @course.enable_feature!(:a11y_checker_eap)

        get "/courses/#{@course.id}"

        accessibility_btn = f("#course_check_accessibility_btn")
        expect(accessibility_btn).to be_displayed
        expect(accessibility_btn.text).to include("Check Accessibility")
      end

      it "does not display the Check Accessibility button when account-level feature flag is disabled" do
        @course.account.disable_feature!(:a11y_checker)
        @course.enable_feature!(:a11y_checker_eap)

        get "/courses/#{@course.id}"

        expect(f("#content")).not_to contain_css("#course_check_accessibility_btn")
      end

      it "does not display the Check Accessibility button when course-level feature flag is disabled" do
        @course.account.enable_feature!(:a11y_checker)
        @course.disable_feature!(:a11y_checker_eap)

        get "/courses/#{@course.id}"

        expect(f("#content")).not_to contain_css("#course_check_accessibility_btn")
      end

      it "navigates to the Accessibility page when button is clicked" do
        @course.account.enable_feature!(:a11y_checker)
        @course.enable_feature!(:a11y_checker_eap)

        get "/courses/#{@course.id}"

        accessibility_btn = f("#course_check_accessibility_btn")
        expect_new_page_load { accessibility_btn.click }

        expect(driver.current_url).to include("/courses/#{@course.id}/accessibility")
      end
    end
  end

  context "As a student" do
    before do
      course_with_student_logged_in
    end

    context "Accessibility navigation tab" do
      it "does not display the Accessibility tab even when feature flags are enabled" do
        @course.account.enable_feature!(:a11y_checker)
        @course.enable_feature!(:a11y_checker_eap)

        get "/courses/#{@course.id}"

        expect(f("#section-tabs")).not_to contain_css("a.accessibility")
      end

      it "does not allow direct access to the Accessibility page" do
        @course.account.enable_feature!(:a11y_checker)
        @course.enable_feature!(:a11y_checker_eap)

        get "/courses/#{@course.id}/accessibility"

        # Should be redirected or see unauthorized
        expect(driver.current_url).not_to include("/courses/#{@course.id}/accessibility")
      end
    end

    context "Check Accessibility button on course home" do
      it "does not display the Check Accessibility button even when feature flags are enabled" do
        @course.account.enable_feature!(:a11y_checker)
        @course.enable_feature!(:a11y_checker_eap)

        get "/courses/#{@course.id}"

        expect(f("#content")).not_to contain_css("#course_check_accessibility_btn")
      end
    end
  end

  context "All courses page (/courses)" do
    before do
      course_with_teacher_logged_in
    end

    it "does not display the Accessibility column when feature flags are disabled" do
      @course.account.disable_feature!(:a11y_checker)

      get "/courses"

      expect(f("#my_courses_table")).not_to contain_css(".course-list-accessibility-column")
    end

    it "does not display the Accessibility column when feature flags are enabled" do
      @course.account.enable_feature!(:a11y_checker)
      @course.enable_feature!(:a11y_checker_eap)

      get "/courses"

      expect(f("#my_courses_table")).not_to contain_css(".course-list-accessibility-column")
    end
  end
end
