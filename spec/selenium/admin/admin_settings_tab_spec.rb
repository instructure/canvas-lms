require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "admin settings tab" do
  it_should_behave_like "in-process server selenium tests"
  before (:each) do
    course_with_admin_logged_in
    get "/accounts/#{Account.default.id}/settings"
  end

  def get_default_services
    default_services = []
    service_hash = Account.default.allowed_services_hash
    service_hash.each do |k, v|
      default_services.push k if  v[:expose_to_ui]
    end
    default_services
  end

  def state_checker checker, check_state
    if (checker)
      check_state.should be_true
    else
      check_state.should be_false
    end
  end

  def check_box_verifier (css_selectors, features, checker=true)
    is_symbol = false
    if features.is_a? Symbol
      is_symbol =true
      if features.eql? :all_selectors
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
    if (is_symbol.eql? false)
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
          default_selectors.push css_selectors
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

  context "acccount settings" do
    it "should change the admins name " do
      replace_content f("#account_name"), "Admin 1"
      click_submit
      Account.default.name.should eql "Admin 1"
      f("#account_name").should have_value "Admin 1"
    end

    it "should change the default file quota" do
      mb=300
      f("#account_default_storage_quota_mb").should have_value "500"
      replace_content f("#account_default_storage_quota_mb"), mb
      click_submit
      bytes = mb*1048576
      Account.default.default_storage_quota.should eql bytes
      f("#account_default_storage_quota_mb").should have_value "300"
    end

    it "should change the default language to spanish" do
      f("#account_default_locale option[value='es']").click
      click_submit
      Account.default.default_locale.should eql "es"
      f("label[for='account_name']").text.should include_text("Nombre de Cuenta")
    end

    it "should change the default time zone to Lima" do
      f("#account_default_time_zone option[value='Lima']").click
      click_submit
      Account.default.default_time_zone.should eql "Lima"
      f("#account_default_time_zone option[value='Lima']").attribute("selected").should be_true
    end
    describe "allow self-enrollment" do
      def enrollment_helper (value='')
        if (value.eql? '')
          f("#account_settings_self_enrollment option[value='']").click
        else
          f("#account_settings_self_enrollment option[value=#{value}]").click
        end
        click_submit
        Account.default[:settings][:self_enrollment].should eql value
        f("#account_settings_self_enrollment").should have_value value
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
  end

  context "quiz ip address filter" do

    def add_quiz_filter name ="www.canvas.instructure.com", value="192.168.217.1/24"
      fj("#ip_filters .name[value='']:visible").send_keys name
      fj("#ip_filters .value[value='']:visible").send_keys value
      click_submit
      filter_hash = {name => value}
      Account.default.settings[:ip_filters].should include filter_hash
      fj("#ip_filters .name[value='#{name}']").should be_displayed
      fj("#ip_filters .value[value='#{value}']").should be_displayed
      filter_hash
    end

    it "should click on the quiz help link" do
      f(".ip_help_link").click
      f("#ip_filters_dialog").text.should include_text "What are Quiz IP Filters?"
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
      Account.default.settings[:ip_filters].should include filter_hash
      fj("#ip_filters .name[value='#{new_name}']").should be_displayed
      fj("#ip_filters .value[value='#{new_value}']").should be_displayed
    end

    it "should delete a quiz filter" do
      pending("bug #8348 - cannot remove quiz IP address filter") do
        filter_hash = add_quiz_filter
        f("#ip_filters .delete_filter_link").click
        click_submit
        f("#ip_filters .value[value='#{filter_hash.values.first}']").should be_nil
        f("#ip_filters .name[value='#{filter_hash.keys.first}']").should be_nil
        Account.default.settings[:ip_filters].should be_nil
      end
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
        Account.default.settings[:equella_endpoint].should eql equella_url
        Account.default.settings[:equella_teaser].should eql "equella feature"
        f("#account_settings_equella_endpoint").should have_value equella_url
        f("#account_settings_equella_teaser").should have_value "equella feature"
      end

      before(:each) do
        f("#enable_equella").click
        is_checked("#enable_equella").should be_true
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
        Account.default.settings[:equella_endpoint].should eql new_equella_url
        Account.default.settings[:equella_teaser].should eql "new equella feature"
        f("#account_settings_equella_endpoint").should have_value new_equella_url
        f("#account_settings_equella_teaser").should have_value "new equella feature"
      end

      it "should delete an equella feature" do
        add_equella_feature
        fj("#account_settings_equella_endpoint:visible").should be_displayed
        fj("#account_settings_equella_teaser:visible").should be_displayed
        replace_content(f("#account_settings_equella_endpoint"), "")
        replace_content(f("#account_settings_equella_teaser"), "")
        click_submit
        Account.default.settings[:equella_endpoint].should eql ""
        Account.default.settings[:equella_teaser].should eql ""
        fj("#account_settings_equella_endpoint:visible").should be_nil
        fj("#account_settings_equella_teaser:visible").should be_nil
      end
    end
  end

  context "enabled web services" do

    it "should click on the google help dialog" do
      f("a.help").click
      f("#ui-dialog-title-google_docs_previews_help_dialog").should include_text("About Google Docs Previews")
    end

    it "should unclick and then click on skype" do
      check_box_verifier("#account_services_skype", {:allowed_services => :skype}, false)
      check_box_verifier("#account_services_skype", {:allowed_services => :skype})
    end

    it "should unclick and then click on delicious" do
      check_box_verifier("#account_services_delicious", {:allowed_services => :delicious}, false)
      check_box_verifier("#account_services_delicious", {:allowed_services => :delicious})
    end

    it "should unclick and then click on diigo" do
      check_box_verifier("#account_services_diigo", {:allowed_services => :diigo}, false)
      check_box_verifier("#account_services_diigo", {:allowed_services => :diigo})
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
      Account.register_service(:myplugin, { :name => "My Plugin", :description => "", :expose_to_ui => :setting, :default => false })
      get "/accounts/#{Account.default.id}/settings"
      check_box_verifier("#account_services_myplugin", { :allowed_services => :myplugin })
      check_box_verifier("#account_services_myplugin", { :allowed_services => :myplugin }, false)
    end

    it "should enable and disable a plugin service (service)" do
      Account.register_service(:myplugin, { :name => "My Plugin", :description => "", :expose_to_ui => :service, :default => false })
      get "/accounts/#{Account.default.id}/settings"
      check_box_verifier("#account_services_myplugin", { :allowed_services => :myplugin })
      check_box_verifier("#account_services_myplugin", { :allowed_services => :myplugin }, false)
    end
  end

  context "who can create wew courses" do

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
end
