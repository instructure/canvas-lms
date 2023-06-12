# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
  class ContextModuleImporter < Importer
    self.item_class = ContextModule

    MAX_URL_LENGTH = 2000

    def self.linked_resource_type_class(type)
      case type
      when /wiki_type|wikipage/i
        WikiPage
      when /page_type|file_type|attachment/i
        Attachment
      when /assignment|project/i
        Assignment
      when /discussion|topic/i
        DiscussionTopic
      when /assessment|quiz/i
        Quizzes::Quiz
      when /contextexternaltool/i
        ContextExternalTool
      end
    end

    def self.select_all_linked_module_items(data, migration)
      return if migration.import_everything?

      (data["modules"] || []).each do |mod|
        select_linked_module_items(mod, migration)
      end
    end

    def self.select_linked_module_items(mod, migration, select_all = false)
      if select_all || migration.import_object?("context_modules", mod["migration_id"]) || migration.import_object?("modules", mod["migration_id"])
        (mod["items"] || []).each do |item|
          if item["type"] == "submodule"
            # recursively select content in submodules
            select_linked_module_items(item, migration, true)
          elsif (resource_class = linked_resource_type_class(item["linked_resource_type"]))
            migration.import_object!(resource_class.table_name, item["linked_resource_id"])
          end
        end
      else
        (mod["items"] || []).each do |item|
          if item["type"] == "submodule"
            select_linked_module_items(item, migration) # the parent may not be selected, but a sub-module may be
          end
        end
      end
    end

    def self.process_migration(data, migration)
      modules = data["modules"] || []
      migration.last_module_position = migration.context.context_modules.maximum(:position) if migration.is_a?(ContentMigration)

      modules.each do |mod|
        process_module(mod, migration)
      end
      migration.context.context_modules.first.try(:fix_position_conflicts)
      migration.context.touch
    end

    def self.process_module(mod, migration)
      if migration.import_object?("context_modules", mod["migration_id"]) || migration.import_object?("modules", mod["migration_id"])
        begin
          import_from_migration(mod, migration.context, migration)
        rescue
          migration.add_import_warning(t("#migration.module_type", "Module"), mod[:title], $!)
        end
      else
        # recursively find sub modules
        (mod["items"] || []).each do |item|
          next unless item["type"] == "submodule"

          process_module(item, migration)
        end
      end
    end

    def self.flatten_item(item, indent)
      if item["type"] == "submodule"
        sub_items = []
        sub_items << { type: "heading", title: item["title"], indent:, migration_id: item["migration_id"] }.with_indifferent_access
        sub_items += (item["items"] || []).map { |i| flatten_item(i, indent + 1) }
        sub_items
      else
        item[:indent] = (item[:indent] || 0) + indent
        item
      end
    end

    def self.import_from_migration(hash, context, migration, item = nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:modules_to_import] && !hash[:modules_to_import][hash[:migration_id]]

      item ||= ContextModule.where(context_type: context.class.to_s, context_id: context, id: hash[:id]).first
      item ||= ContextModule.where(context_type: context.class.to_s, context_id: context, migration_id: hash[:migration_id]).first if hash[:migration_id]
      item ||= ContextModule.new(context:)
      item.migration_id = hash[:migration_id]
      migration.add_imported_item(item)
      item.name = hash[:title] || hash[:description]
      item.mark_as_importing!(migration)

      if item.deleted? && migration.for_master_course_import? &&
         migration.master_course_subscription.content_tag_for(item)&.downstream_changes&.include?("manually_deleted")
        return # it's been deleted downstream, just leave it (and any imported items) alone and return
      end

      if hash[:workflow_state] == "unpublished"
        item.workflow_state = "unpublished" if item.new_record? || item.deleted? || migration.for_master_course_import? # otherwise leave it alone
      else
        item.workflow_state = "active"
      end

      position = (hash[:position] || hash[:order])&.to_i
      if (item.new_record? || item.workflow_state_was == "deleted") && migration.try(:last_module_position) # try to import new modules after current ones instead of interweaving positions
        position = migration.last_module_position + (position || 1)
      end
      item.position = position
      item.context = context

      if hash.key?(:unlock_at) && (migration.for_master_course_import? || hash[:unlock_at].present?)
        item.unlock_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:unlock_at])
      end

      item.require_sequential_progress = hash[:require_sequential_progress] if hash.key?(:require_sequential_progress)
      item.requirement_count = hash[:requirement_count] if hash.key?(:requirement_count)

      if hash[:prerequisites]
        preqs = []
        hash[:prerequisites].each do |prereq|
          if prereq[:module_migration_id] &&
             (ref_mod = ContextModule.where(context_type: context.class.to_s, context_id: context, migration_id: prereq[:module_migration_id]).first)
            preqs << { type: "context_module", name: ref_mod.name, id: ref_mod.id }
          end
        end
        item.prerequisites = preqs if !preqs.empty? || migration.for_master_course_import?
      end
      item.save!

      item_map = {}
      manually_created_items = item.content_tags.not_deleted.where(migration_id: nil).pluck(:position).compact
      item.item_migration_position ||= (manually_created_items + [manually_created_items.count]).max
      items = hash[:items] || []
      items = items.map { |i| flatten_item(i, 0) }.flatten

      imported_migration_ids = []
      items.each do |tag_hash|
        tags = add_module_item_from_migration(item, tag_hash, 0, context, item_map, migration)
        imported_migration_ids.concat tags.map(&:migration_id)
      rescue
        migration.add_import_warning(t(:migration_module_item_type, "Module Item"), tag_hash[:title], $!)
      end

      item.content_tags.where.not(migration_id: nil)
          .where.not(migration_id: imported_migration_ids).each do |tag|
        tag.skip_downstream_changes!
        tag.destroy # clear out missing items afterwards
      end

      item.content_tags.first&.fix_position_conflicts

      if hash[:completion_requirements]
        c_reqs = []
        hash[:completion_requirements].each do |req|
          next unless (item_ref = item_map[req[:item_migration_id]])

          req[:id] = item_ref.id
          req.delete :item_migration_id
          c_reqs << req
        end
        if !c_reqs.empty? || migration.for_master_course_import? # allow clearing requirements on sync
          item.completion_requirements = c_reqs
          item.save
        end
      end

      item
    end

    def self.add_module_item_from_migration(context_module, hash, level, context, item_map, migration)
      hash = hash.with_indifferent_access
      hash[:migration_id] ||= hash[:item_migration_id]
      hash[:migration_id] ||= Digest::MD5.hexdigest(hash[:title]) if hash[:title]
      existing_item = context_module.content_tags.where(id: hash[:id]).first if hash[:id].present?
      existing_item ||= context_module.content_tags.where(migration_id: hash[:migration_id]).first if hash[:migration_id]
      existing_item ||= ContentTag.new(context_module:, context:)

      existing_item.mark_as_importing!(migration)
      migration.add_imported_item(existing_item)

      existing_item.migration_id = hash[:migration_id]
      hash[:indent] = [hash[:indent] || 0, level].max
      resource_class = linked_resource_type_class(hash[:linked_resource_type])
      if resource_class == WikiPage
        wiki = context_module.context.wiki_pages.where(migration_id: hash[:linked_resource_id]).first if hash[:linked_resource_id]
        if wiki
          item = context_module.add_item({
                                           title: wiki.title.presence || hash[:title] || hash[:linked_resource_title],
                                           type: "wiki_page",
                                           id: wiki.id,
                                           indent: hash[:indent].to_i
                                         },
                                         existing_item,
                                         wiki_page: wiki,
                                         position: context_module.migration_position)
        end
      elsif resource_class == Attachment
        file = context_module.context.attachments.not_deleted.where(migration_id: hash[:linked_resource_id]).first if hash[:linked_resource_id]
        if file
          title = hash[:title] || hash[:linked_resource_title]
          item = context_module.add_item({
                                           title:,
                                           type: "attachment",
                                           id: file.id,
                                           indent: hash[:indent].to_i
                                         },
                                         existing_item,
                                         attachment: file,
                                         position: context_module.migration_position)
        end
      elsif resource_class == Assignment
        ass = context_module.context.assignments.where(migration_id: hash[:linked_resource_id]).first if hash[:linked_resource_id]
        if ass
          item = context_module.add_item({
                                           title: ass.title.presence || hash[:title] || hash[:linked_resource_title],
                                           type: "assignment",
                                           id: ass.id,
                                           indent: hash[:indent].to_i
                                         },
                                         existing_item,
                                         assignment: ass,
                                         position: context_module.migration_position)
        end
      elsif /folder|heading|contextmodulesubheader/i.match?((hash[:linked_resource_type] || hash[:type]))
        # just a snippet of text
        item = context_module.add_item({
                                         title: hash[:title] || hash[:linked_resource_title],
                                         type: "context_module_sub_header",
                                         indent: hash[:indent].to_i
                                       },
                                       existing_item,
                                       position: context_module.migration_position)
      elsif /url/i.match?(hash[:linked_resource_type])
        # external url
        if (url = hash[:url])
          if (CanvasHttp.validate_url(hash[:url]) rescue nil)
            url = migration.process_domain_substitutions(url)

            item = context_module.add_item({
                                             title: hash[:title] || hash[:linked_resource_title] || hash["description"],
                                             type: "external_url",
                                             indent: hash[:indent].to_i,
                                             url:
                                           },
                                           existing_item,
                                           position: context_module.migration_position)
          else
            migration.add_import_warning(t(:migration_module_item_type, "Module Item"), hash[:title], "#{hash[:url]} is not a valid URL")
          end
        end
      elsif resource_class == ContextExternalTool
        # external tool
        external_tool_id = nil
        external_tool_url = hash[:url]

        if hash[:linked_resource_global_id] && (!migration || !migration.cross_institution?)
          external_tool_id = hash[:linked_resource_global_id]
        elsif (arr = migration.find_external_tool_translation(hash[:linked_resource_id]))
          external_tool_id = arr[0]
          custom_fields = arr[1]
          if custom_fields.present?
            external_tool_url = add_custom_fields_to_url(hash[:url], custom_fields) || hash[:url]
          end
        elsif hash[:linked_resource_id] && (et = context_module.context.context_external_tools.active.where(migration_id: hash[:linked_resource_id]).first)
          external_tool_id = et.id
        end

        if external_tool_url
          title = hash[:title] || hash[:linked_resource_title] || hash["description"]

          external_tool_url = migration.process_domain_substitutions(external_tool_url)
          if external_tool_id.nil?
            migration.add_warning(t(:foreign_lti_tool,
                                    'The account External Tool for module item "%{title}" must be configured before the item can be launched',
                                    title:))
          end

          item = context_module.add_item({
                                           title:,
                                           type: "context_external_tool",
                                           indent: hash[:indent].to_i,
                                           url: external_tool_url,
                                           id: external_tool_id,
                                           lti_resource_link_lookup_uuid: hash[:lti_resource_link_lookup_uuid]
                                         },
                                         existing_item,
                                         position: context_module.migration_position)
          if hash[:link_settings_json]
            item.link_settings = JSON.parse(hash[:link_settings_json])
          end
          if item.associated_asset && item.associated_asset_id.nil?
            migration.add_warning(
              t(
                "The External Tool resource link (including any possible custom " \
                'parameters) could not be set for module item "%{title}"',
                title:
              )
            )
          end
        end
      elsif resource_class == Quizzes::Quiz
        quiz = context_module.context.quizzes.where(migration_id: hash[:linked_resource_id]).first if hash[:linked_resource_id]
        if quiz
          item = context_module.add_item({
                                           title: quiz.title.presence || hash[:title] || hash[:linked_resource_title],
                                           type: "quiz",
                                           indent: hash[:indent].to_i,
                                           id: quiz.id
                                         },
                                         existing_item,
                                         quiz:,
                                         position: context_module.migration_position)
        end
      elsif resource_class == DiscussionTopic
        topic = context_module.context.discussion_topics.where(migration_id: hash[:linked_resource_id]).first if hash[:linked_resource_id]
        if topic&.is_announcement
          migration.add_warning(t("The announcement \"%{title}\" could not be linked to the module \"%{mod_title}\"", title: hash[:title], mod_title: context_module.name))
        elsif topic
          item = context_module.add_item({
                                           title: topic.title.presence || hash[:title] || hash[:linked_resource_title],
                                           type: "discussion_topic",
                                           indent: hash[:indent].to_i,
                                           id: topic.id
                                         },
                                         existing_item,
                                         discussion_topic: topic,
                                         position: context_module.migration_position)
        end
      elsif hash[:linked_resource_type] == "UNSUPPORTED_TYPE"
        # We know what this is and that we don't support it
      else
        nil # We don't know what this is
      end
      items = []
      if item
        item_map[hash[:migration_id]] = item if hash[:migration_id]
        item.migration_id = hash[:migration_id]
        item.new_tab = hash[:new_tab]
        # add imported items starting from the last manually created item
        context_module.item_migration_position ||= 0
        context_module.item_migration_position += 1
        item.position = context_module.item_migration_position

        item.mark_as_importing!(migration)
        if hash[:workflow_state]
          if item.sync_workflow_state_to_asset?
            item.workflow_state = item.asset_workflow_state if item.deleted? && hash[:workflow_state] != "deleted"
          elsif !["active", "published"].include?(item.workflow_state) || migration.for_master_course_import?
            item.workflow_state = hash[:workflow_state]
          end
        end

        item.save!
        items << item
      end
      hash[:sub_items]&.each do |tag_hash|
        items.concat add_module_item_from_migration(context_module, tag_hash, level + 1, context, item_map, migration)
      end
      items
    end

    def self.add_custom_fields_to_url(original_url, custom_fields)
      return nil unless (uri = URI.parse(original_url))

      custom_fields_query = custom_fields.map { |k, v| "custom_#{CGI.escape(k)}=#{CGI.escape(v)}" }.join("&")
      uri.query = uri.query.present? ? [uri.query, custom_fields_query].join("&") : custom_fields_query
      new_url = uri.to_s

      if new_url.length < MAX_URL_LENGTH
        new_url
      else
        nil
      end
    end
  end
end
