module Importers
  class WikiPageImporter < Importer

    self.item_class = WikiPage

    def self.process_migration_course_outline(data, migration)
      outline = data['course_outline'] ? data['course_outline']: nil
      return unless outline
      to_import = migration.to_import 'outline_folders'

      outline['root_folder'] = true
      begin
        self.import_from_migration(outline.merge({:outline_folders_to_import => to_import}), migration.context)
      rescue
        migration.add_warning("Error importing the course outline.", $!)
      end
    end

    def self.process_migration(data, migration)
      wikis = data['wikis'] ? data['wikis']: []
      wikis.each do |wiki|
        if !wiki
          ErrorReport.log_error(:content_migration, :message => "There was a nil wiki page imported for ContentMigration:#{migration.id}")
          next
        end
        next unless migration.import_object?("wiki_pages", wiki['migration_id']) || migration.import_object?("wikis", wiki['migration_id'])
        begin
          self.import_from_migration(wiki, migration.context) if wiki
        rescue
          migration.add_import_warning(t('#migration.wiki_page_type', "Wiki Page"), wiki[:title], $!)
        end
      end
    end

    def self.import_from_migration(hash, context, item=nil)
      hash = hash.with_indifferent_access
      item ||= WikiPage.find_by_wiki_id_and_id(context.wiki.id, hash[:id])
      item ||= WikiPage.find_by_wiki_id_and_migration_id(context.wiki.id, hash[:migration_id])
      item ||= context.wiki.wiki_pages.new
      # force the url to be the same as the url_name given, since there are
      # likely other resources in the import that link to that url
      if hash[:url_name].present?
        item.url = hash[:url_name].to_url
        item.only_when_blank = true
      end
      if hash[:root_folder] && ['folder', 'FOLDER_TYPE'].member?(hash[:type])
        front_page = context.wiki.front_page
        if front_page.id
          hash[:root_folder] = false
        else
          # If there is no id there isn't a front page yet
          item = front_page
        end
      end
      hide_from_students = hash[:hide_from_students] if !hash[:hide_from_students].nil?
      state = hash[:workflow_state]
      if state || !hide_from_students.nil?
        if state == 'active' && Canvas::Plugin.value_to_boolean(hide_from_students) == false
          item.workflow_state = 'active'
        else
          item.workflow_state = 'unpublished'
        end
      end
      item.set_as_front_page! if !!hash[:front_page] && context.wiki.has_no_front_page
      context.imported_migration_items << item if context.imported_migration_items && item.new_record?
      item.migration_id = hash[:migration_id]
      (hash[:contents] || []).each do |sub_item|
        next if sub_item[:type] == 'embedded_content'
        Importers::WikiPageImporter.import_from_migration(sub_item.merge({
            :outline_folders_to_import => hash[:outline_folders_to_import]
        }), context)
      end
      return if hash[:type] && ['folder', 'FOLDER_TYPE'].member?(hash[:type]) && hash[:linked_resource_id]
      hash[:missing_links] = {}
      allow_save = true
      if hash[:type] == 'linked_resource' || hash[:type] == "URL_TYPE"
        allow_save = false
      elsif ['folder', 'FOLDER_TYPE'].member? hash[:type]
        item.title = hash[:title] unless hash[:root_folder]
        description = ""
        if hash[:header]
          hash[:missing_links][:field] = []
          description += hash[:header][:is_html] ? ImportedHtmlConverter.convert(hash[:header][:body] || "", context, {:missing_links => hash[:missing_links][:header]}) : ImportedHtmlConverter.convert_text(hash[:header][:body] || [""], context)
        end
        hash[:missing_links][:description] = []
        description += ImportedHtmlConverter.convert(hash[:description], context, {:missing_links => hash[:missing_links][:description]}) if hash[:description]
        contents = ""
        allow_save = false if hash[:migration_id] && hash[:outline_folders_to_import] && !hash[:outline_folders_to_import][hash[:migration_id]]
        hash[:contents].each do |sub_item|
          sub_item = sub_item.with_indifferent_access
          if ['folder', 'FOLDER_TYPE'].member? sub_item[:type]
            obj = context.wiki.wiki_pages.find_by_migration_id(sub_item[:migration_id])
            contents += "  <li><a href='/courses/#{context.id}/wiki/#{obj.url}'>#{obj.title}</a></li>\n" if obj
          elsif sub_item[:type] == 'embedded_content'
            if contents && contents.length > 0
              description += "<ul>\n#{contents}\n</ul>"
              contents = ""
            end
            description += "\n<h2>#{sub_item[:title]}</h2>\n" if sub_item[:title]
            hash[:missing_links][:sub_item] = []
            description += ImportedHtmlConverter.convert(sub_item[:description], context, {:missing_links => hash[:missing_links][:sub_item]}) if sub_item[:description]
          elsif sub_item[:type] == 'linked_resource'
            case sub_item[:linked_resource_type]
              when 'TOC_TYPE'
                obj = context.context_modules.not_deleted.find_by_migration_id(sub_item[:linked_resource_id])
                contents += "  <li><a href='/courses/#{context.id}/modules'>#{obj.name}</a></li>\n" if obj
              when 'ASSESSMENT_TYPE'
                obj = context.quizzes.find_by_migration_id(sub_item[:linked_resource_id])
                contents += "  <li><a href='/courses/#{context.id}/quizzes/#{obj.id}'>#{obj.title}</a></li>\n" if obj
              when /PAGE_TYPE|WIKI_TYPE/
                obj = context.wiki.wiki_pages.find_by_migration_id(sub_item[:linked_resource_id])
                contents += "  <li><a href='/courses/#{context.id}/wiki/#{obj.url}'>#{obj.title}</a></li>\n" if obj
              when 'FILE_TYPE'
                file = context.attachments.find_by_migration_id(sub_item[:linked_resource_id])
                if file
                  name = sub_item[:linked_resource_title] || file.name
                  contents += " <li><a href=\"/courses/#{context.id}/files/#{file.id}/download\">#{name}</a></li>"
                end
              when 'DISCUSSION_TOPIC_TYPE'
                obj = context.discussion_topics.find_by_migration_id(sub_item[:linked_resource_id])
                contents += "  <li><a href='/courses/#{context.id}/discussion_topics/#{obj.id}'>#{obj.title}</a></li>\n" if obj
              when 'URL_TYPE'
                if sub_item['title'] && sub_item['description'] && sub_item['title'] != '' && sub_item['description'] != ''
                  contents += " <li><a href='#{sub_item['url']}'>#{sub_item['title']}</a><ul><li>#{sub_item['description']}</li></ul></li>\n"
                else
                  contents += " <li><a href='#{sub_item['url']}'>#{sub_item['title'] || sub_item['description']}</a></li>\n"
                end
            end
          end
        end
        description += "<ul>\n#{contents}\n</ul>" if contents && contents.length > 0
        if hash[:footer]
          hash[:missing_links][:footer] = []
          description += hash[:footer][:is_html] ? ImportedHtmlConverter.convert(hash[:footer][:body] || "", context, {:missing_links => hash[:missing_links][:footer]}) : ImportedHtmlConverter.convert_text(hash[:footer][:body] || [""], context)
        end
        item.body = description
        allow_save = false if !description || description.empty?
      elsif hash[:page_type] == 'module_toc'
      elsif hash[:topics]
        item.title = t('title_for_topics_category', '%{category} Topics', :category => hash[:category_name])
        description = "#{hash[:category_description]}"
        description += "\n\n<ul>\n"
        topic_count = 0
        hash[:topics].each do |topic|
          topic = Importers::DiscussionTopicImporter.import_from_migration(topic.merge({
             :topics_to_import => hash[:topics_to_import],
             :topic_entries_to_import => hash[:topic_entries_to_import]
         }), context)
          if topic
            topic_count += 1
            description += "  <li><a href='/#{context.class.to_s.downcase.pluralize}/#{context.id}/discussion_topics/#{topic.id}'>#{topic.title}</a></li>\n"
          end
        end
        description += "</ul>"
        item.body = description
        return nil if topic_count == 0
      elsif hash[:title] and hash[:text]
        #it's an actual wiki page
        item.title = hash[:title].presence || item.url.presence || "unnamed page"
        if item.title.length > WikiPage::TITLE_LENGTH
          if context.respond_to?(:content_migration) && context.content_migration
            context.content_migration.add_warning(t('warnings.truncated_wiki_title', "The title of the following wiki page was truncated: %{title}", :title => item.title))
          end
          item.title.splice!(0...WikiPage::TITLE_LENGTH) # truncate too-long titles
        end
        hash[:missing_links][:body] = []
        item.body = ImportedHtmlConverter.convert(hash[:text] || "", context, {:missing_links => hash[:missing_links][:body]})
        item.editing_roles = hash[:editing_roles] if hash[:editing_roles].present?
        item.notify_of_update = hash[:notify_of_update] if !hash[:notify_of_update].nil?
      else
        allow_save = false
      end
      if allow_save && hash[:migration_id]
        item.save_without_broadcasting!
        context.imported_migration_items << item if context.imported_migration_items
        if context.respond_to?(:content_migration) && context.content_migration
          hash[:missing_links].each do |field, missing_links|
            context.content_migration.add_missing_content_links(:class => item.class.to_s,
              :id => item.id, :field => field, :missing_links => missing_links,
              :url => "/#{context.class.to_s.underscore.pluralize}/#{context.id}/wiki/#{item.url}")
          end
        end
        return item
      end
    end
  end
end
