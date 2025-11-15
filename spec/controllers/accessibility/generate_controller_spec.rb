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
  describe "#create" do
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
      Account.site_admin.enable_feature!(:a11y_checker_ai_generation)
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

        post :create, params:, format: :json
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

        post :create, params:, format: :json
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

        post :create, params:, format: :json
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
        post :create, params:, format: :json

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

        post :create, params:, format: :json
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

    it "renders unauthorized if a11y_checker_enabled is not enabled" do
      allow(course).to receive(:a11y_checker_enabled?).and_return(false)

      expect(controller).to receive(:render_unauthorized_action)

      controller.send(:check_authorized_action)
    end

    it "renders unauthorized if AI generation feature flag is disabled" do
      Account.site_admin.disable_feature!(:a11y_checker_ai_generation)

      expect(controller).to receive(:render_unauthorized_action)

      controller.send(:check_authorized_action)
    end

    it "calls authorized_action if a11y checker and ai generation is enabled" do
      Account.site_admin.enable_feature!(:a11y_checker_ai_generation)

      expect(controller).to receive(:authorized_action).with(course, user, [:read, :update]).and_return(true)

      controller.send(:check_authorized_action)
    end
  end
end
