# frozen_string_literal: true

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
      allow(Canvas::DynamicSettings).to receive(:find).with(any_args).and_call_original
      allow(Canvas::DynamicSettings).to receive(:find).
        with('rich-content-service', default_ttl: 5.minutes).
        and_return({
          "app-host" => "rce-app",
          "cdn-host" => "rce-cdn"
        })
      allow(Setting).to receive(:get)
    end

    describe ".env_for" do

      it "fills out host values when enabled" do
        env = described_class.env_for
        expect(env[:RICH_CONTENT_APP_HOST]).to eq("rce-app")
      end

      it "populates hosts with an error signal when consul is down" do
        allow(Canvas::DynamicSettings).to receive(:find).
          with('rich-content-service', default_ttl: 5.minutes).
          and_raise(Diplomat::KeyNotFound, "can't talk to consul")
        env = described_class.env_for
        expect(env[:RICH_CONTENT_APP_HOST]).to eq("error")
      end

      it "logs errors for later consideration" do
        allow(Canvas::DynamicSettings).to receive(:find).with("rich-content-service", default_ttl: 5.minutes).
          and_raise(Canvas::DynamicSettings::ConsulError, "can't talk to consul")
        root_account = double("root_account", feature_enabled?: true)
        expect(Canvas::Errors).to receive(:capture_exception) do |type, e|
          expect(type).to eq(:rce_flag)
          expect(e.is_a?(Canvas::DynamicSettings::ConsulError)).to be_truthy
        end
        described_class.env_for
      end

      it "includes a generated JWT for the domain, user, context, and workflwos" do
        user = double("user", global_id: 'global id')
        domain = double("domain")
        ctx = double("ctx", grants_any_right?: true)
        jwt = double("jwt")
        allow(Canvas::Security::ServicesJwt).to receive(:for_user).with(domain, user,
          include(workflows: [:rich_content, :ui],
            context: ctx)
        ).and_return(jwt)
        env = described_class.env_for(user: user, domain: domain, context: ctx)
        expect(env[:JWT]).to eql(jwt)
      end

      it "includes a masquerading user if provided" do
        user = double("user", global_id: 'global id')
        masq_user = double("masq_user", global_id: 'other global id')
        domain = double("domain")
        jwt = double("jwt")
        allow(Canvas::Security::ServicesJwt).to receive(:for_user).with(
          domain,
          user,
          include(real_user: masq_user),
        ).and_return(jwt)
        env = described_class.env_for(user: user, domain: domain, real_user: masq_user)
        expect(env[:JWT]).to eql(jwt)
      end

      it "does not allow file uploading without context" do
        user = double("user", global_id: 'global id')
        env = described_class.env_for(user: user)
        expect(env[:RICH_CONTENT_CAN_UPLOAD_FILES]).to eq(false)
      end

      it "lets context decide if uploading is ok" do
        user = double("user", global_id: 'global id')
        context1 = double("allowed_context", grants_any_right?: true)
        context2 = double("forbidden_context", grants_any_right?: false)
        env1 = described_class.env_for(user: user, context: context1)
        env2 = described_class.env_for(user: user, context: context2)
        expect(env1[:RICH_CONTENT_CAN_UPLOAD_FILES]).to eq(true)
        expect(env2[:RICH_CONTENT_CAN_UPLOAD_FILES]).to eq(false)
      end

      it "does not raise when encyption/signing secrets are nil" do
        allow(Canvas::Security::ServicesJwt).to receive(:for_user).and_raise(Canvas::Security::InvalidJwtKey)
        env = described_class.env_for(user: {}, domain: "domain")
        expect(env[:JWT]).to eq("InvalidJwtKey")
      end
    end
  end
end
