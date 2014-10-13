#
# Copyright (C) 2011 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "accounts/settings.html.erb" do
  describe "sis_source_id edit box" do
    before do
      @account = Account.default.sub_accounts.create!
      @account.sis_source_id = "so_special_sis_id"
      @account.save!
      
      assigns[:context] = @account
      assigns[:account] = @account
      assigns[:account_users] = []
      assigns[:root_account] = @account
      assigns[:associated_courses_count] = 0
      assigns[:announcements] = []
    end

    it "should show to sis admin" do
      admin = account_admin_user
      view_context(@account, admin)
      assigns[:current_user] = admin
      render
      expect(response).to have_tag("input#account_sis_source_id")
    end

    it "should not show to non-sis admin" do
      admin = account_admin_user_with_role_changes(:role_changes => {'manage_sis' => false})
      view_context(@account, admin)
      assigns[:current_user] = admin
      render
      expect(response).to have_tag("span.sis_source_id", @account.sis_source_id)
      expect(response).not_to have_tag("input#account_sis_source_id")
    end
  end

  describe "open registration" do
    before do
      @account = Account.default
      assigns[:account] = @account
      assigns[:account_users] = []
      assigns[:root_account] = @account
      assigns[:associated_courses_count] = 0
      assigns[:announcements] = []
      admin = account_admin_user
      view_context(@account, admin)
    end

    it "should show by default" do
      render
      expect(response).to have_tag("input#account_settings_open_registration")
      expect(response).not_to have_tag("div#open_registration_delegated_warning_dialog")
    end

    it "should show warning dialog when a delegated auth config is around" do
      @account.account_authorization_configs.create!(:auth_type => 'cas')
      render
      expect(response).to have_tag("input#account_settings_open_registration")
      expect(response).to have_tag("div#open_registration_delegated_warning_dialog")
    end
  end

  describe "managed by site admins" do
    before do
      @account = Account.default
      assigns[:account] = @account
      assigns[:account_users] = []
      assigns[:root_account] = @account
      assigns[:associated_courses_count] = 0
      assigns[:announcements] = []
    end

    it "should show settings that can only be managed by site admins" do
      admin = site_admin_user
      view_context(@account, admin)
      render
      expect(response).to have_tag("input#account_settings_global_includes")
      expect(response).to have_tag("input#account_settings_show_scheduler")
      expect(response).to have_tag("input#account_settings_enable_profiles")
    end

    it "it should not show settings to regular admin user" do
      admin = account_admin_user
      view_context(@account, admin)
      render
      expect(response).not_to have_tag("input#account_settings_global_includes")
      expect(response).not_to have_tag("input#account_settings_show_scheduler")
      expect(response).not_to have_tag("input#account_settings_enable_profiles")
    end
  end
  
  describe "quotas" do
    before do
      @account = Account.default
      assigns[:account] = @account
      assigns[:account_users] = []
      assigns[:root_account] = @account
      assigns[:associated_courses_count] = 0
      assigns[:announcements] = []
    end
    
    context "with :manage_storage_quotas" do
      before do
        admin = account_admin_user
        view_context(@account, admin)
        assigns[:current_user] = admin
      end
      
      it "should show quota options" do
        render
        expect(@controller.js_env.include?(:ACCOUNT)).to be_truthy
        expect(response).to have_tag '#tab-quotas-link'
        expect(response).to have_tag '#tab-quotas'
      end
    end
    
    context "without :manage_storage_quotas" do
      before do
        admin = account_admin_user_with_role_changes(:account => @account, :role_changes => {'manage_storage_quotas' => false})
        view_context(@account, admin)
        assigns[:current_user] = admin
      end
      
      it "should not show quota options" do
        render
        expect(@controller.js_env.include?(:ACCOUNT)).to be_falsey
        expect(response).not_to have_tag '#tab-quotas-link'
        expect(response).not_to have_tag '#tab-quotas'
      end
    end
  end

  context "admins" do
    it "should not show add admin button if don't have permission to any roles" do
      account_admin_user_with_role_changes(
          :account => Account.site_admin,
          :membership_type => 'CustomAdmin',
          :role_changes => {manage_account_memberships: true})
      view_context(Account.default, @user)
      assigns[:account] = Account.default
      assigns[:announcements] = []
      render
      expect(response).not_to have_tag '#enroll_users_form'
    end
  end
end
