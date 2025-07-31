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

class YoutubeMigrationService
  SUPPORTED_RESOURCES = [
    WikiPage.name,
    Quizzes::Quiz.name,
    Quizzes::QuizQuestion.name,
    AssessmentQuestion.name,
    DiscussionTopic.name,
    DiscussionEntry.name,
    CalendarEvent.name,
    Assignment.name,
    "CourseSyllabus"
  ].freeze
  QUESTION_RCE_FIELDS = %i[
    question_text
    correct_comments_html
    incorrect_comments_html
    neutral_comments_html
    more_comments_html
  ].freeze
  SCAN_TAG = "youtube_embed_scan"
  CONVERT_TAG = "youtube_embed_convert"

  class EmbedNotFoundError < StandardError; end

  def self.last_youtube_embed_scan_progress_by_course(course)
    Progress.where(tag: SCAN_TAG, context: course).last
  end

  def self.find_scan(course, scan_id)
    Progress.find_by!(tag: SCAN_TAG, context: course, id: scan_id)
  end

  def self.queue_scan_course_for_embeds(course)
    progress = Progress.where(tag: SCAN_TAG, context_type: "Course", context_id: course.id).last
    return progress if progress && (progress.pending? || progress.running?)

    progress = Progress.create!(tag: SCAN_TAG, context: course)
    progress.process_job(self, :scan, {}) # TODO: use n_strand to make sure not monopolize the workpool
    progress
  end

  def self.scan(progress)
    service = new(progress.context)
    resources_with_embeds = service.scan_course_for_embeds
    total_count = resources_with_embeds.values.sum { |resource| resource[:count] || 0 }
    progress.set_results({ resources: resources_with_embeds, total_count:, completed_at: Time.now.utc })
  rescue
    report_id = Canvas::Errors.capture_exception(:youtube_embed_scan, $ERROR_INFO)[:error_report]
    progress.set_results({ error_report_id: report_id, completed_at: Time.now.utc })
  end

  def self.generate_resource_key(type, id)
    "#{type}|#{id}"
  end

  attr_accessor :course

  def initialize(course)
    self.course = course
  end

  def convert_embed(scan_id, embed)
    # TODO: validate if we can find the progress otherwise throw an error
    # TODO: validate if type is supported SUPPORTED_RESOURCES
    # TODO: validate if resource_group_key after split up by "|" is valid
    scan_progress = YoutubeMigrationService.find_scan(course, scan_id)
    message = YoutubeMigrationService.generate_resource_key(embed[:resource_type], embed[:id])
    # TODO: Something will listen on this creation
    convert_progress = Progress.create!(tag: CONVERT_TAG, context: course, message:, results: { original_embed: embed })
    delete_embed_from_scan(scan_progress, embed)
    convert_progress
  rescue
    report_id = Canvas::Errors.capture_exception(:youtube_embed_scan, $ERROR_INFO)[:error_report]
    convert_progress.set_results({ error_report_id: report_id, completed_at: Time.now.utc })
    convert_progress
  end

  def scan_course_for_embeds
    resources_with_embeds = {}

    course.wiki_pages.not_deleted.find_each do |page|
      common_hash = {
        name: page.title,
        id: page.id,
        type: page.class.name,
        content_url: "/courses/#{course.id}/pages/#{page.url}",
      }

      embeds, error = scan_resource(page, :body, page.body)
      errors = [error].compact

      add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    end

    course.quizzes.active.find_each do |quiz|
      common_hash = {
        name: quiz.title,
        id: quiz.id,
        type: quiz.class.name,
        content_url: "/courses/#{course.id}/quizzes/#{quiz.id}",
      }

      description_embeds, description_error = scan_resource(quiz, :description, quiz.description)

      resource_group_key = YoutubeMigrationService.generate_resource_key(quiz.class.name, quiz.id)

      # TODO: fine tune the queries with find_each to not eat all the memory
      questions_embeds_with_errors = quiz.quiz_questions.active.flat_map do |question|
        QUESTION_RCE_FIELDS.map do |field|
          embeds, error = scan_resource(question, field, question.question_data[field], resource_group_key)
          [embeds, error]
        end
      end

      embeds = (description_embeds + questions_embeds_with_errors.flat_map(&:first)).flatten
      errors = [description_error, questions_embeds_with_errors.flat_map(&:second)].flatten.compact

      add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    end

    course.assessment_questions.active.preload(:assessment_question_bank).find_each do |assessment_question|
      next if assessment_question.assessment_question_bank.deleted?

      common_hash = {
        name: assessment_question.question_data[:question_name],
        id: assessment_question.id,
        type: assessment_question.class.name,
        content_url: "/courses/#{course.id}/question_banks/#{assessment_question.assessment_question_bank_id}#question_#{assessment_question.id}_question_text",
      }

      questions_embeds_with_errors = QUESTION_RCE_FIELDS.map do |field|
        embeds, error = scan_resource(assessment_question, field, assessment_question.question_data[field])
        [embeds, error]
      end

      embeds = questions_embeds_with_errors.flat_map(&:first)
      errors = questions_embeds_with_errors.flat_map(&:second).compact

      add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    end

    course.discussion_topics.active.each do |topic|
      common_hash = {
        name: topic.title,
        id: topic.id,
        type: topic.class.name,
        content_url: "/courses/#{course.id}/discussion_topics/#{topic.id}",
      }

      resource_group_key = YoutubeMigrationService.generate_resource_key(topic.class.name, topic.id)

      entry_embeds_with_errors = topic.discussion_entries.active.map do |entry|
        embeds, error = scan_resource(entry, :message, entry.message, resource_group_key)
        [embeds, error]
      end

      message_embeds, message_error = scan_resource(topic, :message, topic.message)

      embeds = (message_embeds + entry_embeds_with_errors.flat_map(&:first)).flatten
      errors = [message_error, entry_embeds_with_errors.flat_map(&:second)].flatten.compact

      add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    end

    course.calendar_events.active.find_each do |event|
      common_hash = {
        name: event.title,
        id: event.id,
        type: event.class.name,
        content_url: "/courses/#{course.id}/calendar_events/#{event.id}",
      }

      embeds, error = scan_resource(event, :description, event.description)
      errors = [error].compact

      add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    end

    course.assignments.active.find_each do |assignment|
      next if assignment.submission_types.include?("online_quiz") ||
              assignment.submission_types.include?("discussion_topic") ||
              assignment.submission_types.include?("external_tool")

      common_hash = {
        name: assignment.title,
        id: assignment.id,
        type: assignment.class.name,
        content_url: "/courses/#{course.id}/assignments/#{assignment.id}",
      }

      embeds, error = scan_resource(assignment, :description, assignment.description)
      errors = [error].compact

      add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    end

    if course.syllabus_body
      common_hash = {
        name: I18n.t(:syllabus, "Course Syllabus"),
        type: "Course",
        id: course.id,
        content_url: "/courses/#{course.id}/assignments/syllabus"
      }

      embeds, error = scan_resource(course, :syllabus_body, course.syllabus_body)
      errors = [error].compact

      add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    end

    # TODO: include outcomes
    # TODO: include grade comments

    resources_with_embeds
  end

  private

  def add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    key = YoutubeMigrationService.generate_resource_key(common_hash[:type], common_hash[:id])
    unless embeds.none? && errors.none?
      resources_with_embeds[key] = {
        **common_hash,
        count: embeds.count,
        embeds:,
        errors:
      }
    end
  end

  def scan_resource(model, field, html, resource_group_key = nil)
    embeds = YoutubeEmbedScanner.embeds_from_html(html)
    [embeds.map { |embed| embed.merge({ id: model.id, resource_type: model.class.name, field:, resource_group_key: }.compact) }, nil]
  rescue
    [[], { id: model.id, resource_type: model.class.name, field: }]
  end

  def delete_embed_from_scan(scan_progress, embed)
    key = embed[:resource_group_key] || YoutubeMigrationService.generate_resource_key(embed[:resource_type], embed[:id])
    resource = scan_progress.results[:resources][key]
    found_embed, index = resource[:embeds].each_with_index.find do |resource_embed, _|
      embed[:path] == resource_embed[:path] &&
        embed[:field] == resource_embed[:field] &&
        embed[:resource_type] == resource_embed[:resource_type] &&
        embed[:resource_type] == resource_embed[:resource_type] &&
        embed[:resource_group_key] == resource_embed[:resource_group_key]
    end

    if found_embed
      resource[:embeds].delete_at(index)
      resource[:count] = [resource[:count] - 1, 0].max
      if resource[:count].zero?
        scan_progress.results[:resources].delete(key)
      else
        scan_progress.results[:resources][key] = resource
      end
      scan_progress.results[:total_count] = [scan_progress.results[:total_count] - 1, 0].max
      scan_progress.save!
    else
      raise EmbedNotFoundError, "Embed not found for resource type: #{embed[:resource_type]}, id: #{embed[:id]}"
    end
  end
end
