require File.expand_path(File.dirname(__FILE__) + '/common')

describe "account" do
  include_examples "in-process server selenium tests"

  before (:each) do
    course_with_admin_logged_in
  end

  describe "authentication configs" do

    it "should allow setting up a secondary ldap server" do
      get "/accounts/#{Account.default.id}/account_authorization_configs"
      click_option('#add_auth_select', 'ldap', :value)
      ldap_div = f('#ldap_div')
      ldap_form = f('form.ldap_form')
      expect(ldap_div).to be_displayed

      ldap_form.find_element(:id, 'account_authorization_config_0_auth_host').send_keys('primary.host.example.com')
      ldap_form.find_element(:id, 'account_authorization_config_0_auth_port').send_keys('1')
      ldap_form.find_element(:id, 'account_authorization_config_0_auth_over_tls_simple_tls').click
      ldap_form.find_element(:id, 'account_authorization_config_0_auth_base').send_keys('primary base')
      ldap_form.find_element(:id, 'account_authorization_config_0_auth_filter').send_keys('primary filter')
      ldap_form.find_element(:id, 'account_authorization_config_0_auth_username').send_keys('primary username')
      ldap_form.find_element(:id, 'account_authorization_config_0_auth_password').send_keys('primary password')
      ldap_form.find_element(:id, 'account_authorization_config_0_login_handle_name').send_keys('login handle')
      ldap_form.find_element(:id, 'account_authorization_config_0_change_password_url').send_keys('http://forgot.password.example.com/')
      submit_form('#auth_form')

      keep_trying_until { expect(Account.default.account_authorization_configs.length).to eq 1 }
      config = Account.default.account_authorization_configs.first
      expect(config.auth_host).to eq 'primary.host.example.com'
      expect(config.auth_port).to eq 1
      expect(config.auth_over_tls).to eq 'simple_tls'
      expect(config.auth_base).to eq 'primary base'
      expect(config.auth_filter).to eq 'primary filter'
      expect(config.auth_username).to eq 'primary username'
      expect(config.auth_decrypted_password).to eq 'primary password'
      expect(config.login_handle_name).to eq 'login handle'
      expect(config.change_password_url).to eq 'http://forgot.password.example.com/'

      # now add a secondary ldap config
      f('.edit_auth_link').click
      ldap_div = f('#ldap_div')
      ldap_form = f('form.ldap_form')
      ldap_div.find_element(:css, '.add_secondary_ldap_link').click
      ldap_form.find_element(:id, 'account_authorization_config_1_auth_host').send_keys('secondary.host.example.com')
      ldap_form.find_element(:id, 'account_authorization_config_1_auth_port').send_keys('2')
      ldap_form.find_element(:id, 'account_authorization_config_1_auth_base').send_keys('secondary base')
      ldap_form.find_element(:id, 'account_authorization_config_1_auth_filter').send_keys('secondary filter')
      ldap_form.find_element(:id, 'account_authorization_config_1_auth_username').send_keys('secondary username')
      ldap_form.find_element(:id, 'account_authorization_config_1_auth_password').send_keys('secondary password')
      submit_form('#auth_form')

      keep_trying_until { expect(Account.default.account_authorization_configs.length).to eq 2 }
      config = Account.default.account_authorization_configs.first
      expect(config.auth_host).to eq 'primary.host.example.com'
      expect(config.auth_over_tls).to eq 'simple_tls'

      config = Account.default.account_authorization_configs[1]
      expect(config.auth_host).to eq 'secondary.host.example.com'
      expect(config.auth_port).to eq 2
      expect(config.auth_over_tls).to eq 'start_tls'
      expect(config.auth_base).to eq 'secondary base'
      expect(config.auth_filter).to eq 'secondary filter'
      expect(config.auth_username).to eq 'secondary username'
      expect(config.auth_decrypted_password).to eq 'secondary password'
      expect(config.login_handle_name).to be_nil
      expect(config.change_password_url).to be_nil

      shown_hosts = ff(".auth_info.auth_host")
      expect(shown_hosts[0].text).to eq "primary.host.example.com"
      expect(shown_hosts[1].text).to eq "secondary.host.example.com"

      # test removing the secondary config
      f('.edit_auth_link').click
      ldap_form = f('form.ldap_form')
      ldap_form.find_element(:css, '.remove_secondary_ldap_link').click
      submit_form('#auth_form')

      keep_trying_until { expect(Account.default.account_authorization_configs.length).to eq 1 }

      # test removing the entire config
      expect_new_page_load do
        f('.delete_auth_link').click
        driver.switch_to.alert.accept
        driver.switch_to.default_content
      end

      expect(Account.default.account_authorization_configs.length).to eq 0
    end

    it "should show Login and Email fields in add user dialog for delegated auth accounts" do
      get "/accounts/#{Account.default.id}/users"
      f(".add_user_link").click
      dialog = f("#add_user_dialog")
      expect(dialog.find_elements(:id, "pseudonym_path").length).to eq 0
      expect(dialog.find_element(:id, "pseudonym_unique_id")).to be_displayed

      Account.default.account_authorization_configs.create(:auth_type => 'cas')
      get "/accounts/#{Account.default.id}/users"
      f(".add_user_link").click
      dialog = f("#add_user_dialog")
      expect(dialog.find_element(:id, "pseudonym_path")).to be_displayed
      expect(dialog.find_element(:id, "pseudonym_unique_id")).to be_displayed
    end

    it "should be able to set login labels for delegated auth accounts" do
      get "/accounts/#{Account.default.id}/account_authorization_configs"
      click_option('#add_auth_select', 'cas', :value)
      expect(f("#account_authorization_config_0_login_handle_name")).to be_displayed

      f("#account_authorization_config_0_auth_base").send_keys("cas.example.com")
      f("#account_authorization_config_0_login_handle_name").send_keys("CAS Username")
      expect_new_page_load { submit_form('#auth_form') }

      get "/accounts/#{Account.default.id}/users"
      f(".add_user_link").click
      dialog = f("#add_user_dialog")
      expect(dialog.find_element(:css, 'label[for="pseudonym_unique_id"]').text).to eq "CAS Username:*"
    end

    context "cas" do
      it "should be able to set unknown user url option" do
        get "/accounts/#{Account.default.id}/account_authorization_configs"
        click_option('#add_auth_select', 'cas', :value)
        expect(f("#account_authorization_config_0_login_handle_name")).to be_displayed

        unknown_user_url = 'https://example.com/unknown_user'
        f("#account_authorization_config_0_unknown_user_url").send_keys(unknown_user_url)
        expect_new_page_load { submit_form('#auth_form') }

        expect(Account.default.account_authorization_configs.first.unknown_user_url).to eq unknown_user_url
      end
    end

    context "saml" do
      it "should be able to set unknown user url option" do
        get "/accounts/#{Account.default.id}/account_authorization_configs"
        click_option('#add_auth_select', 'saml', :value)

        saml_div = f('#saml_div')
        saml_div.find_element(:css, 'button.element_toggler.btn').click

        expect(f("#account_authorization_config_idp_entity_id")).to be_displayed

        unknown_user_url = 'https://example.com/unknown_user'
        f("#account_authorization_config_unknown_user_url").send_keys(unknown_user_url)
        expect_new_page_load { submit_form('#saml_config__form') }

        expect(Account.default.account_authorization_configs.first.unknown_user_url).to eq unknown_user_url
      end
    end

    it "should be able to create a new course" do
      get "/accounts/#{Account.default.id}"
      f('.add_course_link').click
      f('#add_course_form input[type=text]:first-child').send_keys('Test Course')
      f('#course_course_code').send_keys('TEST001')
      submit_form('#add_course_form')

      wait_for_ajaximations
      expect(f('#add_course_dialog')).not_to be_displayed
      assert_flash_notice_message /Test Course successfully added/
    end

    it "should be able to create a new course when no other courses exist" do
      Account.default.courses.each do |c|
        c.course_account_associations.scoped.delete_all
        c.enrollments.scoped.delete_all
        c.course_sections.scoped.delete_all
        c.destroy!
      end

      get "/accounts/#{Account.default.to_param}"
      f('.add_course_link').click
      expect(f('#add_course_form')).to be_displayed
    end

    it "should be able to add a term" do
      get "/accounts/#{Account.default.id}/terms"
      f(".add_term_link").click
      wait_for_ajaximations

      f("#enrollment_term_name").send_keys("some name")
      f("#enrollment_term_sis_source_id").send_keys("some id")

      f("#term_new .general_dates .start_date .edit_term input").send_keys("2011-07-01")
      f("#term_new .general_dates .end_date .edit_term input").send_keys("2011-07-31")

      submit_form(".enrollment_term_form")
      wait_for_ajaximations

      term = Account.default.enrollment_terms.last
      expect(term.name).to eq "some name"
      expect(term.sis_source_id).to eq "some id"

      expect(term.start_at).to eq Date.parse("2011-07-01")
      expect(term.end_at).to eq Date.parse("2011-07-31")
    end

    it "should be able to update term dates" do

      def verify_displayed_term_dates(term, dates)
        dates.each do |en_type, dates|
          expect(term.find_element(:css, ".#{en_type}_dates .start_date .show_term").text).to match /#{dates[0]}/
          expect(term.find_element(:css, ".#{en_type}_dates .end_date .show_term").text).to match /#{dates[1]}/
        end
      end

      get "/accounts/#{Account.default.id}/terms"
      term = f("tr.term")
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
      term = f("tr.term")
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
      term = f("tr.term")
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
      term = f("tr.term")
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

        start = f("#start_saml_debugging")
        refresh = f("#refresh_saml_debugging")
        stop = f("#stop_saml_debugging")
        debug_info = f("#saml_debug_info")

        start.click
        wait_for_ajax_requests

        expect(debug_info.text).to match /Waiting for attempted login/

        aac.debugging_keys.each_with_index do |key, i|
          aac.debug_set(key, "testvalue#{i}")
        end

        refresh.click
        wait_for_ajax_requests

        debug_info = f("#saml_debug_info")

        aac.debugging_keys.each_with_index do |key, i|
          expect(debug_info.text).to match /testvalue#{i}/
        end

        stop.click
        wait_for_ajax_requests
        expect(aac.debugging?).to eq false

        aac.debugging_keys.each do |key|
          expect(aac.debug_get(key)).to eq nil
        end
      end
    end

    it "should configure discovery_url" do
      auth_url = "http://example.com"
      @account = Account.default
      @account.account_authorization_configs.create!(:auth_type => 'saml')
      @account.account_authorization_configs.create!(:auth_type => 'saml')
      get "/accounts/#{Account.default.id}/account_authorization_configs"
      f("#discovery_url_config .admin-links button").click
      f("#discovery_url_config .admin-links a").click
      f("#discovery_url_input").send_keys(auth_url)
      expect_new_page_load { submit_form("#discovery_url_form") }

      @account.reload
      expect(@account.auth_discovery_url).to eq auth_url

      f("#discovery_url_config .admin-links button").click
      f("#discovery_url_config .delete_url").click

      wait_for_ajax_requests

      expect(f("#discovery_url_input").attribute(:value)).to eq ''
      @account.reload
      expect(@account.auth_discovery_url).to eq nil
    end
  end

  describe "user/course search" do
    def submit_input(form_element, input_field_css, input_text, expect_new_page_load = true)
      form_element.find_element(:css, input_field_css).send_keys(input_text)
      go_button = form_element.find_element(:css, 'button')
      if expect_new_page_load
        expect_new_page_load { go_button.click }
      else
        go_button.click
      end
    end

    before (:each) do
      @student_name = 'student@example.com'
      @course_name = 'new course'
      @error_text = 'No Results Found'

      @course = Course.create!(:account => Account.default, :name => @course_name, :course_code => @course_name)
      @course.reload
      student_in_course(:name => @student_name)
      get "/accounts/#{Account.default.id}/courses"
    end

    it "should search for an existing course" do
      find_course_form = f('#new_course')
      submit_input(find_course_form, '#course_name', @course_name)
      expect(f('#section-tabs-header')).to include_text(@course_name)
    end

    it "should correctly autocomplete for courses" do
      get "/accounts/#{Account.default.id}"
      f('#course_name').send_keys(@course_name.chop)

      keep_trying_until do
        ui_auto_complete = f('.ui-autocomplete')
        expect(ui_auto_complete).to be_displayed
      end

      elements = ff('.ui-autocomplete li:first-child a div')
      expect(elements[0].text).to eq @course_name
      expect(elements[1].text).to eq 'Default Term'
      keep_trying_until do
        driver.execute_script("$('.ui-autocomplete li a').hover().click()")
        expect(driver.current_url).to include("/courses/#{@course.id}")
      end
    end

    it "should search for an existing user" do
      find_user_form = f('#new_user')
      submit_input(find_user_form, '#user_name', @student_name, false)
      wait_for_ajax_requests
      expect(f('.users')).to include_text(@student_name)
    end

    it "should behave correctly when searching for a course that does not exist" do
      find_course_form = f('#new_course')
      submit_input(find_course_form, '#course_name', 'some random course name that will not exist')
      wait_for_ajax_requests
      expect(f('#content')).to include_text(@error_text)
      expect(f('#new_user').find_element(:id, 'user_name').text).to be_empty #verifies bug #5133 is fixed
    end

    it "should behave correctly when searching for a user that does not exist" do
      find_user_form = f('#new_user')
      submit_input(find_user_form, '#user_name', 'this student name will not exist', false)
      expect(f('#content')).to include_text(@error_text)
    end
  end

  describe "user details view" do
    def create_sub_account(name = 'sub_account', parent_account = Account.default)
      Account.create(:name => name, :parent_account => parent_account)
    end

    it "should be able to view user details from parent account" do
      user_non_root = user
      create_sub_account.account_users.create!(user: user_non_root)
      get "/accounts/#{Account.default.id}/users/#{user_non_root.id}"
      #verify user details displayed properly
      expect(f('.accounts .unstyled_list li')).to include_text('sub_account')
    end
  end
end
