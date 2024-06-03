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

module DataFixup::ReplaceBrokenMediaObjectLinks
  CONTENT_MAP = {
    AssessmentQuestion => :question_data,
    Assignment => :description,
    Course => :syllabus_body,
    DiscussionTopic => :message,
    Quizzes::Quiz => nil,
    Quizzes::QuizQuestion => :question_data,
    WikiPage => :body
  }.freeze

  def self.update_models(model, field, where_clause, start_at, end_at)
    csv_stuff = false
    error_csv_stuff = false
    file_name = "data_fixup_replace_broken_media_object_links_#{Shard.current.id}_#{model.table_name}_#{field}_#{start_at}_#{end_at}_#{Time.now.to_f}.csv"
    csv = CSV.open(file_name, "w")
    error_csv = nil
    model.where(id: start_at..end_at).where(*where_clause).find_each(strategy: :pluck_ids) do |active_record|
      next unless (field && active_record[field]) || active_record.is_a?(Quizzes::Quiz)

      if active_record.is_a?(AssessmentQuestion) || active_record.is_a?(Quizzes::QuizQuestion)
        question_data = active_record.question_data.dup
        question_data["question_text"] = fix_html(question_data["question_text"])
        if question_data && question_data["answers"]
          question_data["answers"] = active_record["question_data"]["answers"]&.map do |a|
            a.merge({ "text" => fix_html(a["text"]) })
          end
        end
        if active_record.question_data.to_hash != question_data.to_hash
          csv << [Shard.current.id, active_record.class.table_name, active_record.id, active_record.question_data.to_hash, question_data.to_hash]
          csv_stuff = true
          active_record.update!(question_data:)
        end
      elsif active_record.is_a?(Quizzes::Quiz)
        active_record.description = fix_html(active_record.description)
        active_record.quiz_data = active_record.quiz_data.map do |question|
          question = question.merge({ "question_text" => fix_html(question["question_text"]) })
          question["answers"] = question["answers"]&.map do |a|
            a.merge({ "text" => fix_html(a["text"]) })
          end
          question
        end
        if active_record.changed?
          csv << [Shard.current.id, active_record.class.table_name, active_record.id, active_record.changed_attributes.to_hash, active_record.attributes.slice(*active_record.changed_attributes.keys).to_hash]
          csv_stuff = true
          active_record.save!
        end
      else
        new_html = fix_html(active_record[field])
        if active_record[field] != new_html
          csv << [Shard.current.id, active_record.class.table_name, active_record.id, active_record[field], new_html]
          csv_stuff = true
          active_record.update!(field => new_html)
        end
      end
    rescue => e
      error_csv_stuff = true
      error_csv = CSV.open(file_name + "_errors.csv", "a")
      error_csv << [Shard.current.id, active_record.class.table_name, active_record.id, e.message]
      error_csv.close
    end
    csv.close
    if csv_stuff
      Attachment.create!(filename: file_name, uploaded_data: File.open(csv.path), context: Account.site_admin, content_type: "text/csv")
    end
    if error_csv_stuff
      Attachment.create!(filename: file_name + "_errors.csv", uploaded_data: File.open(error_csv.path), context: Account.site_admin, content_type: "text/csv")
    end
    FileUtils.rm_f(file_name)
    FileUtils.rm_f(file_name + "_errors.csv")
  end

  def self.fix_html(html)
    doc = Nokogiri::HTML5::DocumentFragment.parse(html, nil, { max_tree_depth: 10_000 })

    doc.css("iframe[src*='file_contents/course%20files']").each do |e|
      url_match = e["src"]&.match(%r{media_objects(?:_iframe)?/((?:m-|0_)[0-9a-zA-z]+)})&.[](1)
      media_id = url_match if url_match.present?
      id_match = e["id"]&.match(/media_comment_((?:m-|0_)[0-9a-zA-z]+)/)&.[](1)
      media_id ||= id_match if id_match.present?
      media_id ||= e["data-media-id"]
      next unless media_id.present?

      url = Addressable::URI.parse(e["src"])
      url.path = "/media_objects_iframe/#{media_id}"
      e.set_attribute("src", url.to_s)
    end

    doc.to_s
  end

  def self.create_dataset_jobs(model, field, where_clause)
    model.where(*where_clause).find_ids_in_ranges(batch_size: 100_000) do |start_at, end_at|
      delay_if_production(
        priority: Delayed::LOW_PRIORITY,
        n_strand: ["DataFixup::ReplaceBrokenMediaObjectLinks", Shard.current.database_server.id]
      ).update_models(model, field, where_clause, start_at, end_at)
    end
  end

  def self.run
    CONTENT_MAP.each do |model, field|
      pattern = "iframe%/file_contents/course\\%20files/"
      field_search = ["#{field} LIKE '%#{pattern}%'"]
      quiz_field_search = ["description LIKE '%#{pattern}%' OR quiz_data LIKE '%#{pattern}%'"]
      where_clause = (model == Quizzes::Quiz) ? quiz_field_search : field_search

      delay_if_production(
        priority: Delayed::LOW_PRIORITY,
        n_strand: ["DataFixup::ReplaceBrokenMediaObjectLinks", Shard.current.database_server.id]
      ).create_dataset_jobs(model, field, where_clause)
    end
  end
end
