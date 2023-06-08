# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Messages
  describe NameHelper do
    let(:course) { double(:course, account_membership_allows: false) }
    let(:author) { double("Author", short_name: "Author Name") }
    let(:user) { double("User", short_name: "User Name") }
    let(:asset) { double("Asset", user:, author:) }
    let(:message_recipient) { double(:user) }
    let(:assignment) { double(:assignment, anonymize_students?: false, context: course) }
    let(:submission) { double(:submission, assignment:, user:) }

    def asset_for(notification_name, a = asset)
      NameHelper.new(
        asset: a,
        message_recipient:,
        notification_name:
      )
    end

    describe "#reply_to_name" do
      it "is nil for notification types that dont have source users" do
        expect(asset_for("Nonsense").reply_to_name).to be_nil
      end

      it "uses the author name for messages with authors" do
        comment = double(:submission_comment, author:, recipient: user, submission:, can_read_author?: true)
        expect(asset_for("Submission Comment", comment).reply_to_name).to eq "Author Name via Canvas Notifications"
      end

      it "uses the user name for messages belonging to users" do
        expect(asset_for("New Discussion Entry").reply_to_name).to eq "User Name via Canvas Notifications"
      end
    end

    describe "#from_name" do
      it "is nil for notification types that dont have source users" do
        expect(asset_for("Nonsense").from_name).to be_nil
      end

      it "is nil for missing asset" do
        expect(asset_for("Conversation Message", nil).from_name).to be_nil
      end

      it "uses the author name for messages with authors" do
        expect(asset_for("Conversation Message").from_name).to eq "Author Name"
      end

      it "uses the user name for messages belonging to users" do
        expect(asset_for("Assignment Resubmitted", submission).from_name).to eq "User Name"
      end

      it "returns the author's name when the message recipient is the author" do
        assignment = double(:assignment, anonymize_students?: true)
        submission = double(:submission, assignment:)
        asset2 = double(:asset, author:, submission:, can_read_author?: true)
        from_name = NameHelper.new(
          asset: asset2,
          message_recipient: author,
          notification_name: "Submission Comment"
        ).from_name
        expect(from_name).to eq "Author Name"
      end
    end

    describe "anonymized notifications" do
      let(:anon_assignment) { double(:assignment, anonymize_students?: true, context: course) }
      let(:anon_submission) { double(:submission, assignment: anon_assignment, user:) }
      let(:anon_comment) { double(:submission_comment, author:, recipient: user, submission: anon_submission, can_read_author?: false) }

      it "returns Anonymous User for comments when assignment is anonymous" do
        expect(asset_for("Submission Comment For Teacher", anon_comment).from_name).to eq "Anonymous User"
      end

      it "returns Anonymous User for resubmissions when assignment is anonymous" do
        expect(asset_for("Assignment Resubmitted", anon_submission).from_name).to eq "Anonymous User"
      end

      it "returns Anonymous User for submissions when assignment is anonymous" do
        expect(asset_for("Assignment Submitted", anon_submission).from_name).to eq "Anonymous User"
      end
    end
  end
end
