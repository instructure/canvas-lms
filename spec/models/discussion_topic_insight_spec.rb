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
    @course = course_model
    @discussion_topic = @course.discussion_topics.create!
    @user = user_model
    @student = user_model
    @teacher = user_model
    @course.enroll_student(@student, enrollment_state: "active")
    @course.enroll_teacher(@teacher, enrollment_state: "active")
    allow(InstStatsd::Statsd).to receive(:distribution)
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
      @discussion_topic.discussion_entries.create!(message: "message", user: @student)

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

      @inst_llm = instance_double(InstLLM::Client)
      allow(InstLLMHelper).to receive(:client).and_return(@inst_llm)

      @llm_config = double("LLMConfig")
      allow(@llm_config).to receive_messages(model_id: "anthropic.claude-3-haiku-20240307-v1:0", generate_prompt_and_options: ["test prompt", { "max_tokens" => 2000 }], name: "discussion_topic_insights")
      allow(LLMConfigs).to receive(:config_for).with("discussion_topic_insights").and_return(@llm_config)
    end

    it "generates insight entries for unprocessed entries" do
      # active entry, that should be processed
      @discussion_topic.discussion_entries.create!(message: "message", user: @student)

      # deleted entry, that should not be processed
      @discussion_topic.discussion_entries.create!(message: "message_2", user: @student, workflow_state: "deleted")

      # processed entry, that should not be processed
      processed_entry = @discussion_topic.discussion_entries.create!(message: "message_3", user: @student)

      # processed entry with a new version, that should be processed
      processed_entry_with_new_version = @discussion_topic.discussion_entries.create!(message: "message_4", user: @student)

      # processed entry with a different locale, that should be processed
      processed_entry_with_different_locale = @discussion_topic.discussion_entries.create!(message: "message_5", user: @student)

      # teacher entry, that should not be processed
      @discussion_topic.discussion_entries.create!(message: "teacher message", user: @teacher)

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

      valid_llm_response = Array.new(3) do |i|
        {
          "id" => i.to_s,
          "final_label" => "relevant",
          "feedback" => "Great response addressing core topic with clarity and depth."
        }
      end

      expect(@inst_llm).to receive(:chat).and_return(
        InstLLM::Response::ChatResponse.new(
          model: "anthropic.claude-3-haiku-20240307-v1:0",
          message: { role: :assistant, content: valid_llm_response.to_json },
          stop_reason: "stop_reason",
          usage: {
            input_tokens: 100,
            output_tokens: 200,
          }
        )
      )

      @insight.generate
      expect(InstStatsd::Statsd).to have_received(:distribution).with("discussion_topic.insight.entry_batch_count", valid_llm_response.size).at_least(:once)

      expect(@insight.entries.count).to eq(6)
      expect(@insight.entries).to include(insight_entry)
      expect(@insight.entries).to include(insight_entry_2)
      expect(@insight.entries).to include(insight_entry_3)
      expect(@insight.workflow_state).to eq("completed")

      # TODO: test that insights are properly persisted after we have the final ai evaluation structure
      # TODO: test that Cedar is called with the correct data
    end

    it "generates new insight entries if discussion topic is updated" do
      @discussion_topic.discussion_entries.create!(message: "message", user: @student)

      valid_llm_response = [{
        "id" => "0",
        "final_label" => "relevant",
        "feedback" => "Good response."
      }].to_json

      expect(@inst_llm).to receive(:chat).exactly(3).times.and_return(
        InstLLM::Response::ChatResponse.new(
          model: "anthropic.claude-3-haiku-20240307-v1:0",
          message: { role: :assistant, content: valid_llm_response },
          stop_reason: "stop_reason",
          usage: {
            input_tokens: 100,
            output_tokens: 200,
          }
        )
      )

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

    it "handles invalid JSON responses from LLM with retries" do
      @discussion_topic.discussion_entries.create!(message: "message", user: @student)

      expect(@inst_llm).to receive(:chat).exactly(3).times.and_return(
        InstLLM::Response::ChatResponse.new(
          model: "anthropic.claude-3-haiku-20240307-v1:0",
          message: { role: :assistant, content: "This is not valid JSON" },
          stop_reason: "stop_reason",
          usage: {
            input_tokens: 100,
            output_tokens: 50,
          }
        )
      )

      expect { @insight.generate }.to raise_error(JSON::ParserError)
      expect(@insight.reload.workflow_state).to eq("failed")
    end

    it "validates that LLM response is an array with retries" do
      @discussion_topic.discussion_entries.create!(message: "message", user: @student)

      expect(@inst_llm).to receive(:chat).exactly(3).times.and_return(
        InstLLM::Response::ChatResponse.new(
          model: "anthropic.claude-3-haiku-20240307-v1:0",
          message: { role: :assistant, content: "{\"not_an_array\": true}".to_json },
          stop_reason: "stop_reason",
          usage: {
            input_tokens: 100,
            output_tokens: 50,
          }
        )
      )

      expect { @insight.generate }.to raise_error(ArgumentError, /not an array/)
      expect(@insight.reload.workflow_state).to eq("failed")
    end

    it "validates that LLM response length matches expected length with retries" do
      @discussion_topic.discussion_entries.create!(message: "message 1", user: @student)
      @discussion_topic.discussion_entries.create!(message: "message 2", user: @student)

      valid_response = [{
        "id" => "0",
        "final_label" => "relevant",
        "feedback" => "Good response."
      }].to_json

      expect(@inst_llm).to receive(:chat).exactly(3).times.and_return(
        InstLLM::Response::ChatResponse.new(
          model: "anthropic.claude-3-haiku-20240307-v1:0",
          message: { role: :assistant, content: valid_response },
          stop_reason: "stop_reason",
          usage: {
            input_tokens: 100,
            output_tokens: 50,
          }
        )
      )

      expect { @insight.generate }.to raise_error(ArgumentError, /response length.*doesn't match expected length/)
      expect(@insight.reload.workflow_state).to eq("failed")
    end

    it "validates required fields in LLM response with retries" do
      @discussion_topic.discussion_entries.create!(message: "message", user: @student)

      required_fields = %w[final_label feedback]
      required_fields.each do |missing_field|
        @insight.update!(workflow_state: "created")
        valid_response = [{
          "id" => "0",
          "final_label" => "relevant",
          "feedback" => "Good response."
        }]

        valid_response[0].delete(missing_field)

        expect(@inst_llm).to receive(:chat).exactly(3).times.and_return(
          InstLLM::Response::ChatResponse.new(
            model: "anthropic.claude-3-haiku-20240307-v1:0",
            message: { role: :assistant, content: valid_response.to_json },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 100,
              output_tokens: 50,
            }
          )
        )

        expect { @insight.generate }.to raise_error(ArgumentError, /missing required fields.*#{missing_field}/)
        expect(@insight.reload.workflow_state).to eq("failed")
      end
    end

    it "validates final_label has a valid value with retries" do
      @discussion_topic.discussion_entries.create!(message: "message", user: @student)

      invalid_response = [{
        "id" => "0",
        "final_label" => "invalid_label",
        "feedback" => "Good response."
      }].to_json

      expect(@inst_llm).to receive(:chat).exactly(3).times.and_return(
        InstLLM::Response::ChatResponse.new(
          model: "anthropic.claude-3-haiku-20240307-v1:0",
          message: { role: :assistant, content: invalid_response },
          stop_reason: "stop_reason",
          usage: {
            input_tokens: 100,
            output_tokens: 50,
          }
        )
      )

      expect { @insight.generate }.to raise_error(ArgumentError, /invalid final_label/)
      expect(@insight.reload.workflow_state).to eq("failed")
    end

    it "successfully retries after JSON parsing failures" do
      @discussion_topic.discussion_entries.create!(message: "message", user: @student)

      invalid_json = "This is not valid JSON"
      valid_response = [{
        "id" => "0",
        "final_label" => "relevant",
        "feedback" => "Good response."
      }].to_json

      expect(@inst_llm).to receive(:chat).exactly(2).times.and_return(
        InstLLM::Response::ChatResponse.new(
          model: "anthropic.claude-3-haiku-20240307-v1:0",
          message: { role: :assistant, content: invalid_json },
          stop_reason: "stop_reason",
          usage: {
            input_tokens: 100,
            output_tokens: 50,
          }
        ),
        InstLLM::Response::ChatResponse.new(
          model: "anthropic.claude-3-haiku-20240307-v1:0",
          message: { role: :assistant, content: valid_response },
          stop_reason: "stop_reason",
          usage: {
            input_tokens: 100,
            output_tokens: 200,
          }
        )
      )

      @insight.generate

      expect(@insight.entries.count).to eq(1)
      expect(@insight.workflow_state).to eq("completed")
    end

    it "successfully retries after validation failures" do
      @discussion_topic.discussion_entries.create!(message: "message", user: @student)

      invalid_response = {}.to_json
      valid_response = [{
        "id" => "0",
        "final_label" => "relevant",
        "feedback" => "Good response."
      }].to_json

      expect(@inst_llm).to receive(:chat).exactly(2).times.and_return(
        InstLLM::Response::ChatResponse.new(
          model: "anthropic.claude-3-haiku-20240307-v1:0",
          message: { role: :assistant, content: invalid_response },
          stop_reason: "stop_reason",
          usage: {
            input_tokens: 100,
            output_tokens: 50,
          }
        ),
        InstLLM::Response::ChatResponse.new(
          model: "anthropic.claude-3-haiku-20240307-v1:0",
          message: { role: :assistant, content: valid_response },
          stop_reason: "stop_reason",
          usage: {
            input_tokens: 100,
            output_tokens: 200,
          }
        )
      )

      @insight.generate

      expect(@insight.entries.count).to eq(1)
      expect(@insight.workflow_state).to eq("completed")
    end

    it "validates that response IDs are sequential numbers starting from 0 with retries" do
      @discussion_topic.discussion_entries.create!(message: "message", user: @student)

      invalid_response = [{
        "id" => "5",
        "final_label" => "relevant",
        "feedback" => "Good response."
      }].to_json

      expect(@inst_llm).to receive(:chat).exactly(3).times.and_return(
        InstLLM::Response::ChatResponse.new(
          model: "anthropic.claude-3-haiku-20240307-v1:0",
          message: { role: :assistant, content: invalid_response },
          stop_reason: "stop_reason",
          usage: {
            input_tokens: 100,
            output_tokens: 50,
          }
        )
      )

      expect { @insight.generate }.to raise_error(ArgumentError, /not sequential numbers starting from 0/)
      expect(@insight.reload.workflow_state).to eq("failed")
    end

    it "validates that multiple response IDs are sequential starting from 0 with retries" do
      @discussion_topic.discussion_entries.create!(message: "message 1", user: @student)
      @discussion_topic.discussion_entries.create!(message: "message 2", user: @student)

      wrong_sequence_response = [
        {
          "id" => "1",
          "final_label" => "relevant",
          "feedback" => "Good response for entry 1."
        },
        {
          "id" => "0",
          "final_label" => "relevant",
          "feedback" => "Good response for entry 2."
        }
      ].to_json

      expect(@inst_llm).to receive(:chat).exactly(3).times.and_return(
        InstLLM::Response::ChatResponse.new(
          model: "anthropic.claude-3-haiku-20240307-v1:0",
          message: { role: :assistant, content: wrong_sequence_response },
          stop_reason: "stop_reason",
          usage: {
            input_tokens: 100,
            output_tokens: 50,
          }
        )
      )

      expect { @insight.generate }.to raise_error(ArgumentError, /not sequential numbers starting from 0/)
      expect(@insight.reload.workflow_state).to eq("failed")
    end
  end

  describe "#processed_entries" do
    before do
      @insight = @discussion_topic.insights.create!(
        user: @user,
        workflow_state: "completed"
      )
      allow(InstStatsd::Statsd).to receive(:distributed_increment)
    end

    it "returns the latest processed entry for each discussion entry" do
      entry = @discussion_topic.discussion_entries.create!(message: "message", user: @student)
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
      entry = @discussion_topic.discussion_entries.create!(message: "message", user: @student, workflow_state: "deleted")
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
      entry = @discussion_topic.discussion_entries.create!(message: "message", user: @student, workflow_state: "deleted")
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
