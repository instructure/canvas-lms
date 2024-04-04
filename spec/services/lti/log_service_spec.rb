# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe Lti::LogService do
  let(:service) do
    Lti::LogService.new(tool:, context:, user:, placement:, launch_type:)
  end
  let(:tool) { external_tool_model }
  let(:user) { user_model }
  let(:account) { account_model }
  let(:context) { course_model(root_account: account) }
  let(:placement) { :course_navigation }
  let(:launch_type) { :direct_link }

  describe ".new" do
    context "when context is not valid type" do
      let(:context) { user_model }

      it "raises an ArgumentError" do
        expect { service }.to raise_error(ArgumentError, "context must be a Course, Account, or Group")
      end
    end

    context "when launch_type is not valid" do
      let(:launch_type) { :foo }

      it "raises an ArgumentError" do
        expect { service }.to raise_error(ArgumentError, /launch_type must be one of/)
      end
    end
  end

  describe "#call" do
    subject { service.call }

    let(:data) { { foo: "bar" } }

    before do
      allow(PandataEvents).to receive(:send_event)
      allow(service).to receive(:log_data).and_return(data)
    end

    context "when account-level flag is disabled" do
      before do
        account.disable_feature!(:lti_log_launches)
      end

      it "does not send an event to PandataEvents" do
        subject
        expect(PandataEvents).not_to have_received(:send_event)
      end
    end

    context "when site-admin-level flag is disabled" do
      before do
        Account.site_admin.disable_feature!(:lti_log_launches_site_admin)
      end

      it "does not send an event to PandataEvents" do
        subject
        expect(PandataEvents).not_to have_received(:send_event)
      end
    end

    context "when both flags are enabled" do
      before do
        account.enable_feature!(:lti_log_launches)
        Account.site_admin.enable_feature!(:lti_log_launches_site_admin)
      end

      it "sends an event to PandataEvents" do
        subject
        expect(PandataEvents).to have_received(:send_event).with(:lti_launch, data, for_user_id: user.global_id)
      end

      context "without user" do
        let(:user) { nil }

        it "sends event without sub" do
          subject
          expect(PandataEvents).to have_received(:send_event).with(:lti_launch, data, for_user_id: nil)
        end
      end
    end
  end

  describe "#log_data" do
    subject { service.log_data }

    let(:user_relationship) { ["StudentEnrollment"] }

    before do
      allow(service).to receive(:user_relationship).and_return(user_relationship)
    end

    it "includes tool tool_id" do
      expect(subject[:tool_id]).to eq(tool.tool_id)
    end

    it "includes tool domain" do
      expect(subject[:tool_domain]).to eq(tool.domain)
    end

    it "includes tool url" do
      expect(subject[:tool_url]).to eq(tool.url)
    end

    it "includes tool name" do
      expect(subject[:tool_name]).to eq(tool.name)
    end

    it "includes tool lti version" do
      expect(subject[:tool_version]).to eq(tool.lti_version)
    end

    it "includes tool developer key id" do
      expect(subject[:tool_client_id]).to eq(tool.global_developer_key_id.to_s)
    end

    it "includes launch type" do
      expect(subject[:launch_type]).to eq(launch_type)
    end

    it "includes placement" do
      expect(subject[:placement]).to eq(placement)
    end

    it "includes context id" do
      expect(subject[:context_id]).to eq(context.global_id.to_s)
    end

    it "includes context type" do
      expect(subject[:context_type]).to eq(context.class.name)
    end

    it "includes user id" do
      expect(subject[:user_id]).to eq(user.global_id.to_s)
    end

    it "includes user relationship" do
      expect(subject[:user_relationship]).to eq(user_relationship)
    end
  end

  describe "#user_relationship" do
    subject { service.user_relationship }

    let(:account_admin_role) { Role.get_built_in_role("AccountAdmin", root_account_id: account.id) }
    let(:account) { account_model }

    before do
      context.root_account.account_users.create!(user:, role: account_admin_role) if user
    end

    context "without user" do
      let(:user) { nil }

      it "returns an empty string" do
        expect(subject).to eq("")
      end
    end

    context "when context is a Group" do
      let(:context) { group_model(context: course, root_account: account) }
      let(:course) { course_model(root_account: account) }

      before do
        context.add_user(user)
        course.enroll_user(user, "StudentEnrollment")
        course.enroll_user(user, "TaEnrollment")
      end

      it "includes group membership for user" do
        expect(subject).to include("GroupMembership")
      end

      it "includes course enrollment types for user" do
        expect(subject).to include("StudentEnrollment", "TaEnrollment")
      end

      it "includes account roles for user" do
        expect(subject).to include("AccountAdmin")
      end
    end

    context "when context is a Course" do
      let(:context) { course_model(root_account: account) }

      before do
        context.enroll_user(user, "StudentEnrollment")
        context.enroll_user(user, "TaEnrollment")
      end

      it "includes course enrollment types for user" do
        expect(subject).to include("StudentEnrollment", "TaEnrollment")
      end

      it "includes account roles for user" do
        expect(subject).to include("AccountAdmin")
      end
    end

    context "when context is an Account" do
      let(:context) { account }

      it "includes account roles for user" do
        expect(subject).to include("AccountAdmin")
      end
    end

    context "when account chain has multiple accounts" do
      let(:a1) { account_model }
      let(:a2) { account_model(parent_account: a1, root_account: a1) }
      let(:context) { course_model(account: a2, root_account: a1) }

      it "includes roles from top-level account" do
        expect(subject).to include("AccountAdmin")
      end
    end
  end

  describe "#message_type" do
    subject { service.message_type }

    context "when placement is not nil" do
      it "returns the tool's message type for the placement" do
        expect(subject).to eq(tool.extension_setting(placement, :message_type))
      end
    end

    context "when placement is nil" do
      let(:placement) { nil }

      context "when tool is LTI 1.3" do
        before do
          tool.update!(lti_version: "1.3")
        end

        it "returns LtiResourceLinkRequest" do
          expect(subject).to eq("LtiResourceLinkRequest")
        end
      end

      context "when tool is not LTI 1.3" do
        before do
          tool.update!(lti_version: "1.1")
        end

        it "returns basic-lti-launch-request" do
          expect(subject).to eq("basic-lti-launch-request")
        end
      end
    end
  end
end
