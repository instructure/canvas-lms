module Importers
  class ContextExternalToolImporter < Importer

    self.item_class = ContextExternalTool

    def self.process_migration(data, migration)
      tools = data['external_tools'] ? data['external_tools']: []
      tools.each do |tool|
        if migration.import_object?("context_external_tools", tool['migration_id']) || migration.import_object?("external_tools", tool['migration_id'])
          begin
            item = import_from_migration(tool, migration.context, migration)
            if item.consumer_key == 'fake' || item.shared_secret == 'fake'
              migration.add_warning(t('external_tool_attention_needed', 'The security parameters for the external tool "%{tool_name}" need to be set in Course Settings.', :tool_name => item.name))
            end
          rescue
            migration.add_import_warning(t('#migration.external_tool_type', "External Tool"), tool[:title], $!)
          end
        end
      end
    end

    def self.import_from_migration(hash, context, migration=nil, item=nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:external_tools_to_import] && !hash[:external_tools_to_import][hash[:migration_id]]

      if !item && migration && item = check_for_compatible_tool_translation(hash, migration)
        return item
      end

      item ||= ContextExternalTool.find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
      item ||= context.context_external_tools.new
      item.migration_id = hash[:migration_id]
      item.name = hash[:title]
      item.description = hash[:description]
      item.tool_id = hash[:tool_id]
      if hash[:url].present?
        url = hash[:url]
        url = migration.process_domain_substitutions(url) if migration
        item.url = url
      end
      item.domain = hash[:domain] unless hash[:domain].blank?
      item.privacy_level = hash[:privacy_level] || 'name_only'
      item.consumer_key ||= hash[:consumer_key] || 'fake'
      item.shared_secret ||= hash[:shared_secret] || 'fake'
      item.settings = create_tool_settings(hash)
      if hash[:custom_fields].is_a? Hash
        item.settings[:custom_fields] ||= {}
        item.settings[:custom_fields].merge! hash[:custom_fields]
      end

      item.save!
      migration.add_imported_item(item) if migration
      item
    end

    def self.create_tool_settings(hash)
      settings = hash[:settings].is_a?(Hash) ? hash[:settings] : {}
      settings = settings.with_indifferent_access

      if hash[:extensions].is_a? Array
        settings[:vendor_extensions] ||= []
        hash[:extensions].each do |ext|
          next unless ext[:custom_fields].is_a? Hash
          if existing = settings[:vendor_extensions].find { |ve| ve[:platform] == ext[:platform] }
            existing[:custom_fields] ||= {}
            existing[:custom_fields].merge! ext[:custom_fields]
          else
            settings[:vendor_extensions] << {:platform => ext[:platform], :custom_fields => ext[:custom_fields]}
          end
        end
      end
      settings
    end

    def self.check_for_compatible_tool_translation(hash, migration)
      return unless migration.migration_type == "common_cartridge_importer"
      # rather than making a thousand separate tools, try to combine into other tools if we can

      url = hash[:url].presence
      return if url && ContextModuleImporter.add_custom_fields_to_url(url, hash[:custom_fields] || {}).nil?

      domain = hash[:domain]
      domain ||= (URI.parse(url).host rescue nil) if url
      return unless url || domain

      settings = create_tool_settings(hash).with_indifferent_access.except(:custom_fields)

      migration.imported_migration_items_by_class(ContextExternalTool).each do |tool|
        next unless matching_settings?(hash, tool, settings)

        if tool.url.blank? && tool.domain.present?
          match_domain = tool.domain

          if domain && domain == match_domain # translate the hash url to existing tool
            tool.domain = match_domain
            tool.save! if tool.changed?

            migration.add_external_tool_translation(hash[:migration_id], tool, hash[:custom_fields])
            generalize_tool_name(tool)
            return tool
          end
        elsif tool.url.present?
          match_domain = URI.parse(tool.url).host rescue nil

          if domain && match_domain == domain
            # turn the matched tool into a domain only tool
            # and translate both the hash url and the tool's old url

            old_custom_fields = tool.settings[:custom_fields]
            tool.url = nil
            tool.domain = match_domain
            tool.settings[:custom_fields] = {}
            tool.save!

            migration.add_external_tool_translation(tool.migration_id, tool, old_custom_fields)
            migration.add_external_tool_translation(hash[:migration_id], tool, hash[:custom_fields])
            generalize_tool_name(tool)
            return tool
          end
        end
      end

      nil
    end

    def self.generalize_tool_name(tool)
      if tool.domain
        tool.name = CanvasTextHelper.truncate_text(tool.domain, :max_length => 100)
        tool.save! if tool.changed?
      end
    end

    def self.matching_settings?(hash, tool, settings)
      tool.privacy_level == (hash[:privacy_level] || 'name_only') &&
        tool.consumer_key == (hash[:consumer_key] || 'fake') &&
        tool.shared_secret == (hash[:shared_secret] || 'fake') &&
        tool.settings.with_indifferent_access.except(:custom_fields) == settings
    end
  end
end
