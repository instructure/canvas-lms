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

module LoginAndSessionMethods
  def create_session(pseudonym)
    if caller.grep(/onceler\/recorder.*record!/).present?
      raise "don't double sessions in a `before(:once)` block; do it in a `before(:each)` so the stubbing works for all examples and not just the first one"
    end
    @session_stubbed = true
    allow_any_instance_of(PseudonymSession).to receive(:record).and_wrap_original do |original|
      next original.call unless @session_stubbed
      pseudonym.reload
    end
  end

  def destroy_session
    @session_stubbed = false
  end

  def user_session(user)
    create_session(pseudonym(user))
  end

  def user_logged_in(opts={})
    user_with_pseudonym({:active_user => true}.merge(opts))
    create_session(@pseudonym)
  end

  def course_with_teacher_logged_in(opts={})
    user_logged_in(opts)
    course_with_teacher({:user => @user, :active_course => true, :active_enrollment => true}.merge(opts))
  end

  def course_with_student_logged_in(opts={})
    user_logged_in(opts)
    course_with_student({:user => @user, :active_course => true, :active_enrollment => true}.merge(opts))
  end

  def course_with_observer_logged_in(opts={})
    user_logged_in(opts)
    course_with_observer({:user => @user, :active_course => true, :active_enrollment => true}.merge(opts))
  end

  def course_with_ta_logged_in(opts={})
    user_logged_in(opts)
    course_with_ta({:user => @user, :active_course => true, :active_enrollment => true}.merge(opts))
  end

  def course_with_designer_logged_in(opts={})
    user_logged_in(opts)
    course_with_designer({:user => @user, :active_course => true, :active_enrollment => true}.merge(opts))
  end

  def course_with_admin_logged_in(opts={})
    account_admin_user({:active_user => true}.merge(opts))
    user_logged_in({:user => @user}.merge(opts))
    course_with_teacher({:user => @user, :active_course => true, :active_enrollment => true}.merge(opts))
  end

  def provision_quizzes_next(account)
    account.root_account.settings[:provision] = { 'lti' => 'lti url'}
    account.root_account.save!
  end

  def admin_logged_in(opts={})
    account_admin_user({:active_user => true}.merge(opts))
    user_logged_in({:user => @user}.merge(opts))
  end

  def site_admin_logged_in(opts={})
    site_admin_user({:active_user => true}.merge(opts))
    user_logged_in({:user => @user}.merge(opts))
  end

  def enter_student_view(opts={})
    course = opts[:course] || @course || course(opts)
    get "/courses/#{@course.id}/settings"
    driver.execute_script("$('.student_view_button').click()")
    wait_for_ajaximations
  end

  def leave_student_view
    expect_new_page_load { f('.leave_student_view').click }
  end

  def fill_in_login_form(username, password)
    user_element = f('#pseudonym_session_unique_id')
    user_element.send_keys(username)
    password_element = f('#pseudonym_session_password')
    password_element.send_keys(password)
    password_element.submit
    wait_for_ajaximations
  end

  # don't use this unless you are actually testing the login/logout
  # process; instead prefer create_session or the various *_logged_in
  # methods above
  def login_as(username = "nobody@example.com", password = "asdfasdf")
    if Onceler.open_transactions > 0
      raise "don't use real logins with once-ler, since a session cookie could be valid across specs if the pseudonym is shared"
    end
    get "/login"
    expect_new_page_load { fill_in_login_form(username, password) }
    expect_logout_link_present
  end

  def masquerade_as(user)
    masquerade_url = "/users/#{user.id}/masquerade"
    get masquerade_url
    f('a[href="' + masquerade_url + '"]').click
  end

  def displayed_username
    f('[aria-label="Global Navigation"] a[href="/profile"]').click
    f('[aria-label="Global navigation tray"] h2').text
  end


  def expect_logout_link_present
    logout_element = begin
      f('[aria-label="Global Navigation"] a[href="/profile"]').click
      wait_for_animations
      fj('form[action="/logout"] button:contains("Logout")')
    end
    expect(logout_element).to be_present
    logout_element
  end
end
