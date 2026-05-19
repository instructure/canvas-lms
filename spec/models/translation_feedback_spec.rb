# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe TranslationFeedback do
  before :once do
    course_model
    user_model
    @topic = @course.discussion_topics.create!(title: "Test Topic", message: "Test")
    @entry = @topic.discussion_entries.create!(user: @user, message: "Test entry")
  end

  let(:entry_feedback) do
    described_class.create!(
      user: @user,
      course: @course,
      discussion_entry: @entry,
      target_language: "es"
    )
  end

  let(:topic_feedback) do
    described_class.create!(
      user: @user,
      course: @course,
      discussion_topic: @topic,
      target_language: "de"
    )
  end

  describe "validations" do
    it "requires target_language" do
      feedback = described_class.new(
        user: @user,
        course: @course,
        discussion_entry: @entry
      )
      expect(feedback).not_to be_valid
      expect(feedback.errors[:target_language]).to include("can't be blank")
    end
  end

  describe "#root_account" do
    it "sets root_account from context" do
      expect(entry_feedback.root_account).to eq(@course.root_account)
    end
  end

  describe "polymorphic content" do
    it "works with discussion entry" do
      expect(entry_feedback.discussion_entry).to eq(@entry)
      expect(entry_feedback.discussion_topic_id).to be_nil
    end

    it "works with discussion topic" do
      expect(topic_feedback.discussion_topic).to eq(@topic)
      expect(topic_feedback.discussion_entry_id).to be_nil
    end
  end

  describe "#like" do
    it "sets liked to true" do
      entry_feedback.like
      entry_feedback.reload
      expect(entry_feedback.liked).to be true
      expect(entry_feedback.disliked).to be false
    end

    it "toggles from disliked to liked" do
      entry_feedback.dislike
      entry_feedback.like
      entry_feedback.reload
      expect(entry_feedback.liked).to be true
      expect(entry_feedback.disliked).to be false
    end
  end

  describe "#dislike" do
    it "sets disliked to true" do
      entry_feedback.dislike
      entry_feedback.reload
      expect(entry_feedback.liked).to be false
      expect(entry_feedback.disliked).to be true
    end

    it "stores feedback notes" do
      entry_feedback.dislike(notes: "Bad translation")
      entry_feedback.reload
      expect(entry_feedback.feedback_notes).to eq("Bad translation")
    end
  end

  describe "#reset_like" do
    it "clears liked, disliked, and feedback_notes" do
      entry_feedback.dislike(notes: "Bad translation")
      entry_feedback.reset_like
      entry_feedback.reload
      expect(entry_feedback.liked).to be false
      expect(entry_feedback.disliked).to be false
      expect(entry_feedback.feedback_notes).to be_nil
    end
  end
end
