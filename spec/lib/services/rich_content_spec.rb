#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require_dependency "services/rich_content"

module Services
  describe RichContent do
    before do
      allow(Services::RichContent).to receive(:contextually_on).and_call_original
      allow(Canvas::DynamicSettings).to receive(:find).with(any_args).and_call_original
      allow(Canvas::DynamicSettings).to receive(:find).
        with('rich-content-service', default_ttl: 5.minutes).
        and_return({
          "app-host" => "rce-app",
          "cdn-host" => "rce-cdn"
        })
      allow(Setting).to receive(:get)
      allow(Setting).to receive(:get).
        with('rich_content_service_enabled', 'false').
        and_return('true')
    end

    describe ".env_for" do
      it "just returns disabled value if no root_account" do
        allow(Setting).to receive(:get).
          with('rich_content_service_enabled', 'false').
          and_return('false')
        expect(described_class.env_for(nil)).to eq({
          RICH_CONTENT_SERVICE_ENABLED: false
        })
      end

      it "fills out host values when enabled" do
        root_account = double("root_account", feature_enabled?: true)
        env = described_class.env_for(root_account)
        expect(env[:RICH_CONTENT_APP_HOST]).to eq("rce-app")
        expect(env[:RICH_CONTENT_CDN_HOST]).to eq("rce-cdn")
      end

      it "populates hosts with an error signal when consul is down" do
        allow(Canvas::DynamicSettings).to receive(:find).
          with('rich-content-service', default_ttl: 5.minutes).
          and_raise(Imperium::UnableToConnectError, "can't talk to consul")
        root_account = double("root_account", feature_enabled?: true)
        env = described_class.env_for(root_account)
        expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        expect(env[:RICH_CONTENT_APP_HOST]).to eq("error")
        expect(env[:RICH_CONTENT_CDN_HOST]).to eq("error")
      end

      it "logs errors for later consideration" do
        allow(Canvas::DynamicSettings).to receive(:find).with("rich-content-service", default_ttl: 5.minutes).
          and_raise(Canvas::DynamicSettings::ConsulError, "can't talk to consul")
        root_account = double("root_account", feature_enabled?: true)
        expect(Canvas::Errors).to receive(:capture_exception) do |type, e|
          expect(type).to eq(:rce_flag)
          expect(e.is_a?(Canvas::DynamicSettings::ConsulError)).to be_truthy
        end
        described_class.env_for(root_account)
      end

      it "includes a generated JWT for the domain, user, context, and workflwos" do
        root_account = double("root_account", feature_enabled?: true)
        user = double("user", global_id: 'global id')
        domain = double("domain")
        ctx = double("ctx", grants_any_right?: true)
        jwt = double("jwt")
        allow(Canvas::Security::ServicesJwt).to receive(:for_user).with(domain, user,
          include(workflows: [:rich_content, :ui],
            context: ctx)
        ).and_return(jwt)
        env = described_class.env_for(root_account, user: user, domain: domain, context: ctx)
        expect(env[:JWT]).to eql(jwt)
      end

      it "includes a masquerading user if provided" do
        root_account = double("root_account", feature_enabled?: true)
        user = double("user", global_id: 'global id')
        masq_user = double("masq_user", global_id: 'other global id')
        domain = double("domain")
        jwt = double("jwt")
        allow(Canvas::Security::ServicesJwt).to receive(:for_user).with(
          domain,
          user,
          include(real_user: masq_user),
        ).and_return(jwt)
        env = described_class.env_for(root_account,
          user: user, domain: domain, real_user: masq_user)
        expect(env[:JWT]).to eql(jwt)
      end

      it "does not allow file uploading without context" do
        root_account = double("root_account", feature_enabled?: true)
        user = double("user", global_id: 'global id')
        env = described_class.env_for(root_account, user: user)
        expect(env[:RICH_CONTENT_CAN_UPLOAD_FILES]).to eq(false)
      end

      it "lets context decide if uploading is ok" do
        root_account = double("root_account", feature_enabled?: true)
        user = double("user", global_id: 'global id')
        context1 = double("allowed_context", grants_any_right?: true)
        context2 = double("forbidden_context", grants_any_right?: false)
        env1 = described_class.env_for(root_account, user: user, context: context1)
        env2 = described_class.env_for(root_account, user: user, context: context2)
        expect(env1[:RICH_CONTENT_CAN_UPLOAD_FILES]).to eq(true)
        expect(env2[:RICH_CONTENT_CAN_UPLOAD_FILES]).to eq(false)
      end

      context "with all flags on" do
        let(:root_account){double("root_account") }

        before(:each) do
          allow(root_account).to receive(:feature_enabled?).with(:rich_content_service_high_risk).and_return(true)
        end

        it "is contextually on for low risk areas" do
          env = described_class.env_for(root_account, risk_level: :basic)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end

        it "is contextually on for medium risk areas" do
          env = described_class.env_for(root_account, risk_level: :sidebar)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end

        it "is contextually on for high risk areas" do
          env = described_class.env_for(root_account, risk_level: :highrisk)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end
      end

      context "with flag off" do
        let(:root_account){double("root_account") }

        before(:each) do
          allow(root_account).to receive(:feature_enabled?).and_return(false)
        end

        it "is contextually on when no risk specified" do
          env = described_class.env_for(root_account)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end

        it "is contextually on for high risk areas" do
          env = described_class.env_for(root_account, risk_level: :highrisk)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end

        it "is contextually on for low risk areas" do
          env = described_class.env_for(root_account, risk_level: :basic)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end

        it "is contextually on for lower risk areas with sidebar" do
          env = described_class.env_for(root_account, risk_level: :sidebar)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end
      end

      it "treats nil feature values as false" do
        allow(Setting).to receive(:get).
          with('rich_content_service_enabled', 'false').
          and_return('false')
        root_account = double("root_account")
        allow(root_account).to receive(:feature_enabled?).with(:rich_content_service_high_risk).and_return(nil)
        env = described_class.env_for(root_account)
        expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to eq(false)
      end

      context "integrating with a real account and feature flags" do
        it "sets all levels to true when all flags set" do
          account = account_model
          account.enable_feature!(:rich_content_service_high_risk)
          env = described_class.env_for(account)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end

        it "on for basic if flag is disabled" do
          account = account_model
          account.disable_feature!(:rich_content_service_high_risk)
          env = described_class.env_for(account, risk_level: :basic)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end

        it "on for sidebar if flag is disabled" do
          account = account_model
          account.disable_feature!(:rich_content_service_high_risk)
          env = described_class.env_for(account, risk_level: :sidebar)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end

        it "on for high risk if flag is disabled" do
          account = account_model
          account.disable_feature!(:rich_content_service_high_risk)
          env = described_class.env_for(account)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end
      end

      context "without rich_content_service_enabled setting true" do
        before(:each) do
          allow(Setting).to receive(:get).
            with('rich_content_service_enabled', 'false').
            and_return(false)
        end

        it "on for all risk levels if feature flag is enabled" do
          account = account_model
          account.enable_feature!(:rich_content_service_high_risk)
          env = described_class.env_for(account, risk_level: :basic)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
          env = described_class.env_for(account, risk_level: :sidebar)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
          env = described_class.env_for(account, risk_level: :highrisk)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end

        it "off for all risk levels if feature flag is not enabled" do
          account = account_model
          account.disable_feature!(:rich_content_service_high_risk)
          env = described_class.env_for(account, risk_level: :basic)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_falsey
          env = described_class.env_for(account, risk_level: :sidebar)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_falsey
          env = described_class.env_for(account, risk_level: :highrisk)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_falsey
        end
      end
    end
  end
end
