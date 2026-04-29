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

describe Lti::ToolFinderUtils do
  before(:once) do
    @root_account = Account.default
    @account = account_model(root_account: @root_account, parent_account: @root_account)
    course_model(account: @account)
  end

  describe "filter_by_unavailable_context_controls" do
    subject { Lti::ToolFinderUtils.send(:filter_by_unavailable_context_controls, scope, root_account) }

    let_once(:root_account) { account_model }
    let_once(:registration) { lti_registration_with_tool }
    let_once(:dev_key) { registration.developer_key }
    let_once(:tool) { registration.new_external_tool(root_account) }
    let_once(:old_tool) { external_tool_model(context: root_account) }

    let(:scope) { ContextExternalTool.all }

    it "allows 1.3 and 1.1 tools if they are available" do
      expect(subject).to include(tool, old_tool)
    end

    context "with multiple 1.3 tools associated with the same registration" do
      let_once(:other_tool) { registration.new_external_tool(root_account) }

      context "one of the tools is unavailable" do
        before(:once) do
          tool.context_controls.first.update!(available: false)
        end

        it "only returns the other tool in the root account" do
          expect(subject).not_to include(tool)
          expect(subject).to include(other_tool)
        end

        it "only returns the other tool in a subaccount" do
          subaccount = account_model(parent_account: root_account)
          expect(Lti::ToolFinderUtils.send(:filter_by_unavailable_context_controls, scope, subaccount)).not_to include(tool)
          expect(Lti::ToolFinderUtils.send(:filter_by_unavailable_context_controls, scope, subaccount)).to include(other_tool)
        end

        it "only returns the other tool in a course" do
          subaccount = account_model(parent_account: root_account)
          course = course_model(account: subaccount)
          expect(Lti::ToolFinderUtils.send(:filter_by_unavailable_context_controls, scope, course)).not_to include(tool)
          expect(Lti::ToolFinderUtils.send(:filter_by_unavailable_context_controls, scope, course)).to include(other_tool)
        end
      end
    end
  end
end
