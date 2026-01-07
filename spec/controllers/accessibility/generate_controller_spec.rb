# frozen_string_literal: true

#
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

require "spec_helper"

RSpec.describe Accessibility::GenerateController do
  describe "#create_table_caption" do
    let!(:course) { Course.create! }
    let!(:user) { User.create! }
    let(:accessibility_issue_instance) { instance_double(Accessibility::Issue) }

    before do
      allow(controller).to receive_messages(require_context: true, require_user: true, check_authorized_action: true)
      controller.instance_variable_set(:@context, course)
      controller.instance_variable_set(:@current_user, user)

      allow(Accessibility::Issue).to receive(:new).with(context: course).and_return(accessibility_issue_instance)
      allow(LLMConfigs).to receive(:config_for).with("alt_text_generate").and_return({})
      allow(InstLLMHelper).to receive(:with_rate_limit).and_yield
      allow(course).to receive(:a11y_checker_enabled?).and_return(true)
      Account.site_admin.enable_feature!(:a11y_checker_ai_table_caption_generation)
    end

    context "for a wiki page" do
      let!(:wiki_page) { course.wiki_pages.create!(title: "test page", body: "test body") }
      let(:params) do
        {
          course_id: course.id,
          rule: "some_rule",
          content_type: "WikiPage",
          content_id: wiki_page.id.to_s,
          path: "some_path",
          value: "some_value"
        }
      end
      let(:response_data) { { json: { "result" => "success" }, status: :ok } }

      it "returns the correct response" do
        expect(accessibility_issue_instance).to receive(:generate_fix).with("some_rule", "WikiPage", wiki_page.id.to_s, "some_path", "some_value").and_return(response_data)

        post :create_table_caption, params:, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "result" => "success" })
      end
    end

    context "for an assignment" do
      let!(:assignment) { course.assignments.create! }
      let(:params) do
        {
          course_id: course.id,
          rule: "another_rule",
          content_type: "Assignment",
          content_id: assignment.id.to_s,
          path: "another_path",
          value: "another_value"
        }
      end
      let(:response_data) { { json: { "result" => "success" }, status: :ok } }

      it "returns the correct response" do
        expect(accessibility_issue_instance).to receive(:generate_fix).with("another_rule", "Assignment", assignment.id.to_s, "another_path", "another_value").and_return(response_data)

        post :create_table_caption, params:, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "result" => "success" })
      end
    end

    context "with missing params" do
      let(:params) do
        {
          course_id: course.id,
          rule: "some_rule"
        }
      end
      let(:error_response) { { json: { "error" => "missing params" }, status: :bad_request } }

      it "returns an error" do
        expect(accessibility_issue_instance).to receive(:generate_fix).with("some_rule", nil, nil, nil, nil).and_return(error_response)

        post :create_table_caption, params:, format: :json
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq({ "error" => "missing params" })
      end
    end

    context "when rate limit is exceeded" do
      let(:params) do
        {
          course_id: course.id,
          rule: "img-alt",
          content_type: "WikiPage",
          content_id: "123",
          path: "img_path",
          value: "test_value"
        }
      end

      before do
        # Override the previous mock to throw the rate limit exception
        # The error requires a limit parameter
        rate_limit_error = InstLLMHelper::RateLimitExceededError.new(limit: 10)
        allow(InstLLMHelper).to receive(:with_rate_limit).and_raise(rate_limit_error)
      end

      it "returns a too many requests status with appropriate error message" do
        post :create_table_caption, params:, format: :json

        expect(response).to have_http_status(:too_many_requests)
      end
    end

    context "rate limiting" do
      let(:params) do
        {
          course_id: course.id,
          rule: "some_rule",
          content_type: "Assignment",
          content_id: "123",
          path: "some_path",
          value: "some_value"
        }
      end

      it "uses InstLLMHelper with rate limiting" do
        allow(LLMConfigs).to receive(:config_for).and_call_original
        allow(InstLLMHelper).to receive(:with_rate_limit).and_call_original

        config = {}
        allow(LLMConfigs).to receive(:config_for).with("alt_text_generate").and_return(config)

        expect(InstLLMHelper).to receive(:with_rate_limit) do |args|
          expect(args[:user]).to eq user
          expect(args[:llm_config]).to eq config
        end.and_yield

        allow(accessibility_issue_instance).to receive(:generate_fix).and_return({ json: {}, status: :ok })

        post :create_table_caption, params:, format: :json
      end
    end
  end

  describe "#create_image_alt_text" do
    let!(:course) { Course.create! }
    let!(:user) { User.create! }
    let!(:attachment) { attachment_model(context: user, size: 1.megabyte, content_type: "image/png") }

    before do
      allow(controller).to receive_messages(
        require_context: true,
        require_user: true,
        check_authorized_action: true
      )
      controller.instance_variable_set(:@context, course)
      controller.instance_variable_set(:@current_user, user)
      controller.instance_variable_set(:@domain_root_account, Account.default)

      allow(course).to receive_messages(a11y_checker_enabled?: true, root_account: Account.default)
      Account.site_admin.enable_feature!(:a11y_checker_ai_alt_text_generation)

      stub_const("CedarClient", Class.new do
        def self.generate_alt_text(*)
          Struct.new(:image, keyword_init: true).new(image: { "altText" => "Generated alt text" })
        end
      end)
    end

    context "with valid wiki page and image" do
      let!(:wiki_page) do
        page = course.wiki_pages.build(title: "Test Page", body: "<div><p><img src=\"/files/#{attachment.id}\" /></p></div>")
        page.updating_user = user
        page.save!
        page
      end

      let(:params) do
        {
          course_id: course.id,
          content_type: "Page",
          content_id: wiki_page.id,
          path: "./div/p/img"
        }
      end

      it "generates alt text for the image" do
        allow(Attachment).to receive(:find_by).with(id: attachment.id.to_s).and_return(attachment)
        allow(attachment).to receive_messages(grants_right?: true, open: StringIO.new("fake image data"))

        post :create_image_alt_text, params:, format: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "value" => "Generated alt text" })
      end

      it "returns bad_request when user cannot read attachment" do
        allow(Attachment).to receive(:find_by).with(id: attachment.id.to_s).and_return(attachment)
        allow(attachment).to receive(:grants_right?).and_return(false)

        post :create_image_alt_text, params:, format: :json

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["error"]).to eq("Attachment not found")
      end

      it "returns bad_request when image is too large" do
        large_attachment = attachment_model(context: user, size: 11.megabytes, content_type: "image/png")
        wiki_page.update!(body: "<div><p><img src=\"/files/#{large_attachment.id}\" /></p></div>")

        allow(Attachment).to receive(:find_by).with(id: large_attachment.id.to_s).and_return(large_attachment)
        allow(large_attachment).to receive(:grants_right?).and_return(true)

        post :create_image_alt_text, params:, format: :json

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["error"]).to eq("Attachment not found")
      end

      it "returns bad_request when image type is not supported" do
        unsupported_attachment = attachment_model(context: user, size: 1.megabyte, content_type: "application/pdf")
        wiki_page.update!(body: "<div><p><img src=\"/files/#{unsupported_attachment.id}\" /></p></div>")

        allow(Attachment).to receive(:find_by).with(id: unsupported_attachment.id.to_s).and_return(unsupported_attachment)
        allow(unsupported_attachment).to receive(:grants_right?).and_return(true)

        post :create_image_alt_text, params:, format: :json

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["error"]).to eq("Attachment not found")
      end
    end

    context "with external image" do
      let!(:wiki_page) do
        page = course.wiki_pages.build(title: "Test Page", body: "<img src=\"https://example.com/image.png\" />")
        page.updating_user = user
        page.save!
        page
      end

      let(:params) do
        {
          course_id: course.id,
          content_type: "Page",
          content_id: wiki_page.id,
          path: "./img"
        }
      end

      it "returns error when image is not from Canvas" do
        post :create_image_alt_text, params:, format: :json

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["error"]).to eq("Attachment not found")
      end
    end

    context "with missing image" do
      let!(:wiki_page) do
        page = course.wiki_pages.build(title: "Test Page", body: "<div><p><img src=\"/files/999999\" /></p></div>")
        page.updating_user = user
        page.save!
        page
      end

      let(:params) do
        {
          course_id: course.id,
          content_type: "Page",
          content_id: wiki_page.id,
          path: "./div/p/img"
        }
      end

      it "returns bad_request when attachment does not exist" do
        post :create_image_alt_text, params:, format: :json

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["error"]).to eq("Attachment not found")
      end
    end

    context "with invalid parameters" do
      let(:params) do
        {
          course_id: course.id,
          content_type: "",
          content_id: "",
          path: ""
        }
      end

      it "returns bad_request for missing parameters" do
        post :create_image_alt_text, params:, format: :json

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["error"]).to eq("Attachment not found")
      end
    end
  end

  describe "#check_authorized_action" do
    let!(:course) { Course.create! }
    let!(:user) { User.create! }

    before do
      controller.instance_variable_set(:@context, course)
      controller.instance_variable_set(:@current_user, user)
      allow(controller).to receive(:authorized_action).and_return(true)
      allow(course).to receive(:a11y_checker_enabled?).and_return(true)
    end

    it "renders forbidden if a11y_checker_enabled is not enabled" do
      allow(course).to receive(:a11y_checker_enabled?).and_return(false)

      expect(controller).to receive(:render).with(status: :forbidden)

      controller.send(:check_authorized_action)
    end

    it "calls authorized_action if a11y checker is enabled" do
      expect(controller).to receive(:authorized_action).with(course, user, [:read, :update]).and_return(true)

      controller.send(:check_authorized_action)
    end
  end

  describe "#check_table_caption_feature" do
    it "renders forbidden if table caption feature flag is disabled" do
      Account.site_admin.disable_feature!(:a11y_checker_ai_table_caption_generation)

      expect(controller).to receive(:render).with(status: :forbidden)

      controller.send(:check_table_caption_feature)
    end

    it "does not render forbidden if table caption feature flag is enabled" do
      Account.site_admin.enable_feature!(:a11y_checker_ai_table_caption_generation)

      expect(controller).not_to receive(:render)

      controller.send(:check_table_caption_feature)
    end
  end

  describe "#check_alt_text_feature" do
    it "renders forbidden if alt text feature flag is disabled" do
      Account.site_admin.disable_feature!(:a11y_checker_ai_alt_text_generation)

      expect(controller).to receive(:render).with(status: :forbidden)

      controller.send(:check_alt_text_feature)
    end

    it "does not render forbidden if alt text feature flag is enabled" do
      Account.site_admin.enable_feature!(:a11y_checker_ai_alt_text_generation)

      expect(controller).not_to receive(:render)

      controller.send(:check_alt_text_feature)
    end
  end
end
