# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe UserProfile do
  describe "tabs available" do
    let(:account) { Account.default }

    it "should show the profile tab when profiles are enabled" do
      student_in_course(:active_all => true)
      tabs = @student.profile.
        tabs_available(@user, :root_account => account)
      expect(tabs.map { |t| t[:id] }).not_to include UserProfile::TAB_PROFILE

      account.update_attribute :settings, :enable_profiles => true
      tabs = @student.reload.profile.
        tabs_available(@user, :root_account => account)
      expect(tabs.map { |t| t[:id] }).to include UserProfile::TAB_PROFILE
    end

    describe "shared content tab" do
      it "should show shared content tab when user has any non-student enrollment" do
        teacher_in_course(:active_all => true)
        tabs = @teacher.profile.
          tabs_available(@teacher, :root_account => account)
        expect(tabs.map { |t| t[:id] }).to include UserProfile::TAB_CONTENT_SHARES
      end

      it "should show shared content tab when user has account membership" do
        account_admin_user(account: account)
        tabs = @admin.profile.tabs_available(@admin, :root_account => account)
        expect(tabs.map { |t| t[:id] }).to include UserProfile::TAB_CONTENT_SHARES
      end

      it "should not show shared content tab when user has only student enrollments" do
        student_in_course(:active_all => true)
        tabs = @student.profile.
          tabs_available(@student, :root_account => account)
        expect(tabs.map { |t| t[:id] }).not_to include UserProfile::TAB_CONTENT_SHARES
      end
    end

    it "should be i18n'd" do
      student_in_course(:active_all => true)
      I18n.locale = :es
      tabs = @student.profile.tabs_available(@user, :root_account => account)
      expect(tabs.detect{|t| t[:id] == UserProfile::TAB_FILES }[:label]).to_not eq "Files"
    end

    context 'with lti tabs' do
      let(:visibility) { 'public' }
      let(:additional_settings) do
        {
          user_navigation:
            {
              "enabled"=> "true",
              "default"=> "enabled",
              "text"=> "LTI or die",
              "visibility"=> visibility
            }
        }.with_indifferent_access
      end

      context 'with non-admin' do
        it "does show lti tab" do
          student_in_course(:active_all => true)
          external_tool_model(
            context: account,
            opts: { settings: additional_settings }
          )
          tabs = @student.reload.profile.
            tabs_available(@user, :root_account => account)
          expect(tabs.map { |t| t[:id] }).to include(
            account.context_external_tools.first.asset_string
          )
        end

        context 'with permission needed' do
          let(:additional_settings) do
            {
              user_navigation:
                {
                  "enabled"=> "true",
                  "default"=> "enabled",
                  "text"=> "LTI or die",
                  "visibility"=> visibility,
                  'required_permissions': 'manage_data_services'
                }
            }.with_indifferent_access
          end

          it 'does not show the tab' do
            student_in_course(:active_all => true)
            external_tool_model(
              context: account,
              opts: { settings: additional_settings }
            )
            tabs = @student.reload.profile.
              tabs_available(@user, :root_account => account)
            expect(tabs.map { |t| t[:id] }).not_to include(
              account.context_external_tools.first.asset_string
            )
          end
        end
      end

      context 'with admin' do
        it "does show lti tab" do
          account_admin_user
          external_tool_model(
            context: account,
            opts: { settings: additional_settings }
          )
          tabs = @admin.reload.profile.
            tabs_available(@user, :root_account => account)
          expect(tabs.map { |t| t[:id] }).to include(
            account.context_external_tools.first.asset_string
          )
        end
      end

      context 'with visiblity as admins' do
        let(:visibility) { 'admins' }

        context 'with non-admin' do
          it "does not show lti tab" do
            student_in_course(:active_all => true)
            external_tool_model(
              context: account,
              opts: { settings: additional_settings }
            )
            tabs = @student.reload.profile.
              tabs_available(@user, :root_account => account)
            expect(tabs.map { |t| t[:id] }).not_to include(
              account.context_external_tools.first.asset_string
            )
          end
        end

        context 'with admin' do
          it "does show lti tab" do
            account_admin_user
            external_tool_model(
              context: account,
              opts: { settings: additional_settings }
            )
            tabs = @admin.reload.profile.
              tabs_available(@user, :root_account => account)
            expect(tabs.map { |t| t[:id] }).to include(
              account.context_external_tools.first.asset_string
            )
          end
        end
      end

      context 'with permission needed' do
        let(:additional_settings) do
          {
            user_navigation:
              {
                "enabled"=> "true",
                "default"=> "enabled",
                "text"=> "LTI or die",
                "visibility"=> visibility,
                'required_permissions': 'manage_data_services'
              }
          }.with_indifferent_access
        end

        it 'does show the tab' do
          account_admin_user
          external_tool_model(
            context: account,
            opts: { settings: additional_settings }
          )
          tabs = @admin.reload.profile.
            tabs_available(@user, :root_account => account)
          expect(tabs.map { |t| t[:id] }).to include(
            account.context_external_tools.first.asset_string
          )
        end
      end
    end

    it "should show announcements tab" do
      student_in_course(active_all: true)
      tabs = @student.profile.
        tabs_available(@student, root_account: account)
      expect(tabs.map { |t| t[:id] }).to include UserProfile::TAB_PAST_GLOBAL_ANNOUNCEMENTS
    end

    describe "QR mobile login" do
      before :once do
        user_factory(active_all: true)
      end

      context "IMP is present and mobile_qr_login setting is enabled" do
        it "should show the QR mobile login tab" do
          account.settings[:mobile_qr_login_is_enabled] = true
          allow_any_instance_of(UserProfile).to receive(:instructure_misc_plugin_available?).and_return(true)
          tabs = @user.profile.tabs_available(@user, :root_account => account)
          expect(tabs.map { |t| t[:id] }).to include UserProfile::TAB_QR_MOBILE_LOGIN
        end
      end

      context "mobile_qr_login setting is disabled" do
        it "should not show the QR mobile login tab" do
          allow_any_instance_of(UserProfile).to receive(:instructure_misc_plugin_available?).and_return(true)
          account.settings[:mobile_qr_login_is_enabled] = false
          tabs = @user.profile.tabs_available(@user, :root_account => account)
          expect(tabs.map { |t| t[:id] }).not_to include UserProfile::TAB_QR_MOBILE_LOGIN
        end
      end

      context "IMP is not present" do
        it "should not show the QR mobile login tab" do
          allow_any_instance_of(UserProfile).to receive(:instructure_misc_plugin_available?).and_return(false)
          account.settings[:mobile_qr_login_is_enabled] = true
          tabs = @user.profile.tabs_available(@user, :root_account => account)
          expect(tabs.map { |t| t[:id] }).not_to include UserProfile::TAB_QR_MOBILE_LOGIN
        end
      end
    end
  end
end
