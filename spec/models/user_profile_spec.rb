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
    end
  end
end
