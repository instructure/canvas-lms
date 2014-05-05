module Importers
  class ContextExternalToolImporter < Importer

    self.item_class = ContextExternalTool

    def self.process_migration(data, migration)
      tools = data['external_tools'] ? data['external_tools']: []
      tools.each do |tool|
        if migration.import_object?("context_external_tools", tool['migration_id']) || migration.import_object?("external_tools", tool['migration_id'])
          item = import_from_migration(tool, migration.context, migration)
          if item.consumer_key == 'fake' || item.shared_secret == 'fake'
            migration.add_warning(t('external_tool_attention_needed', 'The security parameters for the external tool "%{tool_name}" need to be set in Course Settings.', :tool_name => item.name))
          end
        end
      end
    end

    def self.import_from_migration(hash, context, migration=nil, item=nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:external_tools_to_import] && !hash[:external_tools_to_import][hash[:migration_id]]
      item ||= ContextExternalTool.find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
      item ||= context.context_external_tools.new
      item.migration_id = hash[:migration_id]
      item.name = hash[:title]
      item.description = hash[:description]
      item.tool_id = hash[:tool_id]
      item.url = hash[:url] unless hash[:url].blank?
      item.domain = hash[:domain] unless hash[:domain].blank?
      item.privacy_level = hash[:privacy_level] || 'name_only'
      item.consumer_key ||= hash[:consumer_key] || 'fake'
      item.shared_secret ||= hash[:shared_secret] || 'fake'
      item.settings = hash[:settings].with_indifferent_access if hash[:settings].is_a?(Hash)
      if hash[:custom_fields].is_a? Hash
        item.settings[:custom_fields] ||= {}
        item.settings[:custom_fields].merge! hash[:custom_fields]
      end
      if hash[:extensions].is_a? Array
        item.settings[:vendor_extensions] ||= []
        hash[:extensions].each do |ext|
          next unless ext[:custom_fields].is_a? Hash
          if existing = item.settings[:vendor_extensions].find { |ve| ve[:platform] == ext[:platform] }
            existing[:custom_fields] ||= {}
            existing[:custom_fields].merge! ext[:custom_fields]
          else
            item.settings[:vendor_extensions] << {:platform => ext[:platform], :custom_fields => ext[:custom_fields]}
          end
        end
      end

      item.save!
      migration.add_imported_item(item) if migration && item.new_record?
      item
    end
  end
end
