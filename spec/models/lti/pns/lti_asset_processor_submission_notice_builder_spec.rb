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

RSpec.describe Lti::Pns::LtiAssetProcessorSubmissionNoticeBuilder, type: :model do
  let(:developer_key) do
    dk = DeveloperKey.new(
      scopes: ["https://purl.imsglobal.org/spec/lti/scope/noticehandlers"],
      account: Account.default
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
      account: Account.default,
      developer_key:,
      root_account: Account.default
    )
  end
  let(:iso_timestamp) { Time.now.utc.iso8601 }
  let(:activity_id) { "activity_id" }
  let(:for_user_id) { "for_user_id" }
  let(:notice_event_timestamp) { iso_timestamp }
  let(:param_hash) do
    {
      activity_id:,
      for_user_id:,
      notice_event_timestamp:,
      assets: [{
        title: "title",
        size: "size",
        asset_id: 333,
        url: "url",
        sha256_checksum: 555,
        timestamp: 23,
        content_type: "text"
      }]
    }
  end

  describe "#initialize" do
    context "when activity_id is missing" do
      let(:activity_id) { nil }

      it "raises an error" do
        expect { described_class.new(param_hash) }.to raise_error(ArgumentError)
      end
    end

    context "when for_user_id is missing" do
      let(:for_user_id) { nil }

      it "raises an error" do
        expect { described_class.new(param_hash) }.to raise_error(ArgumentError)
      end
    end

    context "when notice_event_timestamp is missing" do
      let(:notice_event_timestamp) { nil }

      it "raises an error" do
        expect { described_class.new(param_hash) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#build" do
    let(:notice_builder) { described_class.new(param_hash) }
    let(:now) { Time.zone.now }

    it "builds a valid submission notice" do
      allow(SecureRandom).to receive(:uuid).and_return("random_uuid")
      allow(Time.zone).to receive(:now).and_return(now)
      allow(LtiAdvantage::Messages::JwtMessage).to receive(:create_jws).and_return("signed_jwt")
      allow(Rails.application.routes.url_helpers).to receive(:lti_notice_handlers_url).and_return("https://example.com/notice_handler")
      notice_message = notice_builder.build(tool)

      expect(notice_message).to eq({ jwt: "signed_jwt" })
      expect(LtiAdvantage::Messages::JwtMessage).to have_received(:create_jws).with(
        {
          "aud" => developer_key.global_id.to_s,
          "azp" => developer_key.global_id.to_s,
          "exp" => now.to_i + 3600,
          "https://purl.imsglobal.org/spec/lti/claim/activity" => { id: "activity_id" },
          "https://purl.imsglobal.org/spec/lti/claim/assetservice" =>
          {
            assets: [{
              asset_id: 333,
              content_type: "text",
              sha256_checksum: 555,
              size: "size",
              timestamp: 23,
              title: "title",
              url: "url"
            }],
            scope: ["https://purl.imsglobal.org/spec/lti-ap/scope/asset.readonly"]
          },
          "https://purl.imsglobal.org/spec/lti/claim/custom" => {},
          "https://purl.imsglobal.org/spec/lti/claim/context" => {
            "id" => Account.default.lti_context_id,
            "title" => Account.default.name,
            "type" => ["Account"]
          },
          "https://purl.imsglobal.org/spec/lti/claim/deployment_id" => tool.deployment_id.to_s,
          "https://purl.imsglobal.org/spec/lti/claim/for_user" => { user_id: "for_user_id" },
          "https://purl.imsglobal.org/spec/lti/claim/notice" => {
            "id" => "random_uuid",
            "timestamp" => iso_timestamp,
            "type" => "LtiAssetProcessorSubmissionNotice"
          },
          "https://purl.imsglobal.org/spec/lti/claim/platformnotificationservice" =>
          {
            "notice_types_supported" =>
              Lti::Pns::NoticeTypes::ALL,
            "platform_notification_service_url" => "https://example.com/notice_handler",
            "scope" => ["https://purl.imsglobal.org/spec/lti/scope/noticehandlers"],
            "service_versions" => ["1.0"]
          },
          "https://purl.imsglobal.org/spec/lti/claim/version" => "1.3.0",
          "iat" => now.to_i,
          "iss" => "https://canvas.instructure.com",
          "nonce" => "random_uuid",
          "https://purl.imsglobal.org/spec/lti/claim/roles" => ["http://purl.imsglobal.org/vocab/lis/v2/system/person#None"],
          "https://purl.imsglobal.org/spec/lti/claim/target_link_uri" => "https://www.test.tool.com",
        },
        anything
      )
    end
  end
end
