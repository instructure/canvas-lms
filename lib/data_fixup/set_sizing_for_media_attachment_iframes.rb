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

module DataFixup::SetSizingForMediaAttachmentIframes
  CONTENT_MAP = [
    { AssessmentQuestion => :question_data },
    { Assignment => :description },
    { Course => :syllabus_body },
    { DiscussionTopic => :message },
    { DiscussionEntry => :message },
    { Quizzes::Quiz => nil },
    { Quizzes::QuizQuestion => :question_data },
    { Submission => :body },
    { WikiPage => :body }
  ].freeze

  def self.update_active_records(model, field, where_clause, start_at, end_at)
    model.where(id: start_at..end_at).where(*where_clause).find_each(strategy: :pluck_ids) do |active_record|
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

  def self.fix_html(html)
    doc = Nokogiri::HTML5::DocumentFragment.parse(html, nil, { max_tree_depth: 10_000 })
    doc.css("iframe").select do |e|
      next unless e.get_attribute("style")&.match?("width: px; height: px;")

      rewritten_style = e["style"].gsub("width: px; height: px;", "width: 320px; height: 14.25rem;")
      e.set_attribute("style", rewritten_style)
    end

    doc.to_s
  end

  def self.update_dataset(model, field)
    where_clause = (model == Quizzes::Quiz) ? ["description LIKE ? OR quiz_data LIKE ?", "%width: px;%", "%width: px;%"] : ["#{field} LIKE ?", "%width: px;%"]
    model.where(*where_clause).find_ids_in_ranges(batch_size: 100_000) do |start_at, end_at|
      delay_if_production(
        priority: Delayed::LOW_PRIORITY,
        n_strand: ["DataFixup::SetSizingForMediaAttachmentIframes", Shard.current.database_server.id]
      ).update_active_records(model, field, where_clause, start_at, end_at)
    end
  end

  def self.run
    CONTENT_MAP.each do |model_map|
      model_map.each do |model, field|
        delay_if_production(
          priority: Delayed::LOW_PRIORITY,
          n_strand: ["DataFixup::SetSizingForMediaAttachmentIframes", Shard.current.database_server.id]
        ).update_dataset(model, field)
      end
    end
  end

  def self.update_ar(active_record, field)
    active_record.update! field => fix_html(active_record[field])
  end

  def self.update_quiz(active_record)
    active_record.description = fix_html(active_record.description)
    active_record.quiz_data = active_record.quiz_data.map do |question|
      question = question.merge({ "question_text" => fix_html(question["question_text"]) })
      question["answers"] = question["answers"].map do |a|
        a.merge({ "text" => fix_html(a["text"]) })
      end
      question
    end
    active_record.save
  end

  def self.update_question(active_record)
    question_data = active_record.question_data
    question_data["question_text"] = fix_html(question_data["question_text"])
    if question_data && question_data["answers"]
      question_data["answers"] = active_record["question_data"]["answers"].map do |a|
        a.merge({ "text" => fix_html(a["text"]) })
      end
    end
    active_record.update! question_data:
  end
end
