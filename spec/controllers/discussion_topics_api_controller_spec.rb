# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe DiscussionTopicsApiController do
  describe "POST add_entry" do
    before :once do
      Setting.set("enable_page_views", "db")
      course_with_student active_all: true
      @topic = @course.discussion_topics.create!(title: "discussion")
    end

    before do
      user_session(@student)
      allow(controller).to receive_messages(form_authenticity_token: "abc", form_authenticity_param: "abc")
      post "add_entry", params: { topic_id: @topic.id, course_id: @course.id, user_id: @user.id, message: "message", read_state: "read" }, format: "json"
    end

    it "creates a new discussion entry" do
      entry = assigns[:entry]
      expect(entry.discussion_topic).to eq @topic
      expect(entry.id).not_to be_nil
      expect(entry.message).to eq "message"
    end

    it "logs an asset access record for the discussion topic" do
      accessed_asset = assigns[:accessed_asset]
      expect(accessed_asset[:code]).to eq @topic.asset_string
      expect(accessed_asset[:category]).to eq "topics"
      expect(accessed_asset[:level]).to eq "participate"
    end

    it "registers a page view" do
      page_view = assigns[:page_view]
      expect(page_view).not_to be_nil
      expect(page_view.http_method).to eq "post"
      expect(page_view.url).to match %r{^http://test\.host/api/v1/courses/\d+/discussion_topics}
      expect(page_view.participated).to be_truthy
    end
  end

  context "add_entry file quota" do
    before do
      course_with_student active_all: true
      @course.allow_student_forum_attachments = true
      @course.save!
      @topic = @course.discussion_topics.create!(title: "discussion")
      user_session(@student)
      allow(controller).to receive_messages(form_authenticity_token: "abc", form_authenticity_param: "abc")
    end

    it "uploads attachment to submissions folder if topic is graded" do
      assignment_model(course: @course)
      @topic.assignment = @assignment
      @topic.save
      Setting.set("user_default_quota", -1)
      expect(@student.attachments.count).to eq 0

      post "add_entry",
           params: { topic_id: @topic.id,
                     course_id: @course.id,
                     user_id: @user.id,
                     message: "message",
                     read_state: "read",
                     attachment: default_uploaded_data },
           format: "json"

      expect(response).to be_successful
      expect(@student.attachments.count).to eq 1
      expect(@student.attachments.first.folder.for_submissions?).to be_truthy
      expect(@student.attachments.pluck(:filename)).to include(default_uploaded_data.original_filename)
    end

    it "fails if attachment a file over student quota (not course)" do
      Setting.set("user_default_quota", -1)

      post "add_entry",
           params: { topic_id: @topic.id,
                     course_id: @course.id,
                     user_id: @user.id,
                     message: "message",
                     read_state: "read",
                     attachment: default_uploaded_data },
           format: "json"

      expect(response).to_not be_successful
      expect(response.body).to include("User storage quota exceeded")
    end

    it "succeeds otherwise" do
      post "add_entry",
           params: { topic_id: @topic.id,
                     course_id: @course.id,
                     user_id: @user.id,
                     message: "message",
                     read_state: "read",
                     attachment: default_uploaded_data },
           format: "json"

      expect(response).to be_successful
    end

    it "uses instfs to store attachment if instfs is enabled" do
      uuid = "1234-abcd"
      allow(InstFS).to receive_messages(enabled?: true, direct_upload: uuid)
      post "add_entry",
           params: { topic_id: @topic.id,
                     course_id: @course.id,
                     user_id: @user.id,
                     message: "message",
                     read_state: "read",
                     attachment: default_uploaded_data },
           format: "json"
      expect(@student.attachments.first.instfs_uuid).to eq(uuid)
    end
  end

  context "cross-sharding" do
    specs_require_sharding

    before do
      course_with_student active_all: true
      allow(controller).to receive_messages(form_authenticity_token: "abc", form_authenticity_param: "abc")
      @topic = @course.discussion_topics.create!(title: "student topic", message: "Hello", user: @student)
      @entry = @topic.discussion_entries.create!(message: "first message", user: @student)
      @entry2 = @topic.discussion_entries.create!(message: "second message", user: @student)
      @reply = @entry.discussion_subentries.create!(discussion_topic: @topic, message: "reply to first message", user: @student)
    end

    it "returns the entries across shards" do
      user_session(@student)
      @shard1.activate do
        post "entries", params: { topic_id: @topic.id, course_id: @course.id, user_id: @student.id }, format: "json"
        expect(response.parsed_body.count).to eq(2)
      end

      @shard2.activate do
        post "entries", params: { topic_id: @topic.id, course_id: @course.id, user_id: @student.id }, format: "json"
        expect(response.parsed_body.count).to eq(2)
      end
    end

    it "returns the entry replies across shards" do
      user_session(@student)
      @shard1.activate do
        post "replies", params: { topic_id: @topic.id, course_id: @course.id, user_id: @student.id, entry_id: @entry.id }, format: "json"
        expect(response.parsed_body.count).to eq(1)
      end

      @shard2.activate do
        post "replies", params: { topic_id: @topic.id, course_id: @course.id, user_id: @student.id, entry_id: @entry.id }, format: "json"
        expect(response.parsed_body.count).to eq(1)
      end
    end
  end

  context "summary" do
    before do
      course_with_teacher(active_course: true)
      @teacher.update!(locale: "en")
      @topic = @course.discussion_topics.create!(title: "discussion", summary_enabled: true)
      user_session(@teacher)

      @inst_llm = double("InstLLM::Client")
      allow(InstLLMHelper).to receive(:client).and_return(@inst_llm)
    end

    context "with llm config" do
      before do
        expect(LLMConfigs).to receive(:config_for).and_return(
          LLMConfig.new(
            name: "raw-V1_A",
            model_id: "model",
            template: "<CONTENT_PLACEHOLDER>"
          )
        )
        expect(LLMConfigs).to receive(:config_for).and_return(
          LLMConfig.new(
            name: "refined-V1_A",
            model_id: "model",
            template: "<CONTENT_PLACEHOLDER>"
          )
        )
      end

      context "with a previous summary" do
        before do
          @raw_summary = @topic.summaries.create!(
            summary: "raw_summary",
            dynamic_content_hash: Digest::SHA256.hexdigest({
              CONTENT: DiscussionTopic::PromptPresenter.new(@topic).content_for_summary,
              FOCUS: DiscussionTopic::PromptPresenter.focus_for_summary(user_input: nil),
            }.to_json),
            llm_config_version: "raw-V1_A",
            user: @teacher
          )
          @refined_summary = @topic.summaries.create!(
            summary: "refined_summary",
            dynamic_content_hash: Digest::SHA256.hexdigest({
              CONTENT: DiscussionTopic::PromptPresenter.raw_summary_for_refinement(raw_summary: @raw_summary.summary),
              FOCUS: DiscussionTopic::PromptPresenter.focus_for_summary(user_input: ""),
              LOCALE: "English (United States)"
            }.to_json),
            llm_config_version: "refined-V1_A",
            parent: @raw_summary,
            locale: "en",
            user: @teacher
          )
        end

        it "returns the existing summary" do
          expect_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)

          expect(@inst_llm).not_to receive(:chat)

          get "summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

          expect(response).to be_successful
          expect(response.parsed_body["id"]).to eq(@refined_summary.id)
        end

        it "returns a new summary if locale has changed" do
          expect_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)
          @teacher.update!(locale: "es")

          expect(@inst_llm).to receive(:chat).and_return(
            InstLLM::Response::ChatResponse.new(
              model: "model",
              message: { role: :assistant, content: "refined_summary" },
              stop_reason: "stop_reason",
              usage: {
                input_tokens: 10,
                output_tokens: 20,
              }
            )
          )

          get "summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

          expect(response).to be_successful
          expect(@topic.reload.summary_enabled).to be_truthy
          expect(response.parsed_body["id"]).not_to eq(@refined_summary.id)
        end
      end

      it "returns a new summary" do
        expect_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)

        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "raw_summary" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )
        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "refined_summary" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )

        get "summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

        expect(response).to be_successful
      end

      it "enables summary if it was disabled" do
        expect_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)
        @topic.update!(summary_enabled: false)

        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "raw_summary" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )
        expect(@inst_llm).to receive(:chat).and_return(
          InstLLM::Response::ChatResponse.new(
            model: "model",
            message: { role: :assistant, content: "refined_summary" },
            stop_reason: "stop_reason",
            usage: {
              input_tokens: 10,
              output_tokens: 20,
            }
          )
        )

        get "summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

        expect(response).to be_successful
        expect(@topic.reload.summary_enabled).to be_truthy
      end
    end

    it "returns rate limit exceeded error if the user has reached the max number of summaries for the day" do
      cache_key = ["inst_llm_helper", "rate_limit", @teacher.uuid, "raw-V1_A", Time.now.utc.strftime("%Y%m%d")].cache_key
      Canvas.redis.incr(cache_key)

      allow_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)
      expect(LLMConfigs).to receive(:config_for).and_return(
        LLMConfig.new(
          name: "raw-V1_A",
          model_id: "model",
          rate_limit: { limit: 1, period: "day" },
          template: "<CONTENT_PLACEHOLDER>"
        )
      )
      expect(LLMConfigs).to receive(:config_for).and_return(
        LLMConfig.new(
          name: "refined-V1_A",
          model_id: "model",
          template: "<CONTENT_PLACEHOLDER>"
        )
      )

      get "summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id, userInput: "rejected by rate limit" }, format: "json"

      expect(response.status).to eq(429)
      expect(response.parsed_body["error"]).to include("1")
    end

    it "returns an error if the user can't summarize" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(false)

      get "summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_unauthorized
    end

    it "returns an error if there is no llm config" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)
      expect(LLMConfigs).to receive(:config_for).and_return(nil)
      expect(LLMConfigs).to receive(:config_for).and_return(nil)

      get "summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_unprocessable
    end
  end

  context "summary_feedback" do
    before do
      course_with_teacher(active_course: true)
      @topic = @course.discussion_topics.create!(title: "discussion")
      @raw_summary = @topic.summaries.create!(
        summary: "summary",
        dynamic_content_hash: Digest::SHA256.hexdigest({
          CONTENT: DiscussionTopic::PromptPresenter.new(@topic).content_for_summary,
          FOCUS: DiscussionTopic::PromptPresenter.focus_for_summary(user_input: "student feedback"),
        }.to_json),
        llm_config_version: "raw-V1_A",
        user: @teacher
      )
      @refined_summary = @topic.summaries.create!(
        summary: "summary",
        dynamic_content_hash: Digest::SHA256.hexdigest({
          CONTENT: DiscussionTopic::PromptPresenter.raw_summary_for_refinement(raw_summary: @raw_summary.summary),
          FOCUS: DiscussionTopic::PromptPresenter.focus_for_summary(user_input: "student feedback"),
          LOCALE: "English (United States)"
        }.to_json),
        llm_config_version: "refined-V1_A",
        parent: @raw_summary,
        locale: "en",
        user: @teacher
      )

      user_session(@teacher)
    end

    it "returns an error if the user can't summarize" do
      allow_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(false)

      post "summary_feedback", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id, summary_id: @refined_summary.id, _action: "like" }, format: "json"

      expect(response).to be_unauthorized
    end

    it "returns an error if the summary is not found" do
      allow_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)

      post "summary_feedback", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id, summary_id: 0, _action: "like" }, format: "json"

      expect(response).to be_not_found
    end

    it "returns an error if the action is invalid" do
      allow_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)

      post "summary_feedback", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id, summary_id: @refined_summary.id, _action: "invalid" }, format: "json"

      expect(response).to be_bad_request
    end

    it "returns an error if the summary does not belong to the topic" do
      allow_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)
      another_topic = @course.discussion_topics.create!(title: "discussion")

      post "summary_feedback", params: { topic_id: another_topic.id, course_id: @course.id, user_id: @teacher.id, summary_id: @refined_summary.id, _action: "like" }, format: "json"

      expect(response).to be_not_found
    end

    it "creates feedback" do
      allow_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)

      post "summary_feedback", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id, summary_id: @refined_summary.id, _action: "like" }, format: "json"

      expect(response).to be_successful
      expect(response.parsed_body["liked"]).to be_truthy
      expect(response.parsed_body["disliked"]).to be_falsey
    end
  end

  context "disable_summary" do
    before do
      course_with_teacher(active_course: true)
      @topic = @course.discussion_topics.create!(title: "discussion")
      user_session(@teacher)
    end

    it "returns an error if the user can't summarize" do
      allow_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(false)

      put "disable_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_unauthorized
    end

    it "disables the summary" do
      allow_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)
      @topic.update!(summary_enabled: true)

      put "disable_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_successful
      expect(@topic.reload.summary_enabled).to be_falsey
    end
  end

  context "mark_all_topic_read" do
    before do
      course_with_teacher(active_course: true)
      user_session(@teacher)
    end

    it "marks all topic read, but not the announcements" do
      topic1 = @course.discussion_topics.create!(title: "discussion")
      topic2 = @course.discussion_topics.create!(title: "discussion", unlock_at: 1.day.ago)
      announcement1 = @course.announcements.create!(title: "announcement", message: "test")
      # announcement is a discussion topic

      expect(topic1.reload.read_state(@teacher)).to eq("unread")
      expect(topic2.reload.read_state(@teacher)).to eq("unread")
      expect(announcement1.reload.read_state(@teacher)).to eq("unread")

      put "mark_all_topic_read", params: { course_id: @course.id }, format: "json"

      expect(response).to be_successful
      expect(topic1.reload.read_state(@teacher)).to eq("read")
      expect(topic2.reload.read_state(@teacher)).to eq("read")
      expect(announcement1.reload.read_state(@teacher)).to eq("unread")
    end

    it "does not mark unpublished topics read" do
      topic = @course.discussion_topics.create!(title: "discussion", workflow_state: "unpublished")
      expect(topic.reload.read_state(@teacher)).to eq("unread")

      put "mark_all_topic_read", params: { course_id: @course.id }, format: "json"

      expect(response).to be_successful
      expect(topic.reload.read_state(@teacher)).to eq("unread")
    end

    it "marks announcements read if only_announcements is true" do
      announcement1 = @course.announcements.create!(title: "announcement", message: "test")
      announcement2 = @course.announcements.create!(title: "announcement", message: "test", unlock_at: 1.day.ago)
      topic1 = @course.discussion_topics.create!(title: "discussion")

      expect(announcement1.reload.read_state(@teacher)).to eq("unread")
      expect(announcement2.reload.read_state(@teacher)).to eq("unread")
      expect(topic1.reload.read_state(@teacher)).to eq("unread")

      put "mark_all_topic_read", params: { course_id: @course.id, only_announcements: true }, format: "json"

      expect(response).to be_successful
      expect(announcement1.reload.read_state(@teacher)).to eq("read")
      expect(announcement2.reload.read_state(@teacher)).to eq("read")
      expect(topic1.reload.read_state(@teacher)).to eq("unread")
    end

    it "does not mark a topic read if the unlock_at is in the future" do
      topic = @course.discussion_topics.create!(title: "discussion", unlock_at: 1.day.from_now)

      expect(topic.reload.read_state(@teacher)).to eq("unread")

      put "mark_all_topic_read", params: { course_id: @course.id }, format: "json"

      expect(response).to be_successful
      expect(topic.reload.read_state(@teacher)).to eq("unread")
    end
  end
end
