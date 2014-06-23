module Importers
  class GroupImporter < Importer

    self.item_class = Group

    def self.process_migration(data, migration)
      groups = data['groups'] || []
      groups.each do |group|
        if migration.import_object?("groups", group['migration_id'])
          begin
            self.import_from_migration(group, migration.context, migration)
          rescue
            migration.add_import_warning(t('#migration.group_type', "Group"), group[:title], $!)
          end
        end
      end
    end

    def self.import_from_migration(hash, context, migration=nil, item=nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:groups_to_import] && !hash[:groups_to_import][hash[:migration_id]]
      item ||= Group.find_by_context_id_and_context_type_and_id(context.id, context.class.to_s, hash[:id])
      item ||= Group.find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
      item ||= context.groups.new
      migration.add_imported_item(item) if migration
      item.migration_id = hash[:migration_id]
      item.name = hash[:title]
      item.group_category = hash[:group_category].present? ?
          context.group_categories.find_or_initialize_by_name(hash[:group_category]) :
          GroupCategory.imported_for(context)

      item.save!
      migration.add_imported_item(item) if migration
      item
    end
  end
end
