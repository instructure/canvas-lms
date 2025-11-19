# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../../spec_helper"

describe OutcomesService::Service do
  let(:root_account) { account_model }
  let(:course) { course_model(root_account:) }

  context "without settings" do
    describe ".url" do
      it "returns nil url" do
        expect(described_class.url(course)).to be_nil
      end
    end

    describe ".enabled_in_context?" do
      it "returns not enabled" do
        expect(described_class.enabled_in_context?(course)).to be false
      end
    end

    describe ".jwt" do
      it "returns nil jwt" do
        expect(described_class.jwt(course, "outcomes.show")).to be_nil
      end
    end
  end

  context "with settings" do
    before do
      root_account.settings[:provision] = { "outcomes" => {
        domain: "canvas.test",
        beta_domain: "canvas.beta",
        consumer_key: "blah",
        jwt_secret: "woo"
      } }
      root_account.save!
    end

    describe ".url" do
      it "returns url" do
        expect(described_class.url(course)).to eq "http://canvas.test"
      end

      describe "if ApplicationController.test_cluster_name is specified" do
        it "returns a url using the test_cluster_name domain" do
          allow(ApplicationController).to receive(:test_cluster?).and_return(true)
          allow(ApplicationController).to receive(:test_cluster_name).and_return("beta")
          expect(described_class.url(course)).to eq "http://canvas.beta"
          allow(ApplicationController).to receive(:test_cluster_name).and_return("invalid")
          expect(described_class.url(course)).to be_nil
        end
      end
    end

    describe ".enabled_in_context?" do
      it "returns enabled" do
        expect(described_class.enabled_in_context?(course)).to be true
      end
    end

    describe ".jwt" do
      it "returns valid jwt" do
        expect(described_class.jwt(course, "outcomes.show")).not_to be_nil
      end

      it "includes overrides" do
        token = described_class.jwt(course, "outcomes.list", overrides: { context_uuid: "xyz" })
        decoded = JWT.decode(token, "woo", true, algorithm: "HS512")
        expect(decoded[0]).to include(
          "host" => "canvas.test",
          "consumer_key" => "blah",
          "scope" => "outcomes.list",
          "context_uuid" => "xyz"
        )
      end
    end

    describe ".toggle_feature_flag" do
      def expect_post(url)
        expect(CanvasHttp).to receive(:post).with(
          url,
          hash_including("Authorization"),
          form_data: {
            feature_flag: "fake_flag"
          }
        )
      end

      it "enables feature flag" do
        expect_post("http://canvas.test/api/features/enable")
        described_class.toggle_feature_flag(root_account, "fake_flag", true)
      end

      it "disables feature flag" do
        expect_post("http://canvas.test/api/features/disable")
        described_class.toggle_feature_flag(root_account, "fake_flag", false)
      end
    end

    describe ".start_outcome_alignment_service_clone" do
      let(:response_body) { { "job_id" => "123", "status" => "started" }.to_json }
      let(:successful_response) { double(code: "200", body: response_body) }
      let(:accepted_response) { double(code: "202", body: response_body) }
      let(:error_response) { double(code: "500", body: "Internal Server Error") }

      context "when service is enabled" do
        it "makes POST request to /api/alignment_sets/batch_clone with correct parameters" do
          expect(CanvasHttp).to receive(:post).with(
            "http://canvas.test/api/alignment_sets/batch_clone",
            hash_including("Authorization"),
            body: {
              original_assignment_id: 456,
              copied_assignment_id: 789,
              new_context_id: 101,
              original_context_id: 112
            }.to_json,
            content_type: "application/json"
          ).and_return(successful_response)

          result = described_class.start_outcome_alignment_service_clone(
            course,
            original_assignment_id: 456,
            copied_assignment_id: 789,
            new_context_id: 101,
            original_context_id: 112
          )

          expect(result).to eq(JSON.parse(response_body))
        end

        it "uses correct JWT scope for authentication" do
          expect(described_class).to receive(:headers_for).with(course, "outcome_alignment_sets.batch_clone", hash_including(:original_assignment_id, :copied_assignment_id, :new_context_id, :original_context_id))
                                                          .and_return({ "Authorization" => "Bearer fake_jwt" })
          allow(CanvasHttp).to receive(:post).and_return(successful_response)

          described_class.start_outcome_alignment_service_clone(
            course,
            original_assignment_id: 456,
            copied_assignment_id: 789,
            new_context_id: 101,
            original_context_id: 112
          )
        end

        it "returns parsed JSON response on 200 status" do
          allow(CanvasHttp).to receive(:post).and_return(successful_response)

          result = described_class.start_outcome_alignment_service_clone(
            course,
            original_assignment_id: 456,
            copied_assignment_id: 789,
            new_context_id: 101,
            original_context_id: 112
          )

          expect(result).to eq({ "job_id" => "123", "status" => "started" })
        end

        it "returns parsed JSON response on 202 status" do
          allow(CanvasHttp).to receive(:post).and_return(accepted_response)

          result = described_class.start_outcome_alignment_service_clone(
            course,
            original_assignment_id: 456,
            copied_assignment_id: 789,
            new_context_id: 101,
            original_context_id: 112
          )

          expect(result).to eq({ "job_id" => "123", "status" => "started" })
        end

        it "captures error and returns nil on non-success response" do
          allow(CanvasHttp).to receive(:post).and_return(error_response)
          expect(Canvas::Errors).to receive(:capture).with(
            "Unexpected response from Outcomes Service batch clone alignment sets",
            hash_including(
              status_code: "500",
              body: "Internal Server Error",
              payload: {
                original_assignment_id: 456,
                copied_assignment_id: 789,
                new_context_id: 101,
                original_context_id: 112
              }
            )
          )

          result = described_class.start_outcome_alignment_service_clone(
            course,
            original_assignment_id: 456,
            copied_assignment_id: 789,
            new_context_id: 101,
            original_context_id: 112
          )

          expect(result).to be_nil
        end

        it "handles empty response body gracefully" do
          empty_response = double(code: "200", body: "")
          allow(CanvasHttp).to receive(:post).and_return(empty_response)

          result = described_class.start_outcome_alignment_service_clone(
            course,
            original_assignment_id: 456,
            copied_assignment_id: 789,
            new_context_id: 101,
            original_context_id: 112
          )

          expect(result).to be_nil
        end
      end

      context "when service is not enabled" do
        before do
          root_account.settings[:provision] = {}
          root_account.save!
        end

        it "returns nil without making HTTP request" do
          expect(CanvasHttp).not_to receive(:post)

          result = described_class.start_outcome_alignment_service_clone(
            course,
            original_assignment_id: 456,
            copied_assignment_id: 789,
            new_context_id: 101,
            original_context_id: 112
          )

          expect(result).to be_nil
        end
      end
    end
  end
end
