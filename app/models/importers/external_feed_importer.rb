module Importers
  class ExternalFeedImporter < Importer

    self.item_class = ExternalFeed

    def self.process_migration(data, migration)
      tools = data['external_feeds'] ? data['external_feeds']: []
      to_import = migration.to_import 'external_feeds'
      tools.each do |tool|
        if tool['migration_id'] && (!to_import || to_import[tool['migration_id']])
          begin
            self.import_from_migration(tool, migration.context)
          rescue
            migration.add_import_warning(t('#migration.external_feed_type', "External Feed"), tool[:title], $!)
          end
        end
      end
    end

    def self.import_from_migration(hash, context, item=nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:external_feeds_to_import] && !hash[:external_feeds_to_import][hash[:migration_id]]
      item ||= ExternalFeed.find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
      item ||= context.external_feeds.new
      item.migration_id = hash[:migration_id]
      item.url = hash[:url]
      item.title = hash[:title]
      item.feed_type = hash[:feed_type]
      item.feed_purpose = hash[:purpose]
      item.verbosity = hash[:verbosity]
      item.header_match = hash[:header_match] unless hash[:header_match].blank?

      item.save!
      context.imported_migration_items << item if context.imported_migration_items && item.new_record?
      item
    end
  end
end
