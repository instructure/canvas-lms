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

module DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks
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

  ATTRIBUTES = %w[href data src].freeze

  def self.update_active_records(model, field, where_clause, start_at, end_at)
    error_file_name = "data_fixup_replace_media_object_links_for_media_attachment_links_#{Shard.current.id}_#{model.table_name}_#{field}_#{start_at}_#{end_at}_#{Time.now.to_f}_errors.csv"
    had_errors = false
    error_csv = nil

    model.where(id: start_at..end_at).where(*where_clause).find_each(strategy: :pluck_ids) do |active_record|
      next unless (field && active_record[field]) || active_record.is_a?(Quizzes::Quiz)

      if active_record.is_a?(AssessmentQuestion) || active_record.is_a?(Quizzes::QuizQuestion)
        question_data = active_record.question_data
        question_data["question_text"] = fix_html(active_record, question_data["question_text"])
        if question_data && question_data["answers"]
          question_data["answers"] = active_record["question_data"]["answers"].map do |a|
            a.merge({ "text" => fix_html(active_record, a["text"]) })
          end
        end
        begin
          active_record.update! question_data:
        rescue => e
          had_errors = true
          error_csv = CSV.open(error_file_name, "a")
          error_csv << [Shard.current.id, active_record.class.table_name, active_record.id, e.message]
          error_csv.close
        end
      elsif active_record.is_a?(Quizzes::Quiz)
        active_record.description = fix_html(active_record, active_record.description)
        active_record.quiz_data = active_record.quiz_data.map do |question|
          question = question.merge({ "question_text" => fix_html(active_record, question["question_text"]) })
          question["answers"] = question["answers"].map do |a|
            a.merge({ "text" => fix_html(active_record, a["text"]) })
          end
          question
        end
        begin
          active_record.save
        rescue => e
          had_errors = true
          error_csv = CSV.open(error_file_name, "a")
          error_csv << [Shard.current.id, active_record.class.table_name, active_record.id, e.message]
          error_csv.close
        end
      else
        begin
          active_record.update! field => fix_html(active_record, active_record[field])
        rescue => e
          had_errors = true
          error_csv = CSV.open(error_file_name, "a")
          error_csv << [Shard.current.id, active_record.class.table_name, active_record.id, e.message]
          error_csv.close
        end
      end
    end
    if had_errors
      Attachment.create!(filename: error_file_name, uploaded_data: File.open(error_csv.path), context: Account.site_admin, content_type: "text/csv")
      FileUtils.rm_f(error_file_name)
    end
  end

  def self.set_iframe_width_and_height(element, media_id)
    preexisting_style = element["style"] || ""
    return if preexisting_style.include?("height:") || preexisting_style.include?("width:")

    mo = MediaObject.by_media_id(media_id)
    mo = mo.first
    return unless mo

    mo_keys = mo.data[:extensions].keys
    ext_data = mo.data[:extensions][mo_keys.first]
    return unless ext_data

    if !preexisting_style.include?("height:") && !preexisting_style.include?("width:")
      element.set_attribute("style", "width:#{ext_data[:width]}px; height:#{ext_data[:height]}px; #{preexisting_style}")
    end
  end

  def self.fix_html(active_record, html)
    doc = Nokogiri::HTML5::DocumentFragment.parse(html, nil, { max_tree_depth: 10_000 })

    # media comments
    doc.css("a.instructure_inline_media_comment").each do |e|
      next unless e.attributes["id"]&.value&.match?("media_comment_m-")

      media_id = e.attributes["id"].value.gsub("media_comment_", "")
      attachment = get_attachment(active_record, media_id)
      new_src = "/media_attachments_iframe/#{attachment.id}"
      new_src = add_verifier_to_link(new_src, attachment) if attachment.context_type == "User"
      iframe = doc.document.create_element "iframe", { "src" => new_src }
      set_iframe_width_and_height(iframe, media_id)
      e.replace iframe
    end

    # media object iframes
    doc.css("iframe").select do |e|
      next unless e.get_attribute("src")&.match?('(.*\/)?media_objects_iframe\/([^\/\?]*)(.*)')

      source_parts = e.get_attribute("src").match('(.*\/)?media_objects_iframe\/([^\/\?]*)(.*)')
      media_id = source_parts[2]
      attachment = get_attachment(active_record, media_id)
      new_src = "#{source_parts[1]}media_attachments_iframe/#{attachment.id}#{source_parts[3]}"
      new_src = add_verifier_to_link(new_src, attachment) if attachment.context_type == "User"
      e.set_attribute("src", new_src)
      set_iframe_width_and_height(e, media_id)
    end

    # misc...
    # doc.css("a, video, iframe, object, embed").select do |e|
    #   ATTRIBUTES.each do |attr|
    #     next unless e.get_attribute(attr)&.match?('(.*\/)?media_objects\/([^\/\?]*)(.*)')
    #
    #     source_parts = e.get_attribute(attr).match('(.*\/)?media_objects\/([^\/\?]*)(.*)')
    #     media_id = source_parts[2]
    #     attachment = get_attachment(active_record, media_id)
    #     new_src = "#{source_parts[1]}media_attachments/#{attachment.id}#{source_parts[3]}"
    #     new_src = add_verifier_to_link(new_src, attachment) if attachment.context_type == "User"
    #     iframe = doc.document.create_element "iframe", { "src" => new_src }
    #     set_iframe_width_and_height(iframe, media_id)
    #     e.replace iframe
    #   end
    # end

    doc.to_s
  end

  def self.add_verifier_to_link(link, attachment)
    parts = link.split("?")
    verified = parts[0] + "?verifier=#{attachment.uuid}"
    verified += "&#{parts[1]}" if parts[1]
    verified
  end

  def self.get_preferred_contexts(active_record)
    return [active_record, active_record.assessment_question_bank] if active_record.is_a?(AssessmentQuestion)
    return [active_record.user, active_record.discussion_topic] if active_record.is_a?(DiscussionEntry)
    return [active_record.context] if active_record.is_a?(Assignment) || active_record.is_a?(DiscussionTopic) || active_record.is_a?(Quizzes::Quiz)
    return [active_record] if active_record.is_a?(Course)
    return [active_record.user] if active_record.is_a?(Submission)
    return [active_record.quiz.context, active_record.quiz] if active_record.is_a?(Quizzes::QuizQuestion)
    return [active_record.context] if active_record.is_a?(WikiPage)

    []
  end

  def self.create_attachment(active_record, media_id)
    chosen_context = get_preferred_contexts(active_record).compact[0]
    return unless chosen_context

    Attachment.create!(context: chosen_context, media_entry_id: media_id, filename: media_id, content_type: "unknown/unknown")
  end

  def self.get_valid_candidate(candidates, active_record)
    selected_candidates = candidates.where(context: get_preferred_contexts(active_record).compact)
    return selected_candidates.first if selected_candidates.present?

    nil
  end

  def self.get_attachment(active_record, media_id)
    candidates = Attachment.where(media_entry_id: media_id)
    return create_attachment(active_record, media_id) if candidates.empty?

    (chosen_attachment = get_valid_candidate(candidates, active_record)) ? chosen_attachment : create_attachment(active_record, media_id)
  end

  def self.update_dataset(model, field, where_clause)
    model.where(*where_clause).find_ids_in_ranges(batch_size: 100_000) do |start_at, end_at|
      delay_if_production(
        priority: Delayed::LOW_PRIORITY,
        n_strand: ["DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks", Shard.current.database_server.id]
      ).update_active_records(model, field, where_clause, start_at, end_at)
    end
  end

  def self.run
    patterns = ["%media_objects_iframe%", "%media_comment_m-%", "%/media_objects/%"]
    quiz_patterns = ["%media_objects_iframe%", "%media_comment_m-%", "%/media_objects/%", "%media_objects_iframe%", "%media_comment_m-%", "%/media_objects/%"]

    CONTENT_MAP.each do |model_map|
      model_map.each do |model, field|
        field_search = ["#{field} LIKE ? OR #{field} LIKE ? OR #{field} LIKE ?"]
        quiz_field_search = ["description LIKE ? OR description LIKE ? OR description LIKE ? OR quiz_data LIKE ? OR quiz_data LIKE ? OR quiz_data LIKE ?"]
        where_clause = (model == Quizzes::Quiz) ? quiz_field_search.concat(quiz_patterns) : field_search.concat(patterns)

        delay_if_production(
          priority: Delayed::LOW_PRIORITY,
          n_strand: ["DataFixup::ReplaceMediaObjectLinksForMediaAttachmentLinks", Shard.current.database_server.id]
        ).update_dataset(model, field, where_clause)
      end
    end
  end
end
