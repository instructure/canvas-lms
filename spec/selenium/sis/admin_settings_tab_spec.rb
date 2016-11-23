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
    wait_for_ajaximations
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
    f("#account_settings button[type=submit]").click
    wait_for_ajaximations
  end

  def go_to_feature_options(account)
    get_settings_page(account)
    f("#tab-features-link").click
    wait_for_ajaximations
  end

  context "SIS Agent Token Authentication" do
    it "should test SIS Agent Token Authentication", priority: "2", test_id: 132577 do
      course_with_admin_logged_in(:account => Account.site_admin)
      sis_token = "canvas"
      go_to_feature_options(Account.site_admin)
      move_to_click("label[for=ff_allowed_post_grades]")
      go_to_feature_options(account)
      move_to_click("label[for=ff_allowed_post_grades]")
      f("#tab-settings-link").click
      # SIS Agent Token Authentication will not appear without refresh
      refresh_page
      expect(f("#add_sis_app_token")).to be_displayed
      expect(f("#account_settings_sis_app_token")).to be_displayed
      f("#account_settings_sis_app_token").send_keys(sis_token)
      f(".Button--primary").click
      token = f("#account_settings_sis_app_token")
      keep_trying_until do
        expect(token.attribute("value")).to eq sis_token
      end
      go_to_feature_options(account)
      move_to_click("label[for=ff_off_post_grades]")
      f('#tab-settings-link').click
      refresh_page
      expect(f("#account_settings")).not_to contain_css("#account_settings_sis_app_token")
    end
  end

  context "SIS Integration Settings" do
    let(:allow_sis_import) { "#account_allow_sis_import" }
    let(:sis_syncing) { "#account_settings_sis_syncing_value" }
    let(:sis_syncing_locked) { "#account_settings_sis_syncing_locked" }
    let(:default_grade_export) { "#account_settings_sis_default_grade_export_value" }
    let(:require_assignment_due_date) { "#account_settings_sis_require_assignment_due_date_value" }

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
        get_settings_page(account)
      end

      it "persists SIS import settings on refresh" do
        test_checkbox_on_off(allow_sis_import)
      end

      it "does not display SIS syncing setting" do
        expect(f("body")).not_to contain_css(sis_syncing)
      end

      context "SIS grade export disabled" do
        before do
          account.set_feature_flag! :bulk_sis_grade_export, 'off'
          account.set_feature_flag! 'post_grades', 'off'
          get_settings_page(account)
        end

        it "does not display 'Post Grades to SIS'" do
          expect(f("body")).not_to contain_css(default_grade_export)
        end
      end

      context "SIS grade export enabled" do
        before do
          account.set_feature_flag! :bulk_sis_grade_export, 'on'
          account.set_feature_flag! 'post_grades', 'on'
          get_settings_page(account)
        end

        it "persists 'Post Grades to SIS' on refresh" do
          test_checkbox_on_off(default_grade_export)
        end
      end
    end

    context ":new_sis_integrations => true" do
      before do
        account.set_feature_flag! :new_sis_integrations, 'on'
        get_settings_page(account)
      end

      it "persists SIS import settings on refresh" do
        test_checkbox_on_off(allow_sis_import)
      end

      context "persists SIS syncing settings on refresh" do
        it { test_checkbox_on_off(sis_syncing) }

        context "SIS syncing => true" do
          before do
            account.set_feature_flag! :bulk_sis_grade_export, 'on'
            account.set_feature_flag! 'post_grades', 'on'
            account.settings = { sis_syncing: { value: true } }
            account.save
            get_settings_page(account)
          end

          it { test_checkbox_on_off(sis_syncing_locked) }
          it { set_checkbox_via_label(default_grade_export,true)
               click_submit
               test_checkbox_on_off(require_assignment_due_date) }
        end
      end

      context "SIS grade export disabled" do
        before do
          account.set_feature_flag! :bulk_sis_grade_export, 'off'
          account.set_feature_flag! 'post_grades', 'off'
          get_settings_page(account)
        end

        it "does not display the 'Post Grades to SIS' option" do
          expect(f("body")).not_to contain_css(default_grade_export)
        end
      end

      context "SIS grade export enabled" do
        before do
          account.set_feature_flag! :bulk_sis_grade_export, 'on'
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
          account.set_feature_flag! :bulk_sis_grade_export, 'on'
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
            expect(f(default_grade_export)).to be_disabled
          end
        end

      end

    end
  end
end
