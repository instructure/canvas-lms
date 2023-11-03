# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

shared_examples_for "advantage services" do
  let(:extra_tool_context) { raise "Override in spec" }

  shared_examples "extra developer key and account tool check" do
    let(:extra_tool_context) { course_account }

    it_behaves_like "extra developer key and tool check"
  end

  shared_examples "extra developer key and course tool check" do
    let(:extra_tool_context) { course }

    it_behaves_like "extra developer key and tool check"
  end

  shared_examples "extra developer key and tool check" do
    context "a account chain-reachable tool is associated with a different developer key" do
      let(:developer_key_that_should_not_be_resolved_from_request) { DeveloperKey.create!(account: developer_key.account) }
      let(:tool_that_should_not_be_resolved_from_request) do
        ContextExternalTool.create!(
          context: extra_tool_context,
          consumer_key: "key2",
          shared_secret: "secret2",
          name: "test tool 2",
          url: "http://www.tool2.com/launch",
          developer_key: developer_key_that_should_not_be_resolved_from_request,
          lti_version: "1.3",
          workflow_state: "public"
        )
      end

      it "returns 200 and finds the tool associated with the access token's developer key, ignoring other the other developer key and its tool" do
        expect(response).to have_http_status http_success_status
        expect(controller.tool).to eq tool
      end

      context "and that tool is the only tool" do
        let(:before_send_request) { -> { tool.destroy! } }

        it_behaves_like "mime_type check"

        it "returns 401 unauthorized and complains about missing tool" do
          expect(response).to have_http_status :unauthorized
          expect(json).to be_lti_advantage_error_response_body("unauthorized", "Access Token not linked to a Tool associated with this Context")
        end
      end
    end
  end

  describe "common lti advantage request and response check" do
    # #around and #before(:context) don't have access to the right scope, #before(:example) runs too late,
    # so hack our own lifecycle hook
    let(:before_send_request) { -> {} }

    before do
      before_send_request.call
      send_request
    end

    context "with unknown context" do
      let(:context_id) { unknown_context_id }

      it_behaves_like "mime_type check"

      it "returns 404 not found" do
        expect(response).to have_http_status :not_found
      end
    end

    context "with deleted context" do
      let(:before_send_request) do
        lambda do
          context.destroy
        end
      end

      it_behaves_like "mime_type check"

      it "returns 404 not found" do
        expect(response).to have_http_status :not_found
      end
    end

    context "with unbound developer key" do
      let(:before_send_request) do
        lambda do
          developer_key.developer_key_account_bindings.first.update! workflow_state: "off"
        end
      end

      it_behaves_like "mime_type check"

      it "returns 401 unauthorized and complains about missing developer key" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Invalid Developer Key")
      end
    end

    context "with deleted tool" do
      let(:before_send_request) { -> { tool.destroy! } }

      it_behaves_like "mime_type check"

      it "returns 401 unauthorized and complains about missing tool" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Access Token not linked to a Tool associated with this Context")
      end
    end

    context "with no tool" do
      let(:tool) { nil }

      it_behaves_like "mime_type check"

      it "returns 401 unauthorized and complains about missing tool" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Access Token not linked to a Tool associated with this Context")
      end
    end

    context "with tool and course attached to root account with no sub-accounts" do
      # the simple happy-path case.... by default :course and :developer_key are attached directly to the same Account,
      # which has no subaccounts
      it "returns 200 and finds the correct tool" do
        expect(response).to have_http_status http_success_status
        expect(controller.tool).to eq tool
      end
    end

    # want to use let! specifically to set up data that should never be read, so rubocop gets upset
    # rubocop:disable RSpec/LetSetup
    context "with tool attached to root account and course attached to deeply nested sub-account" do
      # child 1
      let(:sub_account_1) { root_account.sub_accounts.create!(name: "sub-account-1") }
      # child 2
      let(:sub_account_2) { root_account.sub_accounts.create!(name: "sub-account-2") }
      # grand-child of child 1
      let(:sub_account_1_1) { sub_account_1.sub_accounts.create!(name: "sub-account-1-1") }
      # place :course at the very bottom of account hierarchy. tool we care about will be way up at :root_account
      let(:course_account) { sub_account_1_1 }
      # place another tool (associated w same developer key) in a separate branch of the account hierarchy to make
      # sure we're just walking straght up the tree
      let!(:tool_that_should_not_be_resolved_from_request) do
        ContextExternalTool.create!(
          context: sub_account_2,
          consumer_key: "key2",
          shared_secret: "secret2",
          name: "test tool 2",
          url: "http://www.tool2.com/launch",
          developer_key:,
          lti_version: "1.3",
          workflow_state: "public"
        )
      end

      it "returns 200 and walks up account chain to find the correct tool" do
        expect(response).to have_http_status http_success_status
        expect(controller.tool).to eq tool
      end
    end

    context "with tool attached to sub-account and course attached to another sub-account thereof" do
      # child 1
      let(:sub_account_1) { root_account.sub_accounts.create!(name: "sub-account-1") }
      # child 2
      let(:sub_account_2) { root_account.sub_accounts.create!(name: "sub-account-2") }
      # grand-child of child 1
      let(:sub_account_1_1) { sub_account_1.sub_accounts.create!(name: "sub-account-1-1") }
      # place :tool in the middle of the account hierarchy
      let(:tool_context) { sub_account_1 }
      # place :course at the very bottom of account hierarchy. tool we care about will be one level up at :sub_account_1
      let(:course_account) { sub_account_1_1 }
      # place another tool (associated w same developer key) in a separate branch of the account hierarchy to make
      # sure we're just walking straght up the tree
      let!(:tool_that_should_not_be_resolved_from_request) do
        ContextExternalTool.create!(
          context: sub_account_2,
          consumer_key: "key2",
          shared_secret: "secret2",
          name: "test tool 2",
          url: "http://www.tool2.com/launch",
          developer_key:,
          lti_version: "1.3",
          workflow_state: "public"
        )
      end

      it "returns 200 and walks up account chain to find the correct tool" do
        expect(response).to have_http_status http_success_status
        expect(controller.tool).to eq tool
      end
    end

    context "with tool and course attached to same deeply nested sub-account" do
      # child 1
      let(:sub_account_1) { root_account.sub_accounts.create!(name: "sub-account-1") }
      # child 2
      let(:sub_account_2) { root_account.sub_accounts.create!(name: "sub-account-2") }
      # grand-child of child 1
      let(:sub_account_1_1) { sub_account_1.sub_accounts.create!(name: "sub-account-1-1") }
      # place :tool iat the very bottom of account hierarchy
      let(:tool_context) { sub_account_1_1 }
      # also place :course at the very bottom of account hierarchy. tool we care about is at the same level
      let(:course_account) { sub_account_1_1 }
      # place another tool (associated w same developer key) one level higher in the account hierarchy to make
      # sure we're just walking the tree bottom-up
      let!(:tool_that_should_not_be_resolved_from_request) do
        ContextExternalTool.create!(
          context: sub_account_1,
          consumer_key: "key2",
          shared_secret: "secret2",
          name: "test tool 2",
          url: "http://www.tool2.com/launch",
          developer_key:,
          lti_version: "1.3",
          workflow_state: "public"
        )
      end

      it "returns 200 and finds the tool in the same sub-sub-account as the course" do
        expect(response).to have_http_status http_success_status
        expect(controller.tool).to eq tool
      end
    end

    # reversal of 'with tool attached to sub-account and course attached to another sub-account thereof'. should result
    # in a tool lookup miss (:tool is "lower" than :course in account hierarchy)
    context "with course attached to sub-account and tool attached to another sub-account thereof" do
      # child 1
      let(:sub_account_1) { root_account.sub_accounts.create!(name: "sub-account-1") }
      # child 2
      let(:sub_account_2) { root_account.sub_accounts.create!(name: "sub-account-2") }
      # grand-child of child 1
      let(:sub_account_1_1) { sub_account_1.sub_accounts.create!(name: "sub-account-1-1") }
      # place :course in the middle of the account hierarchy. tool we care about will be one level down at sub_account_1_1
      let(:course_account) { sub_account_1 }
      # place :tool at the very bottom of account hierarchy. course care about will be one level up at :sub_account_1
      let(:tool_context) { sub_account_1_1 }
      # place another tool (associated w same developer key) in a separate branch of the account hierarchy to make
      # sure we're just walking straght up the tree
      let!(:tool_that_should_not_be_resolved_from_request) do
        ContextExternalTool.create!(
          context: sub_account_2,
          consumer_key: "key2",
          shared_secret: "secret2",
          name: "test tool 2",
          url: "http://www.tool2.com/launch",
          developer_key:,
          lti_version: "1.3",
          workflow_state: "public"
        )
      end

      it_behaves_like "mime_type check"

      it "returns 401 unauthorized and complains about missing tool" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Access Token not linked to a Tool associated with this Context")
      end
    end

    # another negative test, this time where :course and :tool are in completely disjoint account hierarchy branches
    context "with course attached to sub-account and tool attached to another sub-account" do
      # child 1
      let(:sub_account_1) { root_account.sub_accounts.create!(name: "sub-account-1") }
      # child 2
      let(:sub_account_2) { root_account.sub_accounts.create!(name: "sub-account-2") }
      # place :course in one account hierarchy branch
      let(:course_account) { sub_account_1 }
      # place :tool in the other account hierarchy branch
      let(:tool_context) { sub_account_2 }
      # place another tool (associated w same developer key) in a separate branch of the account hierarchy to make
      # sure we're just walking straght up the tree
      let!(:tool_that_should_not_be_resolved_from_request) do
        ContextExternalTool.create!(
          context: sub_account_2,
          consumer_key: "key2",
          shared_secret: "secret2",
          name: "test tool 2",
          url: "http://www.tool2.com/launch",
          developer_key:,
          lti_version: "1.3",
          workflow_state: "public"
        )
      end

      it_behaves_like "mime_type check"

      it "returns 401 unauthorized and complains about missing tool" do
        expect(response).to have_http_status :unauthorized
        expect(json).to be_lti_advantage_error_response_body("unauthorized", "Access Token not linked to a Tool associated with this Context")
      end
    end

    context "with tool attached directly to a course" do
      # place :tool in the other account hierarchy branch
      let(:tool_context) { course }
      # place another tool (associated w same developer key) in the same account that owns the course... tool search
      # should find the course-scoped tool instead
      let!(:tool_that_should_not_be_resolved_from_request) do
        ContextExternalTool.create!(
          context: course_account,
          consumer_key: "key2",
          shared_secret: "secret2",
          name: "test tool 2",
          url: "http://www.tool2.com/launch",
          developer_key:,
          lti_version: "1.3",
          workflow_state: "public"
        )
      end

      it "returns 200 and finds the tool attached directly to the course, ignoring the account-level tool" do
        expect(response).to have_http_status http_success_status
        expect(controller.tool).to eq tool
      end
    end
    # rubocop:enable RSpec/LetSetup

    it_behaves_like "extra developer key and account tool check"
    it_behaves_like "extra developer key and course tool check"
  end
end
