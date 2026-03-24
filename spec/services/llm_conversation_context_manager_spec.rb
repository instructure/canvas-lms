# frozen_string_literal: true

#
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
#

require "webmock/rspec"

describe LLMConversationContextManager do
  let(:course) { course_model }
  let(:ai_experience) do
    # Create without running callbacks to avoid automatic context creation
    AiExperience.create!(
      course:,
      title: "Test Experience",
      pedagogical_guidance: "Test scenario",
      facts: "Test facts",
      learning_objective: "Test objectives"
    ) do |exp|
      exp.define_singleton_method(:create_conversation_context) {} # Stub callback
    end
  end

  before do
    Setting.set("llm_conversation_base_url", "http://localhost:3001")
    allow(Rails.application.credentials).to receive(:llm_conversation_bearer_token).and_return("test-token")
  end

  describe ".create_context" do
    let(:prompt_response) do
      {
        "success" => true,
        "data" => {
          "id" => "prompt-uuid",
          "code" => "alpha",
          "content" => "System prompt",
          "version" => 1
        }
      }
    end

    let(:create_context_response) do
      {
        "success" => true,
        "data" => {
          "id" => "context-uuid",
          "type" => "assignment",
          "data" => {
            "scenario" => "Test scenario",
            "facts" => "Test facts",
            "learning_objectives" => "Test objectives"
          },
          "prompt_id" => "prompt-uuid"
        }
      }
    end

    before do
      stub_request(:get, "http://localhost:3001/prompts/by-code/alpha")
        .with(headers: { "Authorization" => "Bearer test-token" })
        .to_return(status: 200, body: prompt_response.to_json, headers: { "Content-Type" => "application/json" })

      stub_request(:post, "http://localhost:3001/conversation-context")
        .with(
          headers: { "Authorization" => "Bearer test-token" },
          body: hash_including(
            "type" => "assignment",
            "prompt_id" => "prompt-uuid",
            "data" => hash_including(
              "scenario" => "Test scenario",
              "facts" => "Test facts",
              "learning_objectives" => "Test objectives"
            )
          )
        )
        .to_return(status: 200, body: create_context_response.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "creates a conversation context and stores the ID" do
      context_id = described_class.create_context(ai_experience:)

      expect(context_id).to eq("context-uuid")
      expect(ai_experience.reload.llm_conversation_context_id).to eq("context-uuid")
    end

    it "looks up prompt by code before creating context" do
      described_class.create_context(ai_experience:)

      expect(WebMock).to have_requested(:get, "http://localhost:3001/prompts/by-code/alpha")
        .with(headers: { "Authorization" => "Bearer test-token" })
    end

    it "sends correct payload to API" do
      described_class.create_context(ai_experience:)

      expect(WebMock).to have_requested(:post, "http://localhost:3001/conversation-context")
        .with(
          body: hash_including(
            "type" => "assignment",
            "prompt_id" => "prompt-uuid",
            "data" => hash_including(
              "scenario" => "Test scenario",
              "facts" => "Test facts",
              "learning_objectives" => "Test objectives"
            )
          )
        )
    end

    it "does not create context if one already exists" do
      ai_experience.update_column(:llm_conversation_context_id, "existing-id")

      context_id = described_class.create_context(ai_experience:)

      expect(context_id).to be_nil
      expect(WebMock).not_to have_requested(:post, "http://localhost:3001/conversation-context")
    end

    it "raises ConversationError when prompt lookup fails" do
      stub_request(:get, "http://localhost:3001/prompts/by-code/alpha")
        .to_return(status: 404, body: "Not Found")

      expect do
        described_class.create_context(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError, /Failed to get prompt by code/)
    end

    it "raises ConversationError when API call fails" do
      stub_request(:post, "http://localhost:3001/conversation-context")
        .to_return(status: 500, body: "Internal Server Error")

      expect do
        described_class.create_context(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError, /Failed to create conversation context/)
    end

    it "raises ConversationError when bearer token is missing" do
      allow(Rails.application.credentials).to receive(:llm_conversation_bearer_token).and_return(nil)

      expect do
        described_class.create_context(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError, /llm_conversation_bearer_token not found/)
    end
  end

  describe ".update_context" do
    let(:update_context_response) do
      {
        "success" => true,
        "data" => {
          "id" => "context-uuid",
          "type" => "assignment",
          "data" => {
            "scenario" => "Updated scenario",
            "facts" => "Updated facts",
            "learning_objectives" => "Updated objectives"
          }
        }
      }
    end

    before do
      ai_experience.update_column(:llm_conversation_context_id, "context-uuid")

      stub_request(:patch, "http://localhost:3001/conversation-context/context-uuid")
        .with(
          headers: { "Authorization" => "Bearer test-token" },
          body: hash_including(
            "data" => hash_including(
              "scenario" => "Test scenario",
              "facts" => "Test facts",
              "learning_objectives" => "Test objectives"
            )
          )
        )
        .to_return(status: 200, body: update_context_response.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "updates the conversation context" do
      expect do
        described_class.update_context(ai_experience:)
      end.not_to raise_error

      expect(WebMock).to have_requested(:patch, "http://localhost:3001/conversation-context/context-uuid")
    end

    it "does not update if context_id is not set" do
      ai_experience.update_column(:llm_conversation_context_id, nil)

      described_class.update_context(ai_experience:)

      expect(WebMock).not_to have_requested(:patch, %r{http://localhost:3001/conversation-context/})
    end

    it "raises ConversationError when API call fails" do
      stub_request(:patch, "http://localhost:3001/conversation-context/context-uuid")
        .to_return(status: 404, body: "Not Found")

      expect do
        described_class.update_context(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError, /Failed to update conversation context/)
    end

    context "with ai_experiences_context_file_upload feature flag enabled" do
      let(:attachment) { attachment_model(context: course, size: 1.megabyte, filename: "syllabus.pdf") }

      before do
        course.enable_feature!(:ai_experiences_context_file_upload)
        AiExperienceContextFile.create!(ai_experience:, attachment:)
        allow(attachment).to receive(:public_url).and_return("https://example.com/syllabus.pdf")

        stub_request(:patch, "http://localhost:3001/conversation-context/context-uuid")
          .to_return(status: 200, body: update_context_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "sends context_files in PINE-compatible format" do
        described_class.update_context(ai_experience:)

        expect(WebMock).to have_requested(:patch, "http://localhost:3001/conversation-context/context-uuid")
          .with(body: hash_including(
            "data" => hash_including(
              "context_files" => [
                hash_including(
                  "source" => "canvas",
                  "sourceType" => "file",
                  "sourceId" => "file-#{attachment.global_id}"
                )
              ]
            )
          ))
      end

      it "uses global_id for courseId in metadata" do
        described_class.update_context(ai_experience:)

        expect(WebMock).to have_requested(:patch, "http://localhost:3001/conversation-context/context-uuid")
          .with(body: hash_including(
            "data" => hash_including(
              "context_files" => [
                hash_including(
                  "metadata" => hash_including(
                    "courseId" => course.global_id.to_s,
                    "title" => attachment.display_name
                  )
                )
              ]
            )
          ))
      end

      it "excludes deleted attachments from context_files" do
        attachment.update_column(:file_state, "deleted")

        described_class.update_context(ai_experience:)

        expect(WebMock).to have_requested(:patch, "http://localhost:3001/conversation-context/context-uuid")
          .with(body: hash_including(
            "data" => hash_including("context_files" => [])
          ))
      end
    end
  end

  describe ".delete_context" do
    before do
      ai_experience.update_column(:llm_conversation_context_id, "context-uuid")

      stub_request(:delete, "http://localhost:3001/conversation-context/context-uuid")
        .with(headers: { "Authorization" => "Bearer test-token" })
        .to_return(status: 200, body: { "success" => true }.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "deletes the conversation context and clears the ID" do
      described_class.delete_context(ai_experience:)

      expect(WebMock).to have_requested(:delete, "http://localhost:3001/conversation-context/context-uuid")
      expect(ai_experience.reload.llm_conversation_context_id).to be_nil
    end

    it "does not delete if context_id is not set" do
      ai_experience.update_column(:llm_conversation_context_id, nil)

      described_class.delete_context(ai_experience:)

      expect(WebMock).not_to have_requested(:delete, %r{http://localhost:3001/conversation-context/})
    end

    it "raises ConversationError when API call fails" do
      stub_request(:delete, "http://localhost:3001/conversation-context/context-uuid")
        .to_return(status: 500, body: "Internal Server Error")

      expect do
        described_class.delete_context(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError, /Failed to delete conversation context/)
    end
  end

  describe ".sync_index_status" do
    let(:documents_url) { "http://localhost:3001/contexts/context-uuid/documents" }

    before do
      ai_experience.update_column(:llm_conversation_context_id, "context-uuid")
      course.enable_feature!(:ai_experiences_context_file_upload)
    end

    context "when context_id is not present" do
      before { ai_experience.update_column(:llm_conversation_context_id, nil) }

      it "returns nil without making a request" do
        described_class.sync_index_status(ai_experience:)
        expect(WebMock).not_to have_requested(:get, documents_url)
      end
    end

    context "when feature flag is disabled" do
      before { course.disable_feature!(:ai_experiences_context_file_upload) }

      it "returns nil without making a request" do
        described_class.sync_index_status(ai_experience:)
        expect(WebMock).not_to have_requested(:get, documents_url)
      end
    end

    context "when documents list is empty" do
      before do
        stub_request(:get, documents_url)
          .to_return(status: 200, body: { "documents" => [] }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "does not update context_index_status" do
        expect do
          described_class.sync_index_status(ai_experience:)
        end.not_to change { ai_experience.reload.context_index_status }
      end
    end

    context "when all documents are completed" do
      before do
        stub_request(:get, documents_url)
          .to_return(status: 200,
                     body: {
                       "documents" => [
                         { "id" => "doc-1", "status" => "completed" },
                         { "id" => "doc-2", "status" => "completed" }
                       ]
                     }.to_json,
                     headers: { "Content-Type" => "application/json" })
      end

      it "updates context_index_status to 'completed'" do
        described_class.sync_index_status(ai_experience:)
        expect(ai_experience.reload.context_index_status).to eq("completed")
      end

      it "returns 'completed'" do
        expect(described_class.sync_index_status(ai_experience:)).to eq("completed")
      end
    end

    context "when any document has failed" do
      before do
        stub_request(:get, documents_url)
          .to_return(status: 200,
                     body: {
                       "documents" => [
                         { "id" => "doc-1", "status" => "completed" },
                         { "id" => "doc-2", "status" => "failed" }
                       ]
                     }.to_json,
                     headers: { "Content-Type" => "application/json" })
      end

      it "updates context_index_status to 'failed'" do
        described_class.sync_index_status(ai_experience:)
        expect(ai_experience.reload.context_index_status).to eq("failed")
      end

      it "returns 'failed'" do
        expect(described_class.sync_index_status(ai_experience:)).to eq("failed")
      end
    end

    context "when documents are still processing" do
      before do
        stub_request(:get, documents_url)
          .to_return(status: 200,
                     body: {
                       "documents" => [
                         { "id" => "doc-1", "status" => "completed" },
                         { "id" => "doc-2", "status" => "pending" }
                       ]
                     }.to_json,
                     headers: { "Content-Type" => "application/json" })
      end

      it "updates context_index_status to 'processing'" do
        described_class.sync_index_status(ai_experience:)
        expect(ai_experience.reload.context_index_status).to eq("in_progress")
      end
    end

    context "when the API call fails" do
      before do
        stub_request(:get, documents_url)
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "logs a warning and does not raise" do
        expect(Rails.logger).to receive(:warn).with(/Document index status sync failed/)
        expect { described_class.sync_index_status(ai_experience:) }.not_to raise_error
      end
    end
  end

  describe ".trigger_indexing" do
    let(:attachment) { attachment_model(context: course, filename: "syllabus.pdf") }
    let(:documents_url) { "http://localhost:3001/contexts/context-uuid/documents" }

    before do
      ai_experience.update_column(:llm_conversation_context_id, "context-uuid")
      AiExperienceContextFile.create!(ai_experience:, attachment:)
      allow_any_instance_of(Attachment).to receive(:public_url).and_return("http://localhost:3000/files/1/download")
    end

    context "when context_id is not present" do
      before { ai_experience.update_column(:llm_conversation_context_id, nil) }

      it "does not make any requests" do
        described_class.trigger_indexing(ai_experience:)
        expect(WebMock).not_to have_requested(:post, %r{/documents})
      end
    end

    context "when there are no files attached" do
      before { AiExperienceContextFile.where(ai_experience:).destroy_all }

      it "does not make any requests" do
        described_class.trigger_indexing(ai_experience:)
        expect(WebMock).not_to have_requested(:post, documents_url)
      end
    end

    context "with files attached" do
      before do
        stub_request(:post, documents_url)
          .to_return(status: 201, body: { "id" => "doc-1", "status" => "pending" }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "POSTs each file to the documents endpoint" do
        described_class.trigger_indexing(ai_experience:)

        expect(WebMock).to have_requested(:post, documents_url)
          .with(body: hash_including("url" => "http://localhost:3000/files/1/download", "sourceType" => "file"))
      end

      it "sets context_index_status to 'in_progress'" do
        described_class.trigger_indexing(ai_experience:)
        expect(ai_experience.reload.context_index_status).to eq("in_progress")
      end

      it "stores the returned document id on the context file record" do
        described_class.trigger_indexing(ai_experience:)

        context_file = AiExperienceContextFile.find_by(ai_experience:, attachment:)
        expect(context_file.llm_conversation_service_document_id).to eq("doc-1")
      end

      it "skips deleted attachments" do
        attachment.update_column(:file_state, "deleted")

        described_class.trigger_indexing(ai_experience:)

        expect(WebMock).not_to have_requested(:post, documents_url)
      end
    end

    context "with context_file_ids specified" do
      let(:attachment2) { attachment_model(context: course, filename: "slides.pdf") }
      let!(:context_file2) { AiExperienceContextFile.create!(ai_experience:, attachment: attachment2) }

      before do
        stub_request(:post, documents_url)
          .to_return(status: 201, body: { "id" => "doc-2", "status" => "pending" }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "only indexes the specified files, not all files" do
        described_class.trigger_indexing(ai_experience:, context_file_ids: [context_file2.id])

        expect(WebMock).to have_requested(:post, documents_url).once
      end
    end

    context "when the API call fails" do
      before do
        stub_request(:post, documents_url)
          .to_return(status: 503, body: "Service Unavailable")
      end

      it "raises ConversationError" do
        expect { described_class.trigger_indexing(ai_experience:) }
          .to raise_error(LlmConversation::Errors::ConversationError, /Failed to trigger indexing/)
      end
    end
  end

  describe ".remove_documents" do
    let(:attachment) { attachment_model(context: course, filename: "syllabus.pdf") }
    let(:context_file) do
      AiExperienceContextFile.create!(ai_experience:, attachment:).tap do |cf|
        cf.update_column(:llm_conversation_service_document_id, "doc-uuid-1")
      end
    end
    let(:remove_url) { "http://localhost:3001/contexts/context-uuid/documents/doc-uuid-1" }

    before do
      ai_experience.update_column(:llm_conversation_context_id, "context-uuid")
      course.enable_feature!(:ai_experiences_context_file_upload)
    end

    context "when context_id is not present" do
      before { ai_experience.update_column(:llm_conversation_context_id, nil) }

      it "does not make any requests" do
        described_class.remove_documents(ai_experience:, context_files: [context_file])
        expect(WebMock).not_to have_requested(:delete, %r{/documents/})
      end
    end

    context "when feature flag is disabled" do
      before { course.disable_feature!(:ai_experiences_context_file_upload) }

      it "does not make any requests" do
        described_class.remove_documents(ai_experience:, context_files: [context_file])
        expect(WebMock).not_to have_requested(:delete, %r{/documents/})
      end
    end

    context "with context files that have a document id" do
      before do
        stub_request(:delete, remove_url)
          .to_return(status: 200, body: { "success" => true }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "DELETEs each document from the service" do
        described_class.remove_documents(ai_experience:, context_files: [context_file])
        expect(WebMock).to have_requested(:delete, remove_url)
      end

      it "skips context files with no document id" do
        context_file.update_column(:llm_conversation_service_document_id, nil)

        described_class.remove_documents(ai_experience:, context_files: [context_file])
        expect(WebMock).not_to have_requested(:delete, %r{/documents/})
      end
    end

    context "when the API call fails" do
      before do
        stub_request(:delete, remove_url)
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "raises ConversationError" do
        expect { described_class.remove_documents(ai_experience:, context_files: [context_file]) }
          .to raise_error(LlmConversation::Errors::ConversationError)
      end
    end
  end

  describe "error handling" do
    before do
      stub_request(:get, "http://localhost:3001/prompts/by-code/alpha")
        .to_return(status: 200, body: { "success" => true, "data" => { "id" => "prompt-uuid" } }.to_json)
    end

    it "handles timeout errors" do
      stub_request(:post, "http://localhost:3001/conversation-context")
        .to_timeout

      expect do
        described_class.create_context(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError, /Failed to create conversation context/)
    end

    it "handles socket errors" do
      stub_request(:post, "http://localhost:3001/conversation-context")
        .to_raise(SocketError.new("getaddrinfo: nodename nor servname provided"))

      expect do
        described_class.create_context(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError, /Failed to create conversation context/)
    end

    it "handles JSON parse errors" do
      stub_request(:post, "http://localhost:3001/conversation-context")
        .to_return(status: 200, body: "invalid json")

      expect do
        described_class.create_context(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError, /Failed to create conversation context/)
    end
  end
end
