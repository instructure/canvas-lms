# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

describe Login::LoginBrandConfigFilter do
  describe ".filter" do
    subject { described_class.filter(variable_schema.deep_dup, account) }

    let(:account) { Account.default }
    let(:variable_schema) do
      [
        {
          "group_key" => "login",
          "variables" => [
            { "variable_name" => "ic-brand-Login-logo" },
            { "variable_name" => "ic-brand-Login-body-bgd-image" },
            { "variable_name" => "ic-brand-Login-body-bgd-color" },
            { "variable_name" => "ic-brand-Login-custom-message" },
            { "variable_name" => "ic-brand-Login-footer" } # should be removed when filtering
          ]
        },
        {
          "group_key" => "discovery",
          "variables" => [
            { "variable_name" => "ic-brand-Discovery-variable" }
          ]
        },
        {
          "group_key" => "registration",
          "variables" => [
            { "variable_name" => "ic-brand-Registration-variable" }
          ]
        },
        {
          "group_key" => "another_group",
          "variables" => [
            { "variable_name" => "ic-brand-Another-variable" }
          ]
        }
      ]
    end

    context "when login_registration_ui_identity feature flag is disabled" do
      before do
        account.disable_feature!(:login_registration_ui_identity)
      end

      it "removes discovery and registration groups" do
        filtered_schema = subject
        group_keys = filtered_schema.pluck("group_key")
        expect(group_keys).not_to include("discovery")
        expect(group_keys).not_to include("registration")
      end

      it "removes ic-brand-Login-custom-message from login group" do
        filtered_schema = subject
        login_group = filtered_schema.find { |group| group["group_key"] == "login" }
        variable_names = login_group["variables"].pluck("variable_name")
        expect(variable_names).not_to include("ic-brand-Login-custom-message")
      end

      it "keeps other login variables" do
        filtered_schema = subject
        login_group = filtered_schema.find { |group| group["group_key"] == "login" }
        variable_names = login_group["variables"].pluck("variable_name")
        expect(variable_names).to include("ic-brand-Login-logo")
        expect(variable_names).to include("ic-brand-Login-body-bgd-image")
        expect(variable_names).to include("ic-brand-Login-body-bgd-color")
        expect(variable_names).to include("ic-brand-Login-footer") # old variable kept
      end

      it "keeps other groups unchanged" do
        filtered_schema = subject
        other_group = filtered_schema.find { |group| group["group_key"] == "another_group" }
        expect(other_group["variables"].pluck("variable_name")).to include("ic-brand-Another-variable")
      end
    end

    context "when login_registration_ui_identity is enabled but new_login_ui_custom_labels is disabled" do
      before do
        account.enable_feature!(:login_registration_ui_identity)
        allow(Account.site_admin).to receive(:feature_enabled?).and_call_original
        allow(Account.site_admin).to receive(:feature_enabled?).with(:new_login_ui_custom_labels).and_return(false)
      end

      it "removes discovery and registration groups" do
        filtered_schema = subject
        group_keys = filtered_schema.pluck("group_key")
        expect(group_keys).not_to include("discovery")
        expect(group_keys).not_to include("registration")
      end

      it "removes ic-brand-Login-custom-message from login group" do
        filtered_schema = subject
        login_group = filtered_schema.find { |group| group["group_key"] == "login" }
        variable_names = login_group["variables"].pluck("variable_name")
        expect(variable_names).not_to include("ic-brand-Login-custom-message")
      end

      it "keeps other login variables" do
        filtered_schema = subject
        login_group = filtered_schema.find { |group| group["group_key"] == "login" }
        variable_names = login_group["variables"].pluck("variable_name")
        expect(variable_names).to include("ic-brand-Login-logo")
        expect(variable_names).to include("ic-brand-Login-body-bgd-image")
        expect(variable_names).to include("ic-brand-Login-body-bgd-color")
      end
    end

    context "when both feature flags are enabled" do
      before do
        account.enable_feature!(:login_registration_ui_identity)
        allow(Account.site_admin).to receive(:feature_enabled?).and_call_original
        allow(Account.site_admin).to receive(:feature_enabled?).with(:new_login_ui_custom_labels).and_return(true)
      end

      it "removes disallowed login variables" do
        filtered_schema = subject
        login_group = filtered_schema.find { |group| group["group_key"] == "login" }
        variable_names = login_group["variables"].pluck("variable_name")
        expect(variable_names).to match_array(Login::LoginBrandConfigFilter::ALLOWED_LOGIN_VARS)
        expect(variable_names).not_to include("ic-brand-Login-footer")
      end

      it "keeps ic-brand-Login-custom-message in login group" do
        filtered_schema = subject
        login_group = filtered_schema.find { |group| group["group_key"] == "login" }
        variable_names = login_group["variables"].pluck("variable_name")
        expect(variable_names).to include("ic-brand-Login-custom-message")
      end

      it "sets the default value for ic-brand-Login-logo to an empty string" do
        filtered_schema = subject
        login_group = filtered_schema.find { |group| group["group_key"] == "login" }
        logo_variable = login_group["variables"].find { |v| v["variable_name"] == "ic-brand-Login-logo" }
        expect(logo_variable).to include("default")
        expect(logo_variable["default"]).to eq("")
      end

      it "does not remove variables in other groups" do
        filtered_schema = subject
        other_group = filtered_schema.find { |group| group["group_key"] == "another_group" }
        expect(other_group["variables"].pluck("variable_name")).to include("ic-brand-Another-variable")
      end

      context "when self-registration is disabled (default)" do
        it "removes the registration group" do
          filtered_schema = subject
          group_keys = filtered_schema.pluck("group_key")
          expect(group_keys).not_to include("registration")
        end
      end

      context "when self-registration is enabled" do
        before do
          account.enable_feature!(:login_registration_ui_identity)
          allow(Account.site_admin).to receive(:feature_enabled?).and_call_original
          allow(Account.site_admin).to receive(:feature_enabled?).with(:new_login_ui_custom_labels).and_return(true)
          allow(account).to receive(:self_registration?).and_return(true)
        end

        it "keeps the registration group" do
          filtered_schema = subject
          group_keys = filtered_schema.pluck("group_key")
          expect(group_keys).to include("registration")
        end
      end

      context "when new_login_ui_identity_discovery_page is disabled (default)" do
        before do
          allow(Account.site_admin).to receive(:feature_enabled?).with(:new_login_ui_identity_discovery_page).and_return(false)
        end

        it "removes the discovery group" do
          filtered_schema = subject
          group_keys = filtered_schema.pluck("group_key")
          expect(group_keys).not_to include("discovery")
        end
      end

      context "when new_login_ui_identity_discovery_page is enabled" do
        before do
          allow(Account.site_admin).to receive(:feature_enabled?).with(:new_login_ui_identity_discovery_page).and_return(true)
        end

        it "keeps the discovery group" do
          filtered_schema = subject
          group_keys = filtered_schema.pluck("group_key")
          expect(group_keys).to include("discovery")
        end
      end
    end
  end
end
