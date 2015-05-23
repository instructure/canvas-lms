module LoginAndSessionMethods
  alias_method :login, :login_as

  def create_session(pseudonym, real_login = false)
    if real_login
      login_as(pseudonym.unique_id, pseudonym.password)
    else
      PseudonymSession.any_instance.stubs(:session_credentials).returns([])
      PseudonymSession.any_instance.stubs(:record).returns { pseudonym.reload }
      # PseudonymSession.stubs(:find).returns(@pseudonym_session)
    end
  end

  def destroy_session(real_login)
    if real_login
      logout_link = f('#identity .logout a')
      if logout_link
        if logout_link.displayed?
          expect_new_page_load(:accept_alert) { logout_link.click() }
        else
          get '/'
          destroy_session(true)
        end
      end
    else
      PseudonymSession.any_instance.unstub :session_credentials
      PseudonymSession.any_instance.unstub :record
    end
  end

  def user_logged_in(opts={})
    user_with_pseudonym({:active_user => true}.merge(opts))
    create_session(@pseudonym, opts[:real_login] || $in_proc_webserver_shutdown.nil?)
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
  end

  def login_as(username = "nobody@example.com", password = "asdfasdf", expect_success = true)
    destroy_session(true)
    driver.navigate.to(app_host + '/login')
    if expect_success
      expect_new_page_load { fill_in_login_form(username, password) }
      expect(f('#identity .logout')).to be_present
    else
      fill_in_login_form(username, password)
    end
  end
end