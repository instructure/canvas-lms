# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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
require_relative "../../spec_helper"

describe Validators::AccountSettingsValidator do
  let(:account) { Account.default }
  let!(:auth_provider) { account.authentication_providers.create!(auth_type: "saml") }

  def valid_discovery_page_entry(overrides = {})
    {
      authentication_provider_id: auth_provider.id,
      label: "Test Provider",
    }.merge(overrides)
  end

  describe "discovery_page validation" do
    it "passes with valid discovery_page structure" do
      account.settings[:discovery_page] = {
        primary: [valid_discovery_page_entry],
        secondary: [valid_discovery_page_entry]
      }
      expect(account).to be_valid
    end

    it "passes with empty arrays" do
      account.settings[:discovery_page] = {
        primary: [],
        secondary: []
      }
      expect(account).to be_valid
    end

    it "does not add errors when discovery_page is not present" do
      account.settings.delete(:discovery_page)
      expect(account).to be_valid
    end

    it "fails when authentication_provider_id is missing" do
      account.settings[:discovery_page] = {
        primary: [valid_discovery_page_entry.except(:authentication_provider_id)],
        secondary: []
      }
      expect(account).not_to be_valid
      expect(account.errors[:settings]).to include("discovery_page.primary[0].authentication_provider_id is invalid or inactive")
    end

    it "fails when label is missing" do
      account.settings[:discovery_page] = {
        primary: [valid_discovery_page_entry.except(:label)],
        secondary: []
      }
      expect(account).not_to be_valid
      expect(account.errors[:settings]).to include("discovery_page.primary[0].label is required")
    end

    it "fails with invalid icon_url (not a URL)" do
      account.settings[:discovery_page] = {
        primary: [valid_discovery_page_entry.merge(icon_url: "not-a-url")],
        secondary: []
      }
      expect(account).not_to be_valid
      expect(account.errors[:settings]).to include("discovery_page.primary[0].icon_url must be a valid URL")
    end

    it "fails with invalid icon_url (ftp protocol)" do
      account.settings[:discovery_page] = {
        primary: [valid_discovery_page_entry.merge(icon_url: "ftp://example.com/icon.png")],
        secondary: []
      }
      expect(account).not_to be_valid
      expect(account.errors[:settings]).to include("discovery_page.primary[0].icon_url must be a valid URL")
    end

    it "passes with valid http icon_url" do
      account.settings[:discovery_page] = {
        primary: [valid_discovery_page_entry.merge(icon_url: "http://example.com/icon.png")],
        secondary: []
      }
      expect(account).to be_valid
    end

    it "passes with valid https icon_url" do
      account.settings[:discovery_page] = {
        primary: [valid_discovery_page_entry.merge(icon_url: "https://example.com/icon.png")],
        secondary: []
      }
      expect(account).to be_valid
    end

    it "reports errors for multiple invalid entries" do
      second_auth_provider = account.authentication_providers.create!(auth_type: "cas")
      account.settings[:discovery_page] = {
        primary: [
          { authentication_provider_id: auth_provider.id },
          { authentication_provider_id: second_auth_provider.id }
        ],
        secondary: []
      }
      expect(account).not_to be_valid
      expect(account.errors[:settings]).to include("discovery_page.primary[0].label is required")
      expect(account.errors[:settings]).to include("discovery_page.primary[1].label is required")
    end

    it "fails when authentication_provider_id does not exist" do
      account.settings[:discovery_page] = {
        primary: [valid_discovery_page_entry(authentication_provider_id: 999_999)],
        secondary: []
      }
      expect(account).not_to be_valid
      expect(account.errors[:settings]).to include("discovery_page.primary[0].authentication_provider_id is invalid or inactive")
    end

    it "fails when authentication_provider is soft deleted" do
      deleted_provider = account.authentication_providers.create!(auth_type: "ldap")
      deleted_provider.destroy

      account.settings[:discovery_page] = {
        primary: [valid_discovery_page_entry(authentication_provider_id: deleted_provider.id)],
        secondary: []
      }
      expect(account).not_to be_valid
      expect(account.errors[:settings]).to include("discovery_page.primary[0].authentication_provider_id is invalid or inactive")
    end

    it "fails when authentication_provider belongs to a different account" do
      other_account = Account.create!(name: "Other Account")
      other_provider = other_account.authentication_providers.create!(auth_type: "saml")

      account.settings[:discovery_page] = {
        primary: [valid_discovery_page_entry(authentication_provider_id: other_provider.id)],
        secondary: []
      }
      expect(account).not_to be_valid
      expect(account.errors[:settings]).to include("discovery_page.primary[0].authentication_provider_id is invalid or inactive")
    end
  end
end
