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

      it "clears comment when liking" do
        @feedback.dislike
        @feedback.add_comment("bad summary")
        @feedback.like
        expect(@feedback.comment).to be_nil
      end
    end

    context "when action is dislike" do
      it "sets disliked to true" do
        @feedback.dislike
        expect(@feedback.liked).to be false
        expect(@feedback.disliked).to be true
      end
    end

    context "when action is add_comment" do
      it "stores comment on a disliked feedback" do
        @feedback.dislike
        @feedback.add_comment("The summary is inaccurate")
        expect(@feedback.comment).to eq("The summary is inaccurate")
      end

      it "persists the comment to the database" do
        @feedback.dislike
        @feedback.add_comment("The summary is inaccurate")
        @feedback.reload
        expect(@feedback.comment).to eq("The summary is inaccurate")
      end

      it "raises error when feedback is not disliked" do
        expect do
          @feedback.add_comment("some comment")
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "raises error when feedback is liked" do
        @feedback.like
        expect do
          @feedback.add_comment("some comment")
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "overwrites an existing comment" do
        @feedback.dislike
        @feedback.add_comment("first comment")
        @feedback.add_comment("updated comment")
        expect(@feedback.comment).to eq("updated comment")
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

      it "clears comment when resetting" do
        @feedback.dislike
        @feedback.add_comment("bad summary")
        @feedback.reset_like
        expect(@feedback.comment).to be_nil
      end
    end

    context "when action is disable_summary" do
      it "sets summary_disabled to true" do
        @feedback.disable_summary
        expect(@feedback.summary_disabled).to be true
      end
    end
  end

  describe "validations" do
    it "allows comment up to 1024 characters" do
      @feedback.dislike
      @feedback.add_comment("a" * 1024)
      expect(@feedback).to be_valid
    end

    it "rejects comment longer than 1024 characters" do
      @feedback.dislike
      expect do
        @feedback.add_comment("a" * 1025)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "allows nil comment" do
      @feedback.dislike
      expect(@feedback).to be_valid
      expect(@feedback.comment).to be_nil
    end
  end
end
