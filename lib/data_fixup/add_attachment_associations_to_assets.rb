# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require "nokogiri"
module DataFixup::AddAttachmentAssociationsToAssets
  CONTENT_MAP = [
    { Course => :syllabus_body },
  ].freeze
  def self.process_model_and_create_attachment_association(model, field, batch_ids)
    model.where(id: batch_ids).find_each do |active_record|
      next unless (field && active_record[field]) || active_record.is_a?(Quizzes::Quiz)

      if active_record.is_a?(AssessmentQuestion) || active_record.is_a?(Quizzes::QuizQuestion)
        html = active_record.question_data.to_hash["question_text"]
        UserContent.associate_attachments_to_rce_object(
          html,
          active_record,
          blank_user: true,
          feature_enabled: true
        )
      elsif active_record.is_a?(Quizzes::Quiz)
        active_record.quiz_data & map do |question|
          question_html = question["question_text"]
          UserContent.associate_attachments_to_rce_object(
            question_html,
            active_record,
            blank_user: true,
            feature_enabled: true
          )
          next unless question["answers"]

          question["answers"] = question["answers"].map do |a|
            answer_html = a["text"]
            UserContent.associate_attachments_to_rce_object(
              answer_html,
              active_record,
              blank_user: true,
              feature_enabled: true
            )
          end
        end
      else
        UserContent.associate_attachments_to_rce_object(
          active_record[field],
          active_record,
          context_field_name: ((field == :syllabus_body) ? "syllabus_body" : nil),
          blank_user: true,
          feature_enabled: true
        )
      end
    end
  end

  def self.run
    CONTENT_MAP.each do |model_map|
      model_map.each do |model, field|
        model.where(
          "#{field} LIKE ? OR #{field} LIKE ?",
          "%/media_attachments_iframe/%",
          "%/files/%"
        ).find_ids_in_batches do |batch_ids|
          delay_if_production(
            priority: Delayed::LOW_PRIORITY,
            n_strand: ["DataFixup::AddAttachmentAssociationsToAssets", Shard.current.database_server.id]
          ).process_model_and_create_attachment_association(model, field, batch_ids)
        end
      end
    end
  end
end
