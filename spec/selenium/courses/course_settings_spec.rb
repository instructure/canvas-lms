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

require_relative "../common"
require_relative "pages/course_settings_page"

describe "course settings" do
  include_context "in-process server selenium tests"
  include CourseSettingsPage

  before do
    course_with_teacher_logged_in limit_privileges_to_course_section: false
    @account = @course.account
  end

  it "shows unused tabs to teachers" do
    get "/courses/#{@course.id}/settings"
    wait_for_ajaximations
    expect(ff("#section-tabs .section.section-hidden").count).to be > 0
  end

  context "k5 subjects" do
    before do
      @account.enable_as_k5_account!
    end

    it "shows a Back to Subject button that sends the user to the course home path" do
      get "/courses/#{@course.id}/settings"
      expect(f("#back_to_subject")).to be_displayed
      expect(f("#back_to_subject")).to have_attribute("href", course_path(@course.id))
    end

    it "shows the course name" do
      get "/courses/#{@course.id}/settings"
      name = f(".k5-heading-course-name")
      expect(name).to be_displayed
      expect(name.text).to eq @course.name
    end

    it "shows the course alt name if it exists" do
      @course.alt_name = "the alt name"
      @course.save!
      get "/courses/#{@course.id}/settings"
      name = f(".k5-heading-course-name")
      expect(name).to be_displayed
      expect(name.text).to eq @course.alt_name
    end

    it "provides sync to homeroom and homeroom selection" do
      @course.update!(homeroom_course: true, name: "homeroom1")
      orig_teacher = @teacher
      course_with_teacher(user: orig_teacher, course_name: "homeroom2")
      @course.update!(homeroom_course: true)
      course_with_teacher_logged_in(user: orig_teacher)

      get "/courses/#{@course.id}/settings"

      sync_checkbox = f(".sync_enrollments_from_homeroom_checkbox")
      expect(sync_checkbox).to be_displayed

      sync_checkbox.click

      homeroom_selection = f("#course_homeroom_course_id")
      expect(homeroom_selection).not_to be_nil
      expect(homeroom_selection).to be_displayed

      homeroom_selection.click
      options = ff("#course_homeroom_course_id option").map { |e| e.text.strip }
      expect(options).to include "homeroom1"
      expect(options).to include "homeroom2"
    end
  end

  context "considering homeroom courses" do
    before do
      @account.enable_as_k5_account!
      @course.homeroom_course = true
      @course.save!
    end

    it "hides most tabs if set" do
      get "/courses/#{@course.id}/settings"
      expect(ff("#course_details_tabs > ul li").length).to eq 2
      expect(f("#course_details_tab")).to be_displayed
      expect(f("#sections_tab")).to be_displayed
    end

    it "shows synced subjects" do
      @homeroom = @course
      subject1 = course_factory(course_name: "Synced Subject 1", account: @account)
      subject2 = course_factory(course_name: "Synced Subject 2", account: @account)
      subject1.homeroom_course_id = @homeroom.id
      subject1.sync_enrollments_from_homeroom = true
      subject1.save!
      subject2.homeroom_course_id = @homeroom.id
      subject2.sync_enrollments_from_homeroom = true
      subject2.save!

      get "/courses/#{@homeroom.id}/settings"
      expect(f(".coursesettings")).to include_text("This homeroom syncs enrollments and subject start/end dates to: Synced Subject 1, Synced Subject 2")
    end
  end

  describe("Integrations tab") do
    let(:course) { @course }

    context "with the MSFT sync flag on" do
      before { course.root_account.enable_feature!(:microsoft_group_enrollments_syncing) }

      it "displays the course settings tab" do
        get "/courses/#{course.id}/settings"
        expect(f("#integrations_tab")).to be_displayed
      end
    end
  end

  describe "course details" do
    def test_select_standard_for(context)
      grading_standard_for context
      get "/courses/#{@course.id}/settings"

      f(".grading_standard_checkbox").click unless is_checked(".grading_standard_checkbox")
      f(".edit_letter_grades_link").click
      f(".find_grading_standard_link").click
      wait_for_ajaximations

      fj(".grading_standard_select:visible a").click
      fj("button.select_grading_standard_link:visible").click
      f(".done_button").click
      wait_for_new_page_load(submit_form("#course_form"))

      @course.reload
      expect(@course.grading_standard).to eq(@standard)
    end

    context "as a ta" do
      before do
        course_with_ta_logged_in(course: @course)
      end

      it "shows the correct course status when published" do
        get "/courses/#{@course.id}/settings"
        expect(f("#course-status").text).to eq "Course is Published"
      end

      it "shows the correct course status when unpublished" do
        @course.workflow_state = "claimed"
        @course.save!
        get "/courses/#{@course.id}/settings"
        expect(f("#course-status").text).to eq "Course is Unpublished"
      end
    end

    it "shows the correct status with a tooltip when published and graded submissions" do
      course_with_student_submissions({ submission_points: true })
      get "/courses/#{@course.id}/settings"
      course_status = f("#course-status")
      expect(course_status.text).to eq "Course is Published"
      expect(course_status).to have_attribute("title", "You cannot unpublish this course if there are graded student submissions")
    end

    context "archived grading schemes" do
      before do
        Account.site_admin.enable_feature!(:grading_scheme_updates)
        Account.site_admin.enable_feature!(:archived_grading_schemes)
        @active_grading_standard = @course.grading_standards.create!(title: "Active Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "active")
        @archived_grading_standard = @course.grading_standards.create!(title: "Archived Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
        @account_grading_standard = @account.grading_standards.create!(title: "Account Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "active")
      end

      it "does not show archived grading schemes" do
        get "/courses/#{@course.id}/settings"
        f(".grading_standard_checkbox").click unless is_checked(".grading_standard_checkbox")
        f("[data-testid='grading-schemes-selector-dropdown']").click
        expect(f("[data-testid='grading-schemes-selector-option-#{@active_grading_standard.id}']")).to include_text(@active_grading_standard.title)
        expect(f("[data-testid='grading-schemes-selector-dropdown-form']")).not_to contain_css("[data-testid='grading-schemes-selector-option-#{@archived_grading_standard.id}']")
      end

      it "shows archived grading schemes if it is the course default and is auto-selected on page load" do
        @course.update!(grading_standard_id: @archived_grading_standard.id)
        get "/courses/#{@course.id}/settings"
        f(".grading_standard_checkbox").click unless is_checked(".grading_standard_checkbox")
        expect(f("[data-testid='grading-schemes-selector-dropdown']").attribute("value")).to eq(@archived_grading_standard.title)
        f("[data-testid='grading-schemes-selector-dropdown']").click
        expect(f("[data-testid='grading-schemes-selector-option-#{@course.grading_standard.id}']")).to include_text(@course.grading_standard.title)
      end

      it "doesn't let you edit an account level grading scheme" do
        get "/courses/#{@course.id}/settings"
        f(".grading_standard_checkbox").click unless is_checked(".grading_standard_checkbox")
        f("[data-testid='grading-schemes-selector-dropdown']").click
        expect(f("[data-testid='grading-schemes-selector-option-#{@account_grading_standard.id}']")).to include_text(@account_grading_standard.title)
        f("[data-testid='grading-schemes-selector-option-#{@account_grading_standard.id}']").click
        f("[data-testid='grading-schemes-selector-view-button']").click
        wait_for_ajaximations
        expect(f("[data-testid='grading-scheme-#{@account_grading_standard.id}-edit-button']").attribute("disabled")).to eq("true")
      end

      it "only lets you edit the name of an in-use grading-scheme" do
        @course.update!(grading_standard_id: @active_grading_standard.id)
        get "/courses/#{@course.id}/settings"
        f(".grading_standard_checkbox").click unless is_checked(".grading_standard_checkbox")
        f("[data-testid='grading-schemes-selector-dropdown']").click
        f("[data-testid='grading-schemes-selector-option-#{@course.grading_standard.id}']").click
        f("[data-testid='grading-schemes-selector-view-button']").click
        wait_for_ajaximations
        f("[data-testid='grading-scheme-#{@course.grading_standard.id}-edit-button']").click
        wait_for_ajaximations
        f("[data-testid='grading-scheme-name-input']").send_keys(" Edited")
        f("[data-testid='grading-scheme-edit-modal-update-button']").click
        wait_for_ajaximations
        f("[data-testid='grading-scheme-view-modal-close-button']").click
        expect(f("[data-testid='grading-schemes-selector-dropdown']").attribute("title")).to eq("Active Grading Scheme Edited")
      end

      it "shows all archived grading schemes when on course settings scheme management modal" do
        archived_gs1 = @course.grading_standards.create!(title: "Archived Grading Scheme", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
        archived_gs2 = @course.grading_standards.create!(title: "Archived Grading Scheme 2", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
        archived_gs3 = @course.grading_standards.create!(title: "Archived Grading Scheme 3", data: { "A" => 0.9, "F" => 0 }, scaling_factor: 1.0, points_based: false, workflow_state: "archived")
        get "/courses/#{@course.id}/settings"
        f(".grading_standard_checkbox").click unless is_checked(".grading_standard_checkbox")
        f("[data-testid='manage-all-grading-schemes-button']").click
        wait_for_ajaximations
        expect(f("[data-testid='grading-scheme-#{archived_gs1.id}-name']")).to include_text(archived_gs1.title)
        expect(f("[data-testid='grading-scheme-#{archived_gs2.id}-name']")).to include_text(archived_gs2.title)
        expect(f("[data-testid='grading-scheme-#{archived_gs3.id}-name']")).to include_text(archived_gs3.title)
      end
    end

    it "allows selection of existing course grading standard" do
      skip "FOO-4220" # TODO: re-enable this test before merging EVAL-3171
      test_select_standard_for @course
    end

    it "allows selection of existing account grading standard" do
      skip "FOO-4220" # TODO: re-enable this test before merging EVAL-3171
      test_select_standard_for @course.root_account
    end

    it "toggles more options correctly" do
      more_options_text = "more options"
      fewer_options_text = "fewer options"
      get "/courses/#{@course.id}/settings"

      more_options_link = f(".course_form_more_options_link")
      expect(more_options_link.text).to eq more_options_text
      more_options_link.click
      extra_options = f(".course_form_more_options")
      expect(extra_options).to be_displayed
      expect(more_options_link.text).to eq fewer_options_text
      more_options_link.click
      wait_for_ajaximations
      expect(extra_options).not_to be_displayed
      expect(more_options_link.text).to eq more_options_text
    end

    it "shows the self enrollment code and url once enabled" do
      a = Account.default
      a.courses << @course
      a.settings[:self_enrollment] = "manually_created"
      a.save!
      get "/courses/#{@course.id}/settings"
      f(".course_form_more_options_link").click
      wait_for_ajaximations
      f("#course_self_enrollment").click
      wait_for_ajaximations
      wait_for_new_page_load { submit_form("#course_form") }

      code = @course.reload.self_enrollment_code
      expect(code).not_to be_nil
      # this element _can_ still be on the page if the post hasn't finished yet,
      # so make sure it's been populated before continuing
      wait = Selenium::WebDriver::Wait.new(timeout: 5)
      wait.until do
        el = f(".self_enrollment_message")
        el.present? &&
          !el.text.nil? &&
          el.text != ""
      end
      message = f(".self_enrollment_message")
      expect(message).to include_text(code)
      expect(message).not_to include_text("self_enrollment_code")
    end

    it "does not show the self enrollment code and url for blueprint templates even if enabled" do
      a = Account.default
      a.courses << @course
      a.settings[:self_enrollment] = "manually_created"
      a.save!
      @course.update(self_enrollment: true)
      MasterCourses::MasterTemplate.set_as_master_course(@course)
      get "/courses/#{@course.id}/settings"
      expect(f(".self_enrollment_message")).to_not be_displayed
    end

    it "enables announcement limit if show announcements enabled" do
      get "/courses/#{@course.id}/settings"

      more_options_link = f(".course_form_more_options_link")
      more_options_link.click
      wait_for_ajaximations

      # Show announcements and limit setting elements
      expect(course_show_announcements_on_home_page_label).to be_displayed
      home_page_announcement_limit = f("#course_home_page_announcement_limit")
      expect(is_checked(course_show_announcements_on_home_page)).not_to be_truthy
      expect(home_page_announcement_limit).to be_disabled

      course_show_announcements_on_home_page.click
      expect(home_page_announcement_limit).not_to be_disabled
    end

    describe "course paces setting" do
      describe "when the course paces feature flag is enabled" do
        before do
          @account.enable_feature!(:course_paces)
        end

        it "displays the course paces setting (and if checked, the caution text)" do
          get "/courses/#{@course.id}/settings"

          expect(element_exists?(".course-paces-row")).to be_truthy

          caution_text = "Course Pacing is in active development."
          course_paces_checkbox = f("#course_enable_course_paces")

          course_paces_checkbox.click
          wait_for_ajaximations
          expect(f(".course-paces-row")).to include_text caution_text

          course_paces_checkbox.click
          wait_for_ajaximations
          expect(f(".course-paces-row")).not_to include_text caution_text
        end
      end

      describe "when the course paces feature flag is disabled" do
        before do
          @account.disable_feature!(:course_paces)
        end

        it "does not display the course paces setting" do
          get "/courses/#{@course.id}/settings"

          expect(element_exists?(".course-paces-row")).to be_falsey
        end
      end
    end

    it "shows participation by default" do
      get "/courses/#{@course.id}/settings"

      expect(element_exists?(".course-participation-row")).to be_truthy
      expect(element_exists?("#availability_options_container")).to be_truthy
    end

    it "checks if it is a k5 course should not show the fields" do
      @account.enable_as_k5_account!
      get "/courses/#{@course.id}/settings"

      more_options_link = f(".course_form_more_options_link")
      more_options_link.click
      wait_for_ajaximations

      expect(element_exists?("#course_show_announcements_on_home_page")).to be_falsey
      expect(element_exists?("#course_allow_student_discussion_topics")).to be_falsey
      expect(element_exists?("#course_hide_distribution_graphs")).to be_falsey
      expect(element_exists?("#course_lock_all_announcements")).to be_falsey
    end

    context "restrict_quantitative_data dependent settings" do
      it "shows by default" do
        get "/courses/#{@course.id}/settings"
        more_options_link = f(".course_form_more_options_link")
        more_options_link.click
        wait_for_ajaximations
        expect(f("#course_hide_distribution_graphs")).to be_present
        expect(f("#course_hide_final_grades")).to be_present
      end

      it "is not shown when both restrict_quantitative_data course setting and feature flags are ON" do
        @course.root_account.enable_feature! :restrict_quantitative_data
        @course.restrict_quantitative_data = true
        @course.save!

        get "/courses/#{@course.id}/settings"
        more_options_link = f(".course_form_more_options_link")
        more_options_link.click
        wait_for_ajaximations
        expect(f("body")).not_to contain_jqcss("#course_hide_distribution_graphs")
        expect(f("#course_hide_final_grades")).to be_present
        # Verify that other parts of the settings are not visilbe when they shouldn't be
        expect(f("#tab-sections").css_value("display")).to eq "none"
      end

      it "is shown when only restrict_quantitative_data account locked setting and feature flags are ON" do
        root_account = @course.root_account
        root_account.enable_feature! :restrict_quantitative_data
        root_account.settings[:restrict_quantitative_data] = { value: true, locked: true }
        root_account.save!

        get "/courses/#{@course.id}/settings"
        more_options_link = f(".course_form_more_options_link")
        more_options_link.click
        wait_for_ajaximations
        expect(f("#course_hide_distribution_graphs")).to be_present
        expect(f("#course_hide_final_grades")).to be_present
      end

      it "is shown when restrict_quantitative_data feature flag is on but course setting is off" do
        @course.root_account.enable_feature! :restrict_quantitative_data
        @course.restrict_quantitative_data = false
        @course.save!

        get "/courses/#{@course.id}/settings"
        more_options_link = f(".course_form_more_options_link")
        more_options_link.click
        wait_for_ajaximations
        expect(f("#course_hide_distribution_graphs")).to be_present
        expect(f("#course_hide_final_grades")).to be_present
      end
    end
  end

  describe "course items" do
    def admin_cog(id)
      f(id).find_element(:css, ".admin-links").displayed?
    rescue Selenium::WebDriver::Error::NoSuchElementError
      false
    end

    it "does not show cog menu for disabling or moving on home nav item" do
      get "/courses/#{@course.id}/settings#tab-navigation"
      expect(admin_cog("#nav_edit_tab_id_0")).to be_falsey
    end

    it "changes course details" do
      course_name = "new course name"
      course_code = "new course-101"
      locale_text = "English (United States)"
      time_zone_value = "Central Time (US & Canada)"

      get "/courses/#{@course.id}/settings"

      course_form = f("#course_form")
      name_input = course_form.find_element(:id, "course_name")
      replace_content(name_input, course_name)
      code_input = course_form.find_element(:id, "course_course_code")
      replace_content(code_input, course_code)
      click_option("#course_locale", locale_text)
      click_option("#course_time_zone", time_zone_value, :value)
      f(".course_form_more_options_link").click
      wait_for_ajaximations
      expect(f(".course_form_more_options")).to be_displayed
      wait_for_new_page_load { submit_form(course_form) }

      @course.reload
      expect(@course.name).to eq course_name
      expect(@course.course_code).to eq course_code
      expect(@course.locale).to eq "en"
      expect(@course.time_zone.name).to eq time_zone_value
    end

    it "only allows less resrictive options in Customize Syllabus visibility" do
      get "/courses/#{@course.id}/settings"
      click_option("#course_course_visibility", "institution", :value)
      f("#course_custom_course_visibility").click
      expect(ff("select[name*='course[syllabus_visibility_option]']")[0].text).to eq "Institution\nPublic"
      click_option("#course_course_visibility", "course", :value)
      expect(ff("select[name*='course[syllabus_visibility_option]']")[0].text).to eq "Course\nInstitution\nPublic"
    end

    it "allows any option in Customize Files visibility" do
      get "/courses/#{@course.id}/settings"
      click_option("#course_course_visibility", "institution", :value)
      f("#course_custom_course_visibility").click
      expect(ff("select[name*='course[files_visibility_option]']")[0].text).to eq "Course\nInstitution\nPublic"
      click_option("#course_course_visibility", "course", :value)
      expect(ff("select[name*='course[files_visibility_option]']")[0].text).to eq "Course\nInstitution\nPublic"
    end

    it "disables from Course Navigation tab", priority: "1" do
      get "/courses/#{@course.id}/settings#tab-navigation"
      ff(".al-trigger")[0].click
      ff(".icon-x")[0].click
      wait_for_ajaximations
      f("#nav_form button.btn.btn-primary").click
      wait_for_ajaximations
      enter_student_view
      wait_for_ajaximations
      get "/courses/#{@course.id}/settings#tab-navigation"
      wait_for_ajaximations
      expect(f("#content")).not_to contain_link("Home")
    end

    describe "move dialog" do
      it "returns focus to cog menu button when disabling an item" do
        get "/courses/#{@course.id}/settings#tab-navigation"
        cog_menu_button = ff(".al-trigger")[2]
        cog_menu_button.click # open the menu
        ff(".disable_nav_item_link")[2].click # click "Disable"
        check_element_has_focus(cog_menu_button)
      end
    end

    it "adds a section" do
      section_name = "new section"
      get "/courses/#{@course.id}/settings#tab-sections"

      section_input = f("#course_section_name")
      expect(section_input).to be_displayed
      replace_content(section_input, section_name)
      submit_form("#add_section_form")
      wait_for_ajaximations
      new_section = ff("#sections > .section")[1]
      expect(new_section).to include_text(section_name)
    end

    it "deletes a section" do
      add_section("Delete Section")
      get "/courses/#{@course.id}/settings#tab-sections"

      body = f("body")
      expect(body).to include_text("Delete Section")

      f(".delete_section_link").click
      expect(driver.switch_to.alert).not_to be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(ff("#sections > .section").count).to eq 1
    end

    it "edits a section" do
      edit_text = "Section Edit Text"
      add_section("Edit Section")
      get "/courses/#{@course.id}/settings#tab-sections"

      body = f("body")
      expect(body).to include_text("Edit Section")

      f(".edit_section_link").click
      section_input = f("#course_section_name_edit")
      expect(section_input).to be_displayed
      replace_content(section_input, edit_text)
      section_input.send_keys(:return)
      wait_for_ajaximations
      expect(ff("#sections > .section")[0]).to include_text(edit_text)
    end
  end

  context "right sidebar" do
    it "allows leaving student view" do
      enter_student_view
      stop_link = f("#masquerade_bar .leave_student_view")
      expect(stop_link).to include_text "Leave Student View"
      stop_link.click
      expect(displayed_username).to eq(@teacher.name)
    end

    it "allows resetting student view" do
      @fake_student_before = @course.student_view_student
      enter_student_view
      reset_link = f("#masquerade_bar .reset_test_student")
      expect(reset_link).to include_text "Reset Student"
      reset_link.click
      wait_for_ajaximations
      @fake_student_after = @course.student_view_student
      expect(@fake_student_before.id).not_to eq @fake_student_after.id
    end

    it "does not include student view student in the statistics count" do
      @fake_student = @course.student_view_student
      get "/courses/#{@course.id}/settings"
      expect(fj(".summary tr:nth(0)").text).to match(/Students:\s*None/)
    end

    it "shows the count of custom role enrollments" do
      teacher_role = custom_teacher_role("teach")
      student_role = custom_student_role("weirdo")

      custom_ta_role("taaaa")
      course_with_student(course: @course, role: student_role)
      student_role.deactivate!
      course_with_teacher(course: @course, role: teacher_role)
      get "/courses/#{@course.id}/settings"
      expect(fj(".summary tr:nth(1)").text).to match(/weirdo \(inactive\):\s*1/)
      expect(fj(".summary tr:nth(3)").text).to match(/teach:\s*1/)
      expect(fj(".summary tr:nth(5)").text).to match(/taaaa:\s*None/)
    end

    it "shows publish/unpublish buttons in sidebar and no status badge if user can change publish state" do
      course_with_teacher_logged_in(active_all: true)
      get "/courses/#{@course.id}/settings"
      expect(f("#course_status_form")).to be_present
      expect(f("#course_status_form #continue_to")).to have_attribute("value", "#{course_url(@course)}/settings")
      expect(f("#content")).not_to contain_css("#course-status")
    end

    it "shows only published status badge if user can't change publish status" do
      course_with_ta_logged_in(active_all: true)
      get "/courses/#{@course.id}/settings"
      expect(f("#course-status")).to be_present
      expect(f("#content")).not_to contain_css("#course_status_form")
    end
  end

  it "restricts student access inputs be hidden" do
    @account.settings[:restrict_student_future_view] = { locked: true, value: true }
    @account.save!

    get "/courses/#{@course.id}/settings"

    expect(f("#course_restrict_student_past_view")).to_not be_displayed
    expect(f("#course_restrict_student_future_view")).to_not be_displayed
  end

  it "disables editing settings if :manage rights are not granted" do
    user_factory(active_all: true)
    user_session(@user)
    role = custom_account_role("role", account: @account)
    @account.role_overrides.create!(permission: "read_course_content", role:, enabled: true)
    @account.role_overrides.create!(permission: "manage_content", role:, enabled: false)
    @course.account.account_users.create!(user: @user, role:)

    get "/courses/#{@course.id}/settings"

    ffj("#tab-details input:visible").each do |input|
      expect(input).to be_disabled
    end
    expect(f("#content")).not_to contain_css(".course_form button[type='submit']")
  end

  it "lets a sub-account admin edit enrollment term" do
    term = Account.default.enrollment_terms.create!(name: "some term")
    sub_a = Account.default.sub_accounts.create!
    account_admin_user(active_all: true, account: sub_a)
    user_session(@admin)

    @course = sub_a.courses.create!
    get "/courses/#{@course.id}/settings"

    click_option("#course_enrollment_term_id", term.name)

    submit_form("#course_form")

    expect(@course.reload.enrollment_term).to eq term
  end

  context "restrict_quantitative_data setting" do
    it "is not visible if the feature flag is off" do
      @account.disable_feature!(:restrict_quantitative_data)
      @account.save!
      get "/courses/#{@course.id}/settings"
      expect(f("body")).not_to contain_jqcss("input[data-testid='restrict-quantitative-data-checkbox']")
    end

    context "when the flag is on" do
      before do
        @account.enable_feature!(:restrict_quantitative_data)
        @account.save!
      end

      it "The RQD setting is not visible if the course setting is off and the account setting is off" do
        @account.settings[:restrict_quantitative_data] = { locked: false, value: false }
        @course.settings = @course.settings.merge(restrict_quantitative_data: false)
        @account.save
        @course.save
        get "/courses/#{@course.id}/settings"
        expect(f("body")).not_to contain_jqcss("input[data-testid='restrict-quantitative-data-checkbox']")
      end

      it "the setting is not changeable if the account setting is on and locked and the course is on" do
        @account.settings[:restrict_quantitative_data] = { locked: true, value: true }
        @course.settings = @course.settings.merge(restrict_quantitative_data: true)
        @account.save
        @course.save
        get "/courses/#{@course.id}/settings"
        expect(f("input[data-testid='restrict-quantitative-data-checkbox']")).to be_disabled
        expect(is_checked(f("input[data-testid='restrict-quantitative-data-checkbox']"))).to be_truthy
      end

      it "the setting is changeable if the account setting is on and locked but the course is off" do
        @account.settings[:restrict_quantitative_data] = { locked: true, value: true }
        @course.settings = @course.settings.merge(restrict_quantitative_data: false)
        @account.save
        @course.save
        get "/courses/#{@course.id}/settings"
        expect(f("input[data-testid='restrict-quantitative-data-checkbox']")).not_to be_disabled
        expect(is_checked(f("input[data-testid='restrict-quantitative-data-checkbox']"))).to be_falsey
      end

      it "the setting is changeable if the account setting is on and unlocked" do
        @account.settings[:restrict_quantitative_data] = { locked: false, value: true }
        @account.save
        get "/courses/#{@course.id}/settings"
        expect(f("input[data-testid='restrict-quantitative-data-checkbox']")).not_to be_disabled
        expect(is_checked(f("input[data-testid='restrict-quantitative-data-checkbox']"))).to be_falsey
      end

      it "the setting is changeable if the account setting is off but the course setting is on" do
        @account.settings[:restrict_quantitative_data] = { locked: false, value: false }
        @course.settings = @course.settings.merge(restrict_quantitative_data: true)
        @account.save
        @course.save
        get "/courses/#{@course.id}/settings"
        expect(f("input[data-testid='restrict-quantitative-data-checkbox']")).not_to be_disabled
        expect(is_checked(f("input[data-testid='restrict-quantitative-data-checkbox']"))).to be_truthy
      end

      it "the setting is not disabled if prevent course availability editing is enabled" do
        @account.settings[:restrict_quantitative_data] = { locked: false, value: true }
        @account.settings[:prevent_course_availability_editing_by_teachers] = true
        @account.save
        get "/courses/#{@course.id}/settings"
        expect(f("input[data-testid='restrict-quantitative-data-checkbox']")).not_to be_disabled
      end
    end
  end

  context "link validator" do
    before do
      Setting.set("link_validator_poll_timeout", 100)
      Setting.set("link_validator_poll_timeout_initial", 100)
    end

    it "validates all the links" do
      allow_any_instance_of(CourseLinkValidator).to receive(:reachable_url?).and_return(false) # don't actually ping the links for the specs

      course_with_teacher_logged_in
      attachment_model

      bad_url = "http://www.notarealsitebutitdoesntmattercauseimstubbingitanwyay.com"
      bad_url2 = "/courses/#{@course.id}/file_contents/baaaad"
      html = <<~HTML
        <a href="#{bad_url}">Bad absolute link</a>
        <img src="#{bad_url2}">Bad file link</a>
        <img src="/courses/#{@course.id}/file_contents/#{CGI.escape(@attachment.full_display_path)}">Ok file link</a>
        <a href="/courses/#{@course.id}/quizzes">Ok other link</a>
      HTML

      @course.syllabus_body = html
      @course.save!

      bank = @course.assessment_question_banks.create!(title: "bank")
      aq = bank.assessment_questions.create!(question_data: { "question_name" => "test question",
                                                              "question_text" => html,
                                                              "answers" => [{ "id" => 1 }, { "id" => 2 }] })

      assmnt = @course.assignments.create!(title: "assignment", description: html)
      event = @course.calendar_events.create!(title: "event", description: html)
      topic = @course.discussion_topics.create!(title: "discussion title", message: html)
      mod = @course.context_modules.create!(name: "some module")
      mod.add_item(type: "external_url", url: bad_url, title: "pls view")
      page = @course.wiki_pages.create!(title: "wiki", body: html)
      quiz = @course.quizzes.create!(title: "quiz1", description: html)

      qq = quiz.quiz_questions.create!(question_data: aq.question_data.merge("question_name" => "other test question"))

      get "/courses/#{@course.id}/settings"

      expect_new_page_load { f(".validator_link").click }

      f("#link_validator_wrapper button").click
      wait_for_ajaximations
      run_jobs

      wait_for_ajaximations
      expect(f("#all-results")).to be_displayed

      expect(f("#all-results .alert")).to include_text("Found 17 broken links")

      result_links = ff("#all-results .result h2 a")
      expect(result_links.map { |link| link.text.strip }).to match_array([
                                                                           "Course Syllabus",
                                                                           aq.question_data[:question_name],
                                                                           qq.question_data[:question_name],
                                                                           assmnt.title,
                                                                           event.title,
                                                                           topic.title,
                                                                           mod.name,
                                                                           quiz.title,
                                                                           page.title
                                                                         ])
    end

    it "is able to filter links to unpublished content" do
      course_with_teacher_logged_in

      active = @course.assignments.create!(title: "blah")
      unpublished = @course.assignments.create!(title: "blah")
      unpublished.unpublish!
      deleted = @course.assignments.create!(title: "blah")
      deleted.destroy

      active_link = "/courses/#{@course.id}/assignments/#{active.id}"
      unpublished_link = "/courses/#{@course.id}/assignments/#{unpublished.id}"
      deleted_link = "/courses/#{@course.id}/assignments/#{deleted.id}"

      @course.syllabus_body = <<~HTML
        <a href='#{active_link}'>link</a>
        <a href='#{unpublished_link}'>unpublished link</a>
        <a href='#{deleted_link}'>deleted link</a>
      HTML
      @course.save!
      page = @course.wiki_pages.create!(title: "wikiii", body: %(<a href='#{unpublished_link}'>unpublished link</a>))

      get "/courses/#{@course.id}/link_validator"
      wait_for_ajaximations
      move_to_click("#link_validator_wrapper button")
      wait_for_ajaximations
      run_jobs

      wait_for_ajaximations
      expect(f("#all-results")).to be_displayed

      expect(f("#all-results .alert")).to include_text("Found 3 broken links")
      syllabus_result = ff("#all-results .result").detect { |r| r.text.include?("Course Syllabus") }
      expect(syllabus_result).to include_text("unpublished link")
      expect(syllabus_result).to include_text("deleted link")
      page_result = ff("#all-results .result").detect { |r| r.text.include?(page.title) }
      expect(page_result).to include_text("unpublished link")

      # hide the unpublished results
      move_to_click("label[for=show_unpublished]")
      wait_for_ajaximations

      expect(f("#all-results .alert")).to include_text("Found 1 broken link")
      expect(ff("#all-results .result h2 a").count).to eq 1
      result = f("#all-results .result")
      expect(result).to include_text("Course Syllabus")
      expect(result).to include_text("deleted link")

      # show them again
      move_to_click("label[for=show_unpublished]")

      expect(f("#all-results .alert")).to include_text("Found 3 broken links")
      page_result = ff("#all-results .result").detect { |r| r.text.include?(page.title) }
      expect(page_result).to include_text("unpublished link")
    end
  end
end
