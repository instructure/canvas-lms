# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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
#

require_relative "../common"

describe "users" do
  include_context "in-process server selenium tests"

  context "logins" do
    it "allows setting passwords for new pseudonyms" do
      admin = User.create!
      Account.site_admin.account_users.create!(user: admin)
      user_session(admin)

      @user = User.create!
      course_factory.enroll_student(@user)

      get "/users/#{@user.id}"
      pseudonym_form = f("#edit_pseudonym_form")
      f(".add_pseudonym_link").click
      wait_for_ajaximations
      pseudonym_form.find_element(:css, "#pseudonym_unique_id").send_keys("new_user")
      pseudonym_form.find_element(:css, "#pseudonym_password").send_keys("qwertyuiop")
      pseudonym_form.find_element(:css, "#pseudonym_password_confirmation").send_keys("qwertyuiop")
      submit_form(pseudonym_form)
      wait_for_ajaximations

      new_login = f(".login:not(.blank)")
      expect(new_login).not_to be_nil
      expect(new_login.find_element(:css, ".account_name").text).not_to be_blank
      pseudonym = Pseudonym.by_unique_id("new_user").first
      expect(pseudonym.valid_password?("qwertyuiop")).to be_truthy
    end
  end

  context "page views" do
    before do
      course_with_admin_logged_in
      @student = student_in_course.user
      Setting.set("enable_page_views", "db")
    end

    it "validates a basic page view" do
      page_view(user: @student, course: @course, url: "assignments", user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36", http_method: "get")
      get "/users/#{@student.id}"
      rows = ff("#page_view_results tr")
      expect(rows.count).to eq 1
      page_view = rows.first
      expect(page_view).to include_text("Chrome")
      expect(page_view).to include_text("assignments")
      expect(f("#page_view_results")).not_to contain_css("tr [name='IconCheckMark']") # should not have a participation
    end

    it "validates page view with a participation" do
      page_view(user: @student, course: @course, participated: true)
      get "/users/#{@student.id}"
      expect(f("#page_view_results [name='IconCheckMark']")).to be_displayed
    end

    it "validates a page view url" do
      second_student_name = "test student for page views"
      get "/users/#{@student.id}"
      page_view(user: @student, course: @course, participated: true, url: student_in_course(name: second_student_name).user.id.to_s, user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36", http_method: "get")
      refresh_page # in order to get the generated page view
      page_view_url = f("#page_view_results a")
      second_student = User.where(name: second_student_name).first
      expect(page_view_url.text).to eq second_student.id.to_s
      expect_new_page_load { page_view_url.click }
      expect(f(".user_details .name").text).to eq second_student.name
      expect(f("#page_view_results")).not_to contain_css("tr") # validate the second student has no page views
    end

    it "validates all page views were loaded" do
      page_views_count = 30
      page_views_count.times { |i| page_view(user: @student, course: @course, url: ("%03d" % i).to_s) }
      get "/users/#{@student.id}"
      wait_for_ajaximations
      scroll_page_to_bottom
      driver.execute_script("$('#scrollContainer').scrollTop($('#scrollContainer')[0].scrollHeight);")
      wait_for(method: nil, timeout: 0.5) { f("#paginatedView-loading").displayed? }
      # wait for loading spinner to finish
      wait_for_no_such_element { f(".paginatedView-loading") }
      expect(ff("#page_view_results tr").length).to eq page_views_count
    end

    it "filters by date" do
      old_date = DateTime.new(2022, 2, 10).beginning_of_day
      page_view(user: @student, course: @course, url: "recent", created_at: old_date + 1.day + 2.hours)
      page_view(user: @student, course: @course, url: "older", created_at: old_date + 1.hour)
      get "/users/#{@student.id}"
      wait_for_ajaximations
      expect(ff("#page_view_results tr").first.text).to include "recent"
      replace_content(f("[data-testid='inputQueryDate']"), old_date.year.to_s + "-" + old_date.month.to_s + "-" + old_date.day.to_s)
      driver.action.send_keys(:tab).perform
      wait_for_ajaximations
      expect(ff("#page_view_results tr").first.text).to include "older"
      match = f("#page_views_csv_link")["href"].match(/start_time=([^&]+)/)
      expect(match[1]).to include old_date.year.to_s + "-0" + old_date.month.to_s
    end
  end

  context "admin merge" do
    def setup_user_merge(from_user, into_user)
      get "/users/#{from_user.id}/admin_merge"
      f("#manual_user_id").send_keys(into_user.id)
      expect_new_page_load { f('button[type="submit"]').click }
    end

    def reload_users(users)
      users.each(&:reload)
    end

    def submit_merge
      expect_new_page_load { f("#prepare_to_merge").click }
      expect_new_page_load { f('button[type="submit"]').click }
    end

    def validate_login_info(user_id)
      expect(f("#login_information")).to include_text(user_id)
    end

    before do
      @student_1_id = "student1@example.com"
      @student_2_id = "student2@example.com"

      course_with_admin_logged_in
      @student_1 = User.create!(name: "Student One")
      @student_1.register!
      @student_1.pseudonyms.create!(unique_id: @student_1_id, password: "asdfasdf", password_confirmation: "asdfasdf")
      @course.enroll_user(@student_1).accept!

      @student_2 = User.create!(name: "Student Two")
      @student_2.register!
      @student_2.pseudonyms.create!(unique_id: @student_2_id, password: "asdfasdf", password_confirmation: "asdfasdf")
      @course.enroll_user(@student_2).accept!
      @users = [@student_1, @student_2]
    end

    it "merges user a with user b" do
      setup_user_merge(@student_2, @student_1)
      submit_merge
      reload_users(@users)
      expect(@student_1.workflow_state).to eq "registered"
      expect(@student_2.workflow_state).to eq "deleted"
      validate_login_info(@student_1_id)
    end

    it "merges user b with user a" do
      setup_user_merge(@student_1, @student_2)
      submit_merge
      reload_users(@users)
      expect(@student_1.workflow_state).to eq "deleted"
      expect(@student_2.workflow_state).to eq "registered"
      validate_login_info(@student_2_id)
    end

    it "validates switching the users to merge" do
      setup_user_merge(@student_2, @student_1)
      user_names = ff(".result td")
      expect(user_names[0]).to include_text(@student_2.name)
      expect(user_names[1]).to include_text(@student_1.name)
      f("#switch_user_positions").click
      wait_for_ajaximations
      user_names = ff(".result td")
      expect(user_names[0]).to include_text(@student_1.name)
      expect(user_names[1]).to include_text(@student_2.name)
      submit_merge
      reload_users(@users)
      expect(@student_1.workflow_state).to eq "deleted"
      expect(@student_2.workflow_state).to eq "registered"
      validate_login_info(@student_1_id)
    end

    it "cancels a merge and validate both users still exist" do
      setup_user_merge(@student_2, @student_1)
      expect_new_page_load { f("#prepare_to_merge").click }
      wait_for_ajaximations
      expect_new_page_load { f(".button-secondary").click }
      wait_for_ajaximations
      expect(f("#global_nav_courses_link")).to be_displayed
      expect(@student_1.workflow_state).to eq "registered"
      expect(@student_2.workflow_state).to eq "registered"
    end

    it "shows an error if the user id entered is the current users" do
      get "/users/#{@student_1.id}/admin_merge"
      expect_no_flash_message :error
      f("#manual_user_id").send_keys(@student_1.id)
      expect_new_page_load { f('button[type="submit"]').click }
      wait_for_ajaximations
      expect_flash_message :error, "You can't merge an account with itself."
    end

    it "shows an error if invalid text is entered in the id box" do
      get "/users/#{@student_1.id}/admin_merge"
      expect_no_flash_message :error
      f("#manual_user_id").send_keys("azxcvbytre34567uijmm23456yhj")
      expect_new_page_load { f('button[type="submit"]').click }
      wait_for_ajaximations
      expect_flash_message :error, "No active user with that ID was found."
    end

    it "shows an error if the user id doesnt exist" do
      get "/users/#{@student_1.id}/admin_merge"
      expect_no_flash_message :error
      f("#manual_user_id").send_keys(1_234_567_809)
      expect_new_page_load { f('button[type="submit"]').click }
      expect_flash_message :error, "No active user with that ID was found."
    end
  end

  context "registration" do
    before do
      Account.default.canvas_authentication_provider.update_attribute(:self_registration, true)
    end

    it "does not require terms if globally not configured to do so" do
      Setting.set("terms_required", "false")

      get "/register"

      %w[teacher student parent].each do |type|
        f("#signup_#{type}").click
        form = fj(".ui-dialog:visible form")
        expect(form).not_to contain_css('input[name="user[terms_of_use]"]')
        fj(".ui-dialog-titlebar-close:visible").click
      end
    end

    it "does not require terms if account not configured to do so" do
      default_account = Account.default
      default_account.settings[:account_terms_required] = false
      default_account.save!

      get "/register"

      %w[teacher student parent].each do |type|
        f("#signup_#{type}").click
        form = fj(".ui-dialog:visible form")
        expect(form).not_to contain_css('input[name="user[terms_of_use]"]')
        fj(".ui-dialog-titlebar-close:visible").click
      end
    end

    it "requires terms if configured to do so" do
      Account.default.terms_of_service&.update(passive: false)

      get "/register"

      %w[teacher student parent].each do |type|
        f("#signup_#{type}").click
        form = fj(".ui-dialog:visible form")
        input = f('input[name="user[terms_of_use]"]', form)
        expect(input).not_to be_nil
        form.submit
        wait_for_ajaximations
        assert_error_box 'input[name="user[terms_of_use]"]:visible'
        fj(".ui-dialog-titlebar-close:visible").click
      end
    end

    it "registers a student with a join code" do
      Account.default.terms_of_service&.update(passive: false)

      Account.default.allow_self_enrollment!
      course_factory(active_all: true)
      @course.update_attribute(:self_enrollment, true)

      get "/register"
      f("#signup_student").click

      form = fj(".ui-dialog:visible form")
      f("#student_join_code").send_keys(@course.self_enrollment_code)
      f("#student_name").send_keys("student!")
      f("#student_username").send_keys("student")
      f("#student_password").send_keys("asdfasdf")
      f("#student_password_confirmation").send_keys("asdfasdf")
      f('input[name="user[terms_of_use]"]', form).click

      expect_new_page_load { form.submit }
      # confirm the user is authenticated into the dashboard
      expect_logout_link_present
      expect(User.last.initial_enrollment_type).to eq "student"
    end

    it "registers a teacher" do
      Account.default.terms_of_service&.update(passive: false)

      get "/register"
      f("#signup_teacher").click

      form = fj(".ui-dialog:visible form")
      f("#teacher_name").send_keys("teacher!")
      f("#teacher_email").send_keys("teacher@example.com")

      # if instructure_misc_plugin is installed, number of registration fields increase
      if Dir.exist?("./gems/plugins/instructure_misc_plugin") || Dir.exist?("./vendor/plugins/instructure_misc_plugin")
        set_value f("#teacher_organization_type"), "Higher Ed"
        set_value f("#teacher_school_position"), "Dean"
        f("#teacher_phone").send_keys("1231231234")
        f("#teacher_school_name").send_keys("example org")
        set_value f("#location"), "United States and Canada"
      end

      f('input[name="user[terms_of_use]"]', form).click

      expect_new_page_load { form.submit }
      # confirm the user is authenticated into the dashboard

      # close the "check your email to confirm your account" dialog
      f(".ui-dialog-titlebar-close").click
      expect(displayed_username).to eq("teacher!")
      expect(fj('form[action="/logout"] button:contains("Logout")')).to be_present
      expect(User.last.initial_enrollment_type).to eq "teacher"
    end

    it "registers an observer" do
      Account.default.terms_of_service&.update(passive: false)

      user = user_with_pseudonym(active_all: true, password: "lolwut12")
      pairing_code = user.generate_observer_pairing_code

      get "/register"
      f("#signup_parent").click

      form = fj(".ui-dialog:visible form")
      f("#parent_name").send_keys("parent!")
      f("#parent_email").send_keys("parent@example.com")
      f("#password").send_keys("password")
      f("#confirm_password").send_keys("password")
      f("#pairing_code").send_keys(pairing_code.code)
      f('input[name="user[terms_of_use]"]', form).click

      expect_new_page_load { form.submit }
      # confirm the user is authenticated into the dashboard

      expect_logout_link_present

      expect(User.last.initial_enrollment_type).to eq "observer"
    end
  end

  context "masquerading" do
    it "masquerades as a user", priority: "1" do
      site_admin_logged_in(name: "The Admin")
      user_with_pseudonym(active_user: true, name: "The Student")

      masquerade_url = "/users/#{@user.id}/masquerade"
      get masquerade_url
      f('a[href="' + masquerade_url + '"]').click
      expect(displayed_username).to include("The Student")

      bar = f("#masquerade_bar")
      expect(bar).to include_text "You are currently acting as"
      bar.find_element(:css, ".stop_masquerading").click
      expect(displayed_username).to eq("The Admin")
    end
  end
end
