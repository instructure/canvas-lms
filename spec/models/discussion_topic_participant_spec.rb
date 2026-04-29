# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe DiscussionTopicParticipant do
  describe "check_unread_count" do
    before(:once) do
      @participant = DiscussionTopicParticipant.create!(user: user_factory,
                                                        discussion_topic: discussion_topic_model)
    end

    it "sets negative unread_counts to zero on save" do
      @participant.update_attribute(:unread_entry_count, -15)
      expect(@participant.unread_entry_count).to eq 0
    end

    it "does not change an unread_count of zero" do
      @participant.update_attribute(:unread_entry_count, 0)
      expect(@participant.unread_entry_count).to eq 0
    end

    it "does not change a positive unread_count" do
      @participant.update_attribute(:unread_entry_count, 15)
      expect(@participant.unread_entry_count).to eq 15
    end
  end

  describe "create" do
    before(:once) do
      @participant = DiscussionTopicParticipant.create!(user: user_factory,
                                                        discussion_topic: discussion_topic_model)
    end

    it "sets the root_account_id using topic" do
      expect(@participant.root_account_id).to eq @topic.root_account_id
    end
  end

  describe "#posted?" do
    subject { participant.posted? }

    let(:user) { user_factory }
    let(:other_user) { user_factory }
    let(:discussion_topic) { discussion_topic_model }
    let(:participant) { DiscussionTopicParticipant.new(user:, discussion_topic:) }

    before do
      DiscussionTopicParticipant.create!(user:, discussion_topic:)
    end

    context "when participant has no entry but other user has one" do
      before do
        DiscussionTopicParticipant.create!(user: other_user, discussion_topic:)
        DiscussionEntry.create!(user: other_user, discussion_topic:, message: "hi")
      end

      it "returns false" do
        expect(subject).to be_falsey
      end
    end

    context "when participant has a top-level entry" do
      before do
        DiscussionEntry.create!(user:, discussion_topic:, message: "hi")
      end

      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    context "when participant has only a reply entry" do
      before do
        parent_entry = DiscussionEntry.create!(user: other_user, discussion_topic:, message: "hi")
        DiscussionEntry.create!(user:, discussion_topic:, message: "hi", parent_entry:)
      end

      it "returns false" do
        expect(subject).to be_falsey
      end
    end
  end
end
