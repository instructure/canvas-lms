# frozen_string_literal: true

#
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
#

describe DataFixup::CreateLtiRegistrationsFromDeveloperKeys do
  context "with LTI developer keys present" do
    let(:first_account) { account_model }
    let(:second_account) { account_model }
    let(:number_of_keys_without_registrations) { 2 }
    let!(:second_account_key) do
      key = lti_developer_key_model(account: second_account)
      tool_configuration = lti_tool_configuration_model(developer_key: key)
      reg = key.lti_registration
      key.update(lti_registration: nil, skip_lti_sync: true)
      tool_configuration.update(lti_registration: nil)
      reg.delete
      key
    end

    before do
      number_of_keys_without_registrations.times do
        key = lti_developer_key_model(account: first_account)
        tool_configuration = lti_tool_configuration_model(developer_key: key)
        # dev_key_model factory creates reg automatically and ignores the skip_lti_sync param
        reg = key.lti_registration
        key.update(lti_registration: nil, skip_lti_sync: true)
        tool_configuration.update(lti_registration: nil)
        reg.delete
      end
    end

    it "creates lti_registrations" do
      expect { described_class.run }
        .to change { Lti::Registration.where(account: first_account).count }.by(number_of_keys_without_registrations)
        .and change { Lti::Registration.where(account: second_account).count }.by(1)

      second_account_key.reload
      expect(second_account_key.lti_registration.admin_nickname)
        .to eq(second_account_key.name)
      expect(second_account_key.lti_registration.name)
        .to eq(second_account_key.tool_configuration.internal_lti_configuration[:title])
      expect(second_account_key.lti_registration.account)
        .to eq(second_account_key.account)
      expect(second_account_key.lti_registration.internal_service)
        .to eq(second_account_key.internal_service)
    end

    it "links tool configuration to registration" do
      described_class.run
      second_account_key.reload
      expect(second_account_key.lti_registration.manual_configuration)
        .to eq(second_account_key.referenced_tool_configuration)
    end

    context "and with a developer key that already has a registration" do
      # registration will be created for this key automatically
      before { lti_developer_key_model(account: first_account) }

      it "only creates registrations for the keys without registrations" do
        expect { described_class.run }
          .to change { Lti::Registration.where(account: first_account).count }.by(number_of_keys_without_registrations)
      end
    end

    context "with invalid developer key" do
      before do
        second_account_key.scopes += ["invalid_scope"]
        second_account_key.save!(validate: false)
      end

      it "still associates the registration with the key" do
        described_class.run
        expect(second_account_key.reload.lti_registration).to be_present
      end
    end

    context "with invalid tool configuration" do
      before do
        second_account_key.tool_configuration.privacy_level = "invalid"
        second_account_key.tool_configuration.save!(validate: false)
      end

      it "still associates the registration to the tool configuration" do
        described_class.run
        expect(second_account_key.reload.lti_registration.manual_configuration).to be_present
        expect(second_account_key.tool_configuration.lti_registration).to be_present
      end
    end

    context "and with an API key existing" do
      before { dev_key_model(account: first_account) }

      it "ignores the API key" do
        expect { described_class.run }
          .to change { Lti::Registration.where(account: first_account).count }.by(number_of_keys_without_registrations)
      end
    end

    context "and with a site admin developer key" do
      before do
        key = lti_developer_key_model(account: Account.site_admin)
        tool_configuration = lti_tool_configuration_model(developer_key: key)
        # dev_key_model factory creates reg automatically and ignores the skip_lti_sync param
        reg = key.lti_registration
        key.update(lti_registration: nil, skip_lti_sync: true)
        tool_configuration.update(lti_registration: nil)
        reg.delete
      end

      it "creates a site admin registration" do
        expect { described_class.run }
          .to change { Lti::Registration.where(account: Account.site_admin).count }.by(1)
      end
    end

    context "when the registraton can't be saved" do
      let(:scope) { double("scope") }

      before do
        second_account_key.update_attribute!("account_id", Account.last.id + 1)
      end

      it "sends an error to sentry" do
        expect(Sentry).to receive(:with_scope).and_yield(scope)
        expect(Sentry).to receive(:capture_message)
          .with("DataFixup#create_lti_registrations_from_developer_keys", { level: :warning })
        expect(scope).to receive(:set_tags).with(developer_key_id: second_account_key.global_id)
        expect(scope).to receive(:set_context)
          .with("exception", { name: "ActiveRecord::RecordInvalid", message: "Validation failed: Account must exist" })
        described_class.run
      end
    end
  end

  context "with a key created by dynamic registration" do
    let(:redirect_uris) { ["http://example.com"] }
    let(:initiate_login_uri) { "http://example.com/login" }
    let(:client_name) { "Example Tool" }
    let(:jwks_uri) { "http://example.com/jwks" }
    let(:logo_uri) { "http://example.com/logo.png" }
    let(:client_uri) { "http://example.com/" }
    let(:tos_uri) { "http://example.com/tos" }
    let(:policy_uri) { "http://example.com/policy" }
    let(:lti_tool_configuration) do
      {
        domain: "example.com",
        messages: [],
        claims: []
      }
    end
    let(:scopes) { [] }

    let!(:registration) do
      r = Lti::IMS::Registration.new({
        redirect_uris:,
        initiate_login_uri:,
        client_name:,
        jwks_uri:,
        logo_uri:,
        client_uri:,
        tos_uri:,
        policy_uri:,
        lti_tool_configuration:,
        scopes:
      }.compact)
      r.update(developer_key:)
      r
    end

    let(:developer_key) do
      key = lti_developer_key_model
      reg = key.lti_registration
      key.update(lti_registration: nil, skip_lti_sync: true)
      reg.destroy_permanently!
      key
    end

    it "creates an lti_registration and links it to the ims_registration" do
      expect { described_class.run }.to change { Lti::Registration.count }.by(1)
      expect(Lti::Registration.last.ims_registration).to eq(registration)
    end
  end
end
