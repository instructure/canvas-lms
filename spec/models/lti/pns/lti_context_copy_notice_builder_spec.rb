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
#

require_relative "../../../spec_helper"

RSpec.describe Lti::Pns::LtiContextCopyNoticeBuilder do
  let(:account) { account_model }
  let(:developer_key) do
    dk = DeveloperKey.new(
      scopes: ["https://purl.imsglobal.org/spec/lti/scope/noticehandlers"],
      account:
    )
    dk.save!
    dk
  end
  let(:tool) do
    ContextExternalTool.new(
      name: "Test Tool",
      url: "https://www.test.tool.com",
      consumer_key: "key",
      shared_secret: "secret",
      settings: { "platform" => "canvas" },
      account:,
      developer_key:,
      root_account: account
    )
  end

  let(:params) do
    {
      course:,
      source_course:,
      copied_at:
    }
  end
  let(:course) { course_model(account:) }
  let(:source_course) { course_model(account:) }
  let(:copied_at) { Time.now.utc.iso8601 }

  describe "#initialize" do
    it "raises an error if course is missing" do
      expect { described_class.new(params.except(:course)) }.to raise_error(ArgumentError, "Missing required parameter: course")
    end

    it "raises an error if copied_at is missing" do
      expect { described_class.new(params.except(:copied_at)) }.to raise_error(ArgumentError, "Missing required parameter: copied_at")
    end
  end

  describe "#build" do
    subject { described_class.new(params).build(tool) }

    before do
      allow(LtiAdvantage::Messages::JwtMessage).to receive(:create_jws).and_return("signed_jwt")
      allow(Rails.application.routes.url_helpers).to receive(:lti_notice_handlers_url).and_return("https://example.com/notice_handler")
    end

    it "returns a notice" do
      Timecop.freeze do
        expect(subject).to eq({ jwt: "signed_jwt" })
        expect(LtiAdvantage::Messages::JwtMessage).to have_received(:create_jws).with(
          {
            "aud" => developer_key.global_id.to_s,
            "azp" => developer_key.global_id.to_s,
            "exp" => Time.zone.now.to_i + 3600,
            "iat" => Time.zone.now.to_i,
            "iss" => "https://canvas.instructure.com",
            "nonce" => anything,
            "https://purl.imsglobal.org/spec/lti/claim/deployment_id" => tool.deployment_id.to_s,
            "https://purl.imsglobal.org/spec/lti/claim/context" =>
            {
              id: course.lti_context_id,
              label: course.course_code,
              title: course.name,
              type: ["http://purl.imsglobal.org/vocab/lis/v2/course#CourseOffering"]
            },
            "https://purl.imsglobal.org/spec/lti/claim/notice" =>
            {
              "id" => anything,
              "timestamp" => copied_at,
              "type" => "LtiContextCopyNotice"
            },
            "https://purl.imsglobal.org/spec/lti/claim/origin_contexts" => [source_course.lti_context_id],
            "https://purl.imsglobal.org/spec/lti/claim/version" => "1.3.0",
          },
          anything
        )
      end
    end

    context "when source_course is absent" do
      let(:params) { { course:, copied_at: } }

      it "does not include origin_contexts" do
        subject
        expect(LtiAdvantage::Messages::JwtMessage).to have_received(:create_jws).with(
          hash_excluding("https://purl.imsglobal.org/spec/lti/claim/origin_contexts"),
          anything
        )
      end
    end
  end
end
