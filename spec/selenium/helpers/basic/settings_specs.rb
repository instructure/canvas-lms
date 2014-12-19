shared_examples_for "settings basic tests" do
  include_examples "in-process server selenium tests"

  before (:each) do
    course_with_admin_logged_in
  end

  context "admins tab" do

    def add_account_admin
      address = "student1@example.com"
      f(".add_users_link").click
      f("textarea.user_list").send_keys(address)
      f(".verify_syntax_button").click
      wait_for_ajax_requests
      expect(f("#user_lists_processed_people .person").text).to eq address
      f(".add_users_button").click
      wait_for_ajax_requests
      user = User.where(name: address).first
      expect(user).to be_present
      admin = AccountUser.where(user_id: user).first
      expect(admin).to be_present
      expect(admin.role_id).to eq admin_role.id
      expect(f("#enrollment_#{admin.id} .email").text).to eq address
      admin.id
    end

    before (:each) do
      get "/accounts/#{account.id}/settings"
      f("#tab-users-link").click
    end

    it "should add an account admin" do
      add_account_admin
    end

    it "should delete an account admin" do
      admin_id = add_account_admin
      f("#enrollment_#{admin_id} .remove_account_user_link").click
      driver.switch_to.alert.accept
      wait_for_ajax_requests
      expect(AccountUser.where(id: admin_id)).not_to be_exists
    end
  end

  context "account settings" do

    def click_submit
      submit_form("#account_settings")
      wait_for_ajax_requests
    end

    before (:each) do
      course_with_admin_logged_in
      group_model(:context => @course)
      get account_settings_url
    end

    it "should change the account name " do
      new_account_name = 'new default account name'
      replace_content(f("#account_name"), new_account_name)
      click_submit
      account.reload
      expect(account.name).to eq new_account_name
      expect(f("#account_name")).to have_value(new_account_name)
    end

    it "should change the default quotas" do
      f('#tab-quotas-link').click

      # update the quotas
      course_quota = account.default_storage_quota_mb
      course_quota_input = f('[name="default_storage_quota_mb"]')
      expect(course_quota_input).to have_value(course_quota.to_s)

      user_quota = account.default_user_storage_quota_mb
      user_quota_input = f('[name="default_user_storage_quota_mb"]')
      expect(user_quota_input).to have_value(user_quota.to_s)

      group_quota = account.default_group_storage_quota_mb
      group_quota_input = f('[name="default_group_storage_quota_mb"]')
      expect(group_quota_input).to have_value(group_quota.to_s)

      course_quota += 25
      replace_content(course_quota_input, course_quota.to_s)
      user_quota += 15
      replace_content(user_quota_input, user_quota.to_s)
      group_quota += 42
      replace_content(group_quota_input, group_quota.to_s)

      submit_form('#default-quotas')
      wait_for_ajax_requests

      # ensure the account was updated properly
      account.reload
      expect(account.default_storage_quota_mb).to eq course_quota
      expect(account.default_storage_quota).to eq course_quota * 1048576
      account.default_user_storage_quota_mb == user_quota
      expect(account.default_user_storage_quota).to eq user_quota * 1048576
      account.default_group_storage_quota_mb == group_quota
      expect(account.default_group_storage_quota).to eq group_quota * 1048576

      # ensure the new value is reflected after a refresh
      get account_settings_url
      expect(fj('[name="default_storage_quota_mb"]')).to have_value(course_quota.to_s) # fj to avoid selenium caching
      expect(fj('[name="default_user_storage_quota_mb"]')).to have_value(user_quota.to_s) # fj to avoid selenium caching
      expect(fj('[name="default_group_storage_quota_mb"]')).to have_value(group_quota.to_s) # fj to avoid selenium caching
    end

    it "should manually change a course quota" do
      f('#tab-quotas-link').click

      # find the course by id
      click_option('#manual_quotas_type', 'course', :value)
      id_input = f('#manual_quotas_id')
      replace_content(id_input, @course.id.to_s)
      f('#manual_quotas_find_button').click

      wait_for_ajaximations

      link = f('#manual_quotas_link')
      expect(link).to include_text(@course.name)

      quota_input = f('#manual_quotas_quota')
      expect(quota_input).to have_value(@course.storage_quota_mb.to_s)
      replace_content(quota_input, '42')

      f('#manual_quotas_submit_button').click

      wait_for_ajax_requests

      # ensure the account was updated properly
      @course.reload
      expect(@course.storage_quota_mb).to eq 42
    end

    it "should manually change a group quota" do
      f('#tab-quotas-link').click

      # find the course by id
      click_option('#manual_quotas_type', 'group', :value)
      id_input = f('#manual_quotas_id')
      replace_content(id_input, @group.id.to_s)
      f('#manual_quotas_find_button').click

      wait_for_ajaximations

      link = f('#manual_quotas_link')
      expect(link).to include_text(@group.name)

      quota_input = f('#manual_quotas_quota')
      expect(quota_input).to have_value(@group.storage_quota_mb.to_s)
      replace_content(quota_input, '42')

      f('#manual_quotas_submit_button').click

      wait_for_ajax_requests

      # ensure the account was updated properly
      @group.reload
      expect(@group.storage_quota_mb).to eq 42
    end

    it "should change the default language to spanish" do
      f("#account_default_locale option[value='es']").click
      click_submit
      account.reload
      expect(account.default_locale).to eq "es"
      expect(get_value('#account_default_locale')).to eq 'es'
    end
  end
end
