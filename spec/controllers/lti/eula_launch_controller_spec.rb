# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

module Lti
  describe EulaLaunchController do
    include Lti::RedisMessageClient

    before :once do
      course_with_teacher(active_all: true)
    end

    let(:decoded_jwt) do
      lti_message_hint = response.body.match(/<input[^>]*name="lti_message_hint"[^>]*value="([^"]*)"/)[1]
      JSON::JWT.decode(lti_message_hint, :skip_verification)
    end

    describe "#launch_eula" do
      shared_examples "returns 404" do
        it "returns 404" do
          subject
          expect(response).to have_http_status :not_found
        end
      end

      shared_examples "logs launch with Lti::LogService" do
        before do
          allow(Lti::LogService).to receive(:new) do
            double("Lti::LogService").tap { |s| allow(s).to receive(:call) }
          end
        end

        it "logs launch" do
          expect(Lti::LogService).to receive(:new).with(
            tool:,
            context:,
            user: @teacher,
            session_id: nil,
            launch_type: :direct_link,
            launch_url: tool.launch_url,
            message_type: "LtiEulaRequest"
          )
          subject
        end
      end

      shared_examples "returns 200 with required fields in token" do
        it "returns 200 with required fields in token" do
          subject
          expect(response).to have_http_status :ok
          expect(id_token_decoded["https://purl.imsglobal.org/spec/lti/claim/message_type"]).to eq("LtiEulaRequest")
          expect(id_token_decoded["https://purl.imsglobal.org/spec/lti/claim/version"]).to eq("1.3.0")
          expect(id_token_decoded["https://purl.imsglobal.org/spec/lti/claim/deployment_id"]).to eq(tool.deployment_id)
          expect(id_token_decoded["https://purl.imsglobal.org/spec/lti/claim/target_link_uri"]).to eq(tool.launch_url)
          expect(id_token_decoded["https://purl.imsglobal.org/spec/lti/claim/roles"]).not_to be_nil
          expect(id_token_decoded["https://purl.imsglobal.org/spec/lti/claim/eulaservice"]["scope"]).to eq(
            ["https://purl.imsglobal.org/spec/lti/scope/eula/user",
             "https://purl.imsglobal.org/spec/lti/scope/eula/deployment"]
          )
          expect(id_token_decoded["https://purl.imsglobal.org/spec/lti/claim/eulaservice"]["url"]).to eq(tool.asset_processor_eula_url)
        end
      end

      context "in course context" do
        let(:context) { @course }
        let(:tool) { external_tool_1_3_model(context: @course) }
        let(:id_token_decoded) do
          launch = fetch_and_delete_launch(@course, decoded_jwt["verifier"])
          JSON.parse(launch)["post_payload"]
        end

        subject { get :launch_eula, params: { context_external_tool_id: tool.id, course_id: @course.id } }

        context "with feature disabled" do
          before do
            context.root_account.disable_feature!(:lti_asset_processor)
          end

          it_behaves_like "returns 404"
        end

        context "with feature enabled" do
          render_views
          before do
            context.root_account.enable_feature!(:lti_asset_processor)
            user_session(@teacher)
          end

          it_behaves_like "returns 200 with required fields in token"

          it_behaves_like "logs launch with Lti::LogService"
        end

        context "with invalid context_external_tool_id" do
          subject { get :launch_eula, params: { context_external_tool_id: 0, course_id: @course.id } }

          it_behaves_like "returns 404"
        end
      end

      context "in account context" do
        let(:account) { Account.default }
        let(:context) { account }
        let(:tool) { external_tool_1_3_model(context: account) }
        let(:id_token_decoded) do
          launch = fetch_and_delete_launch(account, decoded_jwt["verifier"])
          JSON.parse(launch)["post_payload"]
        end

        subject { get :launch_eula, params: { context_external_tool_id: tool.id, account_id: account.id } }

        context "with feature disabled" do
          before do
            context.root_account.disable_feature!(:lti_asset_processor)
          end

          it_behaves_like "returns 404"
        end

        context "with feature enabled" do
          render_views
          before do
            context.root_account.enable_feature!(:lti_asset_processor)
            user_session(@teacher)
          end

          it_behaves_like "returns 200 with required fields in token"

          it_behaves_like "logs launch with Lti::LogService"
        end

        context "with invalid context_external_tool_id" do
          subject { get :launch_eula, params: { context_external_tool_id: 0, account_id: account.id } }

          it_behaves_like "returns 404"
        end
      end
    end
  end
end
