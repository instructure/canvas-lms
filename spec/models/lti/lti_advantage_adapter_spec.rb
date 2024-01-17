# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative "../../lti_1_3_spec_helper"

describe Lti::LtiAdvantageAdapter do
  include_context "lti_1_3_spec_helper"
  include Lti::RedisMessageClient

  let!(:lti_user_id) { Lti::Asset.opaque_identifier_for(@student) }
  let(:return_url) { "http://www.platform.com/return_url" }
  let(:user) { @student }
  let(:opts) { { resource_type: "course_navigation", domain: "test.com" } }
  let(:controller_double) do
    controller = double(polymorphic_url: "test.com")
    allow(controller).to receive(:params)
    controller
  end
  let(:expander_opts) { { current_user: user, tool:, controller: controller_double } }
  let(:expander) do
    Lti::VariableExpander.new(
      course.root_account,
      course,
      nil,
      expander_opts
    )
  end
  let(:include_storage_target) { true }
  let(:adapter) do
    Lti::LtiAdvantageAdapter.new(
      tool:,
      user:,
      context: course,
      return_url:,
      expander:,
      include_storage_target:,
      opts:
    )
  end
  let(:tool) do
    tool = course.context_external_tools.new(
      name: "bob",
      consumer_key: "key",
      shared_secret: "secret",
      url: "http://www.example.com/basic_lti"
    )
    tool.course_navigation = { enabled: true, message_type: "ResourceLinkRequest" }
    tool.use_1_3 = true
    tool.developer_key = DeveloperKey.create!
    tool.save!
    tool
  end
  let(:login_message) { adapter.generate_post_payload }
  let(:verifier) { Canvas::Security.decode_jwt(login_message["lti_message_hint"])["verifier"] }
  let(:params) { JSON.parse(fetch_and_delete_launch(course, verifier)) }
  let(:assignment) do
    assignment_model(
      course:,
      submission_types: "external_tool",
      external_tool_tag_attributes: { content: tool }
    )
  end

  let_once(:course) do
    course_with_student
    @course
  end

  describe "#generate_post_payload_for_student_context_card" do
    let(:login_message) { adapter.generate_post_payload_for_student_context_card(student_id:) }
    let(:student_id) { "123" }

    it "includes extension lti_student_id claim in the id_token" do
      expect(params["https://www.instructure.com/lti_student_id"]).to eq(student_id)
    end
  end

  describe "#generate_post_payload" do
    context 'when the message type is "LtiDeepLinkingRequest"' do
      let(:opts) { { resource_type: "editor_button", domain: "test.com" } }

      before do
        tool.editor_button = {
          enabled: true,
          message_type: "LtiDeepLinkingRequest",
          icon_url: "http://test.com/icon"
        }
        tool.save!
      end

      it "caches a deep linking request" do
        expect(params["https://purl.imsglobal.org/spec/lti/claim/message_type"]).to eq "LtiDeepLinkingRequest"
      end
    end

    context "when target_link_uri is set" do
      let(:launch_url) { "https://www.cool-tool.com/test?foo=bar" }
      let(:opts) do
        {
          resource_type: "course_navigation",
          domain: "test.com",
          launch_url:
        }
      end

      it "sets the target_link_uri in the id_token" do
        expect(params["https://purl.imsglobal.org/spec/lti/claim/target_link_uri"]).to eq launch_url
      end
    end

    context "when the user is nil" do
      let(:user) { nil }

      it 'sets the "login_hint" to the public user ID' do
        expect(login_message["login_hint"]).to eq User.public_lti_id
      end
    end

    it "generates a resource link request if the tool's resource type setting is 'ResourceLinkRequest'" do
      expect(params["https://purl.imsglobal.org/spec/lti/claim/message_type"]).to eq "LtiResourceLinkRequest"
    end

    it "creates a login message" do
      expect(login_message.keys).to match_array %w[
        iss
        login_hint
        target_link_uri
        lti_message_hint
        canvas_region
        canvas_environment
        client_id
        deployment_id
        lti_storage_target
      ]
    end

    context "lti_storage_target parameter" do
      context "when include_storage_target parameter is not provided" do
        let(:adapter) do
          Lti::LtiAdvantageAdapter.new(
            tool:,
            user:,
            context: course,
            return_url:,
            expander:,
            opts:
          )
        end

        it "is included" do
          expect(login_message.keys).to include("lti_storage_target")
        end
      end

      context "when include_storage_target parameter is true" do
        let(:include_storage_target) { true }

        it "is included" do
          expect(login_message.keys).to include("lti_storage_target")
        end
      end

      context "when include_storage_target parameter is false" do
        let(:include_storage_target) { false }

        it "is not included" do
          expect(login_message.keys).not_to include("lti_storage_target")
        end
      end
    end

    it 'sets the "login_hint" to the current user LTI ID' do
      expect(login_message["login_hint"]).to eq lti_user_id
    end

    it 'sets the "target_link_uri" to the tool launch url' do
      expect(login_message["target_link_uri"]).to eq tool.url
    end

    it 'sets the "canvas_region" to "not_configured"' do
      expect(login_message["canvas_region"]).to eq "not_configured"
    end

    it 'sets the "canvas_environment" to "prod"' do
      expect(login_message["canvas_environment"]).to eq "prod"
    end

    context "when in beta" do
      before do
        allow(ApplicationController).to receive(:test_cluster_name).and_return("beta")
      end

      it 'sets "canvas_enviroment" to "beta"' do
        expect(login_message["canvas_environment"]).to eq "beta"
      end
    end

    context "when in test" do
      before do
        allow(ApplicationController).to receive(:test_cluster_name).and_return("test")
      end

      it 'sets "canvas_enviroment" to "test"' do
        expect(login_message["canvas_environment"]).to eq "test"
      end
    end

    context "when no i18n locale is set in the request" do
      it "sets the canvas_locale in the message hint to the default i18n locale" do
        expect(Canvas::Security.decode_jwt(login_message["lti_message_hint"])["canvas_locale"]).to eq "en"
      end
    end

    context "when the i18n locale is set in the request" do
      it "sets the canvas_locale in the message hint to the locale from the request" do
        I18n.with_locale(:de) do
          expect(Canvas::Security.decode_jwt(login_message["lti_message_hint"])["canvas_locale"]).to eq "de"
        end
      end
    end

    it "sets the domain in the message hint" do
      expect(Canvas::Security.decode_jwt(login_message["lti_message_hint"])["canvas_domain"]).to eq "test.com"
    end

    it "sets the client_id to the developer key global id" do
      expect(login_message["client_id"]).to eq tool.global_developer_key_id
    end

    it "includes the deployment_id" do
      expect(login_message["deployment_id"]).to eq tool.deployment_id
    end

    context "when the user has a past lti context id" do
      before do
        user.past_lti_ids.create!(
          context: course,
          user_uuid: SecureRandom.uuid,
          user_lti_id: SecureRandom.uuid,
          user_lti_context_id: SecureRandom.uuid
        )
      end

      it 'sets the "login_hint" to the current user LTI ID' do
        expect(login_message["login_hint"]).to eq user.past_lti_ids.first.user_lti_context_id
      end
    end

    context "when the DB has a region configured" do
      specs_require_sharding

      let(:region) { "us-east-1" }
      let(:config_stub) do
        config = @shard1.database_server.config.dup
        config[:region] = region
        config
      end
      let(:course) do
        @shard1.activate do
          course_with_student
          @course
        end
      end

      before do
        allow(@shard1.database_server).to receive(:config).and_return(config_stub)
      end

      it 'sets the "canvas_region" to the configured region' do
        expect(login_message["canvas_region"]).to eq region
      end
    end

    context 'when a "launch_url" is set in the options hash' do
      let(:launch_url) { "https://www.cool-took.com/launch?with_query_params=true" }
      let(:opts) { { launch_url: } }

      it("uses the launch_url as the target_link_uri") do
        expect(login_message["target_link_uri"]).to eq launch_url
      end
    end
  end

  describe "#launch_url" do
    it "returns the resource-specific launch URL if set" do
      tool.course_navigation = {
        enabled: true,
        message_type: "ResourceLinkRequest",
        target_link_uri: "https://www.launch.com/course-navigation"
      }
      tool.save!
      expect(adapter.launch_url).to eq "https://www.launch.com/course-navigation"
    end

    it "returns the general launch URL if no resource url is set" do
      expect(adapter.launch_url).to eq "http://www.example.com/basic_lti"
    end

    context "when the oidc_initiation_url is set" do
      let(:oidc_initiation_url) { "https://www.test.com/oidc/login" }

      before { tool.developer_key.update!(oidc_initiation_url:) }

      it "uses the oidc login uri" do
        expect(adapter.launch_url).to eq oidc_initiation_url
      end
    end
  end
end
