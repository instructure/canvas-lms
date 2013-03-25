    def add_account_admin
      address = "student1@example.com"
      f(".add_users_link").click
      f("textarea.user_list").send_keys(address)
      f(".verify_syntax_button").click
      wait_for_ajax_requests
      f("#user_lists_processed_people .person").text.should == address
      f(".add_users_button").click
      wait_for_ajax_requests
      user = User.find_by_name(address)
      user.should be_present
      admin = AccountUser.find_by_user_id(user.id)
      admin.should be_present
      admin.membership_type.should == "AccountAdmin"
      f("#enrollment_#{admin.id} .email").text.should == address
      admin.id
    end

    def click_submit
      submit_form("#account_settings")
      wait_for_ajax_requests
    end

    def should_add_an_account_admin
      add_account_admin
    end

    def should_delete_an_account_admin
      admin_id = add_account_admin
      f("#enrollment_#{admin_id} .remove_account_user_link").click
      driver.switch_to.alert.accept
      wait_for_ajax_requests
      AccountUser.find_by_id(admin_id).should be_nil
    end

    def should_change_the_account_name
      new_account_name = 'new default account name'
      replace_content(f("#account_name"), new_account_name)
      click_submit
      account.reload
      account.name.should == new_account_name
      f("#account_name").should have_value(new_account_name)
    end

    def should_change_the_default_file_quota
      mb = 300
      quota_input = f("#account_default_course_storage_quota")
      quota_input.should have_value("500")
      replace_content(quota_input, mb)
      click_submit
      bytes = mb * 1048576
      account.reload
      account.default_storage_quota.should == bytes
      fj("#account_default_course_storage_quota").should have_value("300") # fj to avoid selenium caching
    end

    def should_change_the_default_language_to_spanish
      f("#account_default_locale option[value='es']").click
      click_submit
      account.reload
      account.default_locale.should == "es"
      f("label[for='account_name']").text.should include_text("Nombre de Cuenta")
    end
