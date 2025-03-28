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

describe DiscussionTopicInsight do
  before do
    @discussion_topic = course_model.discussion_topics.create!
    @user = user_model
  end

  describe "associations" do
    subject do
      described_class.new(
        discussion_topic: @discussion_topic,
        user: @user,
        workflow_state: "completed"
      )
    end

    it "is associated with the correct parameters" do
      subject.valid?
      expect(subject.discussion_topic).to eq(@discussion_topic)
      expect(subject.user).to eq(@user)
      expect(subject.root_account).to eq(@discussion_topic.root_account)
      expect(subject.workflow_state).to eq("completed")
    end
  end

  describe "validations" do
    it "validates presence of user" do
      insight = DiscussionTopicInsight.new(
        discussion_topic: @discussion_topic,
        workflow_state: "completed"
      )
      expect(insight.valid?).to be false
      expect(insight.errors[:user]).to include("can't be blank")
    end

    it "validates workflow_state" do
      insight = DiscussionTopicInsight.new(
        discussion_topic: @discussion_topic,
        user: @user,
        workflow_state: "invalid_state"
      )
      expect(insight.valid?).to be false
      expect(insight.errors[:workflow_state]).to include("is not included in the list")
    end
  end

  describe "#needs_processing?" do
    before do
      @insight = @discussion_topic.insights.create!(
        user: @user,
        workflow_state: "completed"
      )
    end

    it "returns true if there are unprocessed active entries" do
      @discussion_topic.discussion_entries.create!(message: "message", user: @teacher)

      expect(@insight.needs_processing?).to be true
    end

    it "returns false if there are unprocessed deleted entries" do
      @discussion_topic.discussion_entries.create!(message: "message", user: @teacher, workflow_state: "deleted")

      expect(@insight.needs_processing?).to be false
    end

    it "returns true if there are processed entries that have been deleted" do
      entry = @discussion_topic.discussion_entries.create!(message: "message", user: @teacher, workflow_state: "deleted")
      @insight.entries.create!(
        discussion_topic: @discussion_topic,
        discussion_entry: entry,
        discussion_entry_version: entry.discussion_entry_versions.first,
        locale: "en",
        dynamic_content_hash: "hash",
        ai_evaluation: {
          "relevance_classification" => "relevant",
          "confidence" => 3,
          "notes" => "notes"
        },
        ai_evaluation_human_feedback_liked: false,
        ai_evaluation_human_feedback_disliked: false,
        ai_evaluation_human_feedback_notes: ""
      )

      expect(@insight.needs_processing?).to be true
    end
  end

  describe "#generate" do
    before do
      @insight = @discussion_topic.insights.create!(
        user: @user,
        workflow_state: "created"
      )
    end

    it "generates insight entries for unprocessed entries" do
      # active entry, that should be processed
      @discussion_topic.discussion_entries.create!(message: "message", user: @teacher)

      # deleted entry, that should not be processed
      @discussion_topic.discussion_entries.create!(message: "message_2", user: @teacher, workflow_state: "deleted")

      # processed entry, that should not be processed
      processed_entry = @discussion_topic.discussion_entries.create!(message: "message_3", user: @teacher)

      # processed entry with a new version, that should be processed
      processed_entry_with_new_version = @discussion_topic.discussion_entries.create!(message: "message_4", user: @teacher)

      # processed entry with a different locale, that should be processed
      processed_entry_with_different_locale = @discussion_topic.discussion_entries.create!(message: "message_5", user: @teacher)

      prompt_presenter = DiscussionTopic::PromptPresenter.new(@discussion_topic)

      insight_entry = @insight.entries.create!(
        discussion_topic: @discussion_topic,
        discussion_entry: processed_entry,
        discussion_entry_version: processed_entry.discussion_entry_versions.first,
        locale: "en",
        dynamic_content_hash: DiscussionTopicInsight::Entry.hash_for_dynamic_content(
          content: prompt_presenter.content_for_insight(entries: [processed_entry]),
          pretty_locale: "English (United States)"
        ),
        ai_evaluation: {
          "relevance_classification" => "relevant",
          "confidence" => 3,
          "notes" => "notes"
        },
        ai_evaluation_human_feedback_liked: false,
        ai_evaluation_human_feedback_disliked: false,
        ai_evaluation_human_feedback_notes: ""
      )

      old_version = processed_entry_with_new_version.discussion_entry_versions.first
      old_version_content = prompt_presenter.content_for_insight(entries: [processed_entry_with_new_version])
      processed_entry_with_new_version.update!(message: "message_6")
      processed_entry_with_new_version.discussion_entry_versions.first
      insight_entry_2 = @insight.entries.create!(
        discussion_topic: @discussion_topic,
        discussion_entry: processed_entry_with_new_version,
        discussion_entry_version: old_version,
        locale: "en",
        dynamic_content_hash: DiscussionTopicInsight::Entry.hash_for_dynamic_content(
          content: old_version_content,
          pretty_locale: "English (United States)"
        ),
        ai_evaluation: {
          "relevance_classification" => "relevant",
          "confidence" => 3,
          "notes" => "notes"
        },
        ai_evaluation_human_feedback_liked: false,
        ai_evaluation_human_feedback_disliked: false,
        ai_evaluation_human_feedback_notes: ""
      )

      insight_entry_3 = @insight.entries.create!(
        discussion_topic: @discussion_topic,
        discussion_entry: processed_entry_with_different_locale,
        discussion_entry_version: processed_entry_with_different_locale.discussion_entry_versions.first,
        locale: "es",
        dynamic_content_hash: DiscussionTopicInsight::Entry.hash_for_dynamic_content(
          content: prompt_presenter.content_for_insight(entries: [processed_entry_with_different_locale]),
          pretty_locale: "Spanish"
        ),
        ai_evaluation: {
          "relevance_classification" => "relevant",
          "confidence" => 3,
          "notes" => "notes"
        },
        ai_evaluation_human_feedback_liked: false,
        ai_evaluation_human_feedback_disliked: false,
        ai_evaluation_human_feedback_notes: ""
      )

      @insight.generate

      expect(@insight.entries.count).to eq(6)
      expect(@insight.entries).to include(insight_entry)
      expect(@insight.entries).to include(insight_entry_2)
      expect(@insight.entries).to include(insight_entry_3)
      expect(@insight.workflow_state).to eq("completed")

      # TODO: test that insights are properly persisted after we have the final ai evaluation structure
      # TODO: test that Cedar is called with the correct data
    end

    it "generates new insight entries if discussion topic is updated" do
      @discussion_topic.discussion_entries.create!(message: "message", user: @teacher)

      @insight.generate

      expect(@insight.entries.count).to eq(1)

      @insight.generate

      expect(@insight.entries.count).to eq(1)

      @discussion_topic.update(title: "New title")

      @insight.generate

      expect(@insight.entries.count).to eq(2)

      @discussion_topic.update(message: "New message")

      @insight.generate

      expect(@insight.entries.count).to eq(3)
    end

    it "sets workflow_state to failed if an error occurs" do
      allow(@insight).to receive(:unprocessed_entries).and_raise("error")
      expect { @insight.generate }.to raise_error("error")
      expect(@insight.workflow_state).to eq("failed")
    end
  end

  describe "#processed_entries" do
    before do
      @insight = @discussion_topic.insights.create!(
        user: @user,
        workflow_state: "completed"
      )
    end

    it "returns the latest processed entry for each discussion entry" do
      entry = @discussion_topic.discussion_entries.create!(message: "message", user: @teacher)
      old_version = entry.discussion_entry_versions.first
      entry.update!(message: "message_2")
      new_version = entry.discussion_entry_versions.first

      @insight.entries.create!(
        discussion_topic: @discussion_topic,
        discussion_entry: entry,
        discussion_entry_version: old_version,
        locale: "en",
        dynamic_content_hash: "hash",
        ai_evaluation: {
          "relevance_classification" => "relevant",
          "confidence" => 3,
          "notes" => "notes"
        },
        ai_evaluation_human_feedback_liked: false,
        ai_evaluation_human_feedback_disliked: false,
        ai_evaluation_human_feedback_notes: ""
      )

      @insight.entries.create!(
        discussion_topic: @discussion_topic,
        discussion_entry: entry,
        discussion_entry_version: new_version,
        locale: "en",
        dynamic_content_hash: "hash_2",
        ai_evaluation: {
          "relevance_classification" => "relevant",
          "confidence" => 3,
          "notes" => "notes"
        },
        ai_evaluation_human_feedback_liked: false,
        ai_evaluation_human_feedback_disliked: false,
        ai_evaluation_human_feedback_notes: ""
      )

      expect(@insight.processed_entries.count).to eq(1)
      expect(@insight.processed_entries.first.discussion_entry).to eq(entry)
      expect(@insight.processed_entries.first.discussion_entry_version).to eq(new_version)
    end

    it "returns a deleted entry if it points to this insight" do
      entry = @discussion_topic.discussion_entries.create!(message: "message", user: @teacher, workflow_state: "deleted")
      @insight.entries.create!(
        discussion_topic: @discussion_topic,
        discussion_entry: entry,
        discussion_entry_version: entry.discussion_entry_versions.first,
        locale: "en",
        dynamic_content_hash: "hash",
        ai_evaluation: {
          "relevance_classification" => "relevant",
          "confidence" => 3,
          "notes" => "notes"
        },
        ai_evaluation_human_feedback_liked: false,
        ai_evaluation_human_feedback_disliked: false,
        ai_evaluation_human_feedback_notes: ""
      )

      expect(@insight.processed_entries.count).to eq(1)
      expect(@insight.processed_entries.first.discussion_entry).to eq(entry)
    end

    it "does not return a deleted entry if it points to another insight" do
      entry = @discussion_topic.discussion_entries.create!(message: "message", user: @teacher, workflow_state: "deleted")
      other_insight = @discussion_topic.insights.create!(
        user: @user,
        workflow_state: "completed"
      )
      other_insight.entries.create!(
        discussion_topic: @discussion_topic,
        discussion_entry: entry,
        discussion_entry_version: entry.discussion_entry_versions.first,
        locale: "en",
        dynamic_content_hash: "hash",
        ai_evaluation: {
          "relevance_classification" => "relevant",
          "confidence" => 3,
          "notes" => "notes"
        },
        ai_evaluation_human_feedback_liked: false,
        ai_evaluation_human_feedback_disliked: false,
        ai_evaluation_human_feedback_notes: ""
      )

      expect(@insight.processed_entries.count).to eq(0)
    end
  end
end
