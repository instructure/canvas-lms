# frozen_string_literal: true

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

describe DiscussionTopicSummary::Feedback do
  before do
    discussion_topic = course_model.discussion_topics.create!
    @discussion_topic_summary = discussion_topic.summaries.create!(
      discussion_topic:,
      summary: "summary",
      dynamic_content_hash: "hash",
      llm_config_version: "V0_A"
    )
    @user = User.create!(name: "John Doe")
    @feedback = @discussion_topic_summary.feedback.create!(user: @user)
  end

  describe "associations" do
    subject { described_class.new(discussion_topic_summary: @discussion_topic_summary, user: @user) }

    it "is associated with the correct parameters" do
      subject.valid?
      expect(subject.discussion_topic_summary).to eq(@discussion_topic_summary)
      expect(subject.user).to eq(@user)
      expect(subject.root_account).to eq(@discussion_topic_summary.root_account)
    end
  end

  describe "action methods" do
    context "when action is like" do
      it "sets liked to true" do
        @feedback.like
        expect(@feedback.liked).to be true
        expect(@feedback.disliked).to be false
      end
    end

    context "when action is dislike" do
      it "sets disliked to true" do
        @feedback.dislike
        expect(@feedback.liked).to be false
        expect(@feedback.disliked).to be true
      end
    end

    context "when action is reset_like" do
      it "sets liked and disliked to false" do
        @feedback.like
        @feedback.reset_like
        expect(@feedback.liked).to be false
        expect(@feedback.disliked).to be false

        @feedback.dislike
        @feedback.reset_like
        expect(@feedback.liked).to be false
        expect(@feedback.disliked).to be false
      end
    end

    context "when action is disable_summary" do
      it "sets summary_disabled to true" do
        @feedback.disable_summary
        expect(@feedback.summary_disabled).to be true
      end
    end
  end
end
