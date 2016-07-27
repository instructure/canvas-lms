require_dependency 'importers'

module Importers
  class ExternalFeedImporter < Importer

    self.item_class = ExternalFeed

    def self.process_migration(data, migration)
      tools = data['external_feeds'] ? data['external_feeds']: []
      to_import = migration.to_import 'external_feeds'
      tools.each do |tool|
        if tool['migration_id'] && (!to_import || to_import[tool['migration_id']])
          begin
            self.import_from_migration(tool, migration.context, migration)
          rescue
            migration.add_import_warning(t('#migration.external_feed_type', "External Feed"), tool[:title], $!)
          end
        end
      end
    end

    def self.import_from_migration(hash, context, migration, item=nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:external_feeds_to_import] && !hash[:external_feeds_to_import][hash[:migration_id]]
      item ||= find_or_initialize_from_migration(hash, context)
      item.migration_id = hash[:migration_id]
      item.url = hash[:url]
      item.title = hash[:title]
      item.verbosity = hash[:verbosity]
      item.header_match = hash[:header_match] unless hash[:header_match].blank?

      item.save!
      migration.add_imported_item(item)
      item
    end

    def self.find_or_initialize_from_migration(hash, context)
      item = ExternalFeed.where(
        context_id: context,
        context_type: context.class.to_s,
        migration_id: hash[:migration_id]
      ).first if hash[:migration_id]
      item ||= ExternalFeed.where(
        context_id: context,
        context_type: context.class.to_s,
        url: hash[:url],
        header_match: hash[:header_match].presence,
        verbosity: hash[:verbosity]
      ).first if hash[:url]
      item ||= context.external_feeds.temp_record
      item
    end
  end
end
