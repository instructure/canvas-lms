# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module Canvas::Migration::Helpers
  class SelectiveContentFormatter
    BLUEPRINT_SETTING_TYPE = -> { I18n.t("Blueprint Settings") }
    COURSE_SETTING_TYPE = -> { I18n.t("lib.canvas.migration.course_settings", "Course Settings") }
    COURSE_SYLLABUS_TYPE = -> { I18n.t("lib.canvas.migration.syllabus_body", "Syllabus Body") }
    COURSE_PACE_TYPE = -> { I18n.t("Course Pace") }
    SELECTIVE_CONTENT_TYPES = [
      ["context_modules", -> { I18n.t("lib.canvas.migration.context_modules", "Modules") }],
      ["assignments", -> { I18n.t("lib.canvas.migration.assignments", "Assignments") }],
      ["quizzes", -> { I18n.t("lib.canvas.migration.quizzes", "Quizzes") }],
      ["assessment_question_banks", -> { I18n.t("lib.canvas.migration.assessment_question_banks", "Question Banks") }],
      ["discussion_topics", -> { I18n.t("lib.canvas.migration.discussion_topics", "Discussion Topics") }],
      ["wiki_pages", -> { I18n.t("lib.canvas.migration.wikis", "Pages") }],
      ["context_external_tools", -> { I18n.t("lib.canvas.migration.external_tools", "External Tools") }],
      ["tool_profiles", -> { I18n.t("lib.canvas.migration.tool_profiles", "Tool Profiles") }],
      ["announcements", -> { I18n.t("lib.canvas.migration.announcements", "Announcements") }],
      ["calendar_events", -> { I18n.t("lib.canvas.migration.calendar_events", "Calendar Events") }],
      ["rubrics", -> { I18n.t("lib.canvas.migration.rubrics", "Rubrics") }],
      ["groups", -> { I18n.t("lib.canvas.migration.groups", "Student Groups") }],
      ["learning_outcomes", -> { I18n.t("lib.canvas.migration.learning_outcomes", "Learning Outcomes") }],
      ["attachments", -> { I18n.t("lib.canvas.migration.attachments", "Files") }],
    ].freeze

    def initialize(migration = nil, base_url = nil, global_identifiers:)
      @migration = migration
      @base_url = base_url
      @global_identifiers = global_identifiers
    end

    def valid_type?(type = nil)
      type.nil? || SELECTIVE_CONTENT_TYPES.any? { |t| t[0] == type } || type.start_with?("submodules_") || type.start_with?("learning_outcome_groups_")
    end

    def get_content_list(type = nil, source = nil)
      raise "unsupported migration type" unless valid_type?(type)

      if !@migration || @migration.migration_type == "course_copy_importer"
        get_content_from_course(type, source)
      elsif @migration.overview_attachment
        get_content_from_overview(type)
      else
        raise "course hasn't been converted"
      end
    end

    private

    def property_prefix
      @migration ? "copy" : "select"
    end

    # pulls the available items from the overview attachment on the content migration
    def get_content_from_overview(type = nil)
      course_data = Rails.cache.fetch(["migration_selective_cache", @migration.shard, @migration].cache_key, expires_in: 5.minutes) do
        att = @migration.overview_attachment.open
        data = JSON.parse(att.read)
        data = separate_announcements(data)
        data["attachments"] ||= data["file_map"]&.values
        data["quizzes"] ||= data["assessments"]
        data["context_modules"] ||= data["modules"]
        data["wiki_pages"] ||= data["wikis"]
        data["context_external_tools"] ||= data["external_tools"]
        data["learning_outcomes"] ||= data["outcomes"]

        # skip auto generated quiz question banks for canvas imports
        data["assessment_question_banks"]&.reject! do |item|
          item["for_quiz"] && @migration && (@migration.for_course_copy? || (@migration.migration_type == "canvas_cartridge_importer"))
        end

        att.close
        data
      end

      selectable_outcomes = @migration.context.respond_to?(:root_account) &&
                            @migration.context.root_account.feature_enabled?(:selectable_outcomes_in_course_copy)
      content_list = []
      if type
        if (match_data = type.match(/submodules_(.*)/))
          (submodule_data(course_data["context_modules"], match_data[1]) || []).each do |item|
            content_list << item_hash("context_modules", item)
          end
        elsif course_data[type]
          case type
          when "assignments"
            assignment_data(content_list, course_data)
          when "attachments"
            attachment_data(content_list, course_data)
          else
            processed = false
            if type == "learning_outcomes" && selectable_outcomes
              processed = !outcome_data(content_list, course_data).nil?
            end
            unless processed
              course_data[type].each do |item|
                content_list << item_hash(type, item)
              end
            end
          end
        end
      else
        if course_data["course"]
          content_list << { type: "course_settings", property: "#{property_prefix}[all_course_settings]", title: COURSE_SETTING_TYPE.call }
          if course_data["course"]["syllabus_body"]
            content_list << { type: "syllabus_body", property: "#{property_prefix}[all_syllabus_body]", title: COURSE_SYLLABUS_TYPE.call }
          end
        end
        if course_data["course_paces"]
          content_list << { type: "course_paces", property: "#{property_prefix}[all_course_paces]", title: COURSE_PACE_TYPE.call }
        end
        SELECTIVE_CONTENT_TYPES.each do |type2, title|
          next unless course_data[type2] && course_data[type2].count > 0

          hash = { type: type2, property: "#{property_prefix}[all_#{type2}]", title: title.call, count: course_data[type2].count }
          add_url!(hash, type2, selectable_outcomes)
          content_list << hash
        end
      end

      content_list
    end

    # Build learning outcome hierarchy
    def outcome_data(content_list, course_data)
      # Earlier exports may not have groups in course data
      return unless course_data["learning_outcome_groups"]

      outcomes = course_data["learning_outcomes"]
      course_data["learning_outcome_groups"].each do |group|
        content_list << process_group(group, outcomes)
      end
      content_list.concat(
        outcomes.select { |outcome| outcome["parent_migration_id"].nil? }.map { |outcome| item_hash("learning_outcomes", outcome) }
      )
    end

    def process_group(group, outcomes)
      item = item_hash("learning_outcome_groups", group)
      item[:sub_items] = group["child_groups"].map do |subgroup|
        process_group(subgroup, outcomes)
      end
      item[:sub_items].concat(
        outcomes.select { |outcome| outcome["parent_migration_id"] == group["migration_id"] }.map { |outcome| item_hash("learning_outcomes", outcome) }
      )
      item
    end

    # Returns all the assignments in their assignment groups
    def assignment_data(content_list, course_data)
      added_asmnts = []
      course_data["assignment_groups"]&.each do |group|
        item = item_hash("assignment_groups", group)
        sub_items = []
        course_data["assignments"].select { |a| a["assignment_group_migration_id"] == group["migration_id"] }.each do |asmnt|
          sub_items << item_hash("assignments", asmnt)
          added_asmnts << asmnt["migration_id"]
        end
        if sub_items.any?
          item["sub_items"] = sub_items
        end
        content_list << item
      end
      course_data["assignments"].each do |asmnt|
        next if added_asmnts.member? asmnt["migration_id"]

        content_list << item_hash("assignments", asmnt)
      end
    end

    def attachment_data(content_list, course_data)
      return [] unless course_data["attachments"].present?

      remove_name_regex = %r{/[^/]*\z}
      course_data["attachments"].each do |a|
        next unless a["path_name"]

        a["path_name"].gsub!(remove_name_regex, "")
      end
      folder_groups = course_data["attachments"].group_by { |a| a["path_name"] }
      sorted = folder_groups.sort_by(&:first)
      sorted.each do |folder_name, atts|
        if atts.length == 1 && atts[0]["file_name"] == folder_name
          content_list << item_hash("attachments", atts[0])
        else
          mig_id = Digest::MD5.hexdigest(folder_name)
          folder = { type: "folders", property: "#{property_prefix}[folders][id_#{mig_id}]", title: folder_name, migration_id: mig_id, sub_items: [] }
          content_list << folder
          atts.each { |att| folder[:sub_items] << item_hash("attachments", att) }
        end
      end
    end

    def item_hash(type, item)
      hash = {
        type:,
        property: "#{property_prefix}[#{type}][id_#{item["migration_id"]}]",
        title: item["title"],
        migration_id: item["migration_id"]
      }
      case type
      when "attachments"
        hash[:path] = item["path_name"]
        hash[:title] = item["file_name"]
      when "assessment_question_banks"
        if hash[:title].blank? && @migration && @migration.context.respond_to?(:assessment_question_banks)
          if hash[:migration_id] &&
             (bank = @migration.context.assessment_question_banks.where(migration_id: hash[:migration_id]).first)
            hash[:title] = bank.title
          elsif @migration.question_bank_id &&
                (default_bank = @migration.context.assessment_question_banks.where(id: @migration.question_bank_id).first)
            hash[:title] = default_bank.title
          end
          hash[:title] ||= @migration.question_bank_name || AssessmentQuestionBank.default_imported_title
          hash[:migration_id] ||= CC::CCHelper.create_key(hash[:title], "assessment_question_bank", global: @global_identifiers)
        end
      when "context_modules"
        hash[:item_count] = item["item_count"]
        if item["submodules"]
          hash[:submodule_count] = item["submodules"].count
          add_url!(hash, "submodules_#{CGI.escape(item["migration_id"])}")
        end
      end
      add_linked_resource(type, item, hash)
    end

    def add_linked_resource(type, item, hash)
      if type == "assignments"
        if (mig_id = item["quiz_migration_id"])
          hash[:linked_resource] = { type: "quizzes", migration_id: mig_id }
        elsif (mig_id = item["topic_migration_id"])
          hash[:linked_resource] = { type: "discussion_topics", migration_id: mig_id }
        elsif (mig_id = item["page_migration_id"])
          hash[:linked_resource] = { type: "wiki_pages", migration_id: mig_id }
        end
      elsif %w[discussion_topics quizzes wiki_pages].include?(type) &&
            (mig_id = item["assignment_migration_id"])
        hash[:linked_resource] = { type: "assignments", migration_id: mig_id }
      end
      hash
    end

    # returns lists of available content from a source course
    def get_content_from_course(type = nil, source = nil)
      source ||= @migration.source_course || Course.find(@migration.migration_settings[:source_course_id]) if @migration
      return [] unless source

      selectable_outcomes = source.root_account.feature_enabled?(:selectable_outcomes_in_course_copy)
      content_list = []
      source.shard.activate do
        if type
          case type
          when "assignments"
            course_assignment_data(content_list, source)
          when "attachments"
            course_attachments_data(content_list, source)
          when "wiki_pages"
            source.wiki_pages.not_deleted.select("id, title, assignment_id").each do |item|
              content_list << course_item_hash(type, item)
            end
          when "discussion_topics"
            source.discussion_topics.active.only_discussion_topics.select("id, title, user_id, assignment_id").except(:preload).each do |item|
              content_list << course_item_hash(type, item)
            end
          when "learning_outcomes"
            if selectable_outcomes
              root = source.root_outcome_group(false)
              if root
                add_learning_outcome_group_content(root, content_list)
              end
            else
              source.linked_learning_outcomes.active.select("learning_outcomes.id,short_description").each do |item|
                content_list << course_item_hash(type, item)
              end
            end
          when "tool_profiles"
            source.tool_proxies.active.select("id, name").each do |item|
              content_list << course_item_hash(type, item)
            end
          else
            if source.respond_to?(type)
              scope = source.send(type).select(:id).except(:preload)
              # We only need the id and name, so don't fetch everything from DB

              scope = scope.select(:assignment_id) if type == "quizzes"

              scope = if type == "context_modules" || type == "context_external_tools" || type == "groups"
                        scope.select(:name)
                      else
                        scope.select(:title)
                      end

              if scope.klass.respond_to?(:not_deleted)
                scope = scope.not_deleted
              elsif scope.klass.respond_to?(:active)
                scope = scope.active
              end

              scope.each do |item|
                content_list << course_item_hash(type, item)
              end
            elsif selectable_outcomes && (match_data = type.match(/learning_outcome_groups_(.*)/))
              group = source.learning_outcome_groups.find(match_data[1])
              add_learning_outcome_group_content(group, content_list)
            end
          end
        else
          content_list << { type: "course_settings", property: "#{property_prefix}[all_course_settings]", title: COURSE_SETTING_TYPE.call }
          content_list << { type: "syllabus_body", property: "#{property_prefix}[all_syllabus_body]", title: COURSE_SYLLABUS_TYPE.call }
          content_list << { type: "course_paces", property: "#{property_prefix}[all_course_paces]", title: COURSE_PACE_TYPE.call } if source.course_paces.primary.not_deleted.any?

          if @migration && MasterCourses::MasterTemplate.is_master_course?(source) && MasterCourses::MasterTemplate.blueprint_eligible?(@migration.context) &&
             (@migration.context.account.grants_any_right?(@migration.user, :manage_courses, :manage_courses_admin) && @migration.context.account.grants_right?(@migration.user, :manage_master_courses))
            content_list << { type: "blueprint_settings", property: "#{property_prefix}[all_blueprint_settings]", title: BLUEPRINT_SETTING_TYPE.call }
          end

          SELECTIVE_CONTENT_TYPES.each do |type2, title|
            next if type2 == "groups"

            count = 0
            if type2 == "discussion_topics"
              count = source.discussion_topics.active.only_discussion_topics.count
            elsif type2 == "learning_outcomes"
              count = source.linked_learning_outcomes.count
            elsif type2 == "tool_profiles"
              count = source.tool_proxies.active.count
            elsif source.respond_to?(type2) && source.send(type2).respond_to?(:count)
              scope = source.send(type2).except(:preload)
              if scope.klass.respond_to?(:not_deleted)
                scope = scope.not_deleted
              elsif scope.klass.respond_to?(:active)
                scope = scope.active
              end
              count = scope.count
            end

            next if count == 0

            hash = { type: type2, property: "#{property_prefix}[all_#{type2}]", title: title.call, count: }
            add_url!(hash, type2, selectable_outcomes)
            content_list << hash
          end
        end
      end

      content_list
    end

    def add_url!(hash, type, selectable_outcomes = false)
      return if !selectable_outcomes && type == "learning_outcomes"

      if @base_url
        hash[:sub_items_url] = @base_url + "?type=#{type}"
      end
    end

    def add_learning_outcome_group_content(group, content_list)
      group.child_outcome_groups.active.order_by_title.select("learning_outcome_groups.id,title").each do |item|
        hash = course_item_hash("learning_outcome_groups", item)
        add_url!(hash, "learning_outcome_groups_#{item.id}")
        content_list << hash
      end
      group.child_outcome_links.active.order_by_outcome_title.each do |item|
        content_list << course_item_hash("learning_outcomes", item.content)
      end
    end

    def course_item_hash(type, item, include_linked_resource = true)
      title = nil
      title ||= item.title if item.respond_to?(:title)
      title ||= item.full_name if item.respond_to?(:full_name)
      title ||= item.display_name if item.respond_to?(:display_name)
      title ||= item.name if item.respond_to?(:name)
      title ||= item.short_description if item.respond_to?(:short_description)
      title ||= ""

      hash = { type:, title: }
      if @migration
        mig_id = CC::CCHelper.create_key(item, global: @global_identifiers)
        hash[:migration_id] = mig_id
        hash[:property] = "#{property_prefix}[#{type}][id_#{mig_id}]"
      else
        hash[:id] = item.asset_string
      end
      hash = course_linked_resource(item, hash) if include_linked_resource

      hash
    end

    def course_linked_resource(item, hash)
      lr = nil
      if item.is_a?(Assignment)
        if item.quiz
          lr = course_item_hash("quizzes", item.quiz, false)
          lr[:message] = I18n.t("linked_quiz_message",
                                "linked with Quiz '%{title}'",
                                title: item.quiz.title)
        elsif item.discussion_topic
          lr = course_item_hash("discussion_topics", item.discussion_topic, false)
          lr[:message] = I18n.t("linked_discussion_topic_message",
                                "linked with Discussion Topic '%{title}'",
                                title: item.discussion_topic.title)
        elsif item.wiki_page
          lr = course_item_hash("wiki_pages", item.wiki_page, false)
          lr[:message] = I18n.t("linked with Wiki Page '%{title}'",
                                title: item.wiki_page.title)
        end
      elsif [DiscussionTopic, WikiPage, Quizzes::Quiz].any? { |t| item.is_a?(t) } && item.assignment
        lr = course_item_hash("assignments", item.assignment, false)
        lr[:message] = I18n.t("linked_assignment_message",
                              "linked with Assignment '%{title}'",
                              title: item.assignment.title)
      end
      if lr
        lr.delete(:title)
        hash[:linked_resource] = lr
      end
      hash
    end

    def course_assignment_data(content_list, source_course)
      source_course.assignment_groups.active.preload(:assignments).select("id, name").each do |group|
        item = course_item_hash("assignment_groups", group)
        content_list << item
        group.assignments.active.select(:id).select(:title).each do |asmnt|
          item[:sub_items] ||= []
          item[:sub_items] << course_item_hash("assignments", asmnt)
        end
      end
    end

    def course_attachments_data(content_list, source_course)
      Canvas::ICU.collate_by(source_course.folders.active.select("id, full_name, name").preload(:active_file_attachments), &:full_name).each do |folder|
        next if folder.active_file_attachments.empty?

        item = course_item_hash("folders", folder)
        item[:sub_items] = []
        content_list << item
        folder.active_file_attachments.each do |att|
          item[:sub_items] << course_item_hash("attachments", att)
        end
      end
    end

    def submodule_data(modules, parent_mig_id)
      if (mod = modules.detect { |m| m["migration_id"] == parent_mig_id })
        mod["submodules"]
      else
        modules.each do |m|
          if m["submodules"] && (sm_data = submodule_data(m["submodules"], parent_mig_id))
            return sm_data
          end
        end
        nil
      end
    end

    def separate_announcements(course_data)
      return course_data unless course_data["discussion_topics"]

      announcements, topics = course_data["discussion_topics"].partition { |topic_hash| topic_hash["type"] == "announcement" }

      if announcements.any?
        course_data["announcements"] ||= []
        course_data["announcements"] += announcements
        course_data["discussion_topics"] = topics
      end
      course_data
    end
  end
end
