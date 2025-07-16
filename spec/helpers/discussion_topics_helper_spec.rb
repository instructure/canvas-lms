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

describe DiscussionTopicsHelper do
  describe "#any_course_with_checkpoints_enabled?" do
    let(:root_account) { account_model }

    context "when contexts is not an array" do
      it "returns false for nil" do
        expect(helper.any_course_with_checkpoints_enabled?(nil)).to be(false)
      end

      it "returns false for a string" do
        expect(helper.any_course_with_checkpoints_enabled?("not an array")).to be(false)
      end

      it "returns false for a single object" do
        course = course_model(account: root_account)
        expect(helper.any_course_with_checkpoints_enabled?(course)).to be(false)
      end
    end

    context "when contexts is an empty array" do
      it "returns false" do
        expect(helper.any_course_with_checkpoints_enabled?([])).to be(false)
      end
    end

    context "when contexts contains no courses" do
      let(:account) { account_model(parent_account: root_account) }
      let(:user) { user_model }

      it "returns false" do
        expect(helper.any_course_with_checkpoints_enabled?([account, user])).to be(false)
      end
    end

    context "when contexts contains courses" do
      let(:account1) { account_model(parent_account: root_account) }
      let(:account2) { account_model(parent_account: root_account) }
      let(:course1) { course_model(account: account1) }
      let(:course2) { course_model(account: account2) }

      context "when no courses have checkpoints enabled" do
        before do
          root_account.allow_feature!(:discussion_checkpoints)
          account1.disable_feature!(:discussion_checkpoints)
          account2.disable_feature!(:discussion_checkpoints)
        end

        it "returns false" do
          expect(helper.any_course_with_checkpoints_enabled?([course1, course2])).to be(false)
        end
      end

      context "when any course has checkpoints enabled" do
        before do
          root_account.allow_feature!(:discussion_checkpoints)
          account1.enable_feature!(:discussion_checkpoints)
          account2.disable_feature!(:discussion_checkpoints)
        end

        it "returns true" do
          result = helper.any_course_with_checkpoints_enabled?([course1, course2])
          expect(result).to be(true)
        end
      end

      context "when contexts contains mixed types" do
        let(:account) { account_model(parent_account: root_account) }
        let(:user) { user_model }
        let(:group) { group_model }

        before do
          root_account.allow_feature!(:discussion_checkpoints)
          account1.enable_feature!(:discussion_checkpoints)
        end

        it "only considers course contexts and returns true if any course has checkpoints enabled" do
          result = helper.any_course_with_checkpoints_enabled?([course1, account, user, group])
          expect(result).to be(true)
        end
      end
    end
  end
end
