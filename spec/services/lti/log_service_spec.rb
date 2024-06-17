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
    Lti::LogService.new(tool:, context:, user:, session_id:, placement:, launch_type:)
  end

  let_once(:session_id) { SecureRandom.hex }
  let_once(:tool) { external_tool_model(opts: { unified_tool_id: "unified_tool_id" }) }
  let_once(:user) { user_model }
  let_once(:account) { account_model }
  let_once(:context) { course_model(root_account: account) }
  let_once(:placement) { :course_navigation }
  let_once(:launch_type) { :direct_link }

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

    let_once(:data) { { foo: "bar" } }

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

    let_once(:user_relationship) { ["StudentEnrollment"] }

    before do
      allow(service).to receive(:user_relationship).and_return(user_relationship)
    end

    it "includes the correct data" do
      expect(subject).to eq({
                              unified_tool_id: tool.unified_tool_id,
                              tool_id: tool.id.to_s,
                              tool_provided_id: tool.tool_id,
                              tool_domain: tool.domain,
                              tool_url: tool.url,
                              tool_name: tool.name,
                              tool_version: tool.lti_version,
                              tool_client_id: tool.global_developer_key_id.to_s,
                              account_id: account.id.to_s,
                              root_account_uuid: account.uuid,
                              launch_type:,
                              message_type: service.message_type,
                              placement:,
                              context_id: context.id.to_s,
                              context_type: context.class.name,
                              user_id: user.id.to_s,
                              session_id:,
                              shard_id: Shard.current.id.to_s,
                              user_relationship:
                            })
    end

    context "when the context is a course" do
      let_once(:context) { course_model(root_account: account) }

      it "includes the associated account id and root account uuid" do
        expect(subject[:account_id]).to eq(account.id.to_s)
        expect(subject[:root_account_uuid]).to eq(account.uuid)
      end
    end

    context "when the context is an account" do
      let_once(:context) { account }

      it "includes the associated account id and root account uuid" do
        expect(subject[:account_id]).to eq(context.id.to_s)
        expect(subject[:root_account_uuid]).to eq(account.uuid)
      end
    end

    context "when the context is a group" do
      let_once(:context) { group_model(context: course, root_account: account) }
      let_once(:course) { course_model(root_account: account) }

      it "includes the associated account id" do
        expect(subject[:account_id]).to eq(account.id.to_s)
        expect(subject[:root_account_uuid]).to eq(account.uuid)
      end

      context "the group belongs to an account" do
        let_once(:context) { group_model(context: account, root_account: account) }

        it "includes the associated account id" do
          expect(subject[:account_id]).to eq(account.id.to_s)
          expect(subject[:root_account_uuid]).to eq(account.uuid)
        end
      end
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

      context "the group belongs to an account" do
        let(:context) { group_model(context: account, root_account: account) }

        it "includes only account and group level roles for user" do
          expect(subject.split(",")).to contain_exactly("AccountAdmin", "GroupMembership")
        end
      end
    end

    context "when context is a Course" do
      let_once(:context) { course_model(root_account: account) }

      before(:once) do
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
