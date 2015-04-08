require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "admin settings tab" do
  include_examples "in-process server selenium tests"
  before (:each) do
    course_with_admin_logged_in
    get "/accounts/#{Account.default.id}/settings"
  end

  def get_default_services
    default_services = []
    service_hash = Account.default.allowed_services_hash
    service_hash.each { |k, v| default_services.push k if  v[:expose_to_ui] }
    default_services
  end

  def state_checker checker, check_state
    if (checker)
      expect(check_state).to be_truthy
    else
      expect(check_state).to be_falsey
    end
  end

  def check_box_verifier (css_selectors, features, checker = true)
    is_symbol = false

    css_selectors = [css_selectors] unless (css_selectors.is_a? Array)

    if features.is_a? Symbol
      is_symbol = true
      if features == :all_selectors
        features = get_default_services
      end
    end
    if ((features.is_a? Array) && !checker)
      default_selectors = []
      features.each do |feature|
        check_state = Account.default.service_enabled?(feature)
        state_checker checker, !check_state
        default_selectors.push("#account_services_#{feature.to_s}")
      end
      css_selectors = default_selectors
    end
    css_selectors.each do |selector|
      check_state = is_checked(selector)
      state_checker !checker, check_state
      f(selector).click
    end
    click_submit
    if (is_symbol == false)
      check_state = Account.default.service_enabled?(features[:allowed_services])
      state_checker checker, check_state
    else
      if (features.is_a? Array)
        default_selectors = []
        features.each do |feature|
          check_state = Account.default.service_enabled?(feature)
          state_checker checker, check_state
          default_selectors.push("#account_services_#{feature.to_s}")
        end
        if (checker)
          default_selectors += css_selectors
        end
        css_selectors = default_selectors
      else
        check_state = Account.default.settings[features]
        state_checker checker, check_state
      end
    end
    css_selectors.each do |selector|
      check_state = is_checked(selector)
      state_checker checker, check_state
    end
  end

  def click_submit
    submit_form("#account_settings")
    wait_for_ajax_requests
  end

  context "account settings" do

    it "should change the default time zone to Lima" do
      f("#account_default_time_zone option[value='Lima']").click
      click_submit
      expect(Account.default.default_time_zone.name).to eq "Lima"
      expect(f("#account_default_time_zone option[value='Lima']").attribute("selected")).to be_truthy
    end

    describe "allow self-enrollment" do
      def enrollment_helper (value='')
        if (value == '')
          f("#account_settings_self_enrollment option[value='']").click
        else
          f("#account_settings_self_enrollment option[value=#{value}]").click
        end
        click_submit
        expect(Account.default[:settings][:self_enrollment]).to eq value.presence
        expect(f("#account_settings_self_enrollment")).to have_value value
      end

      it "should select never for self-enrollment" do
        enrollment_helper
      end

      it "should select self-enrollment for any courses" do
        enrollment_helper "any"
      end

      it "should select self-enrollment for manually-created courses" do
        enrollment_helper "manually_created"
      end
    end

    it "should click on don't let teachers rename their courses" do
      check_box_verifier("#account_settings_prevent_course_renaming_by_teachers", :prevent_course_renaming_by_teachers)
    end

    it "should uncheck 'students can opt-in to receiving scores in email notifications' " do
      check_box_verifier("#account_settings_allow_sending_scores_in_emails", :allow_sending_scores_in_emails, false)
    end

    it "should set trusted referers for account" do
      trusted_referers = 'https://example.com,http://example.com'
      set_value f("#account_settings_trusted_referers"), trusted_referers
      click_submit
      expect(Account.default[:settings][:trusted_referers]).to eq trusted_referers
      expect(f("#account_settings_trusted_referers").attribute('value')).to eq trusted_referers

      set_value f("#account_settings_trusted_referers"), ''
      click_submit
      expect(Account.default[:settings][:trusted_referers]).to be_nil
      expect(f("#account_settings_trusted_referers").attribute('value')).to eq ''
    end
  end

  context "global includes" do
    it "should not have a global includes section by default" do
      expect(fj('#account_settings_global_includes_settings:visible')).to be_nil
    end

    it "should have a global includes section if enabled" do
      Account.default.settings = Account.default.settings.merge({ :global_includes => true })
      Account.default.save!
      section = f('#account_settings_global_includes_settings')
      expect(section.find_element(:id, 'account_settings_sub_account_includes')).not_to be_nil
    end

    it "a sub-account should not have a global includes section by default" do
      Account.default.settings = Account.default.settings.merge({ :global_includes => true })
      Account.default.save!
      acct = account_model(:root_account => Account.default)
      get "/accounts/#{acct.id}/settings"
      expect(fj('#account_settings_global_includes_settings:visible')).to be_nil
    end

    it "a sub-account should have a global includes section if enabled by the parent" do
      Account.default.settings = Account.default.settings.merge({ :global_includes => true })
      Account.default.settings = Account.default.settings.merge({ :sub_account_includes => true })
      Account.default.save!
      acct = account_model(:root_account => Account.default)
      get "/accounts/#{acct.id}/settings"
      section = f('#account_settings_global_includes_settings')
      expect(section.find_element(:id, 'account_settings_sub_account_includes')).not_to be_nil
    end
  end

  context "quiz ip address filter" do

    def add_quiz_filter name ="www.canvas.instructure.com", value="192.168.217.1/24"
      fj("#ip_filters .name[value='']:visible").send_keys name
      fj("#ip_filters .value[value='']:visible").send_keys value
      click_submit
      filter_hash = {name => value}
      expect(Account.default.settings[:ip_filters]).to include filter_hash
      expect(fj("#ip_filters .name[value='#{name}']")).to be_displayed
      expect(fj("#ip_filters .value[value='#{value}']")).to be_displayed
      filter_hash
    end

    it "should click on the quiz help link" do
      f(".ip_help_link").click
      expect(f("#ip_filters_dialog").text).to include_text "What are Quiz IP Filters?"
    end

    it "should add a quiz filter " do
      add_quiz_filter
    end

    it "should add another quiz filter" do
      add_quiz_filter
      f(".add_ip_filter_link").click
      add_quiz_filter "www.canvas.instructure.com/tests", "129.186.127.12/4"
    end

    it "should edit a quiz filter " do
      add_quiz_filter
      new_name = "www.example.org"
      new_value = "10.192.124.12/8"
      replace_content(fj("#ip_filters .name:visible"), new_name)
      replace_content(fj("#ip_filters .value:visible"), new_value)
      click_submit
      filter_hash = {new_name => new_value}
      expect(Account.default.settings[:ip_filters]).to include filter_hash
      expect(fj("#ip_filters .name[value='#{new_name}']")).to be_displayed
      expect(fj("#ip_filters .value[value='#{new_value}']")).to be_displayed
    end

    it "should delete a quiz filter" do
      skip("bug #8348 - cannot remove quiz IP address filter")
      filter_hash = add_quiz_filter
      f("#ip_filters .delete_filter_link").click
      click_submit
      expect(f("#ip_filters .value[value='#{filter_hash.values.first}']")).to be_nil
      expect(f("#ip_filters .name[value='#{filter_hash.keys.first}']")).to be_nil
      expect(Account.default.settings[:ip_filters]).to be_nil
    end
  end

  context "features" do
    it "should check 'open registration'" do
      check_box_verifier("#account_settings_open_registration", :open_registration)
    end

    it "should uncheck users can edit display name' and check it again" do
      check_box_verifier("#account_settings_users_can_edit_name", :users_can_edit_name, false)
      check_box_verifier("#account_settings_users_can_edit_name", :users_can_edit_name)
    end

    describe "equella settings" do

      def add_equella_feature
        equella_url = "http://oer.equella.com/signon.do"
        f("#account_settings_equella_endpoint").send_keys(equella_url)
        f("#account_settings_equella_teaser").send_keys("equella feature")
        click_submit
        expect(Account.default.settings[:equella_endpoint]).to eq equella_url
        expect(Account.default.settings[:equella_teaser]).to eq "equella feature"
        expect(f("#account_settings_equella_endpoint")).to have_value equella_url
        expect(f("#account_settings_equella_teaser")).to have_value "equella feature"
      end

      before(:each) do
        f("#enable_equella").click
        expect(is_checked("#enable_equella")).to be_truthy
      end
      it "should add an equella feature" do
        add_equella_feature
      end

      it "should edit an equella feature" do
        add_equella_feature
        new_equella_url = "http://oer.equella.com/signon.be"
        replace_content(f("#account_settings_equella_endpoint"), new_equella_url)
        replace_content(f("#account_settings_equella_teaser"), "new equella feature")
        click_submit
        expect(Account.default.settings[:equella_endpoint]).to eq new_equella_url
        expect(Account.default.settings[:equella_teaser]).to eq "new equella feature"
        expect(f("#account_settings_equella_endpoint")).to have_value new_equella_url
        expect(f("#account_settings_equella_teaser")).to have_value "new equella feature"
      end

      it "should delete an equella feature" do
        add_equella_feature
        expect(fj("#account_settings_equella_endpoint:visible")).to be_displayed
        expect(fj("#account_settings_equella_teaser:visible")).to be_displayed
        replace_content(f("#account_settings_equella_endpoint"), "")
        replace_content(f("#account_settings_equella_teaser"), "")
        click_submit
        expect(Account.default.settings[:equella_endpoint]).to be_nil
        expect(Account.default.settings[:equella_teaser]).to be_nil
        expect(fj("#account_settings_equella_endpoint:visible")).to be_nil
        expect(fj("#account_settings_equella_teaser:visible")).to be_nil
      end
    end
  end

  context "enabled web services" do

    it "should click on the google help dialog" do
      fj("label['for'='account_services_google_docs_previews'] .icon-question").click
      expect(fj(".ui-dialog-title:visible")).to include_text("About Google Docs Previews")
    end

    it "should unclick and then click on skype" do
      check_box_verifier("#account_services_skype", {:allowed_services => :skype}, false)
      check_box_verifier("#account_services_skype", {:allowed_services => :skype})
    end

    it "should unclick and then click on delicious" do
      check_box_verifier("#account_services_delicious", {:allowed_services => :delicious}, false)
      check_box_verifier("#account_services_delicious", {:allowed_services => :delicious})
    end

    it "should unclick and click on google docs previews" do
      check_box_verifier("#account_services_google_docs_previews", {:allowed_services => :google_docs_previews}, false)
      check_box_verifier("#account_services_google_docs_previews", {:allowed_services => :google_docs_previews})
    end

    it "should click on user avatars" do
      check_box_verifier("#account_services_avatars", {:allowed_services => :avatars})
      check_box_verifier("#account_services_avatars", {:allowed_services => :avatars}, false)
    end

    it "should disable all web services" do
      check_box_verifier(nil, :all_selectors, false)
    end

    it "should enable all web services" do
      check_box_verifier("#account_services_avatars", :all_selectors)
    end

    it "should enable and disable a plugin service (setting)" do
      Account.register_service(:myplugin, {:name => "My Plugin", :description => "", :expose_to_ui => :setting, :default => false})
      get "/accounts/#{Account.default.id}/settings"
      check_box_verifier("#account_services_myplugin", {:allowed_services => :myplugin})
      check_box_verifier("#account_services_myplugin", {:allowed_services => :myplugin}, false)
    end

    it "should enable and disable a plugin service (service)" do
      Account.register_service(:myplugin, {:name => "My Plugin", :description => "", :expose_to_ui => :service, :default => false})
      get "/accounts/#{Account.default.id}/settings"
      check_box_verifier("#account_services_myplugin", {:allowed_services => :myplugin})
      check_box_verifier("#account_services_myplugin", {:allowed_services => :myplugin}, false)
    end
  end

  context "who can create new courses" do

    it "should check on teachers" do
      check_box_verifier("#account_settings_teachers_can_create_courses", :teachers_can_create_courses)
    end

    it "should check on users with no enrollments" do
      check_box_verifier("#account_settings_no_enrollments_can_create_courses", :no_enrollments_can_create_courses)
    end

    it "should check on students" do
      check_box_verifier("#account_settings_students_can_create_courses", :students_can_create_courses)
    end
  end

  context "custom help links" do
    def set_checkbox(checkbox, checked)
      selector = "##{checkbox['id']}"
      checkbox.click if is_checked(selector) != checked
    end

    it 'should add and delete custom help links' do
      Setting.set('show_feedback_link', 'true')
      get "/accounts/#{Account.default.id}/settings"

      f('.add_custom_help_link').click
      f('.add_custom_help_link').click
      f('.add_custom_help_link').click

      inputs = ff('.custom_help_link:nth-child(1) .formtable input')
      inputs.find{|e| e['id'].ends_with?('_text')}.send_keys('text')
      inputs.find{|e| e['id'].ends_with?('_subtext')}.send_keys('subtext')
      inputs.find{|e| e['id'].ends_with?('_url')}.send_keys('http://www.example.com/example')

      set_checkbox(inputs.find{|e| e['id'].ends_with?('_available_to_user')}, true)
      set_checkbox(inputs.find{|e| e['id'].ends_with?('_available_to_student')}, true)
      set_checkbox(inputs.find{|e| e['id'].ends_with?('_available_to_teacher')}, true)
      set_checkbox(inputs.find{|e| e['id'].ends_with?('_available_to_admin')}, false)

      f('.custom_help_link:nth-child(2) .delete').click
      expect(f('.custom_help_link:nth-child(2)')).not_to be_displayed

      inputs = ff('.custom_help_link:nth-child(3) .formtable input')
      inputs.find{|e| e['id'].ends_with?('_text')}.send_keys('text2')
      inputs.find{|e| e['id'].ends_with?('_subtext')}.send_keys('subtext2')
      inputs.find{|e| e['id'].ends_with?('_url')}.send_keys('http://www.example.com/example2')

      set_checkbox(inputs.find{|e| e['id'].ends_with?('_available_to_user')}, false)
      set_checkbox(inputs.find{|e| e['id'].ends_with?('_available_to_student')}, true)
      set_checkbox(inputs.find{|e| e['id'].ends_with?('_available_to_teacher')}, false)
      set_checkbox(inputs.find{|e| e['id'].ends_with?('_available_to_admin')}, true)

      click_submit
      expect(Account.default.settings[:custom_help_links]).to eq [
        {"text"=>"text", "subtext"=>"subtext", "url"=>"http://www.example.com/example", "available_to"=>["user", "student", "teacher"]},
        {"text"=>"text2", "subtext"=>"subtext2", "url"=>"http://www.example.com/example2", "available_to"=>["student", "admin"]}
      ]

      f('.custom_help_link:nth-child(1) .delete').click
      expect(f('.custom_help_link:nth-child(1)')).not_to be_displayed

      click_submit
      expect(Account.default.settings[:custom_help_links]).to eq [
          {"text"=>"text2", "subtext"=>"subtext2", "url"=>"http://www.example.com/example2", "available_to"=>["student", "admin"]}
      ]
    end

    it "should not delete all of the pre-existing custom help links if notifications tab is submitted" do
      Account.default.settings[:custom_help_links] = [
          {"text"=>"text", "subtext"=>"subtext", "url"=>"http://www.example.com/example", "available_to"=>["user", "student", "teacher"]}]
      Account.default.save!

      Setting.set('show_feedback_link', 'true')
      get "/accounts/#{Account.default.id}/settings"

      f("#tab-notifications-link").click
      submit_form("#account_settings_notifications")
      wait_for_ajax_requests

      expect(Account.default.settings[:custom_help_links]).to eq [
        {"text"=>"text", "subtext"=>"subtext", "url"=>"http://www.example.com/example", "available_to"=>["user", "student", "teacher"]}
      ]
    end
  end

  context "external integration keys" do
    let!(:key_value) { '42' }
    before(:once) do
      ExternalIntegrationKey.key_type :external_key0, label: 'External Key 0', rights: { read: proc { true }, write: true }
      ExternalIntegrationKey.key_type :external_key1, label: proc { 'External Key 1' }, rights: { read: true, write: false }
      ExternalIntegrationKey.key_type :external_key2, label: 'External Key 2', rights: { read: proc { false }, write: false }
    end

    it "should not display external integration keys if no key types exist" do
      ExternalIntegrationKey.stubs(:key_types).returns([])
      get "/accounts/#{Account.default.id}/settings"
      expect(f("#external_integration_keys")).to be_nil
    end

    it "should not display external integration keys if no rights are granted" do
      ExternalIntegrationKey.any_instance.stubs(:grants_right_for?).returns(false)
      get "/accounts/#{Account.default.id}/settings"
      expect(f("#external_integration_keys")).to be_nil
    end

    it "should display keys with the correct rights" do
      eik = ExternalIntegrationKey.new
      eik.context = Account.default
      eik.key_type = 'external_key0'
      eik.key_value = key_value
      eik.save

      eik = ExternalIntegrationKey.new
      eik.context = Account.default
      eik.key_type = 'external_key1'
      eik.key_value = key_value
      eik.save

      get "/accounts/#{Account.default.id}/settings"

      expect(f("label[for='account_external_integration_keys_external_key0']").text).to eq 'External Key 0:'
      expect(f("label[for='account_external_integration_keys_external_key1']").text).to eq 'External Key 1:'
      expect(f("label[for='account_external_integration_keys_external_key2']")).to be_nil

      expect(f("#account_external_integration_keys_external_key0").attribute('value')).to eq key_value
      expect(f("#external_integration_keys span").text).to eq key_value
      expect(f("#account_external_integration_keys_external_key2")).to be_nil
    end

    it "should update writable keys" do
      set_value f("#account_external_integration_keys_external_key0"), key_value
      click_submit

      expect(f("#account_external_integration_keys_external_key0").attribute('value')).to eq key_value

      set_value f("#account_external_integration_keys_external_key0"), ''
      click_submit

      expect(f("#account_external_integration_keys_external_key0").attribute('value')).to eq ''
    end
  end

  it "should show all the feature flags" do
    course_with_admin_logged_in(:account => Account.site_admin)
    get "/accounts/#{Account.site_admin.id}/settings"
    f("#tab-features-link").click
    wait_for_ajaximations
    
    Feature.applicable_features(Account.site_admin).each do |feature|
      expect(f(".feature.#{feature.feature}")).to be_displayed
    end
  end
end
