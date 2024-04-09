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

require "apis/api_spec_helper"
require_relative "../controllers/lti/ims/concerns/advantage_services_shared_context"

module Lti::IMS
  RSpec.describe ScoresController do
    include_context "advantage services context"

    let(:test_request_host) { "www.example.com" }
    let(:context) { course }
    let(:assignment) do
      opts = { course: }
      if tool.present? && tool.use_1_3?
        opts[:submission_types] = "external_tool"
        opts[:external_tool_tag_attributes] = {
          url: tool.url, content_type: "context_external_tool", content_id: tool.id
        }
      end
      assignment_model(opts)
    end
    let(:line_item) do
      if assignment.external_tool? && tool.use_1_3?
        assignment.line_items.first
      else
        line_item_model(course:)
      end
    end
    let(:user) { student_in_course(course:, active_all: true).user }
    let(:line_item_id) { line_item.id }
    let(:result) do
      lti_result_model line_item:, user:, scoreGiven: nil, scoreMaximum: nil
    end
    let(:submission) { nil }
    let(:access_token_scopes) { "https://purl.imsglobal.org/spec/lti-ags/scope/score" }
    let(:userId) { user.id }
    let(:line_item_params) do
      {
        course_id: context_id,
        line_item_id:,
        userId:,
        activityProgress: "Completed",
        gradingProgress: "FullyGraded",
        timestamp: Time.zone.now.iso8601(3)
      }
    end

    describe "#create" do
      let(:headers) do
        headers = {}
        headers["Authorization"] = "Bearer #{access_token_jwt}" if access_token_jwt
        headers["Content-Type"] = "application/json"
        headers
      end
      let(:content_items) do
        [
          {
            type: "file",
            url: "https://getsamplefiles.com/download/txt/sample-1.txt",
            title: "sample1.txt",
            media_type: "text/html" # different than the mime type from extension
          },
          {
            type: "not",
            url: "https://getsamplefiles.com/download/txt/sample-1.txt",
            title: "notAFile.txt"
          }
        ]
      end

      before do
        allow(CanvasHttp).to receive(:get).with("https://getsamplefiles.com/download/txt/sample-1.txt").and_return("sample data")
      end

      def post_instfs_progress(url, params)
        jwt = CGI.parse(URI(url).query)["token"].first
        jwt_params = Canvas::Security.decode_jwt(jwt, ["jwt signing key"])
        form_data = params[:form_data]
        instfs_params = { name: form_data[:filename], instfs_uuid: 1, content_type: form_data[:content_type], token: @token }
        file_params = jwt_params[:capture_params].merge(instfs_params)

        post "/api/v1/files/capture", params: file_params
        run_jobs
      end

      context "when line_item is an assignment and instfs is enabled" do
        let(:folder) { Folder.create!(name: "test", context: user) }
        let(:progress) { Progress.create!(context: assignment, user:, tag: :upload_via_url) }
        let(:submitted_at) { 5.minutes.ago.iso8601(3) }

        before do
          allow(InstFS).to receive_messages(enabled?: true, jwt_secrets: ["jwt signing key"])
          @token = Canvas::Security.create_jwt({}, nil, InstFS.jwt_secret)
          Account.root_accounts.first.enable_feature! :ags_scores_multiple_files
        end

        it "creates a new submission" do
          submission_body = { submitted_at: 1.hour.ago, submission_type: "external_tool" }
          attempt = result.submission.assignment.submit_homework(user, submission_body).attempt
          expect(result.submission.attachments.count).to eq 0

          line_item_params[Lti::Result::AGS_EXT_SUBMISSION] = { content_items:, submitted_at: }
          upload_url = nil
          upload_params = nil
          # get params sent to instfs for easier mocking of the instfs return request
          expect(CanvasHttp).to receive(:post) do |*args|
            upload_url, upload_params, _ = args
            double(class: Net::HTTPCreated, code: 201, body: {})
          end
          post("/api/lti/courses/#{context.id}/line_items/#{line_item_id}/scores", params: line_item_params.to_json, headers:)
          # instfs return url posting
          post_instfs_progress(upload_url, upload_params)

          expect(result.submission.reload.attempt).to eq attempt + 1
          expect(result.submission.attachments.count).to eq 1
          expect(result.submission.submitted_at).to eq submitted_at
          attachment = result.submission.attachments.first
          expect(attachment.display_name).to eq content_items.first[:title]
          expect(attachment.content_type).to eq content_items.first[:media_type]
        end
      end

      context "when submitting after a previous submission" do
        it "submits a file, and then can submit something else" do
          expect(result.submission.attachments.count).to eq 0
          line_item_params[Lti::Result::AGS_EXT_SUBMISSION] = { content_items: }

          post("/api/lti/courses/#{context.id}/line_items/#{line_item_id}/scores", params: line_item_params.to_json, headers:)
          run_jobs
          expect(result.reload.submission.attachments.count).to eq 1

          line_item_params[Lti::Result::AGS_EXT_SUBMISSION] = { submission_type: "external_tool" }
          post("/api/lti/courses/#{context.id}/line_items/#{line_item_id}/scores", params: line_item_params.to_json, headers:)
          run_jobs
          expect(result.reload.submission.attachments.count).to eq 0
        end
      end
    end
  end
end
