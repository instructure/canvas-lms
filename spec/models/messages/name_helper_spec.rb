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

require 'spec_helper'
require_dependency "messages/name_helper"

module Messages

  describe NameHelper do
    let(:author){ double("Author", short_name: "Author Name") }
    let(:user){ double("User", short_name: "User Name") }
    let(:asset){ double("Asset", user: user, author: author) }
    let(:message_recipient) { double(:user) }

    def asset_for(notification_name, a = asset)
      NameHelper.new(
        asset: a,
        message_recipient: message_recipient,
        notification_name: notification_name
      )
    end

    describe '#reply_to_name' do
      it 'is nil for notification types that dont have source users' do
        expect(asset_for("Nonsense").reply_to_name).to be_nil
      end

      it 'uses the author name for messages with authors' do
        expect(asset_for("Submission Comment").reply_to_name).to  eq "Author Name via Canvas Notifications"
      end

      it 'uses the user name for messages belonging to users' do
        expect(asset_for("New Discussion Entry").reply_to_name).to  eq "User Name via Canvas Notifications"
      end
    end

    describe '#from_name' do
      it 'is nil for notification types that dont have source users' do
        expect(asset_for("Nonsense").from_name).to be_nil
      end

      it 'is nil for missing asset' do
        expect(asset_for("Conversation Message", nil).from_name).to be_nil
      end

      it 'uses the author name for messages with authors' do
        expect(asset_for("Conversation Message").from_name).to eq "Author Name"
      end

      it 'uses the user name for messages belonging to users' do
        expect(asset_for("Assignment Resubmitted").from_name).to eq "User Name"
      end

      it 'returns Anonymous User when the user is not allowed to read the author' do
        assignment = double(:assignment, anonymize_students?: false)
        submission = double(:submission, assignment: assignment)
        asset2 = double(:asset, author: author, recipient: user, submission: submission, can_read_author?: false)
        expect(asset_for("Submission Comment", asset2).from_name).to eq "Anonymous User"
      end

      it "returns Anonymous User when the assignment is anonymous and muted" do
        assignment = double(:assignment, anonymize_students?: true)
        submission = double(:submission, assignment: assignment)
        asset2 = double(:asset, author: author, recipient: user, submission: submission)
        expect(asset_for("Submission Comment For Teacher", asset2).from_name).to eq "Anonymous User"
      end

      it "returns the author's name when the message recipient is the author" do
        assignment = double(:assignment, anonymize_students?: true)
        submission = double(:submission, assignment: assignment)
        asset2 = double(:asset, author: author, submission: submission, can_read_author?: true)
        from_name = NameHelper.new(
          asset: asset2,
          message_recipient: author,
          notification_name: "Submission Comment"
        ).from_name
        expect(from_name).to eq "Author Name"
      end
    end
  end
end
