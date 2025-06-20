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

RSpec.describe Lti::Pns::NoticeBuilder do
  let(:tool) do
    ContextExternalTool.new(
      name: "Test Tool",
      url: "https://www.test.tool.com",
      consumer_key: "key",
      shared_secret: "secret",
      settings: { "platform" => "canvas" },
      account: Account.default
    )
  end
  let(:notice_builder) { described_class.new }

  describe "#build" do
    it "sets the tool and returns a signed JWT" do
      allow(SecureRandom).to receive(:uuid).and_return("uuid")
      allow(notice_builder).to receive_messages(notice_type: "type",
                                                notice_event_timestamp: "timestamp",
                                                custom_claims: {
                                                  custom_claims: "custom_claims"
                                                },
                                                user: nil)
      allow(Lti::Messages::PnsNotice).to receive_message_chain(:new, :generate_post_payload_message, :to_h)
        .and_return({
                      default_claims: "default_claims"
                    })
      allow(LtiAdvantage::Messages::JwtMessage).to receive(:create_jws)
        .with({
                custom_claims: "custom_claims",
                default_claims: "default_claims"
              },
              Lti::KeyStorage.present_key)
        .and_return("signed_jwt")

      result = notice_builder.build(tool)

      expect(result).to eq({ jwt: "signed_jwt" })
    end
  end

  describe "#default_claims" do
    it "generates default claims" do
      allow(notice_builder).to receive_messages(notice_claim: {
                                                  type: "type",
                                                  id: "uuid",
                                                  notice: "notice"
                                                },
                                                user: nil)
      allow(Lti::Messages::PnsNotice).to receive_message_chain(:new, :generate_post_payload_message, :to_h).and_return("default_claims")
      expect(notice_builder.send(:default_claims, tool)).to eq("default_claims")
      expect(Lti::Messages::PnsNotice).to have_received(:new).with({
                                                                     tool:,
                                                                     context: Account.default,
                                                                     notice: {
                                                                       type: "type",
                                                                       id: "uuid",
                                                                       notice: "notice"
                                                                     },
                                                                     opts: nil,
                                                                     user: nil,
                                                                     expander: instance_of(Lti::VariableExpander)
                                                                   })
    end
  end

  describe "#sign_jwt" do
    it "creates a signed JWT" do
      allow(LtiAdvantage::Messages::JwtMessage).to receive(:create_jws).and_return("signed_jwt")

      result = notice_builder.send(:sign_jwt, {})

      expect(result).to eq("signed_jwt")
    end
  end

  describe "#notice_claim" do
    it "generates a notice claim" do
      allow(SecureRandom).to receive(:uuid).and_return("uuid")
      allow(notice_builder).to receive_messages(notice_type: "type", notice_event_timestamp: "timestamp")

      result = notice_builder.send(:notice_claim)

      expect(result).to eq({
                             type: "type",
                             id: "uuid",
                             timestamp: "timestamp"
                           })
    end
  end
end
