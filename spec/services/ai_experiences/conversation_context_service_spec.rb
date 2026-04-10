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
#

require "webmock/rspec"

describe AiExperiences::ConversationContextService do
  subject(:service) { described_class.new }

  let(:course) { course_model }
  let(:ai_experience) do
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

  describe "#create" do
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
      context_id = service.create(ai_experience:)

      expect(context_id).to eq("context-uuid")
      expect(ai_experience.reload.llm_conversation_context_id).to eq("context-uuid")
    end

    it "looks up prompt by code before creating context" do
      service.create(ai_experience:)

      expect(WebMock).to have_requested(:get, "http://localhost:3001/prompts/by-code/alpha")
        .with(headers: { "Authorization" => "Bearer test-token" })
    end

    it "sends correct payload to API" do
      service.create(ai_experience:)

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

      context_id = service.create(ai_experience:)

      expect(context_id).to be_nil
      expect(WebMock).not_to have_requested(:post, "http://localhost:3001/conversation-context")
    end

    it "raises ConversationError when prompt lookup fails" do
      stub_request(:get, "http://localhost:3001/prompts/by-code/alpha")
        .to_return(status: 404, body: "Not Found")

      expect do
        service.create(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError)
    end

    it "raises ConversationError when API call fails" do
      stub_request(:post, "http://localhost:3001/conversation-context")
        .to_return(status: 500, body: "Internal Server Error")

      expect do
        service.create(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError)
    end

    it "raises ConversationError when bearer token is missing" do
      allow(Rails.application.credentials).to receive(:llm_conversation_bearer_token).and_return(nil)

      expect do
        service.create(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError, /llm_conversation_bearer_token not found/)
    end

    context "with ai_experiences_context_file_upload feature flag enabled" do
      let(:attachment) { attachment_model(context: course, size: 1.megabyte, filename: "syllabus.pdf") }

      before do
        course.enable_feature!(:ai_experiences_context_file_upload)
        allow_any_instance_of(Attachment).to receive(:public_url).and_return("https://example.com/syllabus.pdf")

        stub_request(:post, "http://localhost:3001/conversation-context")
          .to_return(status: 200, body: create_context_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "reloads context_files to avoid sending stale empty association cache" do
        # Prime the AR association cache as empty before the file exists in DB
        ai_experience.context_files.to_a

        # Add a file directly to DB after the cache was primed
        AiExperienceContextFile.create!(ai_experience:, attachment:)

        service.create(ai_experience:)

        expect(WebMock).to have_requested(:post, "http://localhost:3001/conversation-context")
          .with(body: hash_including(
            "data" => hash_including(
              "context_files" => [
                hash_including("sourceId" => "file-#{attachment.global_id}")
              ]
            )
          ))
      end
    end
  end

  describe "#update" do
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
        service.update(ai_experience:)
      end.not_to raise_error

      expect(WebMock).to have_requested(:patch, "http://localhost:3001/conversation-context/context-uuid")
    end

    it "does not update if context_id is not set" do
      ai_experience.update_column(:llm_conversation_context_id, nil)

      service.update(ai_experience:)

      expect(WebMock).not_to have_requested(:patch, %r{http://localhost:3001/conversation-context/})
    end

    it "raises ConversationError when API call fails" do
      stub_request(:patch, "http://localhost:3001/conversation-context/context-uuid")
        .to_return(status: 404, body: "Not Found")

      expect do
        service.update(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError)
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
        service.update(ai_experience:)

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
        service.update(ai_experience:)

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

        service.update(ai_experience:)

        expect(WebMock).to have_requested(:patch, "http://localhost:3001/conversation-context/context-uuid")
          .with(body: hash_including(
            "data" => hash_including("context_files" => [])
          ))
      end

      it "reloads context_files to avoid sending stale empty association cache" do
        # Prime the AR association cache as empty before the file exists in DB
        ai_experience.context_files.to_a

        # Add a file directly to DB after the cache was primed
        attachment2 = attachment_model(context: course, size: 1.megabyte, filename: "notes.pdf")
        allow(attachment2).to receive(:public_url).and_return("https://example.com/notes.pdf")
        AiExperienceContextFile.create!(ai_experience:, attachment: attachment2)

        service.update(ai_experience:)

        expect(WebMock).to have_requested(:patch, "http://localhost:3001/conversation-context/context-uuid")
          .with(body: hash_including(
            "data" => hash_including(
              "context_files" => array_including(
                hash_including("sourceId" => "file-#{attachment2.global_id}")
              )
            )
          ))
      end
    end
  end

  describe "#delete" do
    before do
      ai_experience.update_column(:llm_conversation_context_id, "context-uuid")

      stub_request(:delete, "http://localhost:3001/conversation-context/context-uuid")
        .with(headers: { "Authorization" => "Bearer test-token" })
        .to_return(status: 200, body: { "success" => true }.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "deletes the conversation context and clears the ID" do
      service.delete(ai_experience:)

      expect(WebMock).to have_requested(:delete, "http://localhost:3001/conversation-context/context-uuid")
      expect(ai_experience.reload.llm_conversation_context_id).to be_nil
    end

    it "does not delete if context_id is not set" do
      ai_experience.update_column(:llm_conversation_context_id, nil)

      service.delete(ai_experience:)

      expect(WebMock).not_to have_requested(:delete, %r{http://localhost:3001/conversation-context/})
    end

    it "raises ConversationError when API call fails" do
      stub_request(:delete, "http://localhost:3001/conversation-context/context-uuid")
        .to_return(status: 500, body: "Internal Server Error")

      expect do
        service.delete(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError)
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
        service.create(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError)
    end

    it "handles socket errors" do
      stub_request(:post, "http://localhost:3001/conversation-context")
        .to_raise(SocketError.new("getaddrinfo: nodename nor servname provided"))

      expect do
        service.create(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError)
    end

    it "handles JSON parse errors" do
      stub_request(:post, "http://localhost:3001/conversation-context")
        .to_return(status: 200, body: "invalid json")

      expect do
        service.create(ai_experience:)
      end.to raise_error(LlmConversation::Errors::ConversationError)
    end
  end
end
