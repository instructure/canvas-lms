# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../common"

describe "admin settings tab" do
  include_context "in-process server selenium tests"
  before :once do
    account_admin_user
  end

  before do
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

  def state_checker(checker, check_state)
    if checker
      expect(check_state).to be_truthy
    else
      expect(check_state).to be_falsey
    end
  end

  def check_box_verifier(css_selectors, features, checker = true)
    is_symbol = false

    css_selectors = [css_selectors] unless css_selectors.is_a? Array

    if features.is_a? Symbol
      is_symbol = true
      if features == :all_selectors
        features = get_default_services
      end
    end
    if (features.is_a? Array) && !checker
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
      sel = f(selector)
      scroll_into_view(sel)
      sel.click
    end
    click_submit
    if is_symbol == false
      check_state = Account.default.service_enabled?(features[:allowed_services])
      state_checker checker, check_state
    elsif features.is_a? Array
      default_selectors = []
      features.each do |feature|
        check_state = Account.default.service_enabled?(feature)
        state_checker checker, check_state
        default_selectors.push("#account_services_#{feature}")
      end
      if checker
        default_selectors += css_selectors
      end
      css_selectors = default_selectors
    else
      check_state = Account.default.settings[features]
      state_checker checker, check_state
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
    f("#tab-features").click
    wait_for_ajaximations
  end

  def select_filter_option(option_text)
    feature_filter_element = f("[placeholder='Filter Features']")
    feature_filter_element.send_keys(option_text[0..3])
    feature_filter_item = fj("[role='option']:contains('#{option_text}')")
    feature_filter_item.click
  end

  context "account settings" do
    before do
      get "/accounts/#{Account.default.id}/settings"
    end

    it "changes the default time zone to Lima" do
      f("#account_default_time_zone option[value='Lima']").click
      click_submit
      expect(Account.default.default_time_zone.name).to eq "Lima"
      expect(f("#account_default_time_zone option[value='Lima']")).to have_attribute("selected", "true")
    end

    describe "allow self-enrollment" do
      def enrollment_helper(value = "")
        if value == ""
          f("#account_settings_self_enrollment option[value='']").click
        else
          f("#account_settings_self_enrollment option[value=#{value}]").click
        end
        click_submit
        expect(Account.default[:settings][:self_enrollment]).to eq value.presence
        expect(f("#account_settings_self_enrollment")).to have_value value
      end

      it "selects never for self-enrollment" do
        enrollment_helper
      end

      it "selects self-enrollment for any courses" do
        enrollment_helper "any"
      end

      it "selects self-enrollment for manually-created courses" do
        enrollment_helper "manually_created"
      end
    end

    it "clicks on don't let teachers rename their courses" do
      check_box_verifier("#account_settings_prevent_course_renaming_by_teachers", :prevent_course_renaming_by_teachers)
    end

    it "clicks on don't let teachers change availability on their courses" do
      check_box_verifier("#account_settings_prevent_course_availability_editing_by_teachers", :prevent_course_availability_editing_by_teachers)
    end

    it "unchecks 'students can opt-in to receiving scores in email notifications'" do
      check_box_verifier("#account_settings_allow_sending_scores_in_emails", :allow_sending_scores_in_emails, false)
    end

    it "sets trusted referers for account" do
      trusted_referers = "https://example.com,http://example.com"
      set_value f("#account_settings_trusted_referers"), trusted_referers
      click_submit
      expect(Account.default[:settings][:trusted_referers]).to eq trusted_referers
      expect(f("#account_settings_trusted_referers")).to have_value trusted_referers

      set_value f("#account_settings_trusted_referers"), ""
      click_submit
      expect(Account.default[:settings][:trusted_referers]).to be_nil
      expect(f("#account_settings_trusted_referers")).to have_value ""
    end
  end

  context "quiz ip address filter" do
    def add_quiz_filter(name = "www.canvas.instructure.com", value = "192.168.217.1/24")
      link = f(%(button[data-testid="add-ip-filter"]))
      scroll_into_view(link)
      link.click
      fj(%(input[data-testid="ip-filter-name"]:last)).send_keys name
      fj(%(input[data-testid="ip-filter-filter"]:last)).send_keys value
      click_submit
      filter_hash = { name => value }
      expect(Account.default.settings[:ip_filters]).to include filter_hash
      expect(fj(%(input[data-testid="ip-filter-name"][value='#{name}']))).to be_displayed
      expect(fj(%(input[data-testid="ip-filter-filter"][value='#{value}']))).to be_displayed
      filter_hash
    end

    def create_quiz_filter(name = "www.canvas.instructure.com", value = "192.168.217.1/24")
      Account.default.tap do |a|
        a.settings[:ip_filters] ||= {}
        a.settings[:ip_filters].store(name, value)
        a.save!
      end
    end

    it "adds a quiz filter" do
      get "/accounts/#{Account.default.id}/settings"
      add_quiz_filter
    end

    it "adds another quiz filter" do
      create_quiz_filter
      get "/accounts/#{Account.default.id}/settings"
      add_quiz_filter "www.canvas.instructure.com/tests", "129.186.127.12/4"
    end

    it "edits a quiz filter" do
      create_quiz_filter
      get "/accounts/#{Account.default.id}/settings"
      new_name = "www.example.org"
      new_value = "10.192.124.12/8"
      replace_content(f(%(input[data-testid="ip-filter-name"])), new_name)
      replace_content(f(%(input[data-testid="ip-filter-filter"])), new_value)
      click_submit
      filter_hash = { new_name => new_value }
      expect(Account.default.settings[:ip_filters]).to include filter_hash
      expect(fj(%(input[data-testid="ip-filter-name"][value='#{new_name}']))).to be_displayed
      expect(fj(%(input[data-testid="ip-filter-filter"][value='#{new_value}']))).to be_displayed
    end

    it "deletes a quiz filter" do
      create_quiz_filter
      get "/accounts/#{Account.default.id}/settings"
      link = f(%([data-testid="delete-ip-filter"]))
      scroll_into_view(link)
      link.click
      click_submit
      expect(f("#account_settings_quiz_ip_filters")).to include_text "No Quiz IP filters have been set"
      expect(Account.default.settings[:ip_filters]).to be_blank
    end
  end

  context "features" do
    before do
      get "/accounts/#{Account.default.id}/settings"
    end

    it "checks 'open registration'" do
      check_box_verifier("#account_settings_open_registration", :open_registration)
    end

    it "unchecks users can edit display name' and check it again" do
      check_box_verifier("#account_settings_users_can_edit_name", :users_can_edit_name, false)
      check_box_verifier("#account_settings_users_can_edit_name", :users_can_edit_name)
    end

    it "unchecks users_can_edit_profile and check it again" do
      check_box_verifier("#account_settings_users_can_edit_profile", :users_can_edit_profile, false)
      check_box_verifier("#account_settings_users_can_edit_profile", :users_can_edit_profile)
    end

    it "unchecks users_can_edit_comm_channels and check it again" do
      check_box_verifier("#account_settings_users_can_edit_comm_channels", :users_can_edit_comm_channels, false)
      check_box_verifier("#account_settings_users_can_edit_comm_channels", :users_can_edit_comm_channels)
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

      before do
        equella = f("#enable_equella")
        scroll_into_view(equella)
        equella.click
      end

      it "adds an equella feature" do
        add_equella_feature
      end

      it "edits an equella feature" do
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

      it "deletes an equella feature" do
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
    before do
      get "/accounts/#{Account.default.id}/settings"
    end

    it "clicks on the google help dialog" do
      question = f("label[for='account_services_google_docs_previews'] .icon-question")
      scroll_into_view(question)
      question.click
      expect(f("[data-testid='about-google-docs']")).to include_text("About Google Docs Previews")
    end

    it "unclicks and then click on skype" do
      check_box_verifier("#account_services_skype", { allowed_services: :skype }, false)
      check_box_verifier("#account_services_skype", { allowed_services: :skype })
    end

    it "unclicks and click on google docs previews" do
      check_box_verifier("#account_services_google_docs_previews", { allowed_services: :google_docs_previews }, false)
      check_box_verifier("#account_services_google_docs_previews", { allowed_services: :google_docs_previews })
    end

    it "clicks on user avatars" do
      check_box_verifier("#account_services_avatars", { allowed_services: :avatars })
      check_box_verifier("#account_services_avatars", { allowed_services: :avatars }, false)
    end

    it "disables all web services" do
      check_box_verifier(nil, :all_selectors, false)
    end

    it "enables all web services" do
      check_box_verifier("#account_services_avatars", :all_selectors)
    end

    it "enables and disable a plugin service (setting)" do
      AccountServices.register_service(:myplugin, { name: "My Plugin", description: "", expose_to_ui: :setting, default: false })
      get "/accounts/#{Account.default.id}/settings"
      check_box_verifier("#account_services_myplugin", { allowed_services: :myplugin })
      check_box_verifier("#account_services_myplugin", { allowed_services: :myplugin }, false)
    end

    it "enables and disable a plugin service (service)" do
      AccountServices.register_service(:myplugin, { name: "My Plugin", description: "", expose_to_ui: :service, default: false })
      get "/accounts/#{Account.default.id}/settings"
      check_box_verifier("#account_services_myplugin", { allowed_services: :myplugin })
      check_box_verifier("#account_services_myplugin", { allowed_services: :myplugin }, false)
    end
  end

  context "who can create new courses" do
    before do
      get "/accounts/#{Account.default.id}/settings"
    end

    it "checks on teachers" do
      check_box_verifier("#account_settings_teachers_can_create_courses", :teachers_can_create_courses)
    end

    it "checks on users with no enrollments" do
      check_box_verifier("#account_settings_no_enrollments_can_create_courses", :no_enrollments_can_create_courses)
    end

    it "checks on students" do
      check_box_verifier("#account_settings_students_can_create_courses", :students_can_create_courses)
    end
  end

  context "custom help links" do
    def set_checkbox(checkbox, checked)
      selector = "##{checkbox["id"]}"
      checkbox.click if is_checked(selector) != checked
    end

    it "sets custom help link text and icon" do
      link_name = "Links"
      icon = "cog"
      help_link_name_input = '[name="account[settings][help_link_name]"]'
      help_link_icon_option = '[data-icon-value="cog"]'

      get "/accounts/#{Account.default.id}/settings"

      set_value f(help_link_name_input), link_name
      option = f(help_link_icon_option)
      scroll_into_view(option)
      option.click

      click_submit

      expect(Account.default.settings[:help_link_name]).to eq link_name
      expect(Account.default.settings[:help_link_icon]).to eq icon

      expect(f(help_link_name_input)).to have_value link_name
      expect(is_checked(f("#{help_link_icon_option} input"))).to be_truthy
    end

    it "does not delete all of the pre-existing custom help links if notifications tab is submitted" do
      Account.default.settings[:custom_help_links] = [
        { "text" => "text", "subtext" => "subtext", "url" => "http://www.example.com/example", "available_to" => %w[user student teacher] }
      ]
      Account.default.save!

      get "/accounts/#{Account.default.id}/settings"

      f("#tab-notifications").click
      wait_for_ajax_requests
      f("#tab-notifications-mount button").click
      wait_for_ajax_requests

      expect(Account.default.settings[:custom_help_links]).to eq [
        { "text" => "text", "subtext" => "subtext", "url" => "http://www.example.com/example", "available_to" => %w[user student teacher] }
      ]
    end

    it "preserves the default help links if the account hasn't been configured with the new ui yet" do
      help_link = { text: "text", subtext: "subtext", url: "http://www.example.com/example", available_to: %w[user student teacher] }
      Account.default.settings[:custom_help_links] = [help_link]
      Account.default.save!

      wait_for_ajaximations
      default_links = Account.default.help_links_builder.instantiate_links(Account.default.help_links_builder.default_links)
      filtered_links = Account.default.help_links_builder.filtered_links(default_links)
      help_links = Account.default.help_links
      wait_for_ajaximations
      expect(help_links).to include(help_link.merge(type: "custom"))
      expect(help_links & filtered_links).to eq(filtered_links)

      get "/accounts/#{Account.default.id}/settings"
      top = f("#custom_help_link_settings .ic-Sortable-item")
      last_button = top.find_elements(:css, "button").last
      scroll_into_view(last_button)
      last_button.click
      wait_for_ajaximations

      click_submit
      new_help_links = Account.default.help_links
      expect(new_help_links.pluck(:id)).to_not include(Account.default.help_links_builder.filtered_links(default_links).first[:id].to_s)
      expect(new_help_links.pluck(:id)).to include(Account.default.help_links_builder.filtered_links(default_links).last[:id].to_s)
      expect(new_help_links.last).to include(help_link)
    end

    it "adds a custom link" do
      get "/accounts/#{Account.default.id}/settings"
      wait_for_ajaximations

      # Click the Help Options button first
      help_options = f(".HelpMenuOptions__Container button")
      scroll_into_view(help_options)
      help_options.click
      wait_for_ajaximations

      # Click "Add Custom Link" in the menu
      fj('[role="menuitemradio"] span:contains("Add Custom Link")').click
      wait_for_ajaximations

      # Fill in the form fields
      replace_content f("#admin_settings_custom_link_name"), "text"
      replace_content f("#admin_settings_custom_link_subtext"), "subtext"
      replace_content f("#admin_settings_custom_link_url"), "http://example.com"

      # Click the label for the user checkbox
      user_label = f('label[for="admin_settings_custom_link_type_user"]')
      scroll_into_view(user_label)
      user_label.click

      # Click submit
      submit = f('#custom_help_link_settings button[type="submit"]')
      scroll_into_view(submit)
      submit.click
      wait_for_ajaximations

      added_item = ff(".ic-Sortable-item .ic-Sortable-item__Text").find { |item| item.text == "text" }
      expect(added_item).to be_present
      expect(added_item.text).to eq "text"
    end

    it "adds a custom link with New designation" do
      get "/accounts/#{Account.default.id}/settings"
      help_options = f(".HelpMenuOptions__Container button")
      scroll_into_view(help_options)
      help_options.click
      fj('[role="menuitemradio"] span:contains("Add Custom Link")').click
      replace_content f("#admin_settings_custom_link_name"), "text"
      replace_content f("#admin_settings_custom_link_subtext"), "subtext"
      replace_content f("#admin_settings_custom_link_url"), "https://newurl.example.com"
      new_label = fj('#custom_help_link_settings fieldset .ic-Label:contains("New"):visible')
      scroll_into_view(new_label)
      new_label.click
      link = f('#custom_help_link_settings button[type="submit"]')
      scroll_into_view(link)
      link.click
      wait_for_ajaximations
      form = f("#account_settings")
      form.submit
      cl = Account.default.help_links.detect { |hl| hl["url"] == "https://newurl.example.com" }
      expect(cl).to include(
        {
          "is_featured" => false,
          "is_new" => true,
        }
      )
    end

    it "edits a custom link" do
      a = Account.default
      a.settings[:custom_help_links] = [{ "text" => "custom-link-text-frd", "subtext" => "subtext", "url" => "https://url.example.com", "type" => "custom", "available_to" => %w[user student teacher admin] }]
      a.save!
      get "/accounts/#{Account.default.id}/settings"
      link = fj('#custom_help_link_settings span:contains("Edit custom-link-text-frd")').find_element(:xpath, "..")
      scroll_into_view(link)
      link.click
      replace_content f("#admin_settings_custom_link_url"), "https://whatever.example.com"
      f('#custom_help_link_settings button[type="submit"]').click
      expect(fj(".ic-Sortable-item:last .ic-Sortable-item__Text")).to include_text("custom-link-text-frd")
      form = f("#account_settings")
      form.submit
      cl = Account.default.help_links.detect { |hl| hl["url"] == "https://whatever.example.com" }
      expect(cl).not_to be_blank
    end

    it "edits a default link" do
      Setting.set("show_feedback_link", "true")

      get "/accounts/#{Account.default.id}/settings"
      link = fj('#custom_help_link_settings span:contains("Edit Report a Problem")').find_element(:xpath, "..")
      scroll_into_view(link)
      link.click
      url = f("#admin_settings_custom_link_url")
      expect(url).to be_disabled
      teachers_label = fj('#custom_help_link_settings fieldset .ic-Label:contains("Teachers"):visible')
      scroll_into_view(teachers_label)
      teachers_label.click
      f('#custom_help_link_settings button[type="submit"]').click
      expect(f(".ic-Sortable-item:nth-of-type(3) .ic-Sortable-item__Text")).to include_text("Report a Problem")
      form = f("#account_settings")
      form.submit
      cl = Account.default.help_links.detect { |hl| hl["url"] == "#create_ticket" }
      expect(cl["available_to"]).not_to include("teacher")
    end
  end

  context "external integration keys" do
    let!(:key_value) { "42" }

    before(:once) do
      ExternalIntegrationKey.key_type :external_key0, label: "External Key 0", rights: { read: proc { true }, write: true }
      ExternalIntegrationKey.key_type :external_key1, label: proc { "External Key 1" }, rights: { read: true, write: false }
      ExternalIntegrationKey.key_type :external_key2, label: "External Key 2", rights: { read: proc { false }, write: false }
    end

    it "does not display external integration keys if no key types exist" do
      allow(ExternalIntegrationKey).to receive(:key_types).and_return([])
      get "/accounts/#{Account.default.id}/settings"
      expect(f("#account_settings")).not_to contain_css("#external_integration_keys")
    end

    it "does not display external integration keys if no rights are granted" do
      allow_any_instance_of(ExternalIntegrationKey).to receive(:grants_right_for?).and_return(false)
      get "/accounts/#{Account.default.id}/settings"
      expect(f("#account_settings")).not_to contain_css("#external_integration_keys")
    end

    it "displays keys with the correct rights" do
      get "/accounts/#{Account.default.id}/settings"

      eik = ExternalIntegrationKey.new
      eik.context = Account.default
      eik.key_type = "external_key0"
      eik.key_value = key_value
      eik.save

      eik = ExternalIntegrationKey.new
      eik.context = Account.default
      eik.key_type = "external_key1"
      eik.key_value = key_value
      eik.save

      get "/accounts/#{Account.default.id}/settings"

      expect(f("label[for='account_external_integration_keys_external_key0']").text).to eq "External Key 0:"
      expect(f("label[for='account_external_integration_keys_external_key1']").text).to eq "External Key 1:"
      expect(f("#account_settings")).not_to contain_css("label[for='account_external_integration_keys_external_key2']")

      expect(f("#account_external_integration_keys_external_key0")).to have_value key_value
      expect(f("#external_integration_keys span").text).to eq key_value
      expect(f("#account_settings")).not_to contain_css("#account_external_integration_keys_external_key2")
    end

    it "updates writable keys" do
      get "/accounts/#{Account.default.id}/settings"

      set_value f("#account_external_integration_keys_external_key0"), key_value
      click_submit

      expect(f("#account_external_integration_keys_external_key0")).to have_value key_value

      set_value f("#account_external_integration_keys_external_key0"), ""
      click_submit

      expect(f("#account_external_integration_keys_external_key0")).to have_value ""
    end
  end

  it "shows all feature flags that are expected to be visible" do
    user = account_admin_user({ active_user: true }.merge(account: Account.site_admin))
    course_with_admin_logged_in(account: Account.default, user:)
    provision_quizzes_next(Account.default)
    get "/accounts/#{Account.default.id}/settings"
    wait_for_new_page_load
    f("#tab-features").click
    wait_for_ajaximations
    features_text = f("#features-selected").text

    Feature.applicable_features(Account.default).each do |feature|
      next if feature.visible_on && !feature.visible_on.call(Account.default)

      # We don't want flags that are enabled in code to appear in the UI
      if feature.enabled? && !feature.can_override?
        expect(features_text).not_to include(feature.display_name.call)
      else
        expect(features_text).to include(feature.display_name.call)
      end
    end
  end

  context "Canvas for Elementary (enable_as_k5_mode) setting", :ignore_js_errors do
    before :once do
      @account = Account.default
      @subaccount = Account.create!(name: "subaccount1", parent_account_id: @account.id)
    end

    it "is locked and enabled for subaccounts of an account where setting is enabled" do
      account_admin_user(account: @account)
      user_session(@admin)
      get "/accounts/#{@account.id}/settings"
      checkbox = "#account_settings_enable_as_k5_account_value"
      box = f(checkbox)
      scroll_into_view(box)
      box.click
      click_submit
      get "/accounts/#{@subaccount.id}/settings"
      expect(is_checked(checkbox)).to be_truthy
      expect(f(checkbox)).to be_disabled
    end
  end

  context "Limited Access for Students" do
    before do |test|
      @account = Account.default
      @current_user = @user
      allow(@account).to receive(:grants_right?).with(@current_user, :manage_account_settings).and_return(true)
      @account.enable_feature!(:allow_limited_access_for_students) if test.metadata[:enable_feature]
      get "/accounts/#{Account.default.id}/settings"
    end

    it "displays enable_limited_access_for_students if feature flag is enabled", :enable_feature do
      expect(f("#account_settings")).to contain_css("#account_settings_enable_limited_access_for_students")
    end

    it "does not display enable_limited_access_for_students if feature flag is disabled" do
      expect(f("#account_settings")).not_to contain_css("#account_settings_enable_limited_access_for_students")
    end
  end
end
