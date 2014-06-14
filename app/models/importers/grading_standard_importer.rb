module Importers
  class GradingStandardImporter < Importer

    self.item_class = GradingStandard

    def self.process_migration(data, migration)
      standards = data['grading_standards'] || []
      standards.each do |standard|
        if migration.import_object?('grading_standards', standard['migration_id'])
          begin
            self.import_from_migration(standard, migration.context, migration)
          rescue
            migration.add_import_warning(t('#migration.grading_standard_type', "Grading Standard"), standard[:title], $!)
          end
        end
      end
    end

    def self.import_from_migration(hash, context, migration=nil, item=nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:grading_standards_to_import] && !hash[:grading_standards_to_import][hash[:migration_id]]
      item ||= GradingStandard.find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
      item ||= context.grading_standards.new
      item.migration_id = hash[:migration_id]
      item.workflow_state = 'active' if item.deleted?
      item.title = hash[:title]
      begin
        item.data = GradingStandard.upgrade_data(JSON.parse(hash[:data]), hash[:version] || 1)
      rescue
        #todo - add to message to display to user
      end

      item.save!
      migration.add_imported_item(item) if migration && item.new_record?
      item
    end
  end
end
