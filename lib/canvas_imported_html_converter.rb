# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require "nokogiri"

class CanvasImportedHtmlConverter < CanvasLinkMigrator::ImportedHtmlConverter
  include CanvasLinkMigrator

  LINK_TYPE_TO_CLASS = {
    announcement: Announcement,
    assessment_question: AssessmentQuestion,
    assignment: Assignment,
    calendar_event: CalendarEvent,
    discussion_topic: DiscussionTopic,
    quiz: Quizzes::Quiz,
    learning_outcome: LearningOutcome,
    wiki_page: WikiPage
  }.freeze

  def initialize(migration)
    @migration = migration
    super(migration_id_converter: Importers::DbMigrationQueryService.new(migration))
  end

  def context
    @migration.context
  end

  def context_path
    @migration_id_converter.context_path
  end

  def resolve_content_links!
    link_map = link_parser.unresolved_link_map
    return unless link_map.present?

    link_resolver.resolve_links!(link_map)
    replace_placeholders!(link_map)
    link_parser.reset!
  end

  def replace_placeholders!(link_map)
    load_questions!(link_map)

    link_map.each do |item_key, field_links|
      item_key[:item] ||= retrieve_item(item_key)

      replace_item_placeholders!(item_key, field_links)

      add_missing_link_warnings!(item_key, field_links)
    rescue
      @migration.add_warning("An error occurred while translating content links", $!)
    end
  end

  # these don't get added to the list of imported migration items
  def load_questions!(link_map)
    aq_item_keys = link_map.keys.select { |item_key| item_key[:type] == :assessment_question }
    aq_item_keys.each_slice(100) do |item_keys|
      context.assessment_questions.where(migration_id: item_keys.pluck(:migration_id)).preload(:assessment_question_bank).each do |aq|
        item_keys.detect { |ikey| ikey[:migration_id] == aq.migration_id }[:item] = aq
      end
    end

    qq_item_keys = link_map.keys.select { |item_key| item_key[:type] == :quiz_question }
    qq_item_keys.each_slice(100) do |item_keys|
      context.quiz_questions.where(migration_id: item_keys.pluck(:migration_id)).each do |qq|
        item_keys.detect { |ikey| ikey[:migration_id] == qq.migration_id }[:item] = qq
      end
    end
  end

  def retrieve_item(item_key)
    klass = LINK_TYPE_TO_CLASS[item_key[:type]]
    return unless klass

    item = @migration.find_imported_migration_item(klass, item_key[:migration_id])
    raise "item not found" unless item

    item
  end

  def add_missing_link_warnings!(item_key, field_links)
    fix_issue_url = nil
    field_links.each do |field, links|
      missing_links = links.select { |link| link[:replaced] && (link[:missing_url] || !link[:new_value]) }
      next unless missing_links.any?

      fix_issue_url ||= fix_issue_url(item_key)
      type = item_key[:type].to_s.humanize.titleize
      @migration.add_warning_for_missing_content_links(type, field, missing_links, fix_issue_url)
    end
  end

  def fix_issue_url(item_key)
    item = item_key[:item]

    case item_key[:type]
    when :assessment_question
      "#{context_path}/question_banks/#{item.assessment_question_bank_id}#question_#{item.id}_question_text"
    when :quiz_question
      "#{context_path}/quizzes/#{item.quiz_id}/edit" # can't jump to the question unfortunately
    when :syllabus
      "#{context_path}/assignments/syllabus"
    when :wiki_page
      "#{context_path}/pages/#{item.url}"
    else
      "#{context_path}/#{item.class.to_s.demodulize.underscore.pluralize}/#{item.id}"
    end
  end

  def replace_item_placeholders!(item_key, field_links, skip_associations = false)
    case item_key[:type]
    when :syllabus
      syllabus = context.syllabus_body
      if LinkReplacer.sub_placeholders!(syllabus, field_links.values.flatten)
        context.class.where(id: context.id).update_all(syllabus_body: syllabus)
      end
    when :assessment_question
      process_assessment_question!(item_key[:item], field_links.values.flatten)
    when :quiz_question
      process_quiz_question!(item_key[:item], field_links.values.flatten)
    else
      item = item_key[:item]
      item_updates = {}
      field_links.each do |field, links|
        html = item.read_attribute(field)
        if LinkReplacer.sub_placeholders!(html, links)
          item_updates[field] = html
        end
      end
      if item_updates.present?
        item.class.where(id: item.id).update_all(item_updates)
        # we don't want the placeholders sticking around in any
        # version we've created.
        rewrite_item_version!(item)
      end

      unless skip_associations
        process_assignment_types!(item, field_links.values.flatten)
      end
    end
  end

  def rewrite_item_version!(item)
    if (version = (item.current_version rescue nil))
      # if there's a current version of this thing, it has placeholders
      # in it.  rather than replace them in the yaml, which is finnicky, let's just
      # make sure the current version is represented by the current model state
      # by overwritting it
      version.model = item.reload
      version.save
    end
  end

  def process_assignment_types!(item, links)
    case item
    when Assignment
      if item.discussion_topic
        replace_item_placeholders!({ item: item.discussion_topic }, { message: links }, true)
      end
      if item.quiz
        replace_item_placeholders!({ item: item.quiz }, { description: links }, true)
      end
    when DiscussionTopic, Quizzes::Quiz
      if item.assignment
        replace_item_placeholders!({ item: item.assignment }, { description: links }, true)
      end
    end
  end

  def process_assessment_question!(aq, links)
    # we have to do a little bit more here because the question_data can get copied all over
    quiz_ids = []
    Quizzes::QuizQuestion.where(assessment_question_id: aq.id).find_each do |qq|
      if LinkReplacer.recursively_sub_placeholders!(qq["question_data"], links)
        Quizzes::QuizQuestion.where(id: qq.id).update_all(question_data: qq["question_data"])
        quiz_ids << qq.quiz_id
      end
    end

    if quiz_ids.any?
      Quizzes::Quiz.where(id: quiz_ids.uniq).where.not(quiz_data: nil).find_each do |quiz|
        if LinkReplacer.recursively_sub_placeholders!(quiz["quiz_data"], links)
          Quizzes::Quiz.where(id: quiz.id).update_all(quiz_data: quiz["quiz_data"])
        end
      end
    end

    # we have to do some special link translations for files in assessment questions
    # because we stopped doing them in the regular importer
    # basically just moving them to the question context
    links.each do |link|
      next unless link[:new_value]

      link[:new_value] = aq.translate_file_link(link[:new_value])
    end

    if LinkReplacer.recursively_sub_placeholders!(aq["question_data"], links)
      AssessmentQuestion.where(id: aq.id).update_all(question_data: aq["question_data"])
    end
  end

  def process_quiz_question!(qq, links)
    if LinkReplacer.recursively_sub_placeholders!(qq["question_data"], links)
      Quizzes::QuizQuestion.where(id: qq.id).update_all(question_data: qq["question_data"])
    end

    quiz = Quizzes::Quiz.where(id: qq.quiz_id).where.not(quiz_data: nil).first
    if quiz && LinkReplacer.recursively_sub_placeholders!(quiz["quiz_data"], links)
      Quizzes::Quiz.where(id: quiz.id).update_all(quiz_data: quiz["quiz_data"])
    end
  end
end
