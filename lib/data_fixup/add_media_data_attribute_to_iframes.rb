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

module DataFixup::AddMediaDataAttributeToIframes
  CONTENT_MAP = [
    { AssessmentQuestion => :question_data },
    { Assignment => :description },
    { Course => :syllabus_body },
    { DiscussionTopic => :message },
    { DiscussionEntry => :message },
    { Quizzes::Quiz => :description },
    { Quizzes::QuizQuestion => :question_data },
    { Submission => :body },
    { WikiPage => :body }
  ].freeze

  def self.fix_html(html)
    doc = Nokogiri::HTML5::DocumentFragment.parse(html, nil, **CanvasSanitize::SANITIZE[:parser_options])

    doc.css("iframe").map do |e|
      next unless e.get_attribute("src")&.match?('(.*\/)?media_attachments_iframe\/([^\/\?]*)(.*)')

      source_parts = e.get_attribute("src").match('(.*\/)?media_attachments_iframe\/([^\/\?]*)(.*)')
      next if !source_parts || !source_parts[2]

      att_id = source_parts[2].to_i
      next if e.get_attribute("data-media-id") || e.get_attribute("data-media-type")

      content_type = Attachment.where(id: att_id).last&.content_type&.split("/")&.[](0)
      content_type = nil if content_type == "unknown"
      content_type ||= MediaObject.where(attachment_id: att_id).last&.media_type&.split("/")&.[](0)
      content_type ||= "video" # just default to this
      e.set_attribute("data-media-type", content_type) if content_type
    end
    doc.to_s
  end

  def self.update_ar(active_record, ar_attribute)
    active_record.update_columns(ar_attribute => fix_html(active_record[ar_attribute]))
  end

  def self.update_quiz(active_record)
    active_record.update_columns description: fix_html(active_record.description)
    if active_record.quiz_data
      quiz_data = active_record.quiz_data.map do |question|
        question = question.merge({ "question_text" => fix_html(question["question_text"]) })
        if question["answers"]
          question["answers"] = question["answers"].map do |a|
            a.merge({ "text" => fix_html(a["text"]) })
          end
        end
        question
      end
      active_record.update_columns(quiz_data:)
    end
  end

  def self.update_question(active_record)
    question_data = active_record.question_data.to_hash
    question_data["question_text"] = fix_html(question_data["question_text"])
    if question_data && question_data["answers"]
      question_data["answers"] = question_data["answers"].map do |a|
        a.merge({ "text" => fix_html(a["text"]) })
      end
    end
    active_record.update_columns(question_data:)
  end

  def self.update_active_records(model, field, batch)
    model.where(id: batch).find_each do |active_record|
      next unless (field && active_record[field]) || active_record.is_a?(Quizzes::Quiz)

      if active_record.is_a?(AssessmentQuestion) || active_record.is_a?(Quizzes::QuizQuestion)
        update_question(active_record)
      elsif active_record.is_a?(Quizzes::Quiz)
        update_quiz(active_record)
      else
        update_ar(active_record, field)
      end
    end
  end

  def self.run
    CONTENT_MAP.each do |model_map|
      model_map.each do |model, field|
        model.where("#{field} LIKE ? AND #{field} NOT LIKE ? AND #{field} NOT LIKE ?", "%<iframe%media_attachments_iframe%", "%data-media-type%", "%data-media-type%").find_ids_in_batches do |batch|
          delay_if_production(
            priority: Delayed::LOW_PRIORITY,
            n_strand: ["DataFixup::AddMediaDataAttributeToIframes", Shard.current.database_server.id]
          ).update_active_records(model, field, batch)
        end
      end
    end
  end
end
