require File.expand_path(File.dirname(__FILE__) + '/common')

describe "account" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_admin_logged_in
  end

  describe "authentication configs" do

    it "should allow setting up a secondary ldap server" do
      get "/accounts/#{Account.default.id}/account_authorization_configs"
      driver.find_element(:id, 'add_auth_select').
          find_element(:css, 'option[value="ldap"]').click
      ldap_div = driver.find_element(:id, 'ldap_div')
      ldap_form = driver.find_element(:css, 'form.ldap_form')
      ldap_div.should be_displayed

      ldap_form.find_element(:id, 'account_authorization_config_0_auth_host').send_keys('primary.host.example.com')
      ldap_form.find_element(:id, 'account_authorization_config_0_auth_port').send_keys('1')
      ldap_form.find_element(:id, 'account_authorization_config_0_auth_over_tls').click
      ldap_form.find_element(:id, 'account_authorization_config_0_auth_base').send_keys('primary base')
      ldap_form.find_element(:id, 'account_authorization_config_0_auth_filter').send_keys('primary filter')
      ldap_form.find_element(:id, 'account_authorization_config_0_auth_username').send_keys('primary username')
      ldap_form.find_element(:id, 'account_authorization_config_0_auth_password').send_keys('primary password')
      ldap_form.find_element(:id, 'account_authorization_config_0_login_handle_name').send_keys('login handle')
      ldap_form.find_element(:id, 'account_authorization_config_0_change_password_url').send_keys('http://forgot.password.example.com/')
      expect_new_page_load { submit_form(ldap_form) }

      Account.default.account_authorization_configs.length.should == 1
      config = Account.default.account_authorization_configs.first
      config.auth_host.should == 'primary.host.example.com'
      config.auth_port.should == 1
      config.auth_over_tls.should == true
      config.auth_base.should == 'primary base'
      config.auth_filter.should == 'primary filter'
      config.auth_username.should == 'primary username'
      config.auth_decrypted_password.should == 'primary password'
      config.login_handle_name.should == 'login handle'
      config.change_password_url.should == 'http://forgot.password.example.com/'

      # now add a secondary ldap config
      driver.find_element(:css, '.edit_auth_link').click
      ldap_div = driver.find_element(:id, 'ldap_div')
      ldap_form = driver.find_element(:css, 'form.ldap_form')
      ldap_div.find_element(:css, '.add_secondary_ldap_link').click
      ldap_form.find_element(:id, 'account_authorization_config_1_auth_host').send_keys('secondary.host.example.com')
      ldap_form.find_element(:id, 'account_authorization_config_1_auth_port').send_keys('2')
      ldap_form.find_element(:id, 'account_authorization_config_1_auth_base').send_keys('secondary base')
      ldap_form.find_element(:id, 'account_authorization_config_1_auth_filter').send_keys('secondary filter')
      ldap_form.find_element(:id, 'account_authorization_config_1_auth_username').send_keys('secondary username')
      ldap_form.find_element(:id, 'account_authorization_config_1_auth_password').send_keys('secondary password')
      expect_new_page_load { submit_form(ldap_form) }

      Account.default.account_authorization_configs.length.should == 2
      config = Account.default.account_authorization_configs.first
      config.auth_host.should == 'primary.host.example.com'

      config = Account.default.account_authorization_configs[1]
      config.auth_host.should == 'secondary.host.example.com'
      config.auth_port.should == 2
      config.auth_over_tls.should == false
      config.auth_base.should == 'secondary base'
      config.auth_filter.should == 'secondary filter'
      config.auth_username.should == 'secondary username'
      config.auth_decrypted_password.should == 'secondary password'
      config.login_handle_name.should be_nil
      config.change_password_url.should be_nil

      shown_hosts = driver.find_elements(:css, ".auth_info.auth_host")
      shown_hosts[0].text.should == "primary.host.example.com"
      shown_hosts[1].text.should == "secondary.host.example.com"

      # test removing the secondary config
      driver.find_element(:css, '.edit_auth_link').click
      ldap_form = driver.find_element(:css, 'form.ldap_form')
      ldap_form.find_element(:css, '.remove_secondary_ldap_link').click
      expect_new_page_load { submit_form(ldap_form) }

      Account.default.account_authorization_configs.length.should == 1

      # test removing the entire config
      expect_new_page_load do
        driver.find_element(:css, '.delete_auth_link').click
        driver.switch_to.alert.accept
        driver.switch_to.default_content
      end

      Account.default.account_authorization_configs.length.should == 0
    end

    it "should show Login and Email fields in add user dialog for delegated auth accounts" do
      get "/accounts/#{Account.default.id}/users"
      driver.find_element(:css, ".add_user_link").click
      dialog = driver.find_element(:id, "add_user_dialog")
      dialog.find_elements(:id, "pseudonym_path").length.should == 0
      dialog.find_element(:id, "pseudonym_unique_id").should be_displayed

      Account.default.account_authorization_configs.create(:auth_type => 'cas')
      get "/accounts/#{Account.default.id}/users"
      driver.find_element(:css, ".add_user_link").click
      dialog = driver.find_element(:id, "add_user_dialog")
      dialog.find_element(:id, "pseudonym_path").should be_displayed
      dialog.find_element(:id, "pseudonym_unique_id").should be_displayed
    end

    it "should be able to set login labels for delegated auth accounts" do
      get "/accounts/#{Account.default.id}/account_authorization_configs"
      driver.find_element(:id, 'add_auth_select').
          find_element(:css, 'option[value="cas"]').click
      driver.find_element(:id, "account_authorization_config_0_login_handle_name").should be_displayed

      driver.find_element(:id, "account_authorization_config_0_auth_base").send_keys("cas.example.com")
      driver.find_element(:id, "account_authorization_config_0_login_handle_name").send_keys("CAS Username")
      expect_new_page_load { submit_form('#auth_form') }

      get "/accounts/#{Account.default.id}/users"
      driver.find_element(:css, ".add_user_link").click
      dialog = driver.find_element(:id, "add_user_dialog")
      dialog.find_element(:css, 'label[for="pseudonym_unique_id"]').text.should == "CAS Username:"
    end

    it "should be able to create a new course" do
      get "/accounts/#{Account.default.id}"
      driver.find_element(:css, '.add_course_link').click
      driver.find_element(:css, '#add_course_form input[type=text]:first-child').send_keys('Test Course')
      driver.find_element(:id, 'course_course_code').send_keys('TEST001')
      submit_form('#add_course_form')

      wait_for_ajaximations
      driver.find_element(:id, 'add_course_dialog').should_not be_displayed
      assert_flash_notice_message /Test Course successfully added/
    end

    it "should be able to create a new course when no other courses exist" do
      Account.default.courses.each { |c| c.destroy! }

      get "/accounts/#{Account.default.to_param}"
      driver.find_element(:css, '.add_course_link').click
      driver.find_element(:css, '#add_course_form').should be_displayed
    end

    it "should be able to update term dates" do

      def verify_displayed_term_dates(term, dates)
        dates.each do |en_type, dates|
          term.find_element(:css, ".#{en_type}_dates .start_date .show_term").text.should match /#{dates[0]}/
          term.find_element(:css, ".#{en_type}_dates .end_date .show_term").text.should match /#{dates[1]}/
        end
      end

      get "/accounts/#{Account.default.id}/terms"
      term = driver.find_element(:css, "tr.term")
      term.find_element(:css, ".edit_term_link").click
      term.find_element(:css, ".editing_term .general_dates .start_date .edit_term input").send_keys("2011-07-01")
      term.find_element(:css, ".editing_term .general_dates .end_date .edit_term input").send_keys("2011-07-31")
      submit_form(".enrollment_term_form")
      keep_trying_until { term.attribute(:class) !~ /editing_term/ }
      verify_displayed_term_dates(term, {
          :general => ["Jul 1", "Jul 31"],
          :student_enrollment => ["term start", "term end"],
          :teacher_enrollment => ["term start", "term end"],
          :ta_enrollment => ["term start", "term end"]
      })

      get "/accounts/#{Account.default.id}/terms"
      term = driver.find_element(:css, "tr.term")
      term.find_element(:css, ".edit_term_link").click
      term.find_element(:css, ".editing_term .student_enrollment_dates .start_date .edit_term input").send_keys("2011-07-02")
      term.find_element(:css, ".editing_term .student_enrollment_dates .end_date .edit_term input").send_keys("2011-07-30")
      submit_form(".enrollment_term_form")
      keep_trying_until { term.attribute(:class) !~ /editing_term/ }
      verify_displayed_term_dates(term, {
          :general => ["Jul 1", "Jul 31"],
          :student_enrollment => ["Jul 2", "Jul 30"],
          :teacher_enrollment => ["term start", "term end"],
          :ta_enrollment => ["term start", "term end"]
      })

      get "/accounts/#{Account.default.id}/terms"
      term = driver.find_element(:css, "tr.term")
      term.find_element(:css, ".edit_term_link").click
      term.find_element(:css, ".editing_term .teacher_enrollment_dates .start_date .edit_term input").send_keys("2011-07-03")
      term.find_element(:css, ".editing_term .teacher_enrollment_dates .end_date .edit_term input").send_keys("2011-07-29")
      term.find_element(:css, ".editing_term .ta_enrollment_dates .start_date .edit_term input").send_keys("2011-07-04")
      term.find_element(:css, ".editing_term .ta_enrollment_dates .end_date .edit_term input").send_keys("2011-07-28")
      submit_form(".enrollment_term_form")
      keep_trying_until { term.attribute(:class) !~ /editing_term/ }
      verify_displayed_term_dates(term, {
          :general => ["Jul 1", "Jul 31"],
          :student_enrollment => ["Jul 2", "Jul 30"],
          :teacher_enrollment => ["Jul 3", "Jul 29"],
          :ta_enrollment => ["Jul 4", "Jul 28"]
      })

      get "/accounts/#{Account.default.id}/terms"
      term = driver.find_element(:css, "tr.term")
      term.find_element(:css, ".edit_term_link").click
      term.find_element(:css, ".editing_term .teacher_enrollment_dates .start_date .edit_term input").clear
      term.find_element(:css, ".editing_term .teacher_enrollment_dates .end_date .edit_term input").clear
      submit_form(".enrollment_term_form")
      keep_trying_until { term.attribute(:class) !~ /editing_term/ }
      verify_displayed_term_dates(term, {
          :general => ["Jul 1", "Jul 31"],
          :student_enrollment => ["Jul 2", "Jul 30"],
          :teacher_enrollment => ["term start", "term end"],
          :ta_enrollment => ["Jul 4", "Jul 28"]
      })
    end

    it "should load/refresh SAML debug info" do
      enable_cache do
        aac = Account.default.account_authorization_configs.create!(:auth_type => 'saml')
        get "/accounts/#{Account.default.id}/account_authorization_configs"

        start = driver.find_element(:id, "start_saml_debugging")
        refresh = driver.find_element(:id, "refresh_saml_debugging")
        stop = driver.find_element(:id, "stop_saml_debugging")
        debug_info = driver.find_element(:id, "saml_debug_info")

        start.click
        wait_for_ajax_requests

        debug_info.text.should =~ /Waiting for attempted login/

        aac.debugging_keys.each_with_index do |key, i|
          aac.debug_set(key, "testvalue#{i}")
        end

        refresh.click
        wait_for_ajax_requests

        debug_info = driver.find_element(:id, "saml_debug_info")

        aac.debugging_keys.each_with_index do |key, i|
          debug_info.text.should =~ /testvalue#{i}/
        end

        stop.click
        wait_for_ajax_requests
        aac.debugging?.should == false

        aac.debugging_keys.each do |key|
          aac.debug_get(key).should == nil
        end
      end
    end
  end

  describe "user/course search" do

    STUDENT_NAME = 'student@example.com'
    COURSE_NAME = 'new course'
    ERROR_TEXT = 'No Results Found'

    def submit_input(form_element, input_field_css, input_text, expect_new_page_load = true)
      form_element.find_element(:css, input_field_css).send_keys(input_text)
      go_button = form_element.find_element(:css, '.button')
      if expect_new_page_load
        expect_new_page_load { go_button.click }
      else
        go_button.click
      end
    end

    before (:each) do
      course = Course.create!(:account => Account.default, :name => COURSE_NAME, :course_code => COURSE_NAME)
      course.reload
      student_in_course(:name => STUDENT_NAME)
      get "/accounts/#{Account.default.id}/courses"
    end

    it "should search for an existing course" do
      find_course_form = driver.find_element(:id, 'new_course')
      submit_input(find_course_form, '#course_name', COURSE_NAME)
      driver.find_element(:id, 'section-tabs-header').should include_text(COURSE_NAME)
    end

    it "should search for an existing user" do
      find_user_form = driver.find_element(:id, 'new_user')
      submit_input(find_user_form, '#user_name', STUDENT_NAME, false)
      wait_for_ajax_requests
      driver.find_element(:css, '.users').should include_text(STUDENT_NAME)
    end

    it "should behave correctly when searching for a course that does not exist" do
      find_course_form = driver.find_element(:id, 'new_course')
      submit_input(find_course_form, '#course_name', 'some random course name that will not exist')
      wait_for_ajax_requests
      driver.find_element(:id, 'content').should include_text(ERROR_TEXT)
      driver.find_element(:id, 'new_user').find_element(:id, 'user_name').text.should be_empty #verifies bug #5133 is fixed
    end

    it "should behave correctly when searching for a user that does not exist" do
      find_user_form = driver.find_element(:id, 'new_user')
      submit_input(find_user_form, '#user_name', 'this student name will not exist', false)
      driver.find_element(:id, 'content').should include_text(ERROR_TEXT)
    end
  end
end
