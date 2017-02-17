require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "admin settings tab" do
  include_context "in-process server selenium tests"
  let(:account) { Account.default }
  let(:sub_account) { account.sub_accounts.create!(:name => 'sub-account') }

  before :each do
    user_logged_in(:user => site_admin_user(account: account))
  end

  def get_settings_page(account)
    get "/accounts/#{account.id}/settings"
  end

  def set_checkbox(id,checked)
    checkbox = f(id)
    checkbox.click if is_checked(checkbox) != checked
  end

  def set_checkbox_via_label(id,checked)
    # Use this method for checkboxes that are hidden by their label (ic-Checkbox)
    checkbox = f(id)
    label = f("label[for=\"#{id[1..-1]}\"]")
    label.click if is_checked(checkbox) != checked
  end

  def get_checkbox(id)
    checkbox = f(id)
    is_checked(checkbox)
  end

  def click_submit
    expect_new_page_load do
      f("#account_settings button[type=submit]").click
    end
  end

  context "SIS Agent Token Authentication" do
    let(:sis_token){ 'too much tuna' }

    it "should test SIS Agent Token Authentication with post_grades feature enabled", priority: "2", test_id: 132577 do
      course_with_admin_logged_in(:account => Account.site_admin)
      account.enable_feature!(:post_grades)

      get_settings_page(account)
      expect(f("#add_sis_app_token")).to be_displayed
      expect(f("#account_settings_sis_app_token")).to be_displayed
      f("#account_settings_sis_app_token").send_keys(sis_token)
      click_submit
      token = f("#account_settings_sis_app_token")
      expect(token).to have_value(sis_token)
    end

    it "should test SIS Agent Token Authentication with post_grades feature disabled", priority: "2", test_id: 132578 do
      course_with_admin_logged_in(:account => Account.site_admin)
      get_settings_page(account)
      expect(f("#add_sis_app_token")).to be_displayed
      expect(f("#account_settings_sis_app_token")).to be_displayed
      f("#account_settings_sis_app_token").send_keys(sis_token)
      click_submit
      token = f("#account_settings_sis_app_token")
      expect(token).to have_value(sis_token)
    end
  end

  context "SIS Integration Settings" do
    let(:allow_sis_import) { "#account_allow_sis_import" }
    let(:sis_syncing) { "#account_settings_sis_syncing_value" }
    let(:sis_syncing_locked) { "#account_settings_sis_syncing_locked" }
    let(:default_grade_export) { "#account_settings_sis_default_grade_export_value" }
    let(:require_assignment_due_date) { "#account_settings_sis_require_assignment_due_date_value" }
    let(:sis_name) { "#account_settings_sis_name" }
    let(:assignment_name_length) { "#account_settings_sis_assignment_name_length_value" }
    let(:assignment_name_length_input) { "#account_settings_sis_assignment_name_length_input_value" }

    def test_checkbox_on_off(id)
      set_checkbox_via_label(id,true)
      click_submit
      expect(get_checkbox(id)).to be_truthy

      set_checkbox_via_label(id,false)
      click_submit
      expect(get_checkbox(id)).to be_falsey
    end

    context ":new_sis_integrations => false" do
      before do
        account.set_feature_flag! :new_sis_integrations, 'off'
      end

      it "persists SIS import settings on refresh" do
        get_settings_page(account)
        test_checkbox_on_off(allow_sis_import)
      end

      it "does not display SIS syncing setting" do
        get_settings_page(account)
        expect(f("body")).not_to contain_css(sis_syncing)
      end

      context "SIS post grades disabled" do
        before do
          account.set_feature_flag! 'post_grades', 'off'
          get_settings_page(account)
        end

        it "does not display 'Post Grades to SIS'" do
          expect(f("body")).not_to contain_css(default_grade_export)
        end
      end

      context "SIS post grades enabled" do
        before do
          account.set_feature_flag! 'post_grades', 'on'
          get_settings_page(account)
        end

        it "persists 'Post Grades to SIS' on refresh" do
          test_checkbox_on_off(default_grade_export)
        end
      end
    end

    context ":new_sis_integrations => true (sub account)" do
      before do
        account.set_feature_flag! :new_sis_integrations, 'on'
        get_settings_page(sub_account)
      end

      it "should have SIS name setting disabled for sub accounts" do
        name_setting = f(sis_name)
        expect(name_setting.displayed?).to be_truthy
        expect(name_setting.enabled?).to be_falsey
      end
    end

    context ":new_sis_integrations => true (root account)" do
      before do
        account.set_feature_flag! :new_sis_integrations, 'on'
      end

      it "should persist custom SIS name" do
        get_settings_page(account)
        custom_sis_name = "PowerSchool"
        f(sis_name).send_keys(custom_sis_name)
        click_submit
        expect(f(sis_name)).to have_value(custom_sis_name)
      end

      it "persists SIS import settings on refresh" do
        get_settings_page(account)
        test_checkbox_on_off(allow_sis_import)
      end

      context "persists SIS syncing settings on refresh" do
        before do
          account.set_feature_flag! 'post_grades', 'on'
        end

        it do
          get_settings_page(account)
          test_checkbox_on_off(sis_syncing)
        end

        context "SIS syncing => true" do
          before do
            account.settings = { sis_syncing: { value: true } }
            account.save
            get_settings_page(account)
          end

          it { test_checkbox_on_off(sis_syncing_locked) }
          it "toggles require assignment due date" do
            set_checkbox_via_label(default_grade_export,true)
            test_checkbox_on_off(require_assignment_due_date)
          end

          it "toggles assignment name length" do
            set_checkbox_via_label(default_grade_export,true)
            test_checkbox_on_off(assignment_name_length)
          end

          it "should test sis assignment name length" do
            set_checkbox_via_label(default_grade_export,true)
            set_checkbox_via_label(assignment_name_length,true)
            name_length = 123
            f("#account_settings_sis_assignment_name_length_input_value").send_keys(name_length)
            click_submit
            expect(f("#account_settings_sis_assignment_name_length_input_value")).to have_value(name_length.to_s)
          end
        end
      end

      context "SIS post grades disabled" do
        before do
          account.set_feature_flag! 'post_grades', 'off'
          get_settings_page(account)
        end

        it "does not display SIS Syncing option" do
          expect(f("body")).not_to contain_css(sis_syncing)
        end

        it "does not display the 'Post Grades to SIS' option" do
          expect(f("body")).not_to contain_css(default_grade_export)
        end
      end

      context "SIS post grades enabled" do
        before do
          account.set_feature_flag! 'post_grades', 'on'
        end

        context "SIS syncing => false" do
          before do
            account.settings = { sis_syncing: { value: false } }
            account.save
            get_settings_page(account)
          end

          it "does not display the 'Post Grades to SIS' option" do
            expect(f(default_grade_export)).not_to be_displayed
          end
        end

        context "SIS syncing => true" do
          before do
            account.settings = { sis_syncing: { value: true } }
            account.save
            get_settings_page(account)
          end

          it "persists 'Post Grades to SIS' settings on refresh" do
            test_checkbox_on_off(default_grade_export)
          end
        end
      end

      context "root and sub-accounts" do
        before do
          account.set_feature_flag! 'post_grades', 'on'
        end

        context "unlocked for sub-accounts" do
          before do
            account.settings = { sis_syncing: { value: true, locked: false } }
            account.save
          end

          it "allows SIS integration settings to change in sub-account" do
            get_settings_page(sub_account)
            expect(f(sis_syncing)).not_to be_disabled
            expect(f(sis_syncing_locked)).not_to be_disabled
            expect(f(require_assignment_due_date)).not_to be_disabled
            expect(f(assignment_name_length)).not_to be_disabled
            expect(f(default_grade_export)).not_to be_disabled
          end
        end

        context "locked for sub-accounts" do
          before do
            account.settings = { sis_syncing: { value: true, locked: true } }
            account.save
          end

          it "doesn't allow SIS integration settings to change in sub-account" do
            get_settings_page(sub_account)
            expect(f(sis_syncing)).to be_disabled
            expect(f(sis_syncing_locked)).to be_disabled
            expect(f(require_assignment_due_date)).to be_disabled
            expect(f(assignment_name_length)).to be_disabled
            expect(f(default_grade_export)).to be_disabled
          end
        end

      end

    end
  end
end
