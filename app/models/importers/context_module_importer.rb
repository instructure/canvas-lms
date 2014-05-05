module Importers
  class ContextModuleImporter < Importer

    self.item_class = ContextModule

    def self.process_migration(data, migration)
      modules = data['modules'] ? data['modules'] : []
      modules.each do |mod|
        if migration.import_object?("context_modules", mod['migration_id']) || migration.import_object?("modules", mod['migration_id'])
          begin
            self.import_from_migration(mod, migration.context, migration)
          rescue
            migration.add_import_warning(t('#migration.module_type', "Module"), mod[:title], $!)
          end
        end
      end
      migration.context.context_modules.first.try(:fix_position_conflicts)
      migration.context.touch
    end

    def self.import_from_migration(hash, context, migration=nil, item=nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:modules_to_import] && !hash[:modules_to_import][hash[:migration_id]]
      item ||= ContextModule.find_by_context_type_and_context_id_and_id(context.class.to_s, context.id, hash[:id])
      item ||= ContextModule.find_by_context_type_and_context_id_and_migration_id(context.class.to_s, context.id, hash[:migration_id]) if hash[:migration_id]
      item ||= ContextModule.new(:context => context)
      migration.add_imported_item(item) if migration && item.new_record?
      item.name = hash[:title] || hash[:description]
      item.migration_id = hash[:migration_id]
      if hash[:workflow_state] == 'unpublished'
        item.workflow_state = 'unpublished'
      else
        item.workflow_state = 'active'
      end

      item.position = hash[:position] || hash[:order]
      item.context = context
      item.unlock_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:unlock_at]) if hash[:unlock_at]
      item.start_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:start_at]) if hash[:start_at]
      item.end_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:end_at]) if hash[:end_at]
      item.require_sequential_progress = hash[:require_sequential_progress] if hash[:require_sequential_progress]

      if hash[:prerequisites]
        preqs = []
        hash[:prerequisites].each do |prereq|
          if prereq[:module_migration_id]
            if ref_mod = ContextModule.find_by_context_type_and_context_id_and_migration_id(context.class.to_s, context.id, prereq[:module_migration_id])
              preqs << {:type=>"context_module", :name=>ref_mod.name, :id=>ref_mod.id}
            end
          end
        end
        item.prerequisites = preqs if preqs.length > 0
      end

      # Clear the old tags to be replaced by new ones
      item.content_tags.destroy_all
      item.save!

      item_map = {}
      @item_migration_position = item.content_tags.not_deleted.map(&:position).compact.max || 0
      (hash[:items] || []).each do |tag_hash|
        begin
          self.add_module_item_from_migration(item, tag_hash, 0, context, item_map, migration)
        rescue
          migration.add_import_warning(t(:migration_module_item_type, "Module Item"), tag_hash[:title], $!) if migration
        end
      end

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


    def self.add_module_item_from_migration(context_module, hash, level, context, item_map, migration=nil)
      hash = hash.with_indifferent_access
      hash[:migration_id] ||= hash[:item_migration_id]
      hash[:migration_id] ||= Digest::MD5.hexdigest(hash[:title]) if hash[:title]
      existing_item = context_module.content_tags.find_by_id(hash[:id]) if hash[:id].present?
      existing_item ||= context_module.content_tags.find_by_migration_id(hash[:migration_id]) if hash[:migration_id]
      existing_item ||= context_module.content_tags.new(:context => context)
      if hash[:workflow_state] == 'unpublished'
        existing_item.workflow_state = 'unpublished'
      else
        existing_item.workflow_state = 'active'
      end
      migration.add_imported_item(existing_item) if migration && existing_item.new_record?
      existing_item.migration_id = hash[:migration_id]
      hash[:indent] = [hash[:indent] || 0, level].max
      if hash[:linked_resource_type] =~ /wiki_type|wikipage/i
        wiki = context_module.context.wiki.wiki_pages.find_by_migration_id(hash[:linked_resource_id]) if hash[:linked_resource_id]
        if wiki
          item = context_module.add_item({
            :title => hash[:title] || hash[:linked_resource_title],
            :type => 'wiki_page',
            :id => wiki.id,
            :indent => hash[:indent].to_i
          }, existing_item, :wiki_page => wiki, :position => context_module.migration_position)
        end
      elsif hash[:linked_resource_type] =~ /page_type|file_type|attachment/i
        # this is a file of some kind
        file = context_module.context.attachments.active.find_by_migration_id(hash[:linked_resource_id]) if hash[:linked_resource_id]
        if file
          title = hash[:title] || hash[:linked_resource_title]
          item = context_module.add_item({
            :title => title,
            :type => 'attachment',
            :id => file.id,
            :indent => hash[:indent].to_i
          }, existing_item, :attachment => file, :position => context_module.migration_position)
        end
      elsif hash[:linked_resource_type] =~ /assignment|project/i
        # this is a file of some kind
        ass = context_module.context.assignments.find_by_migration_id(hash[:linked_resource_id]) if hash[:linked_resource_id]
        if ass
          item = context_module.add_item({
            :title => hash[:title] || hash[:linked_resource_title],
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
        if hash['url']
          item = context_module.add_item({
            :title => hash[:title] || hash[:linked_resource_title] || hash['description'],
            :type => 'external_url',
            :indent => hash[:indent].to_i,
            :url => hash['url']
          }, existing_item, :position => context_module.migration_position)
        end
      elsif hash[:linked_resource_type] =~ /contextexternaltool/i
        # external tool
        external_tool_id = nil
        if hash[:linked_resource_global_id]
          external_tool_id = hash[:linked_resource_global_id]
        elsif hash[:linked_resource_id] && et = context_module.context.context_external_tools.active.find_by_migration_id(hash[:linked_resource_id])
          external_tool_id = et.id
        end
        if hash['url']
          item = context_module.add_item({
            :title => hash[:title] || hash[:linked_resource_title] || hash['description'],
            :type => 'context_external_tool',
            :indent => hash[:indent].to_i,
            :url => hash['url'],
            :id => external_tool_id
          }, existing_item, :position => context_module.migration_position)
        end
      elsif hash[:linked_resource_type] =~ /assessment|quiz/i
        quiz = context_module.context.quizzes.find_by_migration_id(hash[:linked_resource_id]) if hash[:linked_resource_id]
        if quiz
          item = context_module.add_item({
            :title => hash[:title] || hash[:linked_resource_title],
            :type => 'quiz',
            :indent => hash[:indent].to_i,
            :id => quiz.id
          }, existing_item, :quiz => quiz, :position => context_module.migration_position)
        end
      elsif hash[:linked_resource_type] =~ /discussion|topic/i
        topic = context_module.context.discussion_topics.find_by_migration_id(hash[:linked_resource_id]) if hash[:linked_resource_id]
        if topic
          item = context_module.add_item({
            :title => hash[:title] || hash[:linked_resource_title],
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
      if item
        item_map[hash[:migration_id]] = item if hash[:migration_id]
        item.migration_id = hash[:migration_id]
        item.new_tab = hash[:new_tab]
        item.position = (context_module.item_migration_position ||= context_module.content_tags.not_deleted.map(&:position).compact.max || 0)
        item.workflow_state = 'active'
        context_module.item_migration_position += 1
        item.save!
      end
      if hash[:sub_items]
        hash[:sub_items].each do |tag_hash|
          self.add_module_item_from_migration(context_module, tag_hash, level + 1, context, item_map, migration)
        end
      end
      item
    end

  end
end
