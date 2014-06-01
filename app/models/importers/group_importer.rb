module Importers
  class GroupImporter < Importer

    self.item_class = Group

    def self.process_migration(data, migration)
      groups = data['groups'] || []
      groups.each do |group|
        if migration.import_object?("groups", group['migration_id'])
          begin
            self.import_from_migration(group, migration.context)
          rescue
            migration.add_import_warning(t('#migration.group_type', "Group"), group[:title], $!)
          end
        end
      end
    end

    def self.import_from_migration(hash, context, item=nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:groups_to_import] && !hash[:groups_to_import][hash[:migration_id]]
      item ||= Group.find_by_context_id_and_context_type_and_id(context.id, context.class.to_s, hash[:id])
      item ||= Group.find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
      item ||= context.groups.new
      context.imported_migration_items << item if context.imported_migration_items && item.new_record?
      item.migration_id = hash[:migration_id]
      item.name = hash[:title]
      item.group_category = hash[:group_category].present? ?
          context.group_categories.find_or_initialize_by_name(hash[:group_category]) :
          GroupCategory.imported_for(context)

      item.save!
      context.imported_migration_items << item
      item
    end
  end
end
