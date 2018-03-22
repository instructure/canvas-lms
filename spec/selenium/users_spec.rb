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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "users" do
  include_context "in-process server selenium tests"

  context "logins" do
    it "should allow setting passwords for new pseudonyms" do
      admin = User.create!
      Account.site_admin.account_users.create!(user: admin)
      user_session(admin)

      @user = User.create!
      course_factory.enroll_student(@user)

      get "/users/#{@user.id}"
      pseudonym_form = f('#edit_pseudonym_form')
      f(".add_pseudonym_link").click
      wait_for_ajaximations
      pseudonym_form.find_element(:css, "#pseudonym_unique_id").send_keys('new_user')
      pseudonym_form.find_element(:css, "#pseudonym_password").send_keys('qwertyuiop')
      pseudonym_form.find_element(:css, "#pseudonym_password_confirmation").send_keys('qwertyuiop')
      submit_form(pseudonym_form)
      wait_for_ajaximations

      new_login = f('.login:not(.blank)')
      expect(new_login).not_to be_nil
      expect(new_login.find_element(:css, '.account_name').text()).not_to be_blank
      pseudonym = Pseudonym.by_unique_id('new_user').first
      expect(pseudonym.valid_password?('qwertyuiop')).to be_truthy
    end
  end

  context "page views" do

    before (:each) do
      course_with_admin_logged_in
      @student = student_in_course.user
      Setting.set('enable_page_views', 'db')
    end

    it "should validate a basic page view" do
      page_view(:user => @student, :course => @course, :url => 'assignments')
      get "/users/#{@student.id}"
      rows = ff('#page_view_results tr')
      expect(rows.count).to eq 1
      page_view = rows.first
      expect(page_view).to include_text('Firefox')
      expect(page_view).to include_text('assignments')
      expect(f("#page_view_results")).not_to contain_css('tr img') # should not have a participation
    end

    it "should validate page view with a participation" do
      page_view(:user => @student, :course => @course, :participated => true)
      get "/users/#{@student.id}"
      expect(f("#page_view_results .icon-check")).to be_displayed
    end

    it "should validate a page view url" do
      second_student_name = 'test student for page views'
      get "/users/#{@student.id}"
      page_view(:user => @student, :course => @course, :participated => true, :url => student_in_course(:name => second_student_name).user.id.to_s)
      refresh_page # in order to get the generated page view
      page_view_url = f('#page_view_results a')
      second_student = User.where(name: second_student_name).first
      expect(page_view_url.text).to eq second_student.id.to_s
      expect_new_page_load { page_view_url.click }
      expect(f('.user_details .name').text).to eq second_student.name
      expect(f("#page_view_results")).not_to contain_css('tr') # validate the second student has no page views
    end

    it "should validate all page views were loaded" do
      page_views_count = 100
      page_views_count.times { |i| page_view(:user => @student, :course => @course, :url => "#{"%03d" % i}") }
      get "/users/#{@student.id}"
      wait_for_ajaximations
      driver.execute_script("$('#pageviews').scrollTop($('#pageviews')[0].scrollHeight);")
      wait_for_ajaximations
      expect(ff("#page_view_results tr").length).to eq page_views_count
    end
  end

  context "admin merge" do
    def setup_user_merge(from_user, into_user)
      get "/users/#{from_user.id}/admin_merge"
      f('#manual_user_id').send_keys(into_user.id)
      expect_new_page_load { f('button[type="submit"]').click }
    end

    def reload_users(users)
      users.each { |user| user.reload }
    end

    def submit_merge
      expect_new_page_load { f('#prepare_to_merge').click }
      expect_new_page_load { f('button[type="submit"]').click }
    end

    def validate_login_info(user_id)
      expect(f('#login_information')).to include_text(user_id)
    end

    before (:each) do
      @student_1_id = 'student1@example.com'
      @student_2_id = 'student2@example.com'

      course_with_admin_logged_in
      @student_1 = User.create!(:name => 'Student One')
      @student_1.register!
      @student_1.pseudonyms.create!(:unique_id => @student_1_id, :password => 'asdfasdf', :password_confirmation => 'asdfasdf')
      @course.enroll_user(@student_1).accept!

      @student_2 = User.create!(:name => 'Student Two')
      @student_2.register!
      @student_2.pseudonyms.create!(:unique_id => @student_2_id, :password => 'asdfasdf', :password_confirmation => 'asdfasdf')
      @course.enroll_user(@student_2).accept!
      @users = [@student_1, @student_2]
    end

    it "should merge user a with user b" do
      setup_user_merge(@student_2, @student_1)
      submit_merge
      reload_users(@users)
      expect(@student_1.workflow_state).to eq 'registered'
      expect(@student_2.workflow_state).to eq 'deleted'
      validate_login_info(@student_1_id)
    end

    it "should merge user b with user a" do
      setup_user_merge(@student_1, @student_2)
      submit_merge
      reload_users(@users)
      expect(@student_1.workflow_state).to eq 'deleted'
      expect(@student_2.workflow_state).to eq 'registered'
      validate_login_info(@student_2_id)
    end

    it "should validate switching the users to merge" do
      setup_user_merge(@student_2, @student_1)
      user_names = ff('.result td')
      expect(user_names[0]).to include_text(@student_2.name)
      expect(user_names[1]).to include_text(@student_1.name)
      f('#switch_user_positions').click
      wait_for_ajaximations
      user_names = ff('.result td')
      expect(user_names[0]).to include_text(@student_1.name)
      expect(user_names[1]).to include_text(@student_2.name)
      submit_merge
      reload_users(@users)
      expect(@student_1.workflow_state).to eq 'deleted'
      expect(@student_2.workflow_state).to eq 'registered'
      validate_login_info(@student_1_id)
    end

    it "should cancel a merge and validate both users still exist" do
      setup_user_merge(@student_2, @student_1)
      expect_new_page_load { f('#prepare_to_merge').click }
      wait_for_ajaximations
      expect_new_page_load { f('.button-secondary').click }
      wait_for_ajaximations
      expect(f('#global_nav_courses_link')).to be_displayed
      expect(@student_1.workflow_state).to eq 'registered'
      expect(@student_2.workflow_state).to eq 'registered'
    end

    it "should show an error if the user id entered is the current users" do
      get "/users/#{@student_1.id}/admin_merge"
      expect_no_flash_message :error
      f('#manual_user_id').send_keys(@student_1.id)
      expect_new_page_load { f('button[type="submit"]').click }
      wait_for_ajaximations
      expect_flash_message :error, "You can't merge an account with itself."
    end

    it "should show an error if invalid text is entered in the id box" do
      get "/users/#{@student_1.id}/admin_merge"
      expect_no_flash_message :error
      f('#manual_user_id').send_keys("azxcvbytre34567uijmm23456yhj")
      expect_new_page_load { f('button[type="submit"]').click }
      wait_for_ajaximations
      expect_flash_message :error, "No active user with that ID was found."
    end

    it "should show an error if the user id doesnt exist" do
      get "/users/#{@student_1.id}/admin_merge"
      expect_no_flash_message :error
      f('#manual_user_id').send_keys(1234567809)
      expect_new_page_load { f('button[type="submit"]').click }
      expect_flash_message :error, "No active user with that ID was found."
    end
  end

  context "registration" do
    before :each do
      Account.default.canvas_authentication_provider.update_attribute(:self_registration, true)
    end

    it "should not require terms if globally not configured to do so" do
      Setting.set('terms_required', 'false')

      get '/register'

      %w{teacher student parent}.each do |type|
        f("#signup_#{type}").click
        form = fj('.ui-dialog:visible form')
        expect(form).not_to contain_css('input[name="user[terms_of_use]"]')
        fj('.ui-dialog-titlebar-close:visible').click
      end
    end

    it "should not require terms if account not configured to do so" do
      default_account = Account.default
      default_account.settings[:account_terms_required] = false
      default_account.save!

      get '/register'

      %w{teacher student parent}.each do |type|
        f("#signup_#{type}").click
        form = fj('.ui-dialog:visible form')
        expect(form).not_to contain_css('input[name="user[terms_of_use]"]')
        fj('.ui-dialog-titlebar-close:visible').click
      end
    end

    it "should require terms if configured to do so" do
      if terms = Account.default.terms_of_service
        terms.update(passive: false)
      end

      get "/register"

      %w{teacher student parent}.each do |type|
        f("#signup_#{type}").click
        form = fj('.ui-dialog:visible form')
        input = f('input[name="user[terms_of_use]"]', form)
        expect(input).not_to be_nil
        form.submit
        wait_for_ajaximations
        assert_error_box 'input[name="user[terms_of_use]"]:visible'
        fj('.ui-dialog-titlebar-close:visible').click
      end
    end

    it "should register a student with a join code" do
      if terms = Account.default.terms_of_service
        terms.update(passive: false)
      end

      Account.default.allow_self_enrollment!
      course_factory(active_all: true)
      @course.update_attribute(:self_enrollment, true)

      get '/register'
      f('#signup_student').click

      form = fj('.ui-dialog:visible form')
      f('#student_join_code').send_keys(@course.self_enrollment_code)
      f('#student_name').send_keys('student!')
      f('#student_username').send_keys('student')
      f('#student_password').send_keys('asdfasdf')
      f('#student_password_confirmation').send_keys('asdfasdf')
      f('input[name="user[terms_of_use]"]', form).click

      expect_new_page_load { form.submit }
      # confirm the user is authenticated into the dashboard
      expect_logout_link_present
      expect(User.last.initial_enrollment_type).to eq 'student'
    end

    it "should register a teacher" do
      if terms = Account.default.terms_of_service
        terms.update(passive: false)
      end

      get '/register'
      f('#signup_teacher').click

      form = fj('.ui-dialog:visible form')
      f('#teacher_name').send_keys('teacher!')
      f('#teacher_email').send_keys('teacher@example.com')

      # if instructure_misc_plugin is installed, number of registration fields increase
      if (Dir.exist?('./gems/plugins/instructure_misc_plugin') || Dir.exist?('./vendor/plugins/instructure_misc_plugin'))
        set_value f('#teacher_organization_type'), 'Higher Ed'
        set_value f('#teacher_school_position'), 'Dean'
        f('#teacher_phone').send_keys('1231231234')
        f('#teacher_school_name').send_keys('example org')
        set_value f('#location'), 'United States and Canada'
      end

      f('input[name="user[terms_of_use]"]', form).click

      expect_new_page_load { form.submit }
      # confirm the user is authenticated into the dashboard

      # close the "check your email to confirm your account" dialog
      f('.ui-dialog-titlebar-close').click
      expect(displayed_username).to eq('teacher!')
      expect(fj('form[action="/logout"] button:contains("Logout")')).to be_present
      expect(User.last.initial_enrollment_type).to eq 'teacher'
    end

    it "should register an observer" do
      if terms = Account.default.terms_of_service
        terms.update(passive: false)
      end

      user_with_pseudonym(:active_all => true, :password => 'lolwut12')

      get '/register'
      f('#signup_parent').click

      form = fj('.ui-dialog:visible form')
      f('#parent_name').send_keys('parent!')
      f('#parent_email').send_keys('parent@example.com')
      f('#parent_child_username').send_keys(@pseudonym.unique_id)
      f('#parent_child_password').send_keys('lolwut12')
      f('input[name="user[terms_of_use]"]', form).click

      expect_new_page_load { form.submit }
      # confirm the user is authenticated into the dashboard

      # close the "check your email to confirm your account" dialog
      f('.ui-dialog-titlebar-close').click
      expect_logout_link_present

      expect(User.last.initial_enrollment_type).to eq 'observer'
    end
  end

  context "masquerading" do
    it "should masquerade as a user", priority: "1", test_id: 134743 do
      site_admin_logged_in(:name => 'The Admin')
      user_with_pseudonym(:active_user => true, :name => 'The Student')

      masquerade_url = "/users/#{@user.id}/masquerade"
      get masquerade_url
      f('a[href="' + masquerade_url + '"]').click
      expect(displayed_username).to include('The Student')

      bar = f('#masquerade_bar')
      expect(bar).to include_text 'You are currently acting as'
      bar.find_element(:css, '.stop_masquerading').click
      expect(displayed_username).to eq('The Admin')
    end
  end
end
