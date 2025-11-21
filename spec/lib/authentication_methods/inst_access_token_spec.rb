# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe AuthenticationMethods::InstAccessToken do
  let(:signing_keypair) { OpenSSL::PKey::RSA.new(2048) }
  let(:encryption_keypair) { OpenSSL::PKey::RSA.new(2048) }
  let(:signing_priv_key) { signing_keypair.to_s }
  let(:signing_pub_key) { signing_keypair.public_key.to_s }
  let(:encryption_priv_key) { encryption_keypair.to_s }
  let(:encryption_pub_key) { encryption_keypair.public_key.to_s }

  around do |example|
    InstAccess.with_config(signing_key: signing_priv_key, &example)
  end

  describe ".parse" do
    it "is false for bad tokens" do
      result = AuthenticationMethods::InstAccessToken.parse("not-a-token")
      expect(result).to be_falsey
    end

    it "returns a token object for good tokens" do
      token_obj = InstAccess::Token.for_user(user_uuid: "fake-user-uuid", account_uuid: "fake-acct-uuid")
      result = AuthenticationMethods::InstAccessToken.parse(token_obj.to_unencrypted_token_string)
      expect(result.user_uuid).to eq("fake-user-uuid")
    end
  end

  describe ".load_user_and_pseudonym_context" do
    specs_require_sharding

    it "finds the user who created the token" do
      account = Account.default
      user_with_pseudonym(active_all: true)
      token_obj = InstAccess::Token.for_user(user_uuid: @user.uuid, account_uuid: account.uuid)
      ctx = AuthenticationMethods::InstAccessToken.load_user_and_pseudonym_context(token_obj, account)
      expect(ctx[:current_user]).to eq(@user)
      expect(ctx[:current_pseudonym]).to eq(@pseudonym)
    end

    it "returns an empty hash when the user identified by the token does not exist" do
      account = Account.default
      token_obj = InstAccess::Token.for_user(user_uuid: "inexplicably-untied-to-any-user", account_uuid: account.uuid)
      ctx = AuthenticationMethods::InstAccessToken.load_user_and_pseudonym_context(token_obj, account)
      expect(ctx[:current_user]).to be_nil
      expect(ctx[:current_pseudonym]).to be_nil
    end
  end

  describe ".usable_developer_key?" do
    subject { described_class.usable_developer_key?(token, account) }

    let(:account) { Account.create!(name: "account") }
    let(:user) { user_model }
    let(:developer_key) { DeveloperKey.create!(name: "key", account:) }

    before do
      developer_key.developer_key_account_bindings.find_by(
        account:
      ).update!(workflow_state: "on")
    end

    context "when the token has no client_id claim set" do
      let(:token) do
        InstAccess::Token.for_user(
          user_uuid: user.uuid,
          account_uuid: account.uuid
        )
      end

      it { is_expected.to be true }
    end

    describe "#tag_identifier" do
      subject { AuthenticationMethods::InstAccessToken::Authentication.new(request).tag_identifier }

      let(:service_user) { user_model }
      let(:root_account) { account_model }
      let(:user_agent) { "inst-service-ninety-nine/1234567890ABCDEF" }
      let(:key) do
        DeveloperKey.create!(
          name: "key",
          account: root_account,
          internal_service: true,
          service_user:
        )
      end

      let(:request) do
        double(
          ActionDispatch::Request,
          authorization:,
          user_agent:,
          GET: {}
        )
      end

      shared_examples_for "contexts that do not return a tag identifier" do
        it { is_expected.to be_nil }
      end

      context "when no authorization header is present" do
        let(:authorization) { nil }

        it_behaves_like "contexts that do not return a tag identifier"
      end

      context "when an an authorization header is present" do
        include_context "InstAccess setup"

        context "and the header is not a bearer token" do
          let(:authorization) { "notabearertoken" }

          it_behaves_like "contexts that do not return a tag identifier"
        end

        context "and the token is blank" do
          let(:authorization) { "" }

          it_behaves_like "contexts that do not return a tag identifier"
        end

        context "and the header is standard access token string" do
          let(:authorization) { "Bearer #{AccessToken.create!(user: service_user, purpose: "Test Access Token").full_token}" }

          it_behaves_like "contexts that do not return a tag identifier"
        end

        context "and the parsed token lacks a 'client_id' claim" do
          let(:token) do
            InstAccess::Token.for_user(
              user_uuid: service_user.uuid,
              account_uuid: root_account.uuid,
              canvas_domain: "test.host",
              user_global_id: service_user.global_id,
              region: ApplicationController.region,
              instructure_service: true
            )
          end
          let(:authorization) { "Bearer #{token.to_unencrypted_token_string}" }

          it_behaves_like "contexts that do not return a tag identifier"
        end

        context "and the parsed token is not for an instructure service" do
          let(:token) do
            InstAccess::Token.for_user(
              user_uuid: service_user.uuid,
              account_uuid: root_account.uuid,
              canvas_domain: "test.host",
              user_global_id: service_user.global_id,
              region: ApplicationController.region,
              client_id: key.global_id,
              instructure_service: false
            )
          end
          let(:authorization) { "Bearer #{token.to_unencrypted_token_string}" }

          it_behaves_like "contexts that do not return a tag identifier"
        end

        context "and the token is valid" do
          let(:token) do
            InstAccess::Token.for_user(
              user_uuid: service_user.uuid,
              account_uuid: root_account.uuid,
              canvas_domain: "test.host",
              user_global_id: service_user.global_id,
              region: ApplicationController.region,
              client_id: key.global_id,
              instructure_service: true
            )
          end
          let(:authorization) { "Bearer #{token.to_unencrypted_token_string}" }

          it "returns the client identifier as a string" do
            expect(subject).to eq key.global_id.to_s
          end

          context "but the user agent does not match an instructure service" do
            let(:user_agent) { "Chrome/115.0.0.0" }

            it_behaves_like "contexts that do not return a tag identifier"
          end
        end
      end
    end

    describe "#blocked?" do
      subject { AuthenticationMethods::InstAccessToken::Authentication.new(request).blocked? }

      let(:service_user) { user_model }
      let(:root_account) { account_model }
      let(:user_agent) { "inst-service-ninety-nine/1234567890ABCDEF" }
      let(:key) do
        DeveloperKey.create!(
          name: "key",
          account: root_account,
          internal_service: true,
          service_user:
        )
      end

      let(:request) do
        double(
          ActionDispatch::Request,
          authorization:,
          user_agent:,
          GET: {}
        )
      end

      shared_examples_for "contexts that do not block" do
        it { is_expected.to be false }
      end

      context "when no authorization header is present" do
        let(:authorization) { nil }

        it_behaves_like "contexts that do not block"
      end

      context "when an an authorization header is present" do
        include_context "InstAccess setup"

        context "and the header is not a bearer token" do
          let(:authorization) { "notabearertoken" }

          it_behaves_like "contexts that do not block"
        end

        context "and the token is blank" do
          let(:authorization) { "" }

          it_behaves_like "contexts that do not block"
        end

        context "and the header is standard access token string" do
          let(:authorization) { "Bearer #{AccessToken.create!(user: service_user, purpose: "Test Access Token").full_token}" }

          it_behaves_like "contexts that do not block"
        end

        context "and the token is valid" do
          let(:token) do
            InstAccess::Token.for_user(
              user_uuid: service_user.uuid,
              account_uuid: root_account.uuid,
              canvas_domain: "test.host",
              user_global_id: service_user.global_id,
              region: ApplicationController.region,
              client_id: key.global_id,
              instructure_service: true
            )
          end
          let(:authorization) { "Bearer #{token.to_unencrypted_token_string}" }

          it "returns false" do
            expect(subject).to be false
          end

          context "and the token lacks a 'jti' claim" do
            before do
              allow_any_instance_of(InstAccess::Token).to receive(:jti).and_return(nil)
            end

            it_behaves_like "contexts that do not block"
          end

          context "and the token is on the deny list" do
            before do
              allow(RequestThrottle).to receive(:blocklist).and_return Set.new([token.jti])
            end

            it { is_expected.to be true }
          end
        end
      end
    end

    context "when the token has a client_id claim set" do
      let(:token) do
        InstAccess::Token.for_user(
          user_uuid: user.uuid,
          account_uuid: account.uuid,
          client_id: developer_key.global_id
        )
      end

      context "and the the key is active and has a binding on" do
        before do
          developer_key.update!(
            workflow_state: "active"
          )

          developer_key.developer_key_account_bindings.find_by(
            account:
          ).update!(workflow_state: "on")
        end

        it { is_expected.to be true }
      end

      context "and the associated developer key is not found" do
        before { developer_key.delete }

        it { is_expected.to be false }
      end

      context "and the associated developer key is soft deleted" do
        before { developer_key.destroy! }

        it { is_expected.to be false }
      end

      context "and the developer key account binding is off" do
        before do
          developer_key.developer_key_account_bindings.find_by(
            account:
          ).update!(workflow_state: "off")
        end

        it { is_expected.to be false }
      end
    end
  end

  describe ".settings" do
    before do
      described_class.instance_variable_set(:@settings, nil)
    end

    after do
      described_class.instance_variable_set(:@settings, nil)
    end

    it "loads settings from DynamicSettings" do
      allow(DynamicSettings).to receive(:find).and_call_original
      allow(DynamicSettings).to receive(:find)
        .with(tree: :private)
        .and_return(DynamicSettings::FallbackProxy.new({
                                                         "inst_access_token.yml" => {
                                                           "log_tenant_mismatches" => true
                                                         }.to_yaml
                                                       }))

      settings = described_class.settings
      expect(settings["log_tenant_mismatches"]).to be true
    end

    it "caches the settings result" do
      allow(DynamicSettings).to receive(:find).and_call_original
      allow(DynamicSettings).to receive(:find)
        .with(tree: :private)
        .and_return(DynamicSettings::FallbackProxy.new({
                                                         "inst_access_token.yml" => {
                                                           "log_tenant_mismatches" => false
                                                         }.to_yaml
                                                       }))

      described_class.settings
      described_class.settings

      expect(DynamicSettings).to have_received(:find).with(tree: :private).once
    end

    it "returns empty hash when yml is nil" do
      allow(DynamicSettings).to receive(:find).and_call_original
      allow(DynamicSettings).to receive(:find)
        .with(tree: :private)
        .and_return(DynamicSettings::FallbackProxy.new({}))

      settings = described_class.settings
      expect(settings).to eq({})
    end

    it "parses YAML correctly" do
      allow(DynamicSettings).to receive(:find).and_call_original
      allow(DynamicSettings).to receive(:find)
        .with(tree: :private)
        .and_return(DynamicSettings::FallbackProxy.new({
                                                         "inst_access_token.yml" => {
                                                           "log_tenant_mismatches" => true,
                                                           "other_setting" => "value"
                                                         }.to_yaml
                                                       }))

      settings = described_class.settings
      expect(settings["log_tenant_mismatches"]).to be true
      expect(settings["other_setting"]).to eq("value")
    end
  end

  describe ".reload" do
    before do
      allow(DynamicSettings).to receive(:find).and_call_original
      allow(DynamicSettings).to receive(:find)
        .with(tree: :private)
        .and_return(DynamicSettings::FallbackProxy.new({
                                                         "inst_access_token.yml" => {
                                                           "log_tenant_mismatches" => true
                                                         }.to_yaml
                                                       }))
    end

    after do
      described_class.instance_variable_set(:@settings, nil)
    end

    it "clears the cached settings" do
      described_class.settings
      expect(described_class.instance_variable_get(:@settings)).not_to be_nil

      described_class.reload
      expect(described_class.instance_variable_get(:@settings)).to be_nil
    end

    it "allows settings to be reloaded" do
      described_class.settings

      allow(DynamicSettings).to receive(:find)
        .with(tree: :private)
        .and_return(DynamicSettings::FallbackProxy.new({
                                                         "inst_access_token.yml" => {
                                                           "log_tenant_mismatches" => false
                                                         }.to_yaml
                                                       }))

      described_class.reload
      new_settings = described_class.settings

      expect(new_settings["log_tenant_mismatches"]).to be false
    end
  end

  describe ".token_matches_tenant?" do
    specs_require_sharding

    subject { described_class.token_matches_tenant?(token, account) }

    let(:account) { Account.create!(name: "Test Account") }
    let(:user) { user_model }

    context "when token account_uuid matches domain root account uuid" do
      let(:token) do
        InstAccess::Token.for_user(
          user_uuid: user.uuid,
          account_uuid: account.uuid
        )
      end

      it { is_expected.to be true }

      it "does not send an InstStatsd event" do
        expect(InstStatsd::Statsd).not_to receive(:event)
        subject
      end
    end

    context "when token account_uuid does NOT match domain root account" do
      let(:different_account) { Account.create!(name: "Different Account") }
      let(:token) do
        InstAccess::Token.for_user(
          user_uuid: user.uuid,
          account_uuid: different_account.uuid
        )
      end

      context "with feature flag DISABLED (shadow mode)" do
        before do
          Account.site_admin.feature_flags.where(feature: :enforce_service_token_tenant_matching).destroy_all
          described_class.instance_variable_set(:@settings, nil)
        end

        after do
          described_class.instance_variable_set(:@settings, nil)
        end

        context "when log_tenant_mismatches is true" do
          before do
            allow(DynamicSettings).to receive(:find).and_call_original
            allow(DynamicSettings).to receive(:find)
              .with(tree: :private)
              .and_return(DynamicSettings::FallbackProxy.new({
                                                               "inst_access_token.yml" => {
                                                                 "log_tenant_mismatches" => true
                                                               }.to_yaml
                                                             }))
          end

          it "returns true (allows authentication)" do
            expect(subject).to be true
          end

          it "sends an InstStatsd event for monitoring" do
            expect(InstStatsd::Statsd).to receive(:event).with(
              "Service user authorization tenant mismatch",
              "Token account UUID #{different_account.uuid} does not match domain root account UUID #{account.uuid} for client ",
              hash_including(
                type: "tenant_mismatch",
                alert_type: :error
              )
            )
            subject
          end

          it "includes shard tags in the event" do
            expect(InstStatsd::Statsd).to receive(:event).with(
              anything,
              anything,
              hash_including(:tags)
            )
            subject
          end

          context "when token has a client_id" do
            let(:developer_key) { DeveloperKey.create!(name: "key", account:) }
            let(:token) do
              InstAccess::Token.for_user(
                user_uuid: user.uuid,
                account_uuid: different_account.uuid,
                client_id: developer_key.global_id
              )
            end

            it "includes client_id in the event message" do
              expect(InstStatsd::Statsd).to receive(:event).with(
                anything,
                "Token account UUID #{different_account.uuid} does not match domain root account UUID #{account.uuid} for client #{developer_key.global_id}",
                anything
              )
              subject
            end

            it "still returns true in shadow mode" do
              expect(subject).to be true
            end
          end
        end

        context "when log_tenant_mismatches is false" do
          before do
            allow(DynamicSettings).to receive(:find).and_call_original
            allow(DynamicSettings).to receive(:find)
              .with(tree: :private)
              .and_return(DynamicSettings::FallbackProxy.new({
                                                               "inst_access_token.yml" => {
                                                                 "log_tenant_mismatches" => false
                                                               }.to_yaml
                                                             }))
          end

          it "returns true (allows authentication)" do
            expect(subject).to be true
          end

          it "does not send an InstStatsd event" do
            expect(InstStatsd::Statsd).not_to receive(:event)
            subject
          end
        end

        context "when log_tenant_mismatches is nil" do
          before do
            allow(DynamicSettings).to receive(:find).and_call_original
            allow(DynamicSettings).to receive(:find)
              .with(tree: :private)
              .and_return(DynamicSettings::FallbackProxy.new({
                                                               "inst_access_token.yml" => {}.to_yaml
                                                             }))
          end

          it "returns true (allows authentication)" do
            expect(subject).to be true
          end

          it "does not send an InstStatsd event" do
            expect(InstStatsd::Statsd).not_to receive(:event)
            subject
          end
        end

        context "when settings yml is missing" do
          before do
            allow(DynamicSettings).to receive(:find).and_call_original
            allow(DynamicSettings).to receive(:find)
              .with(tree: :private)
              .and_return(DynamicSettings::FallbackProxy.new({}))
          end

          it "returns true (allows authentication)" do
            expect(subject).to be true
          end

          it "does not send an InstStatsd event" do
            expect(InstStatsd::Statsd).not_to receive(:event)
            subject
          end
        end
      end

      context "with feature flag ENABLED (enforcing)" do
        before do
          Account.site_admin.feature_flags.create!(
            feature: :enforce_service_token_tenant_matching,
            state: "on"
          )
        end

        it "returns false (blocks authentication)" do
          expect(subject).to be false
        end

        it "does not send an InstStatsd event" do
          expect(InstStatsd::Statsd).not_to receive(:event)
          subject
        end

        context "when token has a client_id" do
          let(:developer_key) { DeveloperKey.create!(name: "key", account:) }
          let(:token) do
            InstAccess::Token.for_user(
              user_uuid: user.uuid,
              account_uuid: different_account.uuid,
              client_id: developer_key.global_id
            )
          end

          it "returns false" do
            expect(subject).to be false
          end

          it "does not send an event when enforcing" do
            expect(InstStatsd::Statsd).not_to receive(:event)
            subject
          end
        end
      end
    end
  end
end
