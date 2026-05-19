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

describe StudyAssistController do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @course.enable_feature!(:study_assist)
    @page = @course.wiki_pages.create!(title: "Photosynthesis", body: "<p>Plants convert sunlight into energy.</p>")
  end

  before do
    allow(CedarClient).to receive(:enabled?).and_return(true)
    user_session(@student)
  end

  describe "POST #create" do
    context "authorization" do
      it "returns 401 when not logged in" do
        remove_user_session
        post :create, params: { course_id: @course.id, prompt: "" }, format: :json
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns 404 when study_assist feature flag is off" do
        @course.disable_feature!(:study_assist)
        post :create, params: { course_id: @course.id, prompt: "" }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it "returns forbidden for a non-student (teacher)" do
        user_session(@teacher)
        post :create, params: { course_id: @course.id, prompt: "" }, format: :json
        expect(response).to have_http_status(:forbidden)
      end

      it "returns 503 when Cedar is disabled" do
        allow(CedarClient).to receive(:enabled?).and_return(false)
        post :create, params: { course_id: @course.id, prompt: "" }, format: :json
        expect(response).to have_http_status(:service_unavailable)
      end
    end

    context "request validation" do
      it "rejects a prompt over 2KB" do
        post :create,
             params: { course_id: @course.id, prompt: "x" * (2.kilobytes + 1) },
             format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "rejects when state.courseID does not match path course_id" do
        post :create,
             params: { course_id: @course.id, prompt: "Summarize", state: { courseID: "99999", pageID: @page.url } },
             format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "no-prompt chips flow" do
      it "returns enabled chips when all tool flags are on" do
        post :create, params: { course_id: @course.id, prompt: "" }, format: :json
        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["chips"].pluck("chip")).to eq(["Summarize", "Quiz me", "Flashcards"])
      end

      it "filters out disabled tools" do
        @course.disable_feature!(:study_assist_quiz_me)
        post :create, params: { course_id: @course.id }, format: :json
        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["chips"].pluck("chip")).to eq(["Summarize", "Flashcards"])
      end
    end

    context "unsupported prompt" do
      it "returns 422 for free-form chat" do
        post :create,
             params: { course_id: @course.id, prompt: "What is the mitochondria?" },
             format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "tool prompt flow" do
      let(:summary_json) { "A concise summary." }

      before do
        stub_const("CedarClient", Class.new do
          class << self
            attr_accessor :prompt_results
          end
          self.prompt_results = []

          def self.prompt(*)
            value = (prompt_results.size > 1) ? prompt_results.shift : prompt_results.first
            raise value if value.is_a?(Exception)

            value
          end

          def self.enabled?
            true
          end
        end)
        CedarClient.prompt_results = [Struct.new(:response, :response_id).new(summary_json, "r1")]
      end

      it "dispatches summarize prompt and returns response" do
        post :create,
             params: { course_id: @course.id, prompt: "Summarize", state: { courseID: @course.id.to_s, pageID: @page.url } },
             format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["response"]).to eq("A concise summary.")
      end

      it "returns forbidden when the specific tool flag is disabled" do
        @course.disable_feature!(:study_assist_summarize)
        post :create,
             params: { course_id: @course.id, prompt: "Summarize", state: { courseID: @course.id.to_s, pageID: @page.url } },
             format: :json
        expect(response).to have_http_status(:forbidden)
      end

      it "returns 422 when state has no pageID or fileID" do
        post :create,
             params: { course_id: @course.id, prompt: "Summarize", state: { courseID: @course.id.to_s } },
             format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns 422 for unsupported file type" do
        attachment = attachment_model(context: @course, content_type: "image/png", filename: "img.png")
        post :create,
             params: { course_id: @course.id, prompt: "Summarize", state: { courseID: @course.id.to_s, fileID: attachment.id } },
             format: :json
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "bypasses LLM response cache when regenerate=true" do
        allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
        expect(CedarClient).to receive(:prompt).twice.and_call_original
        2.times do
          post :create,
               params: { course_id: @course.id, prompt: "Summarize", regenerate: true, state: { courseID: @course.id.to_s, pageID: @page.url } },
               format: :json
        end
      end

      it "returns 429 when Cedar rate limit is reached" do
        CedarClient.prompt_results = [
          InstructureMiscPlugin::Extensions::CedarClient::CedarLimitReachedError.new("limit")
        ]
        post :create,
             params: { course_id: @course.id, prompt: "Summarize", state: { courseID: @course.id.to_s, pageID: @page.url } },
             format: :json
        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end
end
