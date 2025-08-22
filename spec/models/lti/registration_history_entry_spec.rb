# frozen_string_literal: true

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
describe Lti::RegistrationHistoryEntry do
  let_once(:lti_registration) { lti_registration_with_tool(account:) }
  let_once(:account) { account_model }
  let_once(:user) { user_model }

  describe "validations" do
    let(:history_entry) do
      Lti::RegistrationHistoryEntry.new(lti_registration:,
                                        diff: [["+", "foo.bar", "stuff"]],
                                        update_type: "manual_edit",
                                        created_by: user)
    end

    it "doesn't require a comment" do
      expect(history_entry).to be_valid
    end

    it "limits the length of comments" do
      history_entry.comment = "a" * 2001
      expect(history_entry).not_to be_valid
    end

    it "requires a diff" do
      history_entry.diff = nil
      expect(history_entry).not_to be_valid
    end

    it "requires a valid update_type" do
      history_entry.update_type = "invalid type"
      expect(history_entry).not_to be_valid
    end

    it "requires a created_by" do
      history_entry.created_by = nil
      expect(history_entry).not_to be_valid
    end
  end
end
