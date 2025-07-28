# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "concerns/advantage_services_shared_context"
require_relative "concerns/advantage_services_shared_examples"
require_relative "concerns/lti_services_shared_examples"

describe Lti::IMS::AssetProcessorController do
  include_context "advantage services context"

  let(:assignment) { assignment_model(course:) }
  let(:asset) { lti_asset_model(submission: submission_model(assignment:)) }
  let(:asset_processor) { lti_asset_processor_model(tool:, assignment:) }

  describe "#create_report" do
    let(:action) { :create_report }
    let(:request_method) { :post }
    # Some of the shared specs assume `course` is used for the context (e.g. "course attached to another sub-account" spec)

    let(:content_type) { "application/json" }
    let(:body_overrides) do
      {
        assetId: asset.uuid,
        timestamp: 1.hour.ago.utc.iso8601,
        title: "Test asset processor report",
        type: "originality",
        result: "150/300",
        priority: 0,
        processingProgress: Lti::AssetReport::PROGRESS_PROCESSED,
        "https://example.com/foo/extra": { "extra value" => true },
        "https://example.com/foo/extra2": 1,
        visibleToOwner: true,
      }
    end

    let(:params_overrides) { { asset_processor_id: asset_processor.id } }

    let(:expected_mime_type) { "application/json" }
    let(:http_success_status) { :created }

    it_behaves_like "advantage services", skip_mime_type_checks_on_error: true, route_includes_context: false do
      let(:context) { asset_processor.assignment.context }
    end
    it_behaves_like "lti services", skip_mime_type_checks_on_error: true do
      let(:scope_to_remove) { TokenScopes::LTI_ASSET_REPORT_SCOPE }
    end

    def make_extra_report(timestamp)
      lti_asset_report_model(asset:, asset_processor:, timestamp:)
    end

    def expect_successful_creation(**expect_overides)
      expected_values = body_overrides.merge(expect_overides).compact

      expect do
        send_request

        expect(response.parsed_body).to eq(JSON.parse(expected_values.to_json))
        expect(response).to have_http_status(:created)
      end.to change(Lti::AssetReport, :count).by(1)

      report = Lti::AssetReport.last

      expect(report).to have_attributes(expected_values.slice(:title, :priority))
      expect(report.asset).to eq(asset)
      expect(report.timestamp).to be_within(1.second).of(Time.zone.parse(expected_values[:timestamp]))
      expect(report.report_type).to eq(expected_values[:type])
      expect(report.asset_processor).to eq(asset_processor)
      expect(report.result).to eq(expected_values[:result])
      expect(report.processing_progress).to eq(expected_values[:processingProgress])
      expect(report.workflow_state).to eq("active")
      expect(report.extensions).to eq({
                                        "https://example.com/foo/extra" => { "extra value" => true },
                                        "https://example.com/foo/extra2" => 1,
                                      })
      expect(report.visible_to_owner).to eq(expected_values[:visibleToOwner])
    end

    def expect_no_creation(expected_status, expected_error = nil)
      expect do
        send_request
        expect(response).to have_http_status(expected_status)
        if expected_error
          expect(response.body).to match(expected_error)
        end
      end.not_to change(Lti::AssetReport, :count)
    end

    it "creates an Lti::AssetReport" do
      expect_successful_creation
    end

    context "when there is already an older asset report for the same asset, asset processor" do
      it "deletes the old asset report and creates a new one" do
        first_report = make_extra_report(2.hours.ago)
        expect_successful_creation
        expect(first_report.reload.workflow_state).to eq("deleted")
      end
    end

    context "when there is already an same-age (same timestamp) asset report for the same asset, asset processor" do
      it "deletes the old asset report and creates a new one" do
        first_report = make_extra_report(body_overrides[:timestamp])
        expect_successful_creation
        expect(first_report.reload.workflow_state).to eq("deleted")
      end
    end

    context "when there is already an newer asset report for the same asset, asset processor" do
      let(:body_overrides) { super().merge(timestamp: 1.day.ago.utc.iso8601) }

      it "returns a 409 Conflict and does not create a new asset report" do
        first_report = make_extra_report(Time.zone.now)
        expect_no_creation(:conflict, /existing report/)
        expect(first_report.reload.workflow_state).to eq("active")
      end
    end

    context "when an arbitrary string type is given" do
      let(:body_overrides) { super().merge(type: "anything") }

      it { expect_successful_creation }
    end

    context "when visibleToOwner is false" do
      let(:body_overrides) { super().merge(visibleToOwner: false) }

      it { expect_successful_creation }
    end

    context "when no type is given" do
      let(:body_overrides) { super().except(:type) }

      it { expect_no_creation(:bad_request, "type is missing") }
    end

    context "when a non-string type is given" do
      let(:body_overrides) { super().merge(type: { abc: 123 }) }

      it { expect_no_creation(:bad_request, "type must be a non-empty string") }
    end

    context "when an empty string type is given" do
      let(:body_overrides) { super().merge(type: "") }

      it { expect_no_creation(:bad_request, "type is missing") }
    end

    context "when an invalid timestamp is provided" do
      let(:body_overrides) { super().merge(timestamp: "not a timestamp") }

      it { expect_no_creation(:bad_request, /iso8601/i) }
    end

    context "when the asset is not compatible with the asset processor (e.g. mismatched assignments)" do
      let(:asset_processor) { lti_asset_processor_model(tool:) }

      it { expect_no_creation(:bad_request, /invalid asset/i) }
    end

    context "when the developer key used in auth does not own the asset processor in the URL" do
      let(:tool2) do
        external_tool_1_3_model(developer_key: developer_key_model, context: tool.context)
      end
      let(:asset_processor) { lti_asset_processor_model(tool: tool2, assignment:) }

      it { expect_no_creation(:forbidden) }
    end

    context "when the feature flag lti_asset_processor is disabled" do
      before { tool.root_account.disable_feature!(:lti_asset_processor) }

      it { expect_no_creation(:not_found) }
    end

    context "when non-scalar values are provided" do
      let(:body_overrides) { super().merge(result: [1, 2, 3], title: { "foo" => "bar" }) }

      # This is actually done by params.permit(...)
      it "strips them out and returns only the values actually stored to the database" do
        expect_successful_creation(result: nil, title: nil)
      end
    end
  end

  describe "#lti_asset_show" do
    let(:action) { :lti_asset_show }
    let(:request_method) { :get }
    let(:params_overrides) { { asset_processor_id: asset_processor.id, asset_id: asset.uuid } }
    let(:expected_mime_type) { "text/html" }

    it_behaves_like "advantage services", skip_mime_type_checks_on_error: true, route_includes_context: false do
      let(:http_success_status) { :found }
      let(:context) { asset_processor.assignment.context }
    end
    it_behaves_like "lti services", skip_mime_type_checks_on_error: true do
      let(:http_success_status) { :found }
      let(:scope_to_remove) { TokenScopes::LTI_ASSET_READ_ONLY_SCOPE }
    end

    def expect_not_found
      send_request
      expect(response).to have_http_status(:not_found)
    end

    it "redirects to the asset's public download URL" do
      allow(controller).to receive(:render_or_redirect_to_stored_file).and_call_original
      expect(controller).to receive(:render_or_redirect_to_stored_file)
      send_request
      expect(response).to have_http_status(:found)
      expect(response.location).to include("sf_verifier=")
    end

    context "when the asset is not found" do
      let(:params_overrides) { { asset_processor_id: asset_processor.id, asset_id: "non-existent-id" } }

      it { expect_not_found }
    end

    context "when the asset is not compatible with the asset processor" do
      let(:asset_processor) { lti_asset_processor_model(tool:) }

      it "returns a 400 Bad Request" do
        send_request
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to match(/Invalid asset/)
      end
    end

    context "when the feature flag lti_asset_processor is disabled" do
      before { tool.root_account.disable_feature!(:lti_asset_processor) }

      it { expect_not_found }
    end

    context "when the asset is a text entry" do
      let(:text_content) { "This is a test text entry asset." }
      let(:submission) { submission_model(assignment:, body: text_content, submission_type: "online_text_entry") }
      let(:asset) { submission.lti_assets.first }

      it "returns the text entry content as a downloadable file" do
        send_request
        expect(response).to have_http_status(:found).or have_http_status(:ok)
        # Follow redirect if present
        if response.status == 302 && response.location
          follow_redirect!
        end
        expect(response.headers["Content-Type"]).to eq("text/html")
        expect(response.headers["Content-Disposition"]).to eq("attachment")
        expect(response.body).to eq(text_content)
      end
    end
  end
end
