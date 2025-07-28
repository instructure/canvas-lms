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

  context "find_summary" do
    before do
      course_with_teacher(active_course: true)
      @course.account.update!(default_locale: "hu")

      @topic = @course.discussion_topics.create!(title: "discussion", summary_enabled: true)
      user_session(@teacher)
    end

    context "when the user can summarize the topic" do
      before do
        expect_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)
      end

      context "and config does not exist" do
        before do
          expect(LLMConfigs).to receive(:config_for).and_return(nil)
        end

        it "returns an error if there is no llm config" do
          get "find_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

          expect(response).to be_unprocessable
        end
      end

      context "and config exists" do
        before do
          expect(LLMConfigs).to receive(:config_for).and_return(
            LLMConfig.new(
              name: "raw-V1_A",
              model_id: "model",
              template: "<CONTENT_PLACEHOLDER>",
              rate_limit: { limit: 25, period: "day" }
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

        context "and a summary exists" do
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
                LOCALE: "Magyar"
              }.to_json),
              llm_config_version: "refined-V1_A",
              parent: @raw_summary,
              locale: "hu",
              user: @teacher
            )
          end

          it "returns the most recent summary and usage information for the user" do
            allow(Canvas.redis).to receive(:get).and_return("5")

            get "find_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

            expect(response).to be_successful
            expect(response.parsed_body["id"]).to eq(@refined_summary.id)
            expect(response.parsed_body["usage"]).to eq({ "currentCount" => 5, "limit" => 25 })
          end

          context "and the generated hash is different than the stored one" do
            before do
              allow(Digest::SHA256).to receive(:hexdigest).and_return("different_hash")
            end

            it "returns obsolete as true" do
              get "find_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

              expect(response).to be_successful
              expect(response.parsed_body["obsolete"]).to be(true)
            end
          end

          context "and the generated hash is the same as the stored one" do
            it "returns obsolete as false" do
              get "find_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

              expect(response).to be_successful
              expect(response.parsed_body["obsolete"]).to be(false)
            end
          end
        end

        context "and no summary exists" do
          before do
            @refined_summary&.destroy
            @raw_summary&.destroy
          end

          it "returns an error message" do
            get "find_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"
            puts("response: #{response.body}")
            expect(response).to be_not_found
          end
        end
      end
    end

    context "when the user cannot summarize the topic" do
      before do
        expect_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(false)
      end

      it "returns an unauthorized action response" do
        get "find_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

        expect(response).to be_forbidden
      end
    end
  end

  context "find_or_create_summary" do
    before do
      course_with_teacher(active_course: true)
      @course.account.update!(default_locale: "hu")

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
            template: "<CONTENT_PLACEHOLDER>",
            rate_limit: { limit: 11, period: "day" }
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
              LOCALE: "Magyar"
            }.to_json),
            llm_config_version: "refined-V1_A",
            parent: @raw_summary,
            locale: "hu",
            user: @teacher
          )
        end

        it "returns the existing summary" do
          expect_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)

          expect(@inst_llm).not_to receive(:chat)

          post "find_or_create_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

          expect(response).to be_successful
          expect(response.parsed_body["id"]).to eq(@refined_summary.id)
        end

        it "returns a new summary if locale is different" do
          expect_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)
          @teacher.update!(locale: "en")

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

          post "find_or_create_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

          expect(response).to be_successful
          expect(response.parsed_body["id"]).not_to eq(@refined_summary.id)
        end
      end

      it "returns a new summary with usage" do
        expect_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)
        allow(Canvas.redis).to receive(:get).and_return("5")

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

        post "find_or_create_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

        expect(response).to be_successful
        expect(response.parsed_body["usage"]).to eq({ "currentCount" => 5, "limit" => 11 })
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

        post "find_or_create_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

        expect(response).to be_successful
        expect(@topic.reload.summary_enabled).to be_truthy
      end
    end

    it "returns an error if the user has reached the maximum number of summaries for the day" do
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

      post "find_or_create_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id, userInput: "rejected by rate limit" }, format: "json"

      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body["error"]).to include("1")
    end

    it "returns an error if the user can't summarize" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(false)

      post "find_or_create_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_forbidden
    end

    it "returns an error if there is no llm config" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)
      expect(LLMConfigs).to receive(:config_for).and_return(nil)

      post "find_or_create_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

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

      expect(response).to be_forbidden
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

      expect(response).to be_forbidden
    end

    it "disables the summary" do
      allow_any_instance_of(DiscussionTopic).to receive(:user_can_summarize?).and_return(true)
      @topic.update!(summary_enabled: true)

      put "disable_summary", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_successful
      expect(@topic.reload.summary_enabled).to be_falsey
    end
  end

  context "insight" do
    before do
      course_with_teacher(active_course: true)
      @topic = @course.discussion_topics.create!(title: "discussion")
      user_session(@teacher)
    end

    it "returns an error if the user can't access insights" do
      allow_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(false)

      get "insight", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_forbidden
    end

    it "returns workflow_state nil, if the insight is not found" do
      allow_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(true)

      get "insight", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_successful
      expect(response.parsed_body).to eq({ "workflow_state" => nil })
    end

    it "returns created insight" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(true)

      @topic.insights.create!(user: @teacher, workflow_state: "created")

      get "insight", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_successful
      expect(response.parsed_body).to eq({ "workflow_state" => "created" })
    end

    it "returns in_progress insight" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(true)

      @topic.insights.create!(user: @teacher, workflow_state: "in_progress")

      get "insight", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_successful
      expect(response.parsed_body).to eq({ "workflow_state" => "in_progress" })
    end

    it "returns failed insight" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(true)

      student = user_factory(active_all: true)
      @course.enroll_student(student, enrollment_state: "active")

      @topic.insights.create!(user: @teacher, workflow_state: "failed")
      @topic.discussion_entries.create!(message: "message", user: student)

      get "insight", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_successful
      expect(response.parsed_body).to eq({ "workflow_state" => "failed", "needs_processing" => true })
    end

    it "returns completed insight" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(true)

      @topic.insights.create!(user: @teacher, workflow_state: "completed")

      get "insight", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_successful
      expect(response.parsed_body).to eq({ "workflow_state" => "completed", "needs_processing" => false })
    end
  end

  context "insight_generation" do
    before do
      course_with_teacher(active_course: true)

      @topic = @course.discussion_topics.create!(title: "discussion")

      user_session(@teacher)
    end

    it "returns an error if the user can't access insights" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(false)

      post "insight_generation", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_forbidden
    end

    it "creates an insight and submits a job" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(true)
      expect_any_instance_of(DiscussionTopicInsight).to receive(:delay).and_return(double("DelayedJob", generate: nil))

      post "insight_generation", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_successful
      expect(@topic.insights.count).to eq(1)
      expect(@topic.insights.first.workflow_state).to eq("created")
    end

    it "returns an error if submitting the job fails" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(true)
      expect_any_instance_of(DiscussionTopicInsight).to receive(:delay).and_raise("error")

      post "insight_generation", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_unprocessable
      expect(@topic.insights.count).to eq(0)
    end
  end

  context "insight_entries" do
    before do
      course_with_teacher(active_course: true)

      @topic = @course.discussion_topics.create!(title: "discussion")

      user_session(@teacher)
    end

    it "returns an error if the user can't access insights" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(false)

      get "insight_entries", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_forbidden
    end

    it "returns an empty array if there are no insights" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(true)

      get "insight_entries", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_successful
      expect(response.parsed_body).to eq([])
    end

    it "returns the insight entries" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(true)

      insight = @topic.insights.create!(user: @teacher, workflow_state: "completed")

      entry_1 = @topic.discussion_entries.create!(message: "message_1", user: @teacher)
      insight_entry_1 = insight.entries.create!(
        discussion_topic: @topic,
        discussion_entry: entry_1,
        discussion_entry_version: entry_1.discussion_entry_versions.first,
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

      entry_2 = @topic.discussion_entries.create!(message: "message_2", user: @teacher)
      insight_entry_2 = insight.entries.create!(
        discussion_topic: @topic,
        discussion_entry: entry_2,
        discussion_entry_version: entry_2.discussion_entry_versions.first,
        locale: "en",
        dynamic_content_hash: "hash_2",
        ai_evaluation: {
          "relevance_classification" => "irrelevant",
          "confidence" => 4,
          "notes" => "notes_2"
        },
        ai_evaluation_human_reviewer: @teacher,
        ai_evaluation_human_feedback_liked: true,
        ai_evaluation_human_feedback_disliked: false,
        ai_evaluation_human_feedback_notes: "notes"
      )

      get "insight_entries", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id }, format: "json"

      expect(response).to be_successful
      expect(response.parsed_body.count).to eq(2)
      # TODO: assert better when we finalize the response format
      expect(response.parsed_body.map { |entry| entry["id"] }).to match_array([insight_entry_1.id, insight_entry_2.id])
    end
  end

  context "insight_entry_update" do
    before do
      course_with_teacher(active_course: true)

      @topic = @course.discussion_topics.create!(title: "discussion")
      insight = @topic.insights.create!(user: @teacher, workflow_state: "completed")
      entry = @topic.discussion_entries.create!(message: "message", user: @teacher)
      @insight_entry = insight.entries.create!(
        discussion_topic: @topic,
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

      user_session(@teacher)
      allow(InstStatsd::Statsd).to receive(:distributed_increment)
    end

    it "returns an error if the user can't access insights" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(false)

      put "insight_entry_update", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id, entry_id: @insight_entry.id, relevance_human_feedback_action: "like", relevance_human_feedback_notes: "notes" }, format: "json"

      expect(response).to be_forbidden
    end

    it "returns an error if the entry is not found" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(true)

      put "insight_entry_update", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id, entry_id: 0 }, format: "json"

      expect(response).to be_not_found
    end

    it "returns an error if the action is invalid" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(true)

      put "insight_entry_update", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id, entry_id: @insight_entry.id, relevance_human_feedback_action: "invalid" }, format: "json"

      puts response.body
      puts response.status
      expect(response).to be_bad_request
    end

    it "returns an error if the notes are missing" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(true)

      put "insight_entry_update", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id, entry_id: @insight_entry.id, relevance_human_feedback_action: "like" }, format: "json"

      expect(response).to be_bad_request
    end

    it "dislike the insight entry" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(true)

      put "insight_entry_update", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id, entry_id: @insight_entry.id, relevance_human_feedback_action: "dislike", relevance_human_feedback_notes: "new notes" }, format: "json"

      expect(response).to be_successful

      @insight_entry.reload
      expect(@insight_entry.ai_evaluation_human_reviewer).to eq(@teacher)
      expect(@insight_entry.ai_evaluation_human_feedback_liked).to be_falsey
      expect(@insight_entry.ai_evaluation_human_feedback_disliked).to be_truthy
      expect(@insight_entry.ai_evaluation_human_feedback_notes).to eq("new notes")
      expect(InstStatsd::Statsd).to have_received(:distributed_increment).with("discussion_topic.insight.entry_disliked").at_least(:once)
    end

    it "like the insight entry" do
      expect_any_instance_of(DiscussionTopic).to receive(:user_can_access_insights?).and_return(true)

      put "insight_entry_update", params: { topic_id: @topic.id, course_id: @course.id, user_id: @teacher.id, entry_id: @insight_entry.id, relevance_human_feedback_action: "like", relevance_human_feedback_notes: "nice" }, format: "json"

      expect(response).to be_successful

      @insight_entry.reload
      expect(@insight_entry.ai_evaluation_human_reviewer).to eq(@teacher)
      expect(@insight_entry.ai_evaluation_human_feedback_liked).to be_truthy
      expect(@insight_entry.ai_evaluation_human_feedback_disliked).to be_falsey
      expect(@insight_entry.ai_evaluation_human_feedback_notes).to eq("nice")
      expect(InstStatsd::Statsd).to have_received(:distributed_increment).with("discussion_topic.insight.entry_liked").at_least(:once)
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

  context "migrate_disallow" do
    before do
      course_with_teacher(active_all: true)
      @topic = @course.discussion_topics.create!(title: "discussion", discussion_type: "side_comment")
      user_session(@teacher)
    end

    it "should return 404 if feature flag is not turned on" do
      put "migrate_disallow", params: { course_id: @course.id }
      expect(response).to be_not_found
    end

    it "should update the discussion type to 'threaded' if the feature flag is turned on" do
      allow(Account.site_admin).to receive(:feature_enabled?).and_return(true)

      put "migrate_disallow", params: { course_id: @course.id }

      expect(response).to be_successful
      expect(@topic.reload.discussion_type).to eq("threaded")
    end

    it "should not update the discussion type for announcements" do
      allow(Account.site_admin).to receive(:feature_enabled?).and_return(true)
      announcement = @course.announcements.create!(title: "announcement", message: "test", discussion_type: "side_comment")

      put "migrate_disallow", params: { course_id: @course.id }

      expect(response).to be_successful
      expect(announcement.reload.discussion_type).to eq("side_comment")
    end
  end

  context "update_discussion_types" do
    before do
      course_with_teacher(active_all: true)
    end

    it "should update the discussions types to 'threaded' and 'not_threaded' according to the parameters" do
      allow(Account.site_admin).to receive(:feature_enabled?).and_return(true)
      user_session(@teacher)
      topic1 = @course.discussion_topics.create!(title: "discussion1", discussion_type: "side_comment")
      topic2 = @course.discussion_topics.create!(title: "discussion2", discussion_type: "side_comment")

      put "update_discussion_types", params: { course_id: @course.id, threaded: [topic1.id], not_threaded: [topic2.id] }, format: "json"

      expect(response).to be_successful
      expect(topic1.reload.discussion_type).to eq("threaded")
      expect(topic2.reload.discussion_type).to eq("not_threaded")
    end

    it "should return an error if the discussion type is not side_comment" do
      allow(Account.site_admin).to receive(:feature_enabled?).and_return(true)
      user_session(@teacher)
      topic1 = @course.discussion_topics.create!(title: "discussion1", discussion_type: "threaded")
      topic2 = @course.discussion_topics.create!(title: "discussion2", discussion_type: "side_comment")

      put "update_discussion_types", params: { course_id: @course.id, threaded: [topic1.id], not_threaded: [topic2.id] }, format: "json"

      expect(response).to have_http_status(:bad_request)
      expect(topic1.reload.discussion_type).to eq("threaded")
      expect(topic2.reload.discussion_type).to eq("side_comment")
    end

    it "should throw an error if the user doesn't have the right to modify it" do
      allow(Account.site_admin).to receive(:feature_enabled?).and_return(true)
      student_in_course(active_all: true, course: @course)
      user_session(@student)
      topic1 = @course.discussion_topics.create!(title: "discussion1", discussion_type: "side_comment")
      put "update_discussion_types", params: { course_id: @course.id, threaded: [topic1.id], not_threaded: [] }, format: "json"

      expect(response).to have_http_status(:forbidden)
      expect(topic1.reload.discussion_type).to eq("side_comment")
    end

    it "should throw a 404 if the feature is not enabled" do
      user_session(@teacher)
      topic1 = @course.discussion_topics.create!(title: "discussion1", discussion_type: "side_comment")
      put "update_discussion_types", params: { course_id: @course.id, threaded: [topic1.id], not_threaded: [] }, format: "json"

      expect(response).to be_not_found
      expect(topic1.reload.discussion_type).to eq("side_comment")
    end
  end
end
