require File.expand_path(File.dirname(__FILE__) + '/common')

describe "account authentication configs" do
  it_should_behave_like "in-process server selenium tests"
  
  it "should allow setting up a secondary ldap server" do
    course_with_admin_logged_in

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
    expect_new_page_load { ldap_form.find_element(:css, 'button[type="submit"]').click }

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
    expect_new_page_load { ldap_form.find_element(:css, 'button[type="submit"]').click }

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
    expect_new_page_load { ldap_form.find_element(:css, 'button[type="submit"]').click }

    Account.default.account_authorization_configs.length.should == 1

    # test removing the entire config
    expect_new_page_load { 
      driver.find_element(:css, '.delete_auth_link').click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
    }

    Account.default.account_authorization_configs.length.should == 0
  end
  
  it "should be able to update term dates" do
    course_with_admin_logged_in
    
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
    term.find_element(:css, ".enrollment_term_form .submit_button").click
    keep_trying_until { term.attribute(:class) !~ /editing_term/ }
    verify_displayed_term_dates(term, {
      :general => [ "Jul 1", "Jul 31" ],
      :student_enrollment => [ "term start", "term end" ],
      :teacher_enrollment => [ "term start", "term end" ],
      :ta_enrollment => [ "term start", "term end" ]
    })
    
    get "/accounts/#{Account.default.id}/terms"
    term = driver.find_element(:css, "tr.term")
    term.find_element(:css, ".edit_term_link").click
    term.find_element(:css, ".editing_term .student_enrollment_dates .start_date .edit_term input").send_keys("2011-07-02")
    term.find_element(:css, ".editing_term .student_enrollment_dates .end_date .edit_term input").send_keys("2011-07-30")
    term.find_element(:css, ".enrollment_term_form .submit_button").click
    keep_trying_until { term.attribute(:class) !~ /editing_term/ }
    verify_displayed_term_dates(term, {
      :general => [ "Jul 1", "Jul 31" ],
      :student_enrollment => [ "Jul 2", "Jul 30" ],
      :teacher_enrollment => [ "term start", "term end" ],
      :ta_enrollment => [ "term start", "term end" ]
    })
    
    get "/accounts/#{Account.default.id}/terms"
    term = driver.find_element(:css, "tr.term")
    term.find_element(:css, ".edit_term_link").click
    term.find_element(:css, ".editing_term .teacher_enrollment_dates .start_date .edit_term input").send_keys("2011-07-03")
    term.find_element(:css, ".editing_term .teacher_enrollment_dates .end_date .edit_term input").send_keys("2011-07-29")
    term.find_element(:css, ".editing_term .ta_enrollment_dates .start_date .edit_term input").send_keys("2011-07-04")
    term.find_element(:css, ".editing_term .ta_enrollment_dates .end_date .edit_term input").send_keys("2011-07-28")
    term.find_element(:css, ".enrollment_term_form .submit_button").click
    keep_trying_until { term.attribute(:class) !~ /editing_term/ }
    verify_displayed_term_dates(term, {
      :general => [ "Jul 1", "Jul 31" ],
      :student_enrollment => [ "Jul 2", "Jul 30" ],
      :teacher_enrollment => [ "Jul 3", "Jul 29" ],
      :ta_enrollment => [ "Jul 4", "Jul 28" ]
    })
    
    get "/accounts/#{Account.default.id}/terms"
    term = driver.find_element(:css, "tr.term")
    term.find_element(:css, ".edit_term_link").click
    term.find_element(:css, ".editing_term .teacher_enrollment_dates .start_date .edit_term input").clear
    term.find_element(:css, ".editing_term .teacher_enrollment_dates .end_date .edit_term input").clear
    term.find_element(:css, ".enrollment_term_form .submit_button").click
    keep_trying_until { term.attribute(:class) !~ /editing_term/ }
    verify_displayed_term_dates(term, {
      :general => [ "Jul 1", "Jul 31" ],
      :student_enrollment => [ "Jul 2", "Jul 30" ],
      :teacher_enrollment => [ "term start", "term end" ],
      :ta_enrollment => [ "Jul 4", "Jul 28" ]
    })
  end
end
