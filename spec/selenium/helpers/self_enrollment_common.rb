   def should_register_a_new_user
      get "/enroll/#{@course.self_enrollment_code}"
      f("#student_email").send_keys('new@example.com')
      f('#user_type_new').click
      f("#student_name").send_keys('new guy')
      f('#enroll_form input[name="user[terms_of_use]"]').click
      expect_new_page_load {
        submit_form("#enroll_form")
      }
      f('.btn-primary').text.should eql primary_action
      get "/"
      assert_valid_dashboard
    end

    def should_authenticate_and_register_an_existing_user_open
      user_with_pseudonym(:active_all => true, :username => "existing@example.com", :password => "asdfasdf")
      get "/enroll/#{@course.self_enrollment_code}"
      f("#student_email").send_keys("existing@example.com")
      f('#user_type_existing').click
      f("#student_password").send_keys("asdfasdf")
      expect_new_page_load {
        submit_form("#enroll_form")
      }
      f('.btn-primary').text.should eql primary_action
      get "/"
      assert_valid_dashboard
    end

    def should_register_an_authenticated_user_open
      user_logged_in
      get "/enroll/#{@course.self_enrollment_code}"
      # no option to log in/register, since already authenticated
      f("input[name='pseudonym[unique_id]']").should be_nil
      expect_new_page_load {
        submit_form("#enroll_form")
      }
      f('.btn-primary').text.should eql primary_action
      get "/"
      assert_valid_dashboard
    end

    def should_not_register_a_new_user
      get "/enroll/#{@course.self_enrollment_code}"
      f("input[type=radio][name=user_type]").should be_nil
      f("input[name='user[name]']").should be_nil
    end

    def should_authenticate_and_register_an_existing_user
      user_with_pseudonym(:active_all => true, :username => "existing@example.com", :password => "asdfasdf")
      get "/enroll/#{@course.self_enrollment_code}"
      f("#student_email").send_keys("existing@example.com")
      f("#student_password").send_keys("asdfasdf")
      expect_new_page_load {
        submit_form("#enroll_form")
      }
      f('.btn-primary').text.should eql primary_action
      get "/"
      assert_valid_dashboard
    end

    def should_register_an_authenticated_user_closed
      user_logged_in
      get "/enroll/#{@course.self_enrollment_code}"
      # no option to log in/register, since already authenticated
      f("input[name='pseudonym[unique_id]']").should be_nil
      expect_new_page_load {
        submit_form("#enroll_form")
      }
      f('.btn-primary').text.should eql primary_action
      get "/"
      assert_valid_dashboard
    end

