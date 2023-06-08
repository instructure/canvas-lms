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
  class WikiPageImporter < Importer
    self.item_class = WikiPage

    def self.process_migration_course_outline(data, migration)
      outline = data["course_outline"] || nil
      return unless outline
      return unless migration.import_object?("course_outline", outline["migration_id"])

      to_import = migration.to_import "outline_folders"

      outline["root_folder"] = true
      begin
        import_from_migration(outline.merge({ outline_folders_to_import: to_import }), migration.context, migration)
      rescue
        migration.add_warning("Error importing the course outline.", $!)
      end
    end

    def self.process_migration(data, migration)
      migration.context.conditional_release? # preload it so we don't try to do it inside a page transaction
      if migration.for_master_course_import? # make a tag if it doesn't exist
        migration.context.wiki.load_tag_for_master_course_import!(migration.child_subscription_id)
      end

      wikis = data["wikis"] || []
      wikis.each do |wiki|
        unless wiki
          message = "There was a nil wiki page imported for ContentMigration:#{migration.id}"
          Canvas::Errors.capture(:content_migration, message:)
          next
        end
        next unless wiki_page_migration?(migration, wiki)

        begin
          import_from_migration(wiki, migration.context, migration) if wiki
        rescue
          migration.add_import_warning(t("#migration.wiki_page_type", "Wiki Page"), wiki[:title], $!)
        end
      end
    end

    def self.wiki_page_migration?(migration, wiki)
      migration.import_object?("wiki_pages", wiki["migration_id"]) ||
        migration.import_object?("wikis", wiki["migration_id"])
    end
    private_class_method :wiki_page_migration?

    def self.import_from_migration(hash, context, migration, item = nil)
      hash = hash.with_indifferent_access
      item ||= WikiPage.where(wiki_id: context.wiki, id: hash[:id]).first
      item ||= WikiPage.where(wiki_id: context.wiki, migration_id: hash[:migration_id]).first
      item ||= context.wiki_pages.temp_record(wiki: context.wiki)
      item.mark_as_importing!(migration)

      # force the url to be the same as the url_name given, since there are
      # likely other resources in the import that link to that url
      if hash[:url_name].present?
        item.url = hash[:url_name].to_url
        item.only_when_blank = true
      end
      if hash[:root_folder].present? && ["folder", "FOLDER_TYPE"].member?(hash[:type])
        front_page = context.wiki.front_page
        if front_page&.id
          hash[:root_folder] = false
        else
          item.url ||= Wiki::DEFAULT_FRONT_PAGE_URL
          item.title ||= item.url.titleize
          item.set_as_front_page!
        end
      end
      hide_from_students = hash[:hide_from_students] unless hash[:hide_from_students].nil?
      state = hash[:workflow_state]
      if state && migration.for_master_course_import?
        item.workflow_state = state
      elsif state || !hide_from_students.nil?
        if state == "active" && !item.unpublished? && Canvas::Plugin.value_to_boolean(hide_from_students) == false
          item.workflow_state = "active"
        elsif item.new_record? || item.deleted?
          item.workflow_state = "unpublished"
        end
      elsif item.deleted?
        item.workflow_state = "unpublished"
      end

      if migration.for_master_course_import?
        if context.wiki.can_update_front_page_for_master_courses?
          if hash[:front_page]
            context.wiki.set_front_page_url!(item.url) unless item.unpublished?
          elsif item.persisted? && context.wiki.front_page == item
            context.wiki.unset_front_page!
          end
        end
      elsif !!hash[:front_page] && context.wiki.has_no_front_page
        item.set_as_front_page!
      end
      item.migration_id = hash[:migration_id]
      item.todo_date = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:todo_date])
      item.publish_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:publish_at])

      migration.add_imported_item(item)

      (hash[:contents] || []).each do |sub_item|
        next if sub_item[:type] == "embedded_content"

        Importers::WikiPageImporter.import_from_migration(sub_item.merge({
                                                                           outline_folders_to_import: hash[:outline_folders_to_import]
                                                                         }),
                                                          context,
                                                          migration)
      end
      return if hash[:type] && ["folder", "FOLDER_TYPE"].member?(hash[:type]) && hash[:linked_resource_id]

      allow_save = true
      if hash[:type] == "linked_resource" || hash[:type] == "URL_TYPE"
        allow_save = false
      elsif ["folder", "FOLDER_TYPE"].member? hash[:type]
        item.title = hash[:title] unless hash[:root_folder]
        description = ""
        if hash[:header]
          description += if hash[:header][:is_html]
                           migration.convert_html(hash[:header][:body], :wiki_page, hash[:migration_id], :body)
                         else
                           migration.convert_text(hash[:header][:body] || [""])
                         end
        end

        if hash[:description]
          description += migration.convert_html(hash[:description], :wiki_page, hash[:migration_id], :body)
        end

        contents = ""
        allow_save = false if hash[:migration_id] && hash[:outline_folders_to_import] && !hash[:outline_folders_to_import][hash[:migration_id]]
        hash[:contents].each do |sub_item|
          sub_item = sub_item.with_indifferent_access
          if ["folder", "FOLDER_TYPE"].member? sub_item[:type]
            obj = context.wiki_pages.where(migration_id: sub_item[:migration_id]).first
            contents += "  <li><a href='/courses/#{context.id}/pages/#{obj.url}'>#{obj.title}</a></li>\n" if obj
          elsif sub_item[:type] == "embedded_content"
            if contents.present?
              description += "<ul>\n#{contents}\n</ul>"
              contents = ""
            end
            description += "\n<h2>#{sub_item[:title]}</h2>\n" if sub_item[:title]

            if sub_item[:description]
              description += migration.convert_html(sub_item[:description], :wiki_page, hash[:migration_id], :body)
            end

          elsif sub_item[:type] == "linked_resource"
            case sub_item[:linked_resource_type]
            when "TOC_TYPE"
              obj = context.context_modules.not_deleted.where(migration_id: sub_item[:linked_resource_id]).first
              contents += "  <li><a href='/courses/#{context.id}/modules'>#{obj.name}</a></li>\n" if obj
            when "ASSESSMENT_TYPE"
              obj = context.quizzes.where(migration_id: sub_item[:linked_resource_id]).first
              contents += "  <li><a href='/courses/#{context.id}/quizzes/#{obj.id}'>#{obj.title}</a></li>\n" if obj
            when /PAGE_TYPE|WIKI_TYPE/
              obj = context.wiki_pages.where(migration_id: sub_item[:linked_resource_id]).first
              contents += "  <li><a href='/courses/#{context.id}/pages/#{obj.url}'>#{obj.title}</a></li>\n" if obj
            when "FILE_TYPE"
              file = context.attachments.where(migration_id: sub_item[:linked_resource_id]).first
              if file
                name = sub_item[:linked_resource_title] || file.name
                contents += " <li><a href=\"/courses/#{context.id}/files/#{file.id}/download\">#{name}</a></li>"
              end
            when "DISCUSSION_TOPIC_TYPE"
              obj = context.discussion_topics.where(migration_id: sub_item[:linked_resource_id]).first
              contents += "  <li><a href='/courses/#{context.id}/discussion_topics/#{obj.id}'>#{obj.title}</a></li>\n" if obj
            when "URL_TYPE"
              contents += if sub_item["title"] && sub_item["description"] && sub_item["title"] != "" && sub_item["description"] != ""
                            " <li><a href='#{sub_item["url"]}'>#{sub_item["title"]}</a><ul><li>#{sub_item["description"]}</li></ul></li>\n"
                          else
                            " <li><a href='#{sub_item["url"]}'>#{sub_item["title"] || sub_item["description"]}</a></li>\n"
                          end
            end
          end
        end
        description += "<ul>\n#{contents}\n</ul>" if contents.present?

        if hash[:footer]
          description += if hash[:footer][:is_html]
                           migration.convert_html(hash[:footer][:body], :wiki_page, hash[:migration_id], :body)
                         else
                           migration.convert_text(hash[:footer][:body] || "")
                         end
        end

        item.body = description
        allow_save = false if description.blank?
      # elsif hash[:page_type] == "module_toc"
      elsif hash[:topics]
        item.title = t("title_for_topics_category", "%{category} Topics", category: hash[:category_name])
        description = (hash[:category_description]).to_s
        description += "\n\n<ul>\n"
        topic_count = 0
        hash[:topics].each do |topic|
          topic = Importers::DiscussionTopicImporter.import_from_migration(topic.merge({
                                                                                         topics_to_import: hash[:topics_to_import],
                                                                                         topic_entries_to_import: hash[:topic_entries_to_import]
                                                                                       }),
                                                                           context,
                                                                           migration)
          if topic
            topic_count += 1
            description += "  <li><a href='/#{context.class.to_s.downcase.pluralize}/#{context.id}/discussion_topics/#{topic.id}'>#{topic.title}</a></li>\n"
          end
        end
        description += "</ul>"
        item.body = description
        return nil if topic_count == 0
      elsif hash[:title] && hash[:text]
        # it's an actual wiki page
        item.title = hash[:title].presence || item.url.presence || "unnamed page"
        if item.title.length > WikiPage::TITLE_LENGTH
          migration.add_warning(t("warnings.truncated_wiki_title",
                                  "The title of the following wiki page was truncated: %{title}",
                                  title: item.title))
          item.title.splice!(0...WikiPage::TITLE_LENGTH) # truncate too-long titles
        end

        item.body = migration.convert_html(hash[:text], :wiki_page, hash[:migration_id], :body)

        item.editing_roles = hash[:editing_roles] if hash[:editing_roles].present?
        item.notify_of_update = hash[:notify_of_update] unless hash[:notify_of_update].nil?
      else # rubocop:disable Lint/DuplicateBranch
        allow_save = false
      end
      if allow_save && hash[:migration_id]
        if hash[:assignment].present? && context.conditional_release?
          hash[:assignment][:title] ||= item.title
          item.assignment = Importers::AssignmentImporter.import_from_migration(
            hash[:assignment], context, migration
          )
        else
          item.assignment = nil
        end
        if item.changed?
          item.user = nil
        end
        item.save_without_broadcasting!
        migration.add_imported_item(item)
        item
      end
    end
  end
end
