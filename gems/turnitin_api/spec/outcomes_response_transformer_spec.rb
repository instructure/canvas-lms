# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe TurnitinApi::OutcomesResponseTransformer do
  subject { described_class.new(oauth_key, oauth_secret, lti_params, outcomes_response_json) }

  let(:oauth_key) { "key" }
  let(:oauth_secret) { "secret" }
  let(:lti_params) { { lti_verions: "1p0" } }
  let(:outcomes_response_json) do
    {
      "lis_result_sourcedid" => "6",
      "paperid" => "7",
      "outcomes_tool_placement_url" => "http://turnitin.com/api/lti/1p0/outcome_tool_data/4321"
    }
  end

  describe "initialize" do
    it "initializes properly" do
      expect(subject.key).to eq oauth_key
      expect(subject.lti_params).to eq lti_params
      expect(subject.outcomes_response_json).to eq outcomes_response_json
    end
  end

  describe "response" do
    let(:stubbed_response) do
      {
        status: 200,
        body: fixture("outcome_detailed_response.json"),
        headers: { "Content-Type" => "application/json" }
      }
    end

    before do
      stub_request(:post, "http://turnitin.com/api/lti/1p0/outcome_tool_data/4321")
        .to_return(stubbed_response)
    end

    it "returns expected json response" do
      expect(subject.response.body["outcome_originalfile"]["launch_url"]).to eq "https://turnitin.com/api/lti/1p0/dow...72874634?lang="
    end

    context "when TII returns a non-2xx response" do
      let(:stubbed_body) { "TII errored out oh no " * 10 }
      let(:stubbed_response) { { status: 403, body: stubbed_body } }
      let(:truncated_body) { stubbed_body.truncate(100).inspect }

      it "raises an InvalidResponse error with the status code and content length" do
        expect { subject.response }.to raise_error(
          described_class::InvalidResponse,
          "TII returned 403 code, content length=#{stubbed_body.length}, message unknown, body #{truncated_body}"
        )
      end

      it "increments a statsd counter which includes the status code" do
        allow(InstStatsd::Statsd).to receive(:increment)
        expect { subject.response }.to raise_error(described_class::InvalidResponse)
        expect(InstStatsd::Statsd).to have_received(:increment).with(
          "lti.tii.outcomes_response_bad",
          tags: { status: 403, message: :unknown }
        )
      end

      context "when the response body is one of the known recognized ones" do
        let(:stubbed_body) { "bla bla API product inactive or expired bla bla" }
        let(:stubbed_response) { { status: 401, body: stubbed_body } }

        it "identifies known responses in the InvalidResponse error" do
          expect { subject.response }.to raise_error(
            described_class::InvalidResponse,
            "TII returned 401 code, content length=47, message api_product_inactive, body #{truncated_body}"
          )
        end

        it "identifies known responses in the statsd counter" do
          allow(InstStatsd::Statsd).to receive(:increment)
          expect { subject.response }.to raise_error(described_class::InvalidResponse)
          expect(InstStatsd::Statsd).to have_received(:increment).with(
            "lti.tii.outcomes_response_bad",
            tags: { status: 401, message: :api_product_inactive }
          )
        end
      end
    end
  end

  describe "original_submission" do
    before do
      stub_request(:post, "http://turnitin.com/api/lti/1p0/outcome_tool_data/4321")
        .to_return(status: 200, body: fixture("outcome_detailed_response.json"), headers: { "Content-Type" => "application/json" })

      stub_request(:post, "https://turnitin.com/api/lti/1p0/dow...72874634?lang=")
        .to_return(status: 200, body: "I am an awesome text file", headers: { "Content-Type" => "text/plain", "Content-Disposition" => 'attachment; filename="myfile.txt"' })
    end

    it "returns a File" do
      subject.original_submission do |response|
        expect(response.body).to eq "I am an awesome text file"
      end
    end
  end

  describe "originality report" do
    before do
      stub_request(:post, "http://turnitin.com/api/lti/1p0/outcome_tool_data/4321")
        .to_return(status: 200, body: fixture("outcome_detailed_response.json"), headers: { "Content-Type" => "application/json" })
    end

    it "returns a url" do
      expect(subject.originality_report_url).to eq "https://turnitin.com/api/lti/1p0/dv/...72874634?lang="
    end
  end

  describe "originality data" do
    before do
      stub_request(:post, "http://turnitin.com/api/lti/1p0/outcome_tool_data/4321")
        .to_return(status: 200, body: fixture("outcome_detailed_response.json"), headers: { "Content-Type" => "application/json" })
    end

    it "returns proper keys" do
      expect(subject.originality_data["breakdown"]).to_not be_nil
      expect(subject.originality_data["numeric"]).to_not be_nil
    end

    it "breakdown is set correctly" do
      expect(subject.originality_data["breakdown"]["submitted_works_score"]).to eq 100
      expect(subject.originality_data["breakdown"]["publications_score"]).to eq 0
      expect(subject.originality_data["breakdown"]["internet_score"]).to eq 0
    end

    it "numeric is set correctly" do
      expect(subject.originality_data["numeric"]["max"]).to eq 100
      expect(subject.originality_data["numeric"]["score"]).to eq 100
    end

    it "returns uploaded_at" do
      expect(subject.uploaded_at).to eq "2015-10-24T19:48:40Z"
    end
  end
end
