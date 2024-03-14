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

require_relative "concerns/deep_linking_spec_helper"
require_relative "../concerns/parent_frame_shared_examples"

module Lti
  module IMS
    RSpec.describe DeepLinkingController do
      include_context "deep_linking_spec_helper"

      describe "#deep_linking_response" do
        subject { post :deep_linking_response, params: }

        let(:placement) { "editor_button" }
        let(:return_url_params) { { placement:, content_item_id: 123 } }
        let(:data_token) { Lti::DeepLinkingData.jwt_from(return_url_params) }
        let(:params) { { JWT: deep_linking_jwt, account_id: account.id, data: data_token } }
        let(:course) { course_model(account:) }

        let(:context_external_tool) do
          ContextExternalTool.create!(
            context: course.account,
            url: "http://tool.url/login",
            name: "test tool",
            shared_secret: "secret",
            consumer_key: "key",
            developer_key:,
            lti_version: "1.3"
          )
        end

        it { is_expected.to be_ok }

        it "renders the page" do
          expect(subject).to render_template("lti/ims/deep_linking/deep_linking_response")
        end

        it "sets the JS ENV" do
          expect(controller).to receive(:js_env).with({ deep_linking_use_window_parent: true })
          expect(controller).to receive(:js_env).with({
                                                        deep_link_response: {
                                                          placement:,
                                                          content_items:,
                                                          service_id: 123,
                                                          msg:,
                                                          log:,
                                                          errormsg:,
                                                          errorlog:,
                                                          ltiEndpoint: Rails.application.routes.url_helpers.polymorphic_url(
                                                            [:retrieve, account, :external_tools],
                                                            host: "test.host"
                                                          ),
                                                          reloadpage: false,
                                                          moduleCreated: false
                                                        }
                                                      })

          subject
        end

        context "when returning from a non-internal service" do
          let(:return_url_params) { { placement:, parent_frame_context: context_external_tool.id } }

          it "does not change the DEEP_LINKING_POST_MESSAGE_ORIGIN value in jsenv" do
            subject
            # base_url is the default
            expect(assigns(:js_env)[:DEEP_LINKING_POST_MESSAGE_ORIGIN]).to eq(@controller.request.base_url)
          end
        end

        context "when returning from an internal service" do
          before do
            developer_key.update!(internal_service: true)
            u = course_with_teacher(course:, user: user_model, active_all: true).user
            user_session(u)
          end

          let(:return_url_params) { { placement:, parent_frame_context: context_external_tool.id } }

          it "sets the DEEP_LINKING_POST_MESSAGE_ORIGIN value in js_env" do
            subject
            expect(assigns(:js_env)[:DEEP_LINKING_POST_MESSAGE_ORIGIN]).to eq("http://tool.url")
          end
        end

        it_behaves_like "an endpoint which uses parent_frame_context to set the CSP header" do
          let(:return_url_params) { { placement:, parent_frame_context: pfc_tool.id } }
          let(:pfc_tool_context) do
            # Need to enroll user to make sure user can access pfc tool
            enrollment = course_with_teacher(course:, user: user_model, active_all: true)
            user_session(enrollment.user)
            enrollment.course
          end
        end

        context "when the messages/logs passed in are not strings" do
          let(:msg) { { html: "some message" } }
          let(:errormsg) { { html: "some error message" } }
          let(:log) { { html: "some log" } }
          let(:errorlog) { { html: "some error log" } }

          it "turns them into strings before calling js_env to prevent HTML injection" do
            expect(controller).to receive(:js_env).with({ deep_linking_use_window_parent: true })
            expect(controller).to receive(:js_env).with({
                                                          deep_link_response: hash_including(
                                                            msg: '{"html"=>"some message"}',
                                                            log: '{"html"=>"some log"}',
                                                            errormsg: '{"html"=>"some error message"}',
                                                            errorlog: '{"html"=>"some error log"}'
                                                          )
                                                        })
            subject
          end
        end

        context "when only creating resource links" do
          let(:launch_url) { "http://tool.url/launch" }
          let(:title) { "Item 1" }
          let(:content_items) do
            [
              { type: "ltiResourceLink", url: launch_url, title: },
              { type: "link", url: "http://too.url/sample", title: "Item 2" }
            ]
          end
          let!(:tool) do
            external_tool_1_3_model(
              context: account,
              opts: {
                url: "http://tool.url/login",
                developer_key:
              }
            )
          end

          shared_examples_for "creates resource links in context" do
            let(:context) { raise "set in examples " }

            before do
              subject
            end

            it "creates a resource link in the context" do
              expect(context.lti_resource_links.size).to eq 1
              expect(context.lti_resource_links.first.current_external_tool(context)).to eq tool
              expect(context.lti_resource_links.first.context).to eq context
              expect(context.lti_resource_links.first.title).to eq title
            end

            it "sends resource link uuid in content item response" do
              expect(controller.content_items.first["lookup_uuid"]).to eq context.lti_resource_links.first.lookup_uuid
            end
          end

          context "when context is an account" do
            let(:params) { { JWT: deep_linking_jwt, account_id: account.id, data: data_token } }

            it_behaves_like "creates resource links in context" do
              let(:context) { account }
            end
          end

          context "when context is a course" do
            let(:course) { course_model(account:) }
            let(:params) { { JWT: deep_linking_jwt, course_id: course.id, data: data_token } }

            it_behaves_like "creates resource links in context" do
              let(:context) { course }
            end
          end

          context "when context is a group" do
            let(:group) { group_model(context: course_model(account:)) }
            let(:params) { { JWT: deep_linking_jwt, group_id: group.id, data: data_token } }

            it_behaves_like "creates resource links in context" do
              let(:context) { group }
            end
          end
        end

        shared_examples_for "errors" do
          let(:response_message) { raise "set in examples" }

          it { is_expected.to be_bad_request }

          it "reports error metric" do
            allow(InstStatsd::Statsd).to receive(:increment).and_call_original
            subject
            expect(InstStatsd::Statsd).to have_received(:increment).with("canvas.deep_linking_controller.request_error", tags: { code: 400 })
          end

          it "responds with an error" do
            subject
            expect(json_parse["errors"].to_s).to include response_message
          end
        end

        context "when the data token is invalid" do
          context "when it is absent" do
            let(:data_token) { nil }

            it_behaves_like "errors" do
              let(:response_message) { "presence_required" }
            end
          end

          context "when it is malformed" do
            let(:data_token) { super()[0...-10] } # remove the last 10 characters of the JWT

            it_behaves_like "errors" do
              let(:response_message) { "invalid_or_malformed" }
            end
          end

          context "when it has been used already" do
            before do
              allow(Lti::Security).to receive(:check_and_store_nonce).and_return(false)
            end

            it_behaves_like "errors" do
              let(:response_message) { "already_used" }
            end

            it "checks the nonce again" do
              subject
              expect(Lti::Security).to have_received(:check_and_store_nonce).once
            end
          end
        end

        context "when the jti is being reused" do
          let(:jti) { "static value" }
          let(:nonce_key) { "nonce::#{jti}" }

          before { Lti::Security.check_and_store_nonce(nonce_key, iat, 30.seconds) }

          it { is_expected.to be_successful }
        end

        context "when the aud is invalid" do
          let(:aud) { "banana" }

          it_behaves_like "errors" do
            let(:response_message) { "the 'aud' is invalid" }
          end
        end

        context "when the jwt format is invalid" do
          let(:deep_linking_jwt) { "banana" }

          it_behaves_like "errors" do
            let(:response_message) { "JWT format is invalid" }
          end
        end

        context "when the jwt has the wrong alg" do
          let(:alg) { :HS256 }
          let(:private_jwk) { SecureRandom.uuid }

          it_behaves_like "errors" do
            let(:response_message) { "JWT has unexpected alg" }
          end
        end

        context "when jwt verification fails" do
          let(:private_jwk) do
            new_key = DeveloperKey.new
            new_key.generate_rsa_keypair!
            JSON::JWK.new(new_key.private_jwk)
          end

          it_behaves_like "errors" do
            let(:response_message) { "JWT verification failure" }
          end
        end

        context "when a url is used to get public key" do
          let(:rsa_key_pair) { CanvasSecurity::RSAKeyPair.new }
          let(:url) { "https://get.public.jwk" }
          let(:public_jwk_url_response) do
            {
              keys: [
                public_jwk
              ]
            }
          end
          let(:stubbed_response) { double(success?: true, parsed_response: public_jwk_url_response) }

          before do
            allow(HTTParty).to receive(:get).with(url).and_return(stubbed_response)
          end

          context "when there is no public jwk" do
            before do
              developer_key.update!(public_jwk: nil, public_jwk_url: url)
            end

            it { is_expected.to be_successful }
          end

          context "when there is a public jwk" do
            before do
              developer_key.update!(public_jwk_url: url)
            end

            it { is_expected.to be_successful }
          end

          context "when an empty object is returned" do
            let(:public_jwk_url_response) { {} }
            let(:response_message) { "JWT verification failure" }

            before do
              developer_key.update!(public_jwk_url: url)
            end

            it do
              subject
              expect(json_parse["errors"].to_s).to include response_message
            end
          end

          context "when the url is not valid giving a 404" do
            let(:stubbed_response) { double(success?: false, parsed_response: public_jwk_url_response.to_json) }
            let(:response_message) { "JWT verification failure" }
            let(:public_jwk_url_response) do
              {
                success?: false, code: "404"
              }
            end

            before do
              developer_key.update!(public_jwk_url: url)
            end

            it do
              subject
              expect(json_parse["errors"].to_s).to include response_message
            end
          end
        end

        context "when the developer key is not found" do
          let(:iss) { developer_key.global_id + 100 }

          it_behaves_like "errors" do
            let(:response_message) { "Client not found" }
          end
        end

        context "when the developer key binding is off" do
          before do
            developer_key.developer_key_account_bindings.first.update!(
              workflow_state: "off"
            )
          end

          it_behaves_like "errors" do
            let(:response_message) { "Developer key inactive in context" }
          end
        end

        context "when the developer key is not active" do
          before do
            developer_key.update!(
              workflow_state: "deleted"
            )
          end

          it_behaves_like "errors" do
            let(:response_message) { "Developer key inactive" }
          end
        end

        context "when the iat is in the future" do
          let(:iat) { 1.hour.from_now.to_i }

          it_behaves_like "errors" do
            let(:response_message) { "the 'iat' must not be in the future" }
          end
        end

        context "when the exp is past" do
          let(:exp) { 1.hour.ago.to_i }

          it_behaves_like "errors" do
            let(:response_message) { "the JWT has expired" }
          end
        end

        context "content_item claim message" do
          let(:course) { course_model(account:) }
          let(:developer_key) do
            key = DeveloperKey.create!(account: course.account)
            key.generate_rsa_keypair!
            key.developer_key_account_bindings.first.update!(
              workflow_state: "on"
            )
            key.save!
            key
          end
          let(:context_external_tool) do
            ContextExternalTool.create!(
              context: course.account,
              url: "http://tool.url/login",
              name: "test tool",
              shared_secret: "secret",
              consumer_key: "key",
              developer_key:,
              lti_version: "1.3"
            )
          end
          let(:launch_url) { "http://tool.url/launch" }
          let(:params) { super().merge({ course_id: course.id }) }
          let(:return_url_params) { super().merge({ placement: "course_assignments_menu" }) }

          context "when is empty" do
            let(:content_items) { nil }

            it { is_expected.to be_ok }

            it "does not create a new module" do
              expect { subject }.not_to change { course.context_modules.count }
            end

            it "doesn't ask to reload page" do
              subject
              expect(assigns.dig(:js_env, :deep_link_response, :reloadpage)).to be false
            end
          end

          context "when is omitted" do
            let(:deep_linking_jwt) do
              body = {
                "iss" => iss,
                "aud" => aud,
                "iat" => iat,
                "exp" => exp,
                "jti" => jti,
                "nonce" => SecureRandom.uuid,
                "https://purl.imsglobal.org/spec/lti/claim/message_type" => response_message_type,
                "https://purl.imsglobal.org/spec/lti/claim/version" => lti_version,
                "https://purl.imsglobal.org/spec/lti/claim/deployment_id" => deployment_id,
                "https://purl.imsglobal.org/spec/lti-dl/claim/msg" => msg,
                "https://purl.imsglobal.org/spec/lti-dl/claim/errormsg" => errormsg,
                "https://purl.imsglobal.org/spec/lti-dl/claim/log" => log,
                "https://purl.imsglobal.org/spec/lti-dl/claim/errorlog" => errorlog
              }
              JSON::JWT.new(body).sign(private_jwk, alg).to_s
            end

            it { is_expected.to be_ok }

            it "does not create a new module" do
              expect { subject }.not_to change { course.context_modules.count }
            end

            it "doesn't ask to reload page" do
              subject
              expect(assigns.dig(:js_env, :deep_link_response, :reloadpage)).to be false
            end
          end

          context "when module item content items are received" do
            before do
              course
              user_session(@user)
              context_external_tool
            end

            context "when context_module_id param is included" do
              let(:context_module) { course.context_modules.create!(name: "Test Module") }
              let(:return_url_params) { super().merge({ context_module_id: context_module.id }) }

              context "single item" do
                let(:content_items) do
                  [{ type: "ltiResourceLink", url: launch_url, title: "Item 1", custom_params: { "a" => "b" } }]
                end

                it "creates a resource link" do
                  expect { subject }.to change { course.lti_resource_links.count }.by 1
                end

                it "creates a module item" do
                  expect { subject }.to change { context_module.content_tags.count }.by 1
                end

                context "when window.targetName is _blank" do
                  let(:content_items) do
                    [{ type: "ltiResourceLink", url: launch_url, title: "Item 1", window: { targetName: "_blank" } }]
                  end

                  it "sets new_tab true on module item" do
                    subject
                    expect(context_module.content_tags.last.new_tab).to be true
                  end
                end

                it "asks to reload page" do
                  subject
                  expect(assigns.dig(:js_env, :deep_link_response, :reloadpage)).to be true
                end

                context "when placement is link_selection" do
                  let(:return_url_params) { super().merge({ placement: :link_selection }) }

                  it "doesn't create a resource link" do
                    # The resource links for these are rather created when the module item is created
                    expect { subject }.not_to change { course.lti_resource_links.count }
                  end

                  it "doesn't create a module item" do
                    expect { subject }.not_to change { context_module.content_tags.count }
                  end

                  it "doesn't ask to reload page" do
                    subject
                    expect(assigns.dig(:js_env, :deep_link_response, :reloadpage)).to be false
                  end

                  context "with line item" do
                    let(:content_items) do
                      [{ type: "ltiResourceLink", url: launch_url, title: "Item 1", lineItem: { scoreMaximum: 5 } }]
                    end

                    it "doesn't create a resource link" do
                      # The resource links for these are rather created when the module item is created
                      expect { subject }.not_to change { course.lti_resource_links.count }
                    end

                    it "doesn't create a module item" do
                      expect { subject }.not_to change { context_module.content_tags.count }
                    end

                    it "doesn't ask to reload page" do
                      subject
                      expect(assigns.dig(:js_env, :deep_link_response, :reloadpage)).to be false
                    end
                  end
                end
              end

              context "multiple items" do
                let(:content_items) do
                  [
                    { type: "ltiResourceLink", url: launch_url, title: "Item 1" },
                    { type: "ltiResourceLink", url: launch_url, title: "Item 2", custom: { mycustom: "123" } },
                    { type: "ltiResourceLink", url: launch_url, title: "Item 3", lineItem: { scoreMaximum: 5 } }
                  ]
                end

                it "creates multiple module items" do
                  expect(subject).to be_successful
                  expect(context_module.content_tags.count).to eq(3)
                end

                it "leaves module items unpublished" do
                  subject
                  expect(context_module.content_tags.last.workflow_state).to eq("unpublished")
                end

                it "creates all resource links" do
                  expect(course.lti_resource_links).to be_empty
                  expect(subject).to be_successful
                  expect(course.lti_resource_links.size).to eq 3
                end

                it "adds the resource link as the content tag's associated asset" do
                  expect(subject).to be_successful

                  content_tags = context_module.content_tags
                  lti_resource_links = course.lti_resource_links

                  expect(content_tags.first.associated_asset).to eq(lti_resource_links.first)
                  expect(content_tags.second.associated_asset).to eq(lti_resource_links.second)
                  expect(content_tags.last.associated_asset).to eq(lti_resource_links.last)
                end

                it "adds custom params to the resource links" do
                  expect(subject).to be_successful
                  expect(course.lti_resource_links.second.custom).to eq("mycustom" => "123")
                end

                it "does not pass launch dimensions" do
                  expect(subject).to be_successful
                  expect(context_module.content_tags[0][:link_settings]).to be_nil
                end

                it "ignores line items from tool" do
                  expect { subject }.not_to change { course.assignments.count }
                end

                it "asks to reload page" do
                  subject
                  expect(assigns.dig(:js_env, :deep_link_response, :reloadpage)).to be true
                end

                context "when content items have iframe property" do
                  let(:content_items) do
                    [
                      { type: "ltiResourceLink", url: "http://tool.url", iframe: { width: 642, height: 842 }, title: "Item 1" },
                      { type: "ltiResourceLink", url: "http://tool.url", iframe: { width: 642 }, title: "Item 2" },
                      { type: "ltiResourceLink", url: "http://tool.url", iframe: { height: 842 }, title: "Item 3" }
                    ]
                  end

                  it "passes launch dimensions as link_settings" do
                    expect(subject).to be_successful
                    expect(context_module.content_tags[0][:link_settings]["selection_width"]).to be(642)
                    expect(context_module.content_tags[0][:link_settings]["selection_height"]).to be(842)

                    expect(context_module.content_tags[1][:link_settings]["selection_width"]).to be(642)
                    expect(context_module.content_tags[1][:link_settings]["selection_height"]).to be_nil

                    expect(context_module.content_tags[2][:link_settings]["selection_width"]).to be_nil
                    expect(context_module.content_tags[2][:link_settings]["selection_height"]).to be(842)
                  end
                end

                context "when the user is not authorized" do
                  before do
                    u = User.create
                    user_session u
                  end

                  it "returns 'unauthorized' (and doesn't render twice)" do
                    subject
                    expect(response).to have_http_status(:unauthorized)
                  end
                end
              end
            end

            context "when placement should create new module" do
              let(:return_url_params) { super().merge({ placement: "module_index_menu_modal" }) }

              context "when feature flag is disabled" do
                it "does not change anything" do
                  expect { subject }.not_to change { course.context_modules.count }
                  expect { subject }.not_to change { course.lti_resource_links.count }
                  expect { subject }.not_to change { ContentTag.where(context: course).count }
                end
              end

              context "when feature flag is enabled" do
                before do
                  course.root_account.enable_feature!(:lti_deep_linking_module_index_menu_modal)
                end

                context "single item" do
                  let(:content_items) do
                    [{ type: "ltiResourceLink", url: launch_url, title: "Item 1" }]
                  end

                  it "creates a new context module" do
                    expect { subject }.to change { course.context_modules.count }.by 1
                  end

                  it "creates a resource link" do
                    expect { subject }.to change { course.lti_resource_links.count }.by 1
                  end

                  context "from the assignment_selection placement" do
                    let(:return_url_params) { super().merge({ placement: "assignment_selection" }) }

                    context "with no line items" do
                      let(:content_items) do
                        [{ type: "ltiResourceLink", url: launch_url, title: "Item 1" }]
                      end

                      it "does not create a resource link" do
                        expect { subject }.not_to change { Lti::ResourceLink.count }
                      end
                    end

                    context "with line items" do
                      let(:content_items) do
                        [
                          { type: "ltiResourceLink", url: launch_url, title: "Item 1", lineItem: { scoreMaximum: 4 } },
                          { type: "ltiResourceLink", url: launch_url, title: "Item 2", lineItem: { scoreMaximum: 4 } },
                        ]
                      end

                      it "creates resource links and only resource links for the course" do
                        expect { subject }.not_to change { Lti::ResourceLink.count }
                      end
                    end
                  end

                  it "creates a module item" do
                    expect { subject }.to change { ContentTag.where(context: course).count }.by 1
                  end

                  it "leaves module items unpublished" do
                    subject
                    expect(ContentTag.where(context: course).last.workflow_state).to eq("unpublished")
                  end

                  it "tells the frontend a module was created" do
                    subject
                    expect(assigns.dig(:js_env, :deep_link_response, :moduleCreated)).to be true
                  end
                end

                context "multiple items" do
                  let(:content_items) do
                    [
                      { type: "ltiResourceLink", url: launch_url, title: "Item 1" },
                      { type: "ltiResourceLink", url: launch_url, title: "Item 2" },
                      { type: "ltiResourceLink", url: launch_url, title: "Item 3" }
                    ]
                  end

                  it "creates a new context module" do
                    expect { subject }.to change { course.context_modules.count }.by 1
                  end

                  it "creates one resource link per item" do
                    expect { subject }.to change { course.lti_resource_links.count }.by 3
                  end

                  it "creates one module item per item" do
                    expect { subject }.to change { ContentTag.where(context: course).count }.by 3
                  end

                  it "leaves module items unpublished" do
                    subject
                    expect(ContentTag.where(context: course).last.workflow_state).to eq("unpublished")
                  end
                end
              end
            end
          end

          context "when content items that contain line items are received" do
            let(:content_items) { [content_item] }
            let(:content_item) do
              { type: "ltiResourceLink", url: launch_url, title: "Item 1", lineItem: }
            end
            let(:lineItem) do
              { scoreMaximum: 10 }
            end

            before do
              course
              user_session(@user)
              context_external_tool
              course.root_account.enable_feature! :lti_deep_linking_line_items
              course.root_account.enable_feature! :lti_deep_linking_module_index_menu_modal
            end

            shared_examples_for "does nothing" do
              it "does not create an assignment" do
                expect { subject }.not_to change { course.assignments.count }
              end
            end

            context "when feature flag is disabled" do
              before do
                course.root_account.disable_feature! :lti_deep_linking_line_items
              end

              it_behaves_like "does nothing"
            end

            context "when context is an account" do
              let(:params) { super().except(:course_id).merge({ account_id: account.id }) }

              it_behaves_like "does nothing"
            end

            context "when placement is not allowed to create line items" do
              let(:return_url_params) { super().merge({ placement: "homework_submission" }) }

              it_behaves_like "does nothing"
            end

            context "when required parameter scoreMaximum is absent" do
              let(:lineItem) { { tag: "will not work" } }

              it_behaves_like "does nothing"
              it "sends error in content item response" do
                subject
                expect(assigns.dig(:js_env, :deep_link_response, :content_items).first).to have_key(:errors)
              end

              it "does not create a context module" do
                expect { subject }.not_to change { course.context_modules.count }
              end

              context "when title is present in content item" do
                let(:title) { "hello" }
                let(:content_item) do
                  super().merge({ title: })
                end

                it "includes title in response" do
                  subject
                  expect(assigns.dig(:js_env, :deep_link_response, :content_items, 0, :title)).to eq title
                end
              end

              context "when label is present in line item" do
                let(:label) { "will not work" }
                let(:lineItem) { { label: } }

                it "includes label as title in response" do
                  subject
                  expect(assigns.dig(:js_env, :deep_link_response, :content_items, 0, :title)).to eq label
                end
              end
            end

            it "leaves assignment unpublished" do
              subject
              expect(course.assignments.last.workflow_state).to eq("unpublished")
            end

            it "does not create a context module" do
              expect { subject }.not_to change { course.context_modules.count }
            end

            context "when content item includes available dates" do
              let(:content_item) do
                super().merge({ available: { startDateTime: Time.zone.now.iso8601, endDateTime: Time.zone.now.iso8601 } })
              end

              it "sets assignment unlock date to startDateTime" do
                subject
                expect(Assignment.last.unlock_at).to eq content_item.dig(:available, :startDateTime)
              end

              it "sets assignment lock date to endDateTime" do
                subject
                expect(Assignment.last.lock_at).to eq content_item.dig(:available, :endDateTime)
              end
            end

            context "when content item includes submission dates" do
              let(:content_item) do
                super().merge({ submission: { endDateTime: Time.zone.now.iso8601 } })
              end

              it "sets assignment due date to endDateTime" do
                subject
                expect(Assignment.last.due_at).to eq content_item.dig(:submission, :endDateTime)
              end
            end

            context "when content item includes title" do
              let(:content_item) do
                super().merge({ title: "hello" })
              end

              it "uses title for assignment title" do
                subject
                expect(Assignment.last.title).to eq content_items.first[:title]
              end
            end

            context "when line item includes label" do
              let(:lineItem) do
                super().merge({ label: "hello" })
              end

              it "uses label for assignment title" do
                subject
                expect(Assignment.last.title).to eq content_items.first.dig(:lineItem, :label)
              end
            end

            context "when line item includes tag" do
              let(:lineItem) do
                super().merge({ tag: "hello" })
              end

              it "stores tag on line item" do
                subject
                expect(Lti::LineItem.last.tag).to eq content_items.first.dig(:lineItem, :tag)
              end
            end

            context "when line item includes resourceId" do
              let(:lineItem) do
                super().merge({ resourceId: "hello" })
              end

              it "stores resourceId on line item" do
                subject
                expect(Lti::LineItem.last.resource_id).to eq content_items.first.dig(:lineItem, :resourceId)
              end
            end

            context "when content item includes custom" do
              let(:content_item) do
                super().merge({ custom: { hello: "$User.id" } })
              end

              it "stores custom on resource link" do
                subject
                expect(Lti::ResourceLink.last.custom).to eq content_items.first[:custom].with_indifferent_access
              end
            end

            context "when placement should create new module" do
              let(:return_url_params) { super().merge({ placement: "module_index_menu_modal" }) }

              before do
                course.root_account.enable_feature! :lti_deep_linking_module_index_menu_modal
              end

              it "creates a new context module" do
                expect { subject }.to change { course.context_modules.count }.by 1
              end

              it "creates a module item for every content item" do
                expect { subject }.to change { ContentTag.where(context: course).count }.by content_items.length
              end

              it "creates a link within the module item to the created assignment" do
                subject
                new_module = course.context_modules.last
                content_tags = new_module.content_tags

                expect(content_tags.last.title).to eq(content_item[:title])
              end

              it "leaves assignment unpublished" do
                subject
                expect(course.assignments.last.workflow_state).to eq("unpublished")
                expect(ContentTag.where(context: course).last.workflow_state).to eq("unpublished")
              end
            end

            context "when on the new assignment page" do
              before do
                course.root_account.enable_feature! :lti_assignment_page_line_items
              end

              let(:return_url_params) { super().merge({ placement: "assignment_selection" }) }
              let(:content_items) do
                [
                  { type: "ltiResourceLink", url: launch_url, title: "Item 1", lineItem: { scoreMaximum: 4 } },
                  { type: "ltiResourceLink", url: launch_url, title: "Item 2", lineItem: { scoreMaximum: 4 } },
                  { type: "ltiResourceLink", url: launch_url, title: "Item 3", lineItem: { scoreMaximum: 4 } }
                ]
              end

              context "when assignment edit page feature flag is disabled" do
                before do
                  course.root_account.disable_feature! :lti_assignment_page_line_items
                end

                it_behaves_like "does nothing"
              end

              it "does not create a new module" do
                expect { subject }.not_to change { course.context_modules.count }
              end

              it "does not create an assignment" do
                expect { subject }.not_to change { course.assignments.count }
              end
            end

            context "when on the edit assignment page" do
              let(:assignment) { assignment_model(course:, workflow_state: "published") }
              let(:return_url_params) { super().merge({ placement: "assignment_selection", assignment_id: assignment.id }) }
              let(:content_items) do
                [
                  { type: "ltiResourceLink", url: launch_url, title: "Item 1", lineItem: { scoreMaximum: 4 } }
                ]
              end

              it "does not create a new assignment" do
                assignment
                expect { subject }.not_to change { course.assignments.count }
              end

              it "leaves assignment in same workflow_state it was in" do
                subject
                expect(course.assignments.last.workflow_state).to eq("published")
              end
            end

            context "when creating a single item in an existing module" do
              let(:context_module) { course.context_modules.create!(name: "Test Module") }
              let(:return_url_params) { super().merge({ context_module_id: context_module.id, placement: "link_selection" }) }

              before do
                context_module
              end

              it "does not create a new module" do
                expect { subject }.not_to change { course.context_modules.count }
              end

              it "creates an assignment" do
                expect { subject }.to change { course.assignments.count }.by 1
              end

              it "adds assignment to given module" do
                expect { subject }.to change { course.context_modules.last.content_tags.count }.by 1
              end
            end
          end

          context "when a content item for a collaboration is received" do
            before do
              course
              user_session(@user)
              context_external_tool
            end

            let(:content_items) do
              [
                { type: "ltiResourceLink", url: launch_url, title: "Item 1" }
              ]
            end

            let(:return_url_params) { super().merge(placement: "collaboration") }

            it "does not create a resource link" do
              expect do
                subject
              end.to_not change { Lti::ResourceLink.count }
            end

            it "includes tool_id in the js_env deep_link_response" do
              allow(controller).to receive(:js_env)
              subject
              expected_js_env_attributes = {
                tool_id: context_external_tool.id,
                content_items:
              }

              expect(controller).to have_received(:js_env).with(deep_link_response: hash_including(expected_js_env_attributes))
            end
          end
        end
      end
    end
  end
end
