# frozen_string_literal: true

#
# Copyright (C) 2017 Instructure, Inc.
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

describe Lti::ContentItemSelectionRequest do
  include ExternalToolsSpecHelper

  subject(:lti_request) { described_class.new(**default_params) }

  let(:default_params) do
    {
      context: course,
      domain_root_account: root_account,
      user: teacher,
      base_url:,
      tool:
    }
  end

  let(:base_url) { "https://canvas.test/" }
  let(:course) { course_model }
  let(:root_account) { course.root_account }
  let(:teacher) { course_with_teacher(course:).user }
  let(:placement) { "resource_selection" }
  let(:tool) { new_valid_tool(course) }
  let(:launch_url) { "http://www.test.com/launch" }

  context "#generate_lti_launch" do
    it "generates an Lti::Launch" do
      expect(lti_request.generate_lti_launch(placement:)).to be_a Lti::Launch
    end

    it "sends opts to the Lti::Launch" do
      opts = {
        post_only: true,
        tool_dimensions: { selection_height: "1000px", selection_width: "100%" }
      }

      expect(Lti::Launch).to receive(:new).with(opts).and_return(Lti::Launch.new(opts))

      lti_request.generate_lti_launch(placement:, opts:)
    end

    it "generates resource_url based on a launch_url" do
      lti_launch = lti_request.generate_lti_launch(placement:, opts: { launch_url: "https://www.example.com" })
      expect(lti_launch.resource_url).to eq "https://www.example.com"
    end

    it "defaults resource_url to tool url" do
      lti_launch = lti_request.generate_lti_launch(placement:)
      expect(lti_launch.resource_url).to eq tool.resource_selection[:url]
    end

    context "with environment-specific overrides" do
      let(:override_url) { "http://www.example-beta.com/selection_test" }
      let(:domain) { "www.example-beta.com" }

      before do
        allow(ApplicationController).to receive_messages(test_cluster?: true, test_cluster_name: "beta")

        tool.settings[:environments] = {
          domain:
        }
        tool.save!
      end

      it "uses override for resource_url" do
        lti_launch = lti_request.generate_lti_launch(placement:)
        expect(lti_launch.resource_url).to eq override_url
      end

      context "when launch_url is passed in params" do
        let(:launch_url) { "https://www.example.com/other_lti_launch" }
        let(:override_launch_url) { "https://www.example-beta.com/other_lti_launch" }

        it "uses overridden launch_url for resource_url" do
          lti_launch = lti_request.generate_lti_launch(placement:, opts: { launch_url: })
          expect(lti_launch.resource_url).to eq override_launch_url
        end
      end
    end

    it "sets the link text to the placement label" do
      lti_launch = lti_request.generate_lti_launch(placement:, opts: { launch_url: "https://www.example.com" })
      expect(lti_launch.link_text).to eq tool.label_for(placement.to_sym, I18n.locale)
    end

    it "sets the analytics id to the tool id" do
      lti_launch = lti_request.generate_lti_launch(placement:, opts: { launch_url: "https://www.example.com" })
      expect(lti_launch.analytics_id).to eq tool.tool_id
    end

    context "params" do
      it "builds a params hash that includes the default lti params" do
        lti_launch = lti_request.generate_lti_launch(placement:)
        default_params = described_class.default_lti_params(course, root_account, teacher).stringify_keys
        expect(lti_launch.params).to include(default_params)
      end

      it "sets the 'accept_multiple' param to false" do
        lti_launch = lti_request.generate_lti_launch(placement:)
        expect(lti_launch.params["accept_multiple"]).to eq "false"
      end

      it "adds message type and version params" do
        lti_launch = lti_request.generate_lti_launch(placement:)
        expect(lti_launch.params).to include({
                                               "lti_message_type" => "ContentItemSelectionRequest",
                                               "lti_version" => "LTI-1p0"
                                             })
      end

      it "adds context_title param" do
        lti_launch = lti_request.generate_lti_launch(placement:)
        expect(lti_launch.params["context_title"]).to eq course.name
      end

      it "adds the 'ext_lti_assignment_id' if available" do
        lti_assignment_id = SecureRandom.uuid
        body = { lti_assignment_id: }
        secure_params = Canvas::Security.create_jwt(body)
        lti_request = described_class.new(**default_params.merge({ secure_params: }))
        lti_launch = lti_request.generate_lti_launch(placement:)
        expect(lti_launch.params["ext_lti_assignment_id"]).to eq lti_assignment_id
      end

      context "return_url" do
        let(:base_uri) { URI.parse(base_url) }

        it "properly sets the return URL when no content item id is provided" do
          create_url = Rails.application.routes.url_helpers.course_external_content_success_url(
            host: base_uri.host,
            protocol: base_uri.scheme,
            course_id: course.id,
            service: :external_tool_dialog
          )

          lti_launch = lti_request.generate_lti_launch(placement:)

          expect(lti_launch.params["content_item_return_url"]).to eq create_url
        end

        it "properly sets the return URL when a content item id is provided" do
          item_id = 1
          update_url = Rails.application.routes.url_helpers.course_external_content_update_url(
            host: base_uri.host,
            protocol: base_uri.scheme,
            course_id: course.id,
            service: :external_tool_dialog,
            id: item_id
          )

          lti_launch = lti_request.generate_lti_launch(placement:, opts: { content_item_id: item_id })

          expect(lti_launch.params["content_item_return_url"]).to eq update_url
        end

        it "generates a url a http protocol when the base_uri uses http" do
          base_uri.scheme = "http"
          lti_request_with_scheme = described_class.new(**default_params.merge(base_url: base_uri.to_s))
          create_url = Rails.application.routes.url_helpers.course_external_content_success_url(
            host: base_uri.host,
            protocol: base_uri.scheme,
            course_id: course.id,
            service: :external_tool_dialog
          )

          lti_launch = lti_request_with_scheme.generate_lti_launch(placement:)

          expect(lti_launch.params["content_item_return_url"]).to eq create_url
        end

        it "generates a url with a port when there is a port in the base_uri" do
          base_uri.port = 8080
          lti_request_with_port = described_class.new(**default_params.merge(base_url: base_uri.to_s))
          create_url = Rails.application.routes.url_helpers.course_external_content_success_url(
            host: base_uri.host,
            protocol: base_uri.scheme,
            port: base_uri.port,
            course_id: course.id,
            service: :external_tool_dialog
          )

          lti_launch = lti_request_with_port.generate_lti_launch(placement:)

          expect(lti_launch.params["content_item_return_url"]).to eq create_url
        end
      end

      context "data" do
        it "includes the default launch URL" do
          lti_launch = lti_request.generate_lti_launch(placement:)
          decoded_jwt = JSON::JWT.decode(lti_launch.params["data"], :skip_verification)
          expect(decoded_jwt["default_launch_url"]).to eq tool.extension_setting(placement, :url)
        end

        it "includes content_item_id and oauth_consumer_key if content_item_id provided" do
          item_id = 1
          opts = { content_item_id: item_id }
          lti_launch = lti_request.generate_lti_launch(placement:, opts:)
          decoded_jwt = JSON::JWT.decode(lti_launch.params["data"], :skip_verification)
          expected_hash = { "default_launch_url" => tool.extension_setting(placement, :url),
                            "content_item_id" => item_id,
                            "oauth_consumer_key" => tool.consumer_key }
          expect(decoded_jwt).to eq expected_hash
        end

        it "does not include content_item_id or oauth_consumer_key if content_item_id is not provided" do
          lti_launch = lti_request.generate_lti_launch(placement:)
          decoded_jwt = JSON::JWT.decode(lti_launch.params["data"], :skip_verification)
          expect(decoded_jwt.keys).not_to include ["content_item_id", "oauth_consumer_key"]
        end
      end

      context "placement params" do
        it "adds params for the migration_selection placement" do
          lti_launch = lti_request.generate_lti_launch(placement: "migration_selection", opts: { launch_url: })
          params = lti_launch.params
          expect(params["accept_media_types"]).to include(
            "application/vnd.ims.imsccv1p1",
            "application/vnd.ims.imsccv1p2",
            "application/vnd.ims.imsccv1p3",
            "application/zip,application/xml"
          )
          expect(params["ext_content_file_extensions"]).to include("zip", "imscc", "mbz", "xml")
          expect(params).to include({
                                      "accept_presentation_document_targets" => "download",
                                      "accept_copy_advice" => "true"
                                    })
        end

        it "adds params for the editor_button placement" do
          lti_launch = lti_request.generate_lti_launch(placement: "editor_button", opts: { launch_url: })
          params = lti_launch.params
          expect(params["accept_media_types"]).to include(
            "image/*",
            "text/html",
            "application/vnd.ims.lti.v1.ltilink",
            "*/*"
          )
          expect(params["accept_presentation_document_targets"]).to include(
            "embed",
            "frame",
            "iframe",
            "window"
          )
          expect(params["accept_multiple"]).to eq("true")
        end

        it "adds params for the resource_selection placement" do
          lti_launch = lti_request.generate_lti_launch(placement: "resource_selection", opts: { launch_url: })
          params = lti_launch.params
          expect(params["accept_media_types"]).to eq "application/vnd.ims.lti.v1.ltilink"
          expect(params["accept_presentation_document_targets"]).to include(
            "frame",
            "window"
          )
        end

        it "adds params for the link_selection placement"
        it "adds params for the assignment_selection placement"

        it "adds params for the collaboration placement" do
          lti_launch = lti_request.generate_lti_launch(placement: "collaboration", opts: { launch_url: })

          expect(lti_launch.params).to include({
                                                 "accept_media_types" => "application/vnd.ims.lti.v1.ltilink",
                                                 "accept_presentation_document_targets" => "window",
                                                 "accept_unsigned" => "false",
                                                 "auto_create" => "true",
                                               })
        end

        it "substitutes collaboration variables in a collaboration launch"

        context "homework_submission" do
          it "adds params for an assignment that can accept an online_url submission" do
            assignment = assignment_model(course:, submission_types: "online_url")
            opts = { assignment:, launch_url: }
            lti_launch = lti_request.generate_lti_launch(placement: "homework_submission", opts:)
            expect(lti_launch.params).to include({
                                                   "accept_media_types" => "*/*",
                                                   "accept_presentation_document_targets" => "window",
                                                   "accept_copy_advice" => "false"
                                                 })
          end

          it "adds params for an assignment that can accept an online_upload submission" do
            assignment = assignment_model(course:, submission_types: "online_upload")
            opts = { assignment:, launch_url: }
            lti_launch = lti_request.generate_lti_launch(placement: "homework_submission", opts:)
            expect(lti_launch.params).to include({
                                                   "accept_media_types" => "*/*",
                                                   "accept_presentation_document_targets" => "none",
                                                   "accept_copy_advice" => "true"
                                                 })
          end

          it "adds params for extensions allowed by an assignment" do
            assignment = assignment_model(
              course:,
              submission_types: "online_upload",
              allowed_extensions: %w[txt jpg]
            )
            opts = { assignment:, launch_url: }
            lti_launch = lti_request.generate_lti_launch(placement: "homework_submission", opts:)
            expect(lti_launch.params["accept_media_types"]).to include("text/plain", "image/jpeg")
            expect(lti_launch.params["ext_content_file_extensions"]).to include("txt", "jpg")
          end

          it "adds params for assignments that accept either an online_upload or online_url" do
            assignment = assignment_model(course:, submission_types: "online_upload,online_url")
            opts = { assignment:, launch_url: }
            lti_launch = lti_request.generate_lti_launch(placement: "homework_submission", opts:)

            expect(lti_launch.params["accept_presentation_document_targets"]).to include(
              "window",
              "none"
            )
            expect(lti_launch.params).to include({
                                                   "accept_media_types" => "*/*",
                                                   "accept_copy_advice" => "true"
                                                 })
          end
        end
      end
    end
  end

  context ".default_lti_params" do
    before do
      allow(Lti::Asset).to receive(:opaque_identifier_for).with(course).and_return("course_opaque_id")
    end

    it "generates default_lti_params" do
      root_account.lti_guid = "account_guid"

      I18n.with_locale(:de) do
        params = described_class.default_lti_params(course, root_account)
        expect(params).to include({
                                    context_id: "course_opaque_id",
                                    tool_consumer_instance_guid: "account_guid",
                                    roles: "urn:lti:sysrole:ims/lis/None",
                                    launch_presentation_locale: "de",
                                    launch_presentation_document_target: "iframe",
                                    ext_roles: "urn:lti:sysrole:ims/lis/None"
                                  })
      end
    end

    it "adds user information when a user is provided" do
      allow(Lti::Asset).to receive(:opaque_identifier_for).with(teacher, context: course).and_return("teacher_opaque_id")

      params = described_class.default_lti_params(course, root_account, teacher)

      expect(params).to include({
                                  roles: "Instructor",
                                  user_id: "teacher_opaque_id"
                                })
      expect(params[:ext_roles]).to include("urn:lti:role:ims/lis/Instructor", "urn:lti:sysrole:ims/lis/User")
    end
  end
end
