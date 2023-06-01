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

require_relative "lti/concerns/parent_frame_shared_examples"

describe ExternalContentController do
  describe "GET success" do
    it "doesn't require a context" do
      get :success, params: { service: "equella" }
      expect(response).to be_successful
    end

    it "gets a context for external_tool_dialog" do
      c = course_factory
      get :success, params: { service: "external_tool_dialog", course_id: c.id }
      expect(assigns[:context]).to_not be_nil
    end
  end

  describe "GET success/:id" do
    context "no lti_version is passed" do
      let(:course) { course_factory }
      let(:params) do
        {
          service: "external_tool_dialog",
          course_id: course.id,
          id: 123
        }
      end

      before do
        course_with_teacher
        user_session(@teacher)
      end

      it "returns a 401 rather than a 500" do
        get(:success, params:)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST success/external_tool_dialog" do
    describe "js_env setting" do
      let(:params) do
        {
          service: "external_tool_dialog",
          course_id: c.id,
          lti_message_type: "ContentItemSelection",
          lti_version: "LTI-1p0",
          data: "",
          content_items: Rails.root.join("spec/fixtures/lti/content_items.json").read,
          lti_msg: "some lti message",
          lti_log: "some lti log",
          lti_errormsg: "some lti error message",
          lti_errorlog: "some lti error log"
        }
      end

      let!(:c) { course_factory }

      it "js env is set correctly" do
        post(:success, params:)

        data = controller.js_env[:retrieved_data]
        expect(data).to_not be_nil
        expect(data.first).to be_a(IMS::LTI::Models::ContentItems::ContentItem)

        expect(data.first.id).to eq("http://lti-tool-provider-example.dev/messages/blti")
        expect(data.first.url).to eq("http://lti-tool-provider-example.dev/messages/blti")
        expect(data.first.text).to eq("Arch Linux")
        expect(data.first.title).to eq("Its your computer")
        expect(data.first.placement_advice.presentation_document_target).to eq("iframe")
        expect(data.first.placement_advice.display_height).to eq(600)
        expect(data.first.placement_advice.display_width).to eq(800)
        expect(data.first.media_type).to eq("application/vnd.ims.lti.v1.ltilink")
        expect(data.first.type).to eq("LtiLinkItem")
        expect(data.first.thumbnail.height).to eq(128)
        expect(data.first.thumbnail.width).to eq(128)
        expect(data.first.thumbnail.id).to eq("http://www.runeaudio.com/assets/img/banner-archlinux.png")

        e = "external_tools/retrieve?display=borderless&url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti"
        expect(data.first.canvas_url).to end_with(e)

        env = controller.js_env
        expect(env[:service]).to eq(params[:service])
        expect(env[:message]).to eq(params[:lti_msg])
        expect(env[:log]).to eq(params[:lti_log])
        expect(env[:error_message]).to eq(params[:lti_errormsg])
        expect(env[:error_log]).to eq(params[:lti_errorlog])
      end

      it "turns the messages/logs into strings to prevent HTML injection" do
        params[:lti_msg] = { html: "msg somehtml" }
        params[:lti_log] = { html: "log somehtml" }
        params[:lti_errormsg] = { html: "errormsg somehtml" }
        params[:lti_errorlog] = { html: "errorlog somehtml" }

        post(:success, params:)
        env = controller.js_env

        expect(env[:message]).to eq('{"html"=>"msg somehtml"}')
        expect(env[:log]).to eq('{"html"=>"log somehtml"}')
        expect(env[:error_message]).to eq('{"html"=>"errormsg somehtml"}')
        expect(env[:error_log]).to eq('{"html"=>"errorlog somehtml"}')
        expect(env[:lti_response_messages]).to eq(
          lti_msg: '{"html"=>"msg somehtml"}',
          lti_log: '{"html"=>"log somehtml"}',
          lti_errormsg: '{"html"=>"errormsg somehtml"}',
          lti_errorlog: '{"html"=>"errorlog somehtml"}'
        )
      end

      it_behaves_like "an endpoint which uses parent_frame_context to set the CSP header" do
        subject do
          user_session(account_admin_user(account: Account.site_admin))
          post(
            :success,
            params: {
              service: "external_tool_dialog",
              course_id: c.id,
              parent_frame_context: pfc_tool.id
            }
          )
        end

        let(:pfc_tool_context) { c }
      end

      describe "DEEP_LINKING_POST_MESSAGE_ORIGIN" do
        subject do
          post(
            :success,
            params: {
              service: "external_tool_dialog",
              course_id: c.id,
              parent_frame_context: tool.id
            }
          )
        end

        let(:tool) do
          c.context_external_tools.create!(
            {
              name: "test tool",
              domain: "test.com",
              consumer_key: "fake_oauth_consumer_key",
              shared_secret: "secret",
              developer_key:,
              url: "http://test.com/login",
            }
          )
        end
        let(:developer_key) do
          key = DeveloperKey.new
          key.generate_rsa_keypair!
          key.save!
          key.developer_key_account_bindings.first.update!(
            workflow_state: "on"
          )
          key
        end

        context "when returning from a non-internal service" do
          it "does not set the DEEP_LINKING_POST_MESSAGE_ORIGIN value in jsenv" do
            expect(controller).not_to receive(:js_env).with({ DEEP_LINKING_POST_MESSAGE_ORIGIN: "http://test.com" }, true)
            subject
          end
        end

        context "when returning from an internal service" do
          before do
            user_session(account_admin_user(account: Account.site_admin))
            developer_key.update!(internal_service: true)
          end

          it "sets the DEEP_LINKING_POST_MESSAGE_ORIGIN value in jsenv" do
            allow(controller).to receive(:js_env)
            subject
            expect(controller).to have_received(:js_env).with({ DEEP_LINKING_POST_MESSAGE_ORIGIN: "http://test.com" }, true)
          end

          context "when the tool has a domain and not a url" do
            let(:tool) do
              c.context_external_tools.create!(
                {
                  name: "test tool",
                  domain: "test.com",
                  consumer_key: "fake_oauth_consumer_key",
                  shared_secret: "secret",
                  developer_key:,
                }
              )
            end

            it "sets the DEEP_LINKING_POST_MESSAGE_ORIGIN value in jsenv" do
              allow(controller).to receive(:js_env)
              subject
              expect(controller).to have_received(:js_env).with({ DEEP_LINKING_POST_MESSAGE_ORIGIN: "https://test.com" }, true)
            end
          end
        end
      end
    end

    context "external_tool service_id" do
      let(:test_course) { course_factory }
      let(:launch_url) { "http://test.com/launch" }
      let(:tool) do
        test_course.context_external_tools.create!(
          {
            name: "test tool",
            domain: "test.com",
            consumer_key: oauth_consumer_key,
            shared_secret: "secret"
          }
        )
      end
      let(:service_id) { "3" }
      let(:oauth_consumer_key) { "key" }
      let(:content_item_selection) do
        message = IMS::LTI::Models::Messages::ContentItemSelection.new(
          {
            lti_message_type: "ContentItemSelection",
            lti_version: "LTI-1p0",
            content_items: Rails.root.join("spec/fixtures/lti/content_items.json").read,
            data: Canvas::Security.create_jwt({ content_item_id: service_id, oauth_consumer_key: }),
            lti_msg: "",
            lti_log: "",
            lti_errormsg: "",
            lti_errorlog: ""
          }
        )
        message.launch_url = launch_url
        message.oauth_consumer_key = oauth_consumer_key
        message
      end

      before do
        allow_any_instance_of(Lti::MessageAuthenticator).to receive(:valid?).and_return(true)
        course_with_teacher
        user_session(@teacher)
      end

      it "validates the signature" do
        expect_any_instance_of(Lti::MessageAuthenticator).to receive(:valid?).and_return(false)
        post(
          :success,
          params: {
            service: "external_tool_dialog",
            course_id: test_course.id,
            id: service_id,
          }.merge(content_item_selection.signed_post_params(tool.shared_secret))
        )
        expect(response).to have_http_status(:unauthorized)
      end

      it "sets the service_id if one is passed in" do
        post(
          :success,
          params: {
            service: "external_tool_dialog",
            course_id: test_course.id,
            id: service_id,
          }.merge(content_item_selection.signed_post_params(tool.shared_secret))
        )
        expect(controller.js_env[:service_id]).to eq service_id
      end

      it "returns a 401 if the service_id, and data attribute don't match" do
        params = content_item_selection.signed_post_params(tool.shared_secret)
                                       .merge(
                                         {
                                           service: "external_tool_dialog",
                                           course_id: test_course.id,
                                           id: 3,
                                           data: Canvas::Security.create_jwt({ content_item_id: "1" })
                                         }
                                       )
        post(:success, params:)
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns a 401 if the consumer_key, and data attribute don't match" do
        params = content_item_selection.signed_post_params(tool.shared_secret)
                                       .merge(
                                         {
                                           service: "external_tool_dialog",
                                           course_id: test_course.id,
                                           id: service_id,
                                           data: Canvas::Security.create_jwt({ content_item_id: service_id, oauth_consumer_key: "invalid" })
                                         }
                                       )
        post(:success, params:)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "#content_items_for_canvas" do
    it "sets default placement advice" do
      c = course_factory
      post(:success, params: { service: "external_tool_dialog",
                               course_id: c.id,
                               lti_message_type: "ContentItemSelection",
                               lti_version: "LTI-1p0",
                               data: "",
                               content_items: Rails.root.join("spec/fixtures/lti/content_items_2.json").read,
                               lti_msg: "",
                               lti_log: "",
                               lti_errormsg: "",
                               lti_errorlog: "" })

      data = controller.js_env[:retrieved_data]
      expect(data.first.placement_advice.presentation_document_target).to eq("default")
      expect(data.first.placement_advice.display_height).to eq(600)
      expect(data.first.placement_advice.display_width).to eq(800)
    end

    it "uses the default url if one isn't provided" do
      c = course_factory
      json = JSON.parse(Rails.root.join("spec/fixtures/lti/content_items_2.json").read)
      json["@graph"][0].delete("url")
      launch_url = "http://example.com/launch"
      post(:success, params: { service: "external_tool_dialog",
                               course_id: c.id,
                               lti_message_type: "ContentItemSelection",
                               lti_version: "LTI-1p0",
                               data: Canvas::Security.create_jwt({ default_launch_url: launch_url }),
                               content_items: json.to_json,
                               lti_msg: "",
                               lti_log: "",
                               lti_errormsg: "",
                               lti_errorlog: "" })

      data = controller.js_env[:retrieved_data]
      expect(data.first.canvas_url).to include "http%3A%2F%2Fexample.com%2Flaunch"
    end

    context "lti_links" do
      it "generates a canvas tool launch url" do
        c = course_factory
        json = JSON.parse(Rails.root.join("spec/fixtures/lti/content_items.json").read)
        post(:success, params: { service: "external_tool_dialog",
                                 course_id: c.id,
                                 lti_message_type: "ContentItemSelection",
                                 lti_version: "LTI-1p0",
                                 content_items: json.to_json })

        data = controller.js_env[:retrieved_data]
        expect(data.first.canvas_url).to include "/external_tools/retrieve"
        expect(data.first.canvas_url).to include "url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti"
      end

      it "generates a borderless launch url for iframe target" do
        c = course_factory
        json = JSON.parse(Rails.root.join("spec/fixtures/lti/content_items.json").read)
        json["@graph"][0]["placementAdvice"]["presentationDocumentTarget"] = "iframe"
        post(:success, params: { service: "external_tool_dialog",
                                 course_id: c.id,
                                 lti_message_type: "ContentItemSelection",
                                 lti_version: "LTI-1p0",
                                 content_items: json.to_json })

        data = controller.js_env[:retrieved_data]
        expect(data.first.canvas_url).to include "display=borderless"
      end

      it "generates a borderless launch url for window target" do
        c = course_factory
        json = JSON.parse(Rails.root.join("spec/fixtures/lti/content_items.json").read)
        json["@graph"][0]["placementAdvice"]["presentationDocumentTarget"] = "window"
        post(:success, params: { service: "external_tool_dialog",
                                 course_id: c.id,
                                 lti_message_type: "ContentItemSelection",
                                 lti_version: "LTI-1p0",
                                 content_items: json.to_json })

        data = controller.js_env[:retrieved_data]
        expect(data.first.canvas_url).to include "display=borderless"
      end
    end
  end

  describe "#oembed_retrieve" do
    subject do
      get(:oembed_retrieve, params:)
      response
    end

    let(:oembed_resource) do
      {
        "height" => 75,
        "html" => "<img src=\"www.test.edu/foo.svg\" alt=\"Read This\" width=\"75\" height=\"75\" style=\"background-color:\n#ffcc00;\"/>",
        "type" => "rich",
        "version" => "1.0",
        "width" => 75
      }
    end

    let(:endpoint) { "https://www.test.edu/new/oembed-endpoint?img=21&color=ffcc00" }
    let(:expected_oembed_uri) { "#{endpoint}&url=#{CGI.escape(url)}&format=json" }
    let(:oembed_token) { "" }
    let(:params) { { endpoint:, url: } }
    let(:success_double) { double("success", body: oembed_resource.to_json) }
    let(:tool) { external_tool_model }
    let(:url) { "https://www.test.edu/new_actionicons/oembed-endpoint" }
    let(:user) { user_model }

    before { allow(CanvasHttp).to receive(:get).and_return(success_double) }

    describe "oembed tokens" do
      let(:oembed_token) do
        unsigned_token = JSON::JWT.new(
          {
            sub:,
            iss:,
            aud:,
            iat:,
            exp:,
            jti:,
            endpoint:,
            url:
          }
        )
        unsigned_token.sign(tool.shared_secret).to_s
      end

      let(:aud) { Canvas::Security.config["lti_iss"] }
      let(:exp) { iat + 5.minutes.seconds.to_i }
      let(:iat) { Time.zone.now.to_i }
      let(:iss) { tool.consumer_key }
      let(:jti) { SecureRandom.uuid }
      let(:params) { { oembed_token: } }
      let(:sub) { Lti::Asset.opaque_identifier_for(user) }

      context "and an active user session" do
        before { user_session(user) }

        it "embeds oembed objects" do
          expect(CanvasHttp).to receive(:get).with(expected_oembed_uri)
          expect(subject).to be_successful
        end

        context "when the disable_oembed_retrieve feature flag is enabled" do
          it "returns a 410 gone" do
            Account.default.enable_feature!(:disable_oembed_retrieve)
            expect(subject.status).to eq(410)
          end
        end

        context "when a disabled tool shares the same consumer key" do
          before do
            disabled_tool = tool.dup
            disabled_tool.update!(shared_secret: SecureRandom.uuid)
            disabled_tool.destroy!
          end

          it "uses the active tool to verify the signature" do
            expect(CanvasHttp).to receive(:get).with(expected_oembed_uri)
            expect(subject).to be_successful
          end
        end

        context "when the user has changed" do
          before { user_session(user_model) }

          it { is_expected.to be_unauthorized }
        end

        context "when the token is expired" do
          let(:exp) { 2.days.ago.to_i }

          it { is_expected.to be_unauthorized }
        end

        context "when the audience differs from the expected" do
          let(:aud) { "https://not.expected.audience" }

          it { is_expected.to be_unauthorized }
        end

        context "when the JTI has been seen already" do
          specs_require_cache(:redis_cache_store)
          let(:static_uuid) { "d219444f-a608-45c3-b81b-74bf6ac7da25" }

          before do
            allow(SecureRandom).to receive(:uuid).and_return(static_uuid)
            # record the JTI as used
            get(:oembed_retrieve, params:)
          end

          it { is_expected.to be_unauthorized }
        end

        context "when the issuer is not found" do
          let(:iss) { "#{tool.consumer_key}-no-tool-here" }

          it { is_expected.to be_not_found }
        end

        context "when the iss identifies a tool from another account" do
          let(:root_account_two) { account_model }
          let(:tool_two) { external_tool_model(context: root_account_two) }
          let(:iss) { "second-tool-consumer-key" }

          before { tool_two.update!(consumer_key: iss) }

          it { is_expected.to be_not_found }
        end

        context "when the issuer secret yields the wrong signature" do
          before do
            oembed_token
            tool.update!(shared_secret: "super secret")
          end

          it { is_expected.to be_unauthorized }
        end

        context "when no active tool is found" do
          before { tool.destroy! }

          it { is_expected.to be_not_found }
        end

        context 'when the "oembed_token" parameter is empty' do
          let(:params) { {} }

          it { is_expected.to be_bad_request }
        end

        context 'when the "oembed_token" parameter is not a JWT' do
          let(:oembed_token) { "123" }

          it { is_expected.to be_bad_request }
        end
      end

      context "when there is no user session" do
        it { is_expected.to redirect_to "/login" }
      end
    end
  end
end
