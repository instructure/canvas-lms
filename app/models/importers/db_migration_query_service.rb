# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
  # This class encapsulates the logic to retrieve metadata (for various types of assets)
  # given a migration id. This particular implementation relies on db queries in Canvas
  # but future implementations may rely on a static asset_migration_map
  #
  # Each function returns exactly one id (if available), and nil if an id
  # cannot be resolved
  class DbMigrationQueryService
    def initialize(context, migration)
      @context = context
      @migration = migration
    end

    def attachment_path_id_lookup
      @migration.attachment_path_id_lookup
    end

    def attachment_path_id_lookup_lower
      @migration.attachment_path_id_lookup_lower
    end

    # Returns the path for the context, for a course, it should return something like
    # "courses/1"
    def context_path
      "/#{@context.class.to_s.underscore.pluralize}/#{@context.id}"
    end

    # Looks up a wiki page slug for a migration id
    def convert_wiki_page_migration_id_to_slug(migration_id)
      @context.wiki_pages.where(migration_id:).limit(1).pick(:url)
    end

    # looks up a discussion topic
    def convert_discussion_topic_migration_id(migration_id)
      @context.discussion_topics.where(migration_id:).limit(1).pick(:id)
    end

    def convert_context_module_tag_migration_id(migration_id)
      @context.context_module_tags.where(migration_id:).limit(1).pick(:id)
    end

    def convert_attachment_migration_id(migration_id)
      @context.attachments.where(migration_id:).limit(1).pick(:id)
    end

    def convert_migration_id(type, migration_id)
      if Importers::LinkParser::KNOWN_REFERENCE_TYPES.include? type
        @context.send(type).scope.where(migration_id:).limit(1).pick(:id)
      end
    end

    def lookup_attachment_by_migration_id(migration_id)
      @context.attachments.where(migration_id:).first
    end

    def root_folder_name
      Folder.root_folders(@context).first.name
    end

    def process_domain_substitutions(url)
      @migration.process_domain_substitutions(url)
    end

    def context_hosts
      if (account = @migration&.context&.root_account)
        HostUrl.context_hosts(account)
      else
        []
      end
    end

    def report_link_parse_warning(ref_type)
      Sentry.with_scope do |scope|
        scope.set_tags(type: ref_type)
        scope.set_tags(url:)
        Sentry.capture_message("Link Parser failed to validate type", level: :warning)
      end
    end

    def supports_embedded_images
      true
    end

    # Returns a link with a boolean "resolved" property indicating whether the link
    # was actually resolved, or if needs further processing.
    def link_embedded_image(info_match)
      extension = MIME::Types[info_match[:mime_type]]&.first&.extensions&.first
      image_data = Base64.decode64(info_match[:image])
      md5 = Digest::MD5.hexdigest image_data
      folder_name = I18n.t("embedded_images")
      @folder ||= Folder.root_folders(@context).first.sub_folders
                        .where(name: folder_name, workflow_state: "hidden", context: @context).first_or_create!
      filename = "#{md5}.#{extension}"
      file = Tempfile.new([md5, ".#{extension}"])
      file.binmode
      file.write(image_data)
      file.close
      attachment = FileInContext.attach(@context, file.path, display_name: filename, folder: @folder, explicit_filename: filename, md5:)
      {
        resolved: true,
        url: "#{context_path}/files/#{attachment.id}/preview",
      }
    rescue
      {
        resolved: false,
        url: "#{folder_name}/#{filename}"
      }
    end

    def fix_relative_urls?
      # For course copies don't try to fix relative urls. Any url we can
      # correctly alter was changed during the 'export' step
      !@migration&.for_course_copy?
    end

    # Allows the implementation to preload items that will be used by the replacer
    def preload_items_for_replacer(link_map)
      # these don't get added to the list of imported migration items
      load_questions!(link_map)
    end

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

    def retrieve_item(link_type, migration_id)
      klass = LINK_TYPE_TO_CLASS[link_type]
      return unless klass

      item = @migration.find_imported_migration_item(klass, migration_id)
      raise "item not found" unless item

      item
    end

    def load_questions!(link_map)
      aq_item_keys = link_map.keys.select { |item_key| item_key[:type] == :assessment_question }
      aq_item_keys.each_slice(100) do |item_keys|
        @context.assessment_questions.where(migration_id: item_keys.pluck(:migration_id)).preload(:assessment_question_bank).each do |aq|
          item_keys.detect { |ikey| ikey[:migration_id] == aq.migration_id }[:item] = aq
        end
      end

      qq_item_keys = link_map.keys.select { |item_key| item_key[:type] == :quiz_question }
      qq_item_keys.each_slice(100) do |item_keys|
        @context.quiz_questions.where(migration_id: item_keys.pluck(:migration_id)).each do |qq|
          item_keys.detect { |ikey| ikey[:migration_id] == qq.migration_id }[:item] = qq
        end
      end
    end

    def replace_syllabus_placeholders!(_item_key, field_links)
      syllabus = @context.syllabus_body
      if LinkReplacer.sub_placeholders!(syllabus, field_links)
        @context.class.where(id: @context.id).update_all(syllabus_body: syllabus)
      end
    end

    def replace_assessment_question_placeholders!(aq, links)
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

    def replace_quiz_question_placeholders!(qq, links)
      if LinkReplacer.recursively_sub_placeholders!(qq["question_data"], links)
        Quizzes::QuizQuestion.where(id: qq.id).update_all(question_data: qq["question_data"])
      end

      quiz = Quizzes::Quiz.where(id: qq.quiz_id).where.not(quiz_data: nil).first
      if quiz && LinkReplacer.recursively_sub_placeholders!(quiz["quiz_data"], links)
        Quizzes::Quiz.where(id: quiz.id).update_all(quiz_data: quiz["quiz_data"])
      end
    end

    def replace_item_placeholders!(item, field_links)
      item_updates = {}
      field_links.each do |field, links|
        html = item.read_attribute(field)
        if LinkReplacer.sub_placeholders!(html, links)
          item_updates[field] = html
        end
      end
      item_updates
    end

    def update_all_items(item, item_updates)
      item.class.where(id: item.id).update_all(item_updates)
      # we don't want the placeholders sticking around in any
      # version we've created.
      rewrite_item_version!(item)
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

    def get_context_path_for_item(item)
      item.class.to_s.demodulize.underscore.pluralize
    end
  end
end
