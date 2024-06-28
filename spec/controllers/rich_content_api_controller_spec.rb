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

describe RichContentApiController do
  context "generate" do
    before do
      course_with_teacher(active_course: true)
      @teacher.account.enable_feature!(:ai_text_tools)

      @inst_llm = double("InstLLM::Client")
      allow(InstLLMHelper).to receive(:client).and_return(@inst_llm)

      user_session(@teacher)
    end

    context "with llm config" do
      before do
        expect(LLMConfigs).to receive(:config_for).and_return(
          LLMConfig.new(
            name: "rich_content_generate",
            model_id: "model",
            template: ""
          )
        )
        expect(LLMConfigs).to receive(:config_for).and_return(
          LLMConfig.new(
            name: "rich_content_modify",
            model_id: "model",
            template: "<CONTENT_PLACEHOLDER> <PROMPT_PLACEHOLDER>"
          )
        )
      end

      context "generate new text" do
        it "generates text for the prompt" do
          expect(@inst_llm).to receive(:chat).and_return(
            InstLLM::Response::ChatResponse.new(
              model: "model",
              message: { role: :assistant, content: "pandas" },
              stop_reason: "stop_reason",
              usage: {
                input_tokens: 10,
                output_tokens: 20,
              }
            )
          )

          post "generate", params: { course_id: @course.id, prompt: "I need info on pandas", type_of_request: "generate" }, format: "json"

          expect(response).to be_successful
          expect(response.parsed_body["content"]).to eq("pandas")
        end
      end
    end

    it "returns rate limit exceeded error if the user has reached the max number of summaries for the day" do
      cache_key = ["inst_llm_helper", "rate_limit", @teacher.uuid, "rich_content_generate", Time.now.utc.strftime("%Y%m%d")].cache_key
      Canvas.redis.incr(cache_key)

      expect(LLMConfigs).to receive(:config_for).and_return(
        LLMConfig.new(
          name: "rich_content_generate",
          model_id: "model",
          rate_limit: { limit: 1, period: "day" },
          template: ""
        )
      )
      expect(LLMConfigs).to receive(:config_for).and_return(
        LLMConfig.new(
          name: "rich_content_modify",
          model_id: "model",
          template: "<CONTENT_PLACEHOLDER> <PROMPT_PLACEHOLDER>"
        )
      )

      post "generate", params: { course_id: @course.id, prompt: "bad input", type_of_request: "generate" }, format: "json"

      expect(response.status).to eq(429)
      expect(response.parsed_body["error"]).to include("1")
    end

    it "returns an error if the user can't summarize" do
      student_in_course(active_all: true, course: @course)
      user_session(@student)

      post "generate", params: { course_id: @course.id, prompt: "nope", type_of_request: "generate" }, format: "json"

      expect(response).to be_unauthorized
    end

    it "returns an error if there is no llm config" do
      expect(LLMConfigs).to receive(:config_for).and_return(nil)
      expect(LLMConfigs).to receive(:config_for).and_return(nil)

      post "generate", params: { course_id: @course.id, prompt: "no config", type_of_request: "generate" }, format: "json"

      expect(response).to be_unprocessable
    end
  end
end
