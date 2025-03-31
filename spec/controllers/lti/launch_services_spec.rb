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
#

describe Lti::LaunchServices do
  subject { dummy_class.new }

  let(:dummy_class) do
    Class.new do
      include Lti::LaunchServices
    end
  end

  describe "#context" do
    it "raises an error when not implemented" do
      expect { subject.context }.to raise_error("Abstract Method")
    end
  end

  describe "#tool" do
    it "raises an error when not implemented" do
      expect { subject.tool }.to raise_error("Abstract Method")
    end
  end

  describe "#build_jwt_message" do
    let(:adapter) { double("LtiAdapter") }

    context "when message_type is AssetProcessorSettingsRequest" do
      it "calls generate_post_payload_for_asset_processor_settings on the adapter" do
        allow(adapter).to receive(:generate_post_payload_for_asset_processor_settings)
        subject.build_jwt_message(adapter, LtiAdvantage::Messages::AssetProcessorSettingsRequest::MESSAGE_TYPE)
        expect(adapter).to have_received(:generate_post_payload_for_asset_processor_settings)
      end
    end

    context "when message_type is ReportReviewRequest" do
      it "calls generate_post_payload_for_report_review on the adapter" do
        allow(adapter).to receive(:generate_post_payload_for_report_review)
        subject.build_jwt_message(adapter, LtiAdvantage::Messages::ReportReviewRequest::MESSAGE_TYPE)
        expect(adapter).to have_received(:generate_post_payload_for_report_review)
      end
    end

    context "when message_type is EulaRequest" do
      it "calls generate_post_payload_for_eula on the adapter" do
        allow(adapter).to receive(:generate_post_payload_for_eula)
        subject.build_jwt_message(adapter, LtiAdvantage::Messages::EulaRequest::MESSAGE_TYPE)
        expect(adapter).to have_received(:generate_post_payload_for_eula)
      end
    end

    context "when message_type is unsupported" do
      it "raises an error" do
        expect do
          subject.build_jwt_message(adapter, "unsupported_message_type")
        end.to raise_error("Unsupported message type: unsupported_message_type")
      end
    end
  end
end
