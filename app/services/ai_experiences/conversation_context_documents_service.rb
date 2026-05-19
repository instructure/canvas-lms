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

module AiExperiences
  class ConversationContextDocumentsService
    def initialize(account:)
      @client = LlmConversation::HttpClient.new(account:)
    end

    def sync_index_status(ai_experience:)
      return unless ai_experience.llm_conversation_context_id.present?
      return unless ai_experience.course.feature_enabled?(:ai_experiences_context_file_upload)

      response = @client.get("/contexts/#{ai_experience.llm_conversation_context_id}/documents")

      documents = response["documents"] || []
      return if documents.empty?

      statuses = documents.pluck("status")
      new_status = if statuses.all?("completed")
                     "completed"
                   elsif statuses.any?("failed")
                     "failed"
                   else
                     "in_progress"
                   end

      ai_experience.update_column(:context_index_status, new_status)

      failed_file_names = if new_status == "failed"
                            failed_doc_ids = documents.select { |d| d["status"] == "failed" }.pluck("id")
                            ai_experience.ai_experience_context_files
                                         .where(llm_conversation_service_document_id: failed_doc_ids)
                                         .preload(:attachment)
                                         .filter_map { |cf| cf.attachment&.display_name }
                          else
                            []
                          end

      { status: new_status, failed_file_names: }
    rescue LlmConversation::Errors::ConversationError => e
      Rails.logger.warn("Document index status sync failed for ai_experience #{ai_experience.id}: #{e.message}")
    end

    def trigger_indexing(ai_experience:, context_file_ids: nil)
      context_id = ai_experience.llm_conversation_context_id
      return unless context_id.present?

      scope = ai_experience.ai_experience_context_files
      scope = scope.where(id: context_file_ids) if context_file_ids.present?
      context_file_records = scope.preload(:attachment)
      return if context_file_records.empty?

      context_file_records.each do |context_file|
        file = context_file.attachment
        next if file.nil? || file.file_state == "deleted"

        response = @client.post(
          "/contexts/#{context_id}/documents",
          payload: { url: file.public_url, sourceType: "file" }
        )

        doc_id = response["id"]
        context_file.update_column(:llm_conversation_service_document_id, doc_id) if doc_id.present?
      end

      ai_experience.update_column(:context_index_status, "in_progress")
    end

    def remove_documents(ai_experience:, context_files:)
      context_id = ai_experience.llm_conversation_context_id
      return unless context_id.present?
      return unless ai_experience.course.feature_enabled?(:ai_experiences_context_file_upload)

      context_files.each do |context_file|
        next if context_file.llm_conversation_service_document_id.blank?

        @client.delete("/contexts/#{context_id}/documents/#{context_file.llm_conversation_service_document_id}")
      end
    end
  end
end
