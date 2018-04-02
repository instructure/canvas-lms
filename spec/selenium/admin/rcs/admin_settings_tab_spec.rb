#
# Copyright (C) 2017 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + '/../../common')

describe "admin settings tab" do
  include_context "in-process server selenium tests"
  before :once do
    account_admin_user
    enable_all_rcs Account.default
  end

  before :each do
    stub_rcs_config
    user_session(@admin)
  end

  def get_default_services
    default_services = []
    service_hash = Account.default.allowed_services_hash
    service_hash.each do |k, v|
      default_services.push k if v[:expose_to_ui] &&
        (!v[:expose_to_ui_proc] || v[:expose_to_ui_proc].call(@user, Account.default))
    end
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
        default_selectors.push("#account_services_#{feature}")
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
          default_selectors.push("#account_services_#{feature}")
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
    move_to_click("#account_settings button[type=submit]")
    wait_for_ajax_requests
  end

  def go_to_feature_options(account_id)
    get "/accounts/#{account_id}/settings"
    f("#tab-features-link").click
    wait_for_ajaximations
  end

  context "account settings" do
    before :each do
      get "/accounts/#{Account.default.id}/settings"
    end

    it "should change the default time zone to Lima" do
      f("#account_default_time_zone option[value='Lima']").click
      wait_for_ajaximations
      click_submit
      expect(Account.default.default_time_zone.name).to eq "Lima"
      expect(f("#account_default_time_zone option[value='Lima']")).to have_attribute("selected", "true")
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
      expect(f("#account_settings_trusted_referers")).to have_value trusted_referers

      set_value f("#account_settings_trusted_referers"), ''
      click_submit
      expect(Account.default[:settings][:trusted_referers]).to be_nil
      expect(f("#account_settings_trusted_referers")).to have_value ''
    end
  end

  context "quiz ip address filter" do
    before :each do
      get "/accounts/#{Account.default.id}/settings"
    end

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

    def create_quiz_filter(name="www.canvas.instructure.com", value="192.168.217.1/24")
      Account.default.tap do |a|
        a.settings[:ip_filters] ||= []
        a.settings[:ip_filters] << {name => value}
        a.save!
      end
    end

    it "should click on the quiz help link" do
      f(".ip_help_link").click
      expect(f("#ip_filters_dialog")).to include_text "What are Quiz IP Filters?"
    end

    it "should add a quiz filter" do
      add_quiz_filter
    end

    it "should add another quiz filter" do
      create_quiz_filter
      f(".add_ip_filter_link").click
      add_quiz_filter "www.canvas.instructure.com/tests", "129.186.127.12/4"
    end

    it "should edit a quiz filter" do
      create_quiz_filter
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
      filter_hash = add_quiz_filter
      f("#ip_filters .delete_filter_link").click
      click_submit
      expect(f("#account_settings")).not_to contain_css("#ip_filters .value[value='#{filter_hash.values.first}']")
      expect(f("#account_settings")).not_to contain_css("#ip_filters .name[value='#{filter_hash.keys.first}']")
      expect(Account.default.settings[:ip_filters]).to be_blank
    end
  end

  context "features" do
    before :each do
      get "/accounts/#{Account.default.id}/settings"
    end

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
        expect(f("#account_settings")).not_to contain_jqcss("#account_settings_equella_endpoint:visible")
        expect(f("#account_settings")).not_to contain_jqcss("#account_settings_equella_teaser:visible")
      end
    end
  end

  context "enabled web services" do
    before :each do
      get "/accounts/#{Account.default.id}/settings"
    end

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
      AccountServices.register_service(:myplugin, {:name => "My Plugin", :description => "", :expose_to_ui => :setting, :default => false})
      get "/accounts/#{Account.default.id}/settings"
      check_box_verifier("#account_services_myplugin", {:allowed_services => :myplugin})
      check_box_verifier("#account_services_myplugin", {:allowed_services => :myplugin}, false)
    end

    it "should enable and disable a plugin service (service)" do
      AccountServices.register_service(:myplugin, {:name => "My Plugin", :description => "", :expose_to_ui => :service, :default => false})
      get "/accounts/#{Account.default.id}/settings"
      check_box_verifier("#account_services_myplugin", {:allowed_services => :myplugin})
      check_box_verifier("#account_services_myplugin", {:allowed_services => :myplugin}, false)
    end
  end

  context "who can create new courses" do
    before :each do
      get "/accounts/#{Account.default.id}/settings"
    end

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
    before :once do
      Setting.set('show_feedback_link', 'true')
    end

    def set_checkbox(checkbox, checked)
      selector = "##{checkbox['id']}"
      checkbox.click if is_checked(selector) != checked
    end

    it "should set custom help link text and icon" do
      link_name = 'Links'
      icon = 'cog'
      help_link_name_input = '[name="account[settings][help_link_name]"]'
      help_link_icon_option = '[data-icon-value="cog"]'

      get "/accounts/#{Account.default.id}/settings"

      set_value f(help_link_name_input), link_name
      f(help_link_icon_option).click

      click_submit

      expect(Account.default.settings[:help_link_name]).to eq link_name
      expect(Account.default.settings[:help_link_icon]).to eq icon

      expect(f(help_link_name_input)).to have_value link_name
      expect(is_checked(f("#{help_link_icon_option} input"))).to be_truthy
    end

    it "should not delete all of the pre-existing custom help links if notifications tab is submitted" do
      Account.default.settings[:custom_help_links] = [
          {"text"=>"text", "subtext"=>"subtext", "url"=>"http://www.example.com/example", "available_to"=>["user", "student", "teacher"]}]
      Account.default.save!

      get "/accounts/#{Account.default.id}/settings"

      f("#tab-notifications-link").click
      f("#account_settings_notifications button[type=submit]").click
      wait_for_ajax_requests

      expect(Account.default.settings[:custom_help_links]).to eq [
        {"text"=>"text", "subtext"=>"subtext", "url"=>"http://www.example.com/example", "available_to"=>["user", "student", "teacher"]}
      ]
    end

    it "should preserve the default help links if the account hasn't been configured with the new ui yet" do
      help_link = {:text => "text", :subtext => "subtext", :url => "http://www.example.com/example", :available_to => ["user", "student", "teacher"]}
      Account.default.settings[:custom_help_links] = [help_link]
      Account.default.save!

      help_links = Account.default.help_links
      expect(help_links).to include(help_link.merge(:type => "custom"))
      expect(help_links & Account::HelpLinks.instantiate_links(Account::HelpLinks.default_links)).to eq(
                                                                                                       Account::HelpLinks.instantiate_links(Account::HelpLinks.default_links))

      get "/accounts/#{Account.default.id}/settings"

      top = f('#custom_help_link_settings .ic-Sortable-item')
      top.find_elements(:css, 'button').last.click
      wait_for_ajaximations

      click_submit

      new_help_links = Account.default.help_links
      expect(new_help_links.map { |x| x[:id] }).to_not include(Account::HelpLinks.default_links.first[:id].to_s)
      expect(new_help_links.map { |x| x[:id] }).to include(Account::HelpLinks.default_links.last[:id].to_s)
      expect(new_help_links.last).to include(help_link)
    end

    it "adds a custom link" do
      get "/accounts/#{Account.default.id}/settings"
      f('.HelpMenuOptions__Container button').click
      fj('[role="menuitemradio"] span:contains("Add Custom Link")').click
      replace_content fj('#custom_help_link_settings input[name$="[text]"]:visible'), 'text'
      replace_content fj('#custom_help_link_settings textarea[name$="[subtext]"]:visible'), 'subtext'
      replace_content fj('#custom_help_link_settings input[name$="[url]"]:visible'), 'https://url.example.com'
      move_to_click('#custom_help_link_settings button[type="submit"]')
      wait_for_animations
      trigger_form_submit_event('#account_settings')
      wait_for_ajaximations
      cl = Account.default.help_links.detect do |hl|
        hl_indifferent = HashWithIndifferentAccess.new(hl)
        hl_indifferent['url'] == 'https://url.example.com'
      end
      expect(cl).to include({"text"=>"text", "subtext"=>"subtext", "url"=>"https://url.example.com", "type"=>"custom", "available_to"=>["user", "student", "teacher", "admin", "observer", "unenrolled"]})
    end

    it "edits a custom link" do
      a = Account.default
      a.settings[:custom_help_links] = [{"text"=>"custom-link-text-frd", "subtext"=>"subtext", "url"=>"https://url.example.com", "type"=>"custom", "available_to"=>["user", "student", "teacher", "admin"]}]
      a.save!
      get "/accounts/#{Account.default.id}/settings"
      fj('#custom_help_link_settings span:contains("Edit custom-link-text-frd")').find_element(:xpath, '..').click
      replace_content fj('#custom_help_link_settings input[name$="[url]"]:visible'), 'https://whatever.example.com'
      f('#custom_help_link_settings button[type="submit"]').click
      wait_for_animations
      trigger_form_submit_event('#account_settings')
      wait_for_ajax_requests
      cl = Account.default.help_links.detect do |hl|
        hl_indifferent = HashWithIndifferentAccess.new(hl)
        hl_indifferent['url'] == 'https://whatever.example.com'
      end
      expect(cl).not_to be_blank
    end

    it "edits a default link" do
      get "/accounts/#{Account.default.id}/settings"
      fj('#custom_help_link_settings span:contains("Edit Report a Problem")').find_element(:xpath, '..').click
      url = fj('#custom_help_link_settings input[name$="[url]"]:visible')
      expect(url).to be_disabled
      fj('#custom_help_link_settings fieldset .ic-Label:contains("Teachers"):visible').click
      f('#custom_help_link_settings button[type="submit"]').click
      wait_for_animations
      trigger_form_submit_event('#account_settings')
      wait_for_ajax_requests
      cl = Account.default.help_links.detect do |hl|
        hl_indifferent = HashWithIndifferentAccess.new(hl)
        hl_indifferent['url'] == '#create_ticket'
      end
      expect(cl['available_to']).not_to include('teacher')
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
      allow(ExternalIntegrationKey).to receive(:key_types).and_return([])
      get "/accounts/#{Account.default.id}/settings"
      expect(f("#account_settings")).not_to contain_css("#external_integration_keys")
    end

    it "should not display external integration keys if no rights are granted" do
      allow_any_instance_of(ExternalIntegrationKey).to receive(:grants_right_for?).and_return(false)
      get "/accounts/#{Account.default.id}/settings"
      expect(f("#account_settings")).not_to contain_css("#external_integration_keys")
    end

    it "should display keys with the correct rights" do
      get "/accounts/#{Account.default.id}/settings"

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
      expect(f("#account_settings")).not_to contain_css("label[for='account_external_integration_keys_external_key2']")

      expect(f("#account_external_integration_keys_external_key0")).to have_value key_value
      expect(f("#external_integration_keys span").text).to eq key_value
      expect(f("#account_settings")).not_to contain_css("#account_external_integration_keys_external_key2")
    end

    it "should update writable keys" do
      get "/accounts/#{Account.default.id}/settings"

      set_value f("#account_external_integration_keys_external_key0"), key_value
      click_submit

      expect(f("#account_external_integration_keys_external_key0")).to have_value key_value

      set_value f("#account_external_integration_keys_external_key0"), ''
      click_submit

      expect(f("#account_external_integration_keys_external_key0")).to have_value ''
    end
  end

  it "shows all feature flags that are expected to be visible" do
    course_with_admin_logged_in(:account => Account.site_admin)
    enable_all_rcs @course.account
    provision_quizzes_next @course

    get "/accounts/#{Account.site_admin.id}/settings"
    f("#tab-features-link").click
    wait_for_ajaximations

    Feature.applicable_features(Account.site_admin).each do |feature|
      next if feature.visible_on && !feature.visible_on.call(Account.site_admin)
      expect(f(".feature.#{feature.feature}")).to be_displayed
    end
  end
end
