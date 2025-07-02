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
  let(:builder) { Lti::Pns::LtiHelloWorldNoticeBuilder.new }

  before do
    # A valid type besides LtiHelloWorldNotice (subscribing to that will try to
    # send a test notice, require public keys/lti_1_3_spec_helper, etc.)
    @valid_notice_type = "LtiAssetProcessorSubmissionNotice"
    @invalid_notice_type = "InvalidNoticeType"
    @valid_handler_url = tool.url + "/handler"
    @invalid_handler_url = "invalid_url"
  end

  describe "subscribe_tool_for_notice" do
    def subscribe!(**overrides)
      Lti::PlatformNotificationService.subscribe_tool_for_notice(
        tool:,
        notice_type: @valid_notice_type,
        handler_url: @valid_handler_url,
        max_batch_size: nil,
        **overrides
      )
    end

    context "with valid parameters" do
      it "creates a new notice handler" do
        expect { subscribe! }.to change { Lti::NoticeHandler.count }.by(1)
      end

      it "returns API JSON of the created notice handler" do
        handler = subscribe!
        expect(handler).to eq({ notice_type: @valid_notice_type, handler: @valid_handler_url })
      end

      it "sends out test notice for hello_world notice_type" do
        expect(Lti::Pns::LtiHelloWorldNoticeBuilder).to receive(:new).and_return(builder)
        expect(builder).to receive(:build).and_return({ jwt: "jwt" })
        expect(Services::NotificationService).to receive(:process).and_return("response")
        handler = subscribe!(notice_type: "LtiHelloWorldNotice")
        expect(handler).to eq({ notice_type: "LtiHelloWorldNotice", handler: @valid_handler_url })
      end

      it "accepts a number for max_batch_size" do
        handler = subscribe!(max_batch_size: 20)
        expect(handler).to eq({ notice_type: @valid_notice_type, handler: @valid_handler_url, max_batch_size: 20 })
      end
    end

    context "with non-integer max_batch_size" do
      it "raises an InvalidNoticeHandler" do
        expect { subscribe!(max_batch_size: "1.4") }.to \
          raise_error(described_class::InvalidNoticeHandler, /max.batch.size must be an integer/i)

        expect { subscribe!(max_batch_size: "foo") }.to \
          raise_error(described_class::InvalidNoticeHandler, /max.batch.size is not a number/i)
      end
    end

    context "with a number below the minimum max_batch_size" do
      it "raises an InvalidNoticeHandler" do
        expect { subscribe!(max_batch_size: Lti::NoticeHandler::MIN_MAX_BATCH_SIZE - 1) }.to \
          raise_error(described_class::InvalidNoticeHandler, /max.batch.size must be greater than or equal to 10/i)
        expect { subscribe!(max_batch_size: 0) }.to \
          raise_error(described_class::InvalidNoticeHandler, /max.batch.size must be greater than or equal to 10/i)
        expect { subscribe!(max_batch_size: -1) }.to \
          raise_error(described_class::InvalidNoticeHandler, /max.batch.size must be greater than or equal to 10/i)
        expect(Lti::NoticeHandler.count).to eq(0)
      end
    end

    context "with invalid notice_type" do
      it "raises an InvalidNoticeHandler" do
        expect { subscribe!(notice_type: @invalid_notice_type) }.to \
          raise_error(described_class::InvalidNoticeHandler, "Validation failed: Notice type unknown, must be one of [#{Lti::Pns::NoticeTypes::ALL.join(", ")}]")
        expect(Lti::NoticeHandler.count).to eq(0)
      end
    end

    context "with invalid handler_url" do
      it "raises an InvalidNoticeHandler" do
        expect { subscribe!(handler_url: @invalid_handler_url) }.to \
          raise_error(described_class::InvalidNoticeHandler, "Validation failed: Url is not a valid URL")
        expect(Lti::NoticeHandler.count).to eq(0)
      end
    end

    context "when handler_url does not match tool's host" do
      it "raises an InvalidNoticeHandler" do
        expect { subscribe!(handler_url: "http://www.invalid.com/handler") }.to \
          raise_error(described_class::InvalidNoticeHandler, "Validation failed: Url should match tool's domain or redirect uri")
        expect(Lti::NoticeHandler.count).to eq(0)
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
      it "raises an InvalidNoticeHandler" do
        expect do
          Lti::PlatformNotificationService.unsubscribe_tool_for_notice(
            tool:,
            notice_type: @invalid_notice_type
          )
        end.to raise_error(described_class::InvalidNoticeHandler, "Validation failed: Notice type unknown, must be one of [#{Lti::Pns::NoticeTypes::ALL.join(", ")}]")
      end
    end
  end

  describe "notify_tools_in_account" do
    let(:builder) { Lti::Pns::LtiHelloWorldNoticeBuilder.new({ custom: 1 }) }
    let(:builder2) { Lti::Pns::LtiHelloWorldNoticeBuilder.new({ custom: 2 }) }

    def make_notice_handler!(**)
      Lti::NoticeHandler.create!(
        context_external_tool_id: tool.id,
        notice_type: "LtiHelloWorldNotice",
        url: @valid_handler_url,
        root_account: tool.root_account,
        account: tool.account,
        **
      )
    end

    it "sends out notification_service webhook requests" do
      make_notice_handler!
      allow(builder).to receive(:build).and_return({ jwt: "jwt" })
      allow(SecureRandom).to receive(:uuid).and_return("uuid")
      expect(Services::NotificationService).to receive(:process).with(
        "pns-notify/uuid",
        '{"notices":[{"jwt":"jwt"}]}',
        "webhook",
        '{"url":"http://www.tool.com/launch/handler"}'
      )
      Lti::PlatformNotificationService.notify_tools_in_account(tool.account, builder)
    end

    it "raises an ArgumentError when builders have different notice_types" do
      allow(builder).to receive(:build).and_return('{"jwt":"jwt"}')
      allow(builder2).to receive_messages(build: '{"jwt":"jwt"}', notice_type: "OtherNoticeType")
      allow(LtiAdvantage::Messages::JwtMessage).to receive(:create_jws).and_return("signed_jwt")
      expect do
        Lti::PlatformNotificationService.notify_tools_in_account(tool.account, builder, builder2)
      end.to raise_error(ArgumentError, "builders must have the same notice_type")
    end

    it "batches notifications according to the max_batch_size of the handler" do
      handler = make_notice_handler!
      handler.max_batch_size = 2
      handler.save!(validate: false)
      builders = (1..5).map do |i|
        builder = Lti::Pns::LtiHelloWorldNoticeBuilder.new({ custom: i })
        allow(builder).to receive(:build).and_return({ jwt: "jwt#{i}" })
        builder
      end
      allow(SecureRandom).to receive(:uuid).and_return("uuid")
      [%w[jwt1 jwt2], %w[jwt3 jwt4], %w[jwt5]].each do |batch|
        expect(Services::NotificationService).to receive(:process).with(
          "pns-notify/uuid",
          { notices: batch.map { |jwt| { jwt: } } }.to_json,
          "webhook",
          { url: "http://www.tool.com/launch/handler" }.to_json
        )
      end
      Lti::PlatformNotificationService.notify_tools_in_account(tool.account, *builders)
    end
  end

  describe "notify_tools_in_course" do
    subject { Lti::PlatformNotificationService.notify_tools_in_course(course, builder) }

    let(:course) { course_model }
    let(:root_account) { course.root_account }
    let(:notice_handler) do
      Lti::NoticeHandler.last
    end
    let(:builder) { Lti::Pns::LtiContextCopyNoticeBuilder.new(course:, copied_at: Time.zone.now) }

    before do
      allow(Lti::PlatformNotificationService).to receive(:send_notices).and_return(true)
      Lti::PlatformNotificationService.subscribe_tool_for_notice(tool:, notice_type: Lti::Pns::NoticeTypes::CONTEXT_COPY, handler_url: "https://example.com/notice", max_batch_size: 10)
    end

    context "with tool installed in root account" do
      let(:tool) { external_tool_1_3_model(context: root_account) }

      it "sends notice to tool" do
        subject
        expect(Lti::PlatformNotificationService).to have_received(:send_notices).with(notice_handler:, builders: anything)
      end
    end

    context "with tool installed in subaccount" do
      let(:course) { course_model(account: subaccount) }
      let(:subaccount) { account_model(parent_account: root_account) }
      let(:root_account) { account_model }
      let(:tool) { external_tool_1_3_model(context: subaccount) }

      it "sends notice to tool" do
        subject
        expect(Lti::PlatformNotificationService).to have_received(:send_notices).with(notice_handler:, builders: anything)
      end
    end

    context "with tool installed in course" do
      let(:tool) { external_tool_1_3_model(context: course) }

      it "sends notice to tool" do
        subject
        expect(Lti::PlatformNotificationService).to have_received(:send_notices).with(notice_handler:, builders: anything)
      end
    end
  end
end
