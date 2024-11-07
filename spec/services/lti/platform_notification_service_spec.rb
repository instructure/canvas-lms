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
require_relative "../../spec_helper"

describe Lti::PlatformNotificationService do
  let(:developer_key) { DeveloperKey.create! }
  let(:tool) do
    ContextExternalTool.create!(
      context: Account.default,
      consumer_key: "key",
      shared_secret: "secret",
      name: "test tool",
      url: "http://www.tool.com/launch",
      developer_key:,
      lti_version: "1.3",
      root_account: Account.default
    )
  end

  before do
    @valid_notice_type = "LtiHelloWorldNotice"
    @invalid_notice_type = "InvalidNoticeType"
    @valid_handler_url = tool.url + "/handler"
    @invalid_handler_url = "invalid_url"
  end

  describe "subscribe_tool_for_notice" do
    context "with valid parameters" do
      it "creates a new notice handler" do
        expect do
          Lti::PlatformNotificationService.subscribe_tool_for_notice(
            tool:,
            notice_type: @valid_notice_type,
            handler_url: @valid_handler_url
          )
        end.to change { Lti::NoticeHandler.count }.by(1)
      end

      it "returns API JSON of the created notice handler" do
        handler = Lti::PlatformNotificationService.subscribe_tool_for_notice(
          tool:,
          notice_type: @valid_notice_type,
          handler_url: @valid_handler_url
        )
        expect(handler).to eq({ notice_type: @valid_notice_type, handler: @valid_handler_url })
      end
    end

    context "with invalid notice_type" do
      it "raises an ArgumentError" do
        expect do
          Lti::PlatformNotificationService.subscribe_tool_for_notice(
            tool:,
            notice_type: @invalid_notice_type,
            handler_url: @valid_handler_url
          )
        end.to raise_error(ArgumentError, "unknown notice_type, it must be one of [#{Lti::PlatformNotificationService::NOTICE_TYPES.join(", ")}]")
      end
    end

    context "with invalid handler_url" do
      it "raises an ArgumentError" do
        expect do
          Lti::PlatformNotificationService.subscribe_tool_for_notice(
            tool:,
            notice_type: @valid_notice_type,
            handler_url: @invalid_handler_url
          )
        end.to raise_error(ArgumentError, "handler must be a valid URL or an empty string")
      end
    end

    context "with handler_url does not match tool's host" do
      it "raises an ArgumentError" do
        expect do
          Lti::PlatformNotificationService.subscribe_tool_for_notice(
            tool:,
            notice_type: @valid_notice_type,
            handler_url: "http://www.invalid.com/handler"
          )
        end.to raise_error(ArgumentError, "handler url should match tool's domain")
      end
    end
  end

  describe "unsubscribe_tool_for_notice" do
    context "with valid parameters" do
      before do
        Lti::NoticeHandler.create!(
          context_external_tool_id: tool.id,
          notice_type: @valid_notice_type,
          url: @valid_handler_url,
          root_account: tool.root_account,
          account: tool.account
        )
      end

      it "removes the notice handler" do
        expect do
          Lti::PlatformNotificationService.unsubscribe_tool_for_notice(
            tool:,
            notice_type: @valid_notice_type
          )
        end.to change { Lti::NoticeHandler.active.count }.by(-1)
      end

      it "returns an empty api json" do
        expect(Lti::PlatformNotificationService.unsubscribe_tool_for_notice(
                 tool:,
                 notice_type: @valid_notice_type
               )).to eq({ notice_type: @valid_notice_type, handler: "" })
      end
    end

    context "with invalid notice_type" do
      it "raises an ArgumentError" do
        expect do
          Lti::PlatformNotificationService.unsubscribe_tool_for_notice(
            tool:,
            notice_type: @invalid_notice_type
          )
        end.to raise_error(ArgumentError, "unknown notice_type, it must be one of [#{Lti::PlatformNotificationService::NOTICE_TYPES.join(", ")}]")
      end
    end
  end
end
