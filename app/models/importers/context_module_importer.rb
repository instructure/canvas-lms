require_dependency 'importers'

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
      (data['modules'] || []).each do |mod|
        self.select_linked_module_items(mod, migration)
      end
    end

    def self.select_linked_module_items(mod, migration, select_all=false)
      if select_all || migration.import_object?("context_modules", mod['migration_id']) || migration.import_object?("modules", mod['migration_id'])
        (mod['items'] || []).each do |item|
          if item['type'] == 'submodule'
            # recursively select content in submodules
            self.select_linked_module_items(item, migration, true)
          elsif resource_class = linked_resource_type_class(item['linked_resource_type'])
            migration.import_object!(resource_class.table_name, item['linked_resource_id'])
          end
        end
      else
        (mod['items'] || []).each do |item|
          if item['type'] == 'submodule'
            self.select_linked_module_items(item, migration) # the parent may not be selected, but a sub-module may be
          end
        end
      end
    end

    def self.process_migration(data, migration)
      modules = data['modules'] ? data['modules'] : []
      migration.last_module_position = migration.context.context_modules.maximum(:position) if migration.is_a?(ContentMigration)

      modules.each do |mod|
        self.process_module(mod, migration)
      end
      migration.context.context_modules.first.try(:fix_position_conflicts)
      migration.context.touch
    end

    def self.process_module(mod, migration)
      if migration.import_object?("context_modules", mod['migration_id']) || migration.import_object?("modules", mod['migration_id'])
        begin
          self.import_from_migration(mod, migration.context, migration)
        rescue
          migration.add_import_warning(t('#migration.module_type', "Module"), mod[:title], $!)
        end
      else
        # recursively find sub modules
        (mod['items'] || []).each do |item|
          next unless item['type'] == 'submodule'
          self.process_module(item, migration)
        end
      end
    end

    def self.flatten_item(item, indent)
      if item['type'] == 'submodule'
        sub_items = []
        sub_items << {:type => 'heading', :title => item['title'], :indent => indent, :migration_id => item['migration_id']}.with_indifferent_access
        sub_items += (item['items'] || []).map{|item| self.flatten_item(item, indent + 1)}
        sub_items
      else
        item[:indent] = (item[:indent] || 0) + indent
        item
      end
    end

    def self.import_from_migration(hash, context, migration, item=nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:modules_to_import] && !hash[:modules_to_import][hash[:migration_id]]
      item ||= ContextModule.where(context_type: context.class.to_s, context_id: context, id: hash[:id]).first
      item ||= ContextModule.where(context_type: context.class.to_s, context_id: context, migration_id: hash[:migration_id]).first if hash[:migration_id]
      item ||= ContextModule.new(:context => context)
      item.migration_id = hash[:migration_id]
      migration.add_imported_item(item)
      item.name = hash[:title] || hash[:description]
      if hash[:workflow_state] == 'unpublished'
        item.workflow_state = 'unpublished' if item.new_record? || item.deleted? # otherwise leave it alone
      else
        item.workflow_state = 'active'
      end

      position = hash[:position] || hash[:order]
      if item.new_record? && migration.try(:last_module_position) # try to import new modules after current ones instead of interweaving positions
        position = migration.last_module_position + (position || 1)
      end
      item.position = position
      item.context = context
      item.unlock_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:unlock_at]) if hash[:unlock_at]
      item.start_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:start_at]) if hash[:start_at]
      item.end_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:end_at]) if hash[:end_at]
      item.require_sequential_progress = hash[:require_sequential_progress] if hash[:require_sequential_progress]
      item.requirement_count = hash[:requirement_count] if hash[:requirement_count]

      if hash[:prerequisites]
        preqs = []
        hash[:prerequisites].each do |prereq|
          if prereq[:module_migration_id]
            if ref_mod = ContextModule.where(context_type: context.class.to_s, context_id: context, migration_id: prereq[:module_migration_id]).first
              preqs << {:type=>"context_module", :name=>ref_mod.name, :id=>ref_mod.id}
            end
          end
        end
        item.prerequisites = preqs if preqs.length > 0
      end
      item.save!

      item_map = {}
      @item_migration_position = item.content_tags.not_deleted.map(&:position).compact.max || 0

      items = hash[:items] || []
      items = items.map{|item| self.flatten_item(item, 0)}.flatten

      imported_migration_ids = []

      items.each do |tag_hash|
        begin
          tags = self.add_module_item_from_migration(item, tag_hash, 0, context, item_map, migration)
          imported_migration_ids.concat tags.map(&:migration_id)
        rescue
          migration.add_import_warning(t(:migration_module_item_type, "Module Item"), tag_hash[:title], $!)
        end
      end

      item.content_tags.where.not(:migration_id => imported_migration_ids).destroy_all # clear out missing items afterwards

      if hash[:completion_requirements]
        c_reqs = []
        hash[:completion_requirements].each do |req|
          if item_ref = item_map[req[:item_migration_id]]
            req[:id] = item_ref.id
            req.delete :item_migration_id
            c_reqs << req
          end
        end
        if c_reqs.length > 0
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
      existing_item ||= ContentTag.new(:context_module => context_module, :context => context)
      migration.add_imported_item(existing_item)
      existing_item.migration_id = hash[:migration_id]
      hash[:indent] = [hash[:indent] || 0, level].max
      resource_class = linked_resource_type_class(hash[:linked_resource_type])
      if resource_class == WikiPage
        wiki = context_module.context.wiki.wiki_pages.where(migration_id: hash[:linked_resource_id]).first if hash[:linked_resource_id]
        if wiki
          item = context_module.add_item({
            :title => wiki.title.presence || hash[:title] || hash[:linked_resource_title],
            :type => 'wiki_page',
            :id => wiki.id,
            :indent => hash[:indent].to_i
          }, existing_item, :wiki_page => wiki, :position => context_module.migration_position)
        end
      elsif resource_class == Attachment
        file = context_module.context.attachments.not_deleted.where(migration_id: hash[:linked_resource_id]).first if hash[:linked_resource_id]
        if file
          title = hash[:title] || hash[:linked_resource_title]
          item = context_module.add_item({
            :title => title,
            :type => 'attachment',
            :id => file.id,
            :indent => hash[:indent].to_i
          }, existing_item, :attachment => file, :position => context_module.migration_position)
        end
      elsif resource_class == Assignment
        ass = context_module.context.assignments.where(migration_id: hash[:linked_resource_id]).first if hash[:linked_resource_id]
        if ass
          item = context_module.add_item({
            :title => ass.title.presence || hash[:title] || hash[:linked_resource_title],
            :type => 'assignment',
            :id => ass.id,
            :indent => hash[:indent].to_i
          }, existing_item, :assignment => ass, :position => context_module.migration_position)
        end
      elsif (hash[:linked_resource_type] || hash[:type]) =~ /folder|heading|contextmodulesubheader/i
        # just a snippet of text
        item = context_module.add_item({
          :title => hash[:title] || hash[:linked_resource_title],
          :type => 'context_module_sub_header',
          :indent => hash[:indent].to_i
        }, existing_item, :position => context_module.migration_position)
      elsif hash[:linked_resource_type] =~ /url/i
        # external url
        if url = hash[:url]
          if (CanvasHttp.validate_url(hash[:url]) rescue nil)
            url = migration.process_domain_substitutions(url)

            item = context_module.add_item({
              :title => hash[:title] || hash[:linked_resource_title] || hash['description'],
              :type => 'external_url',
              :indent => hash[:indent].to_i,
              :url => url
            }, existing_item, :position => context_module.migration_position)
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
        elsif arr = migration.find_external_tool_translation(hash[:linked_resource_id])
          external_tool_id = arr[0]
          custom_fields = arr[1]
          if custom_fields.present?
            external_tool_url = add_custom_fields_to_url(hash[:url], custom_fields) || hash[:url]
          end
        elsif hash[:linked_resource_id] && et = context_module.context.context_external_tools.active.where(migration_id: hash[:linked_resource_id]).first
          external_tool_id = et.id
        end

        if external_tool_url
          title = hash[:title] || hash[:linked_resource_title] || hash['description']

          external_tool_url = migration.process_domain_substitutions(external_tool_url)
          if external_tool_id.nil?
            migration.add_warning(t(:foreign_lti_tool,
                %q{The account External Tool for module item "%{title}" must be configured before the item can be launched},
                :title => title))
          end

          item = context_module.add_item({
            :title => title,
            :type => 'context_external_tool',
            :indent => hash[:indent].to_i,
            :url => external_tool_url,
            :id => external_tool_id
          }, existing_item, :position => context_module.migration_position)
        end
      elsif resource_class == Quizzes::Quiz
        quiz = context_module.context.quizzes.where(migration_id: hash[:linked_resource_id]).first if hash[:linked_resource_id]
        if quiz
          item = context_module.add_item({
            :title => quiz.title.presence || hash[:title] || hash[:linked_resource_title],
            :type => 'quiz',
            :indent => hash[:indent].to_i,
            :id => quiz.id
          }, existing_item, :quiz => quiz, :position => context_module.migration_position)
        end
      elsif resource_class == DiscussionTopic
        topic = context_module.context.discussion_topics.where(migration_id: hash[:linked_resource_id]).first if hash[:linked_resource_id]
        if topic && topic.is_announcement
          migration.add_warning(t("The announcement \"%{title}\" could not be linked to the module \"%{mod_title}\"", :title => hash[:title], :mod_title => context_module.name))
        elsif topic
          item = context_module.add_item({
            :title => topic.title.presence || hash[:title] || hash[:linked_resource_title],
            :type => 'discussion_topic',
            :indent => hash[:indent].to_i,
            :id => topic.id
          }, existing_item, :discussion_topic => topic, :position => context_module.migration_position)
        end
      elsif hash[:linked_resource_type] == 'UNSUPPORTED_TYPE'
        # We know what this is and that we don't support it
      else
        # We don't know what this is
      end
      items = []
      if item
        item_map[hash[:migration_id]] = item if hash[:migration_id]
        item.migration_id = hash[:migration_id]
        item.new_tab = hash[:new_tab]
        item.position = (context_module.item_migration_position ||= context_module.content_tags.not_deleted.map(&:position).compact.max || 0)
        if hash[:workflow_state] && ContentTag::TABLELESS_CONTENT_TYPES.include?(item.content_type) && !['active', 'published'].include?(item.workflow_state)
          item.workflow_state = hash[:workflow_state]
        end
        context_module.item_migration_position += 1
        item.save!
        items << item
      end
      if hash[:sub_items]
        hash[:sub_items].each do |tag_hash|
          items.concat self.add_module_item_from_migration(context_module, tag_hash, level + 1, context, item_map, migration)
        end
      end
      items
    end

    def self.add_custom_fields_to_url(original_url, custom_fields)
      return nil unless uri = URI.parse(original_url)

      custom_fields_query = custom_fields.map{|k, v| "custom_#{CGI.escape(k)}=#{CGI.escape(v)}"}.join("&")
      uri.query = uri.query.present? ? ([uri.query, custom_fields_query].join("&")) : custom_fields_query
      new_url = uri.to_s

      if new_url.length < MAX_URL_LENGTH
        return new_url
      else
        return nil
      end
    end

  end
end
