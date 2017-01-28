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
  before do
    assigns[:account_roles] = []
    assigns[:course_roles] = []
  end

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
      assigns[:announcements] = AccountNotification.none.paginate
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
      assigns[:announcements] = AccountNotification.none.paginate
      admin = account_admin_user
      view_context(@account, admin)
    end

    it "should show by default" do
      render
      expect(response).to have_tag("input#account_settings_open_registration")
      expect(response).not_to have_tag("div#open_registration_delegated_warning_dialog")
    end

    it "should show warning dialog when a delegated auth config is around" do
      @account.authentication_providers.create!(:auth_type => 'cas')
      @account.authentication_providers.first.move_to_bottom
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
      assigns[:announcements] = AccountNotification.none.paginate
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

  describe "SIS Integration Settings" do
    before do
      assigns[:account_users] = []
      assigns[:associated_courses_count] = 0
      assigns[:announcements] = AccountNotification.none.paginate
    end

    def do_render(user,account=nil)
      account = @account unless account
      view_context(account,user)
      render
    end

    context "site admin user" do
      before do
        @account = Account.site_admin
        assigns[:account] = @account
        assigns[:root_account] = @account
      end

      context "should not show settings to site admin user" do
        context "new_sis_integrations => true" do
          before do
            @account.stubs(:feature_enabled?).with(:new_sis_integrations).returns(true)
          end

          it { expect(response).not_to have_tag("#sis_integration_settings") }
          it { expect(response).not_to have_tag("#sis_grade_export_settings") }
          it { expect(response).not_to have_tag("#old_sis_integrations") }
          it { expect(response).not_to have_tag("input#allow_sis_import") }
        end
      end

      context "new_sis_integrations => false" do
        before do
          @account.stubs(:feature_enabled?).with(:new_sis_integrations).returns(false)
        end

        it { expect(response).not_to have_tag("#sis_integration_settings") }
        it { expect(response).not_to have_tag("#sis_grade_export_settings") }
        it { expect(response).not_to have_tag("#old_sis_integrations") }
        it { expect(response).not_to have_tag("input#allow_sis_import") }
      end
    end

    context "regular admin user" do
      let(:current_user) { account_admin_user }
      before do
        @account = Account.default
        @subaccount = @account.sub_accounts.create!(:name => 'sub-account')

        assigns[:account] = @account
        assigns[:root_account] = @account
        assigns[:current_user] = current_user

        @account.stubs(:feature_enabled?).with(:post_grades).returns(true)
        @account.stubs(:feature_enabled?).with(:google_docs_domain_restriction).returns(true)
      end

      context "new_sis_integrations => false" do
        before do
          @account.stubs(:feature_enabled?).with(:new_sis_integrations).returns(false)
          @account.stubs(:grants_right?).with(current_user, :manage_account_memberships).returns(true)
        end

        context "show old version of settings to regular admin user" do
          before do
            @account.stubs(:grants_right?).with(current_user, :manage_site_settings).returns(true)
            do_render(current_user)
          end

          it { expect(response).to     have_tag("#sis_grade_export_settings") }
          it { expect(response).to     have_tag("#account_allow_sis_import") }
          it { expect(response).to     have_tag("#old_sis_integrations") }
          it { expect(response).not_to have_tag("#sis_integration_settings") }
          it { expect(response).not_to have_tag("#account_settings_sis_syncing_value") }
        end
      end

      context "new_sis_integrations => true" do
        let(:sis_name) { "input#account_settings_sis_name" }
        let(:allow_sis_import) { "input#account_allow_sis_import" }
        let(:sis_syncing) { "input#account_settings_sis_syncing_value" }
        let(:sis_syncing_locked) { "input#account_settings_sis_syncing_locked" }
        let(:default_grade_export) { "#account_settings_sis_default_grade_export_value" }
        let(:require_assignment_due_date) { "#account_settings_sis_require_assignment_due_date_value" }
        let(:assignment_name_length) { "#account_settings_sis_assignment_name_length_value" }

        before do
          @account.stubs(:feature_enabled?).with(:new_sis_integrations).returns(true)
        end

        context "should show settings to regular admin user" do
          before do
            do_render(current_user)
          end

          it { expect(response).to     have_tag("#sis_integration_settings") }
          it { expect(response).to     have_tag(allow_sis_import) }
          it { expect(response).to     have_tag(sis_syncing) }
          it { expect(response).to     have_tag(sis_syncing_locked) }
          it { expect(response).to     have_tag(require_assignment_due_date) }
          it { expect(response).to     have_tag(assignment_name_length) }
          it { expect(response).not_to have_tag("#sis_grade_export_settings") }
          it { expect(response).not_to have_tag("#old_sis_integrations") }
          it { expect(response).to     have_tag(sis_name) }
        end

        context "SIS syncing enabled" do
          before do
            Assignment.stubs(:sis_grade_export_enabled?).returns(true)
          end

          context "for root account" do
            before do
              @account.stubs(:sis_syncing).returns({value: true, locked: true})
              do_render(current_user)
            end

            it "should enable all controls under SIS syncing" do
              expect(response).not_to have_tag("#{sis_syncing}[disabled]")
              expect(response).not_to have_tag("#{sis_syncing_locked}[disabled]")
              expect(response).not_to have_tag("#{default_grade_export}[disabled]")
              expect(response).not_to have_tag("#{require_assignment_due_date}[disabled]")
              expect(response).not_to have_tag("#{sis_name}[disabled]")
              expect(response).not_to have_tag("#{assignment_name_length}[disabled]")
            end
          end

          context "for sub-accounts (inherited)" do
            context "locked" do
              before do
                @account.stubs(:sis_syncing).returns({value: true, locked: true, inherited: true })
                do_render(current_user, @account)
              end

              it "should disable all controls under SIS syncing" do
                expect(response).to have_tag("#{sis_syncing}[disabled]")
                expect(response).to have_tag("#{sis_syncing_locked}[disabled]")
                expect(response).to have_tag("#{default_grade_export}[disabled]")
                expect(response).to have_tag("#{require_assignment_due_date}[disabled]")
                expect(response).to have_tag("#{assignment_name_length}[disabled]")
              end
            end

            context "not locked" do
              before do
                @account.stubs(:sis_syncing).returns({value: true, locked: false, inherited: true })
                do_render(current_user)
              end

              it "should enable all controls under SIS syncing" do
                expect(response).not_to have_tag("#{sis_syncing}[disabled]")
                expect(response).not_to have_tag("#{sis_syncing_locked}[disabled]")
                expect(response).not_to have_tag("#{default_grade_export}[disabled]")
                expect(response).not_to have_tag("#{require_assignment_due_date}[disabled]")
                expect(response).not_to have_tag("#{assignment_name_length}[disabled]")
              end
            end
          end
        end
      end
    end
  end

  describe "quotas" do
    before do
      @account = Account.default
      assigns[:account] = @account
      assigns[:account_users] = []
      assigns[:root_account] = @account
      assigns[:associated_courses_count] = 0
      assigns[:announcements] = AccountNotification.none.paginate
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
      role = custom_account_role('CustomAdmin', :account => Account.site_admin)
      account_admin_user_with_role_changes(
          :account => Account.site_admin,
          :role => role,
          :role_changes => {manage_account_memberships: true})
      view_context(Account.default, @user)
      assigns[:account] = Account.default
      assigns[:announcements] = AccountNotification.none.paginate
      render
      expect(response).not_to have_tag '#enroll_users_form'
    end
  end

  context "theme editor" do
    before do
      @account = Account.default
      assigns[:account] = @account
      assigns[:account_users] = []
      assigns[:root_account] = @account
      assigns[:associated_courses_count] = 0
      assigns[:announcements] = AccountNotification.none.paginate
    end

    it "should show sub account theme editor option for non siteadmin admins" do
      admin = account_admin_user
      view_context(@account, admin)
      assigns[:current_user] = admin
      render
      expect(response).to include("Let sub-accounts use the Theme Editor")
    end
  end
end
