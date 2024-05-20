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

module Services
  describe RichContent do
    before do
      allow(DynamicSettings).to receive(:find).with(any_args).and_call_original
      allow(DynamicSettings).to receive(:find)
        .with("rich-content-service", default_ttl: 5.minutes)
        .and_return(DynamicSettings::FallbackProxy.new({
                                                         "app-host" => "rce-app",
                                                         "cdn-host" => "rce-cdn"
                                                       }))
      allow(Setting).to receive(:get)
    end

    describe ".env_for" do
      it "fills out host values when enabled" do
        env = described_class.env_for
        expect(env[:RICH_CONTENT_APP_HOST]).to eq("rce-app")
      end

      it "includes a generated JWT for the domain, user, context, and workflwos" do
        user = double("user", global_id: "global id")
        domain = double("domain")
        ctx = double("ctx", grants_right?: true)
        jwt = double("jwt")
        allow(CanvasSecurity::ServicesJwt).to receive(:for_user).with(domain,
                                                                      user,
                                                                      include(workflows: [:rich_content, :ui],
                                                                              context: ctx)).and_return(jwt)
        env = described_class.env_for(user:, domain:, context: ctx)
        expect(env[:JWT]).to eql(jwt)
      end

      it "includes a masquerading user if provided" do
        user = double("user", global_id: "global id")
        masq_user = double("masq_user", global_id: "other global id")
        domain = double("domain")
        jwt = double("jwt")
        allow(CanvasSecurity::ServicesJwt).to receive(:for_user).with(
          domain,
          user,
          include(real_user: masq_user)
        ).and_return(jwt)
        env = described_class.env_for(user:, domain:, real_user: masq_user)
        expect(env[:JWT]).to eql(jwt)
      end

      it "does not allow file uploading without context" do
        user = double("user", global_id: "global id")
        env = described_class.env_for(user:)
        expect(env[:RICH_CONTENT_CAN_UPLOAD_FILES]).to be(false)
      end

      it "lets context decide if uploading is ok" do
        user = double("user", global_id: "global id")
        context1 = double("allowed_context", grants_right?: true)
        context2 = double("forbidden_context", grants_right?: false)
        env1 = described_class.env_for(user:, context: context1)
        env2 = described_class.env_for(user:, context: context2)
        expect(env1[:RICH_CONTENT_CAN_UPLOAD_FILES]).to be(true)
        expect(env2[:RICH_CONTENT_CAN_UPLOAD_FILES]).to be(false)
      end

      it "does not raise when encyption/signing secrets are nil" do
        allow(CanvasSecurity::ServicesJwt).to receive(:for_user).and_raise(Canvas::Security::InvalidJwtKey)
        env = described_class.env_for(user: {}, domain: "domain")
        expect(env[:JWT]).to eq("InvalidJwtKey")
      end

      describe "RICH_CONTENT_CAN_EDIT_FILES" do
        context "when the user can edit context files" do
          subject { described_class.env_for(user:, context:)[:RICH_CONTENT_CAN_EDIT_FILES] }

          let(:user) { double("user", global_id: "some-global-id") }
          let(:context) { double("allowed_context", grants_right?: true) }

          it { is_expected.to be_truthy }
        end

        context "when the user cannot edit context files" do
          subject { described_class.env_for(user:, context:)[:RICH_CONTENT_CAN_EDIT_FILES] }

          let(:user) { double("user", global_id: "some-global-id") }
          let(:context) { double("allowed_context", grants_right?: false) }

          it { is_expected.to be_falsey }
        end
      end
    end
  end
end
