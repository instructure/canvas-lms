# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Importers
  class LinkReplacer
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

    def initialize(migration, migration_query_service)
      @migration = migration
      @migration_query_service = migration_query_service
    end

    def context_path
      @migration_query_service.context_path
    end

    def context
      @migration.context
    end

    def replace_placeholders!(link_map)
      @migration_query_service.preload_items_for_replacer(link_map)

      link_map.each do |item_key, field_links|
        item_key[:item] ||= @migration_query_service.retrieve_item(item_key[:type], item_key[:migration_id])

        replace_item_placeholders!(item_key, field_links)

        add_missing_link_warnings!(item_key, field_links)
      rescue
        @migration.add_warning("An error occurred while translating content links", $!)
      end
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
        "#{context_path}/#{@migration_query_service.get_context_path_for_item(item)}/#{item.id}"
      end
    end

    def replace_item_placeholders!(item_key, field_links, skip_associations = false)
      case item_key[:type]
      when :syllabus
        @migration_query_service.replace_syllabus_placeholders!(item_key, field_links.values.flatten)
      when :assessment_question
        @migration_query_service.replace_assessment_question_placeholders!(item_key[:item], field_links.values.flatten)
      when :quiz_question
        @migration_query_service.replace_quiz_question_placeholders!(item_key[:item], field_links.values.flatten)
      else
        item = item_key[:item]
        item_updates = @migration_query_service.replace_item_placeholders!(item, field_links)

        if item_updates.present?
          @migration_query_service.update_all_items(item, item_updates)
        end

        unless skip_associations
          process_assignment_types!(item, field_links.values.flatten)
        end
      end
    end

    # returns false if no substitutions were made
    def self.sub_placeholders!(html, links)
      subbed = false
      links.each do |link|
        new_value = link[:new_value] || link[:old_value]
        if html.gsub!(link[:placeholder], new_value)
          link[:replaced] = true
          subbed = true
        end
      end
      subbed
    end

    def self.recursively_sub_placeholders!(object, links)
      subbed = false
      case object
      when Hash
        object.each_value { |o| subbed = true if recursively_sub_placeholders!(o, links) }
      when Array
        object.each { |o| subbed = true if recursively_sub_placeholders!(o, links) }
      when String
        subbed = sub_placeholders!(object, links)
      end
      subbed
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
  end
end
