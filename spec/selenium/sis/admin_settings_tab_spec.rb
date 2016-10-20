require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "admin settings tab" do
  include_context "in-process server selenium tests"
  let(:account) { Account.default }

  before :each do
    user_logged_in(:user => site_admin_user(account: account))
    get "/accounts/#{account.id}/settings"
  end

  def set_checkbox(checkbox,checked)
    checkbox.click if is_checked(checkbox) != checked
  end

  def click_submit
    f("#account_settings button[type=submit]").click
    wait_for_ajaximations
  end

  def go_to_feature_options(account_id)
    get "/accounts/#{account_id}/settings"
    f("#tab-features-link").click
    wait_for_ajaximations
  end

  context "SIS Agent Token Authentication" do
    it "should test SIS Agent Token Authentication", priority: "2", test_id: 132577 do
      course_with_admin_logged_in(:account => Account.site_admin)
      sis_token = "canvas"
      go_to_feature_options(Account.site_admin.id)
      move_to_click("label[for=ff_allowed_post_grades]")
      go_to_feature_options(account.id)
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
      go_to_feature_options(account.id)
      move_to_click("label[for=ff_off_post_grades]")
      f('#tab-settings-link').click
      refresh_page
      expect(f("#account_settings")).not_to contain_css("#account_settings_sis_app_token")
    end
  end

  context "SIS Integration Settings" do
    let(:allow_sis_import) { "#account_allow_sis_import" }
    let(:default_grade_export) { "#account_settings_sis_default_grade_export_value" }
    
    it "persists SIS import settings on refresh" do
      set_checkbox(f(allow_sis_import),false)
      click_submit
      expect(is_checked(f(allow_sis_import))).to be_falsey

      set_checkbox(f(allow_sis_import),true)
      click_submit
      expect(is_checked(f(allow_sis_import))).to be_truthy

      set_checkbox(f(allow_sis_import),false)
      click_submit
      expect(is_checked(f(allow_sis_import))).to be_falsey
    end

    context "SIS grade export enabled" do
      
      before do
        account.set_feature_flag! :bulk_sis_grade_export, 'on'
        account.set_feature_flag! 'post_grades', 'on'
        get "/accounts/#{account.id}/settings"
      end

      it "persists 'Post Grades to SIS' settings on refresh" do
        set_checkbox(f(default_grade_export),false)
        click_submit
        expect(is_checked(f(default_grade_export))).to be_falsey

        set_checkbox(f(default_grade_export),true)
        click_submit
        expect(is_checked(f(default_grade_export))).to be_truthy

        set_checkbox(f(default_grade_export),false)
        click_submit
        expect(is_checked(f(default_grade_export))).to be_falsey
      end
    end

    context "SIS grade export disabled" do
      before do
        account.set_feature_flag! :bulk_sis_grade_export, 'off'
        account.set_feature_flag! 'post_grades', 'off'
        get "/accounts/#{account.id}/settings"
      end

      it "does not display the 'Post Grades to SIS' option" do
        expect(f("body")).not_to contain_css(default_grade_export)
      end
    end

  end
end
