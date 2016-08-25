module LoginAndSessionMethods
  def create_session(pseudonym)
    PseudonymSession.any_instance.stubs(:record).returns { pseudonym.reload }
  end

  def destroy_session
    PseudonymSession.any_instance.unstub :record
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
    get "/users/#{user.id}/masquerade"
    f('.masquerade_button').click
  end

  def displayed_username
    f('[aria-label="Main Navigation"] a[href="/profile"]').click
    f('#global_nav_profile_display_name').text
  end


  def expect_logout_link_present
    logout_element = begin
      f('[aria-label="Main Navigation"] a[href="/profile"]').click
      fj('form[action="/logout"] button:contains("Logout")')
    end
    expect(logout_element).to be_present
    logout_element
  end
end
