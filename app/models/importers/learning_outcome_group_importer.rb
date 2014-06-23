module Importers
  class LearningOutcomeGroupImporter < Importer

    self.item_class = LearningOutcomeGroup

    def self.import_from_migration(hash, migration, item=nil)
      hash = hash.with_indifferent_access
      if hash[:is_global_standard]
        if Account.site_admin.grants_right?(migration.user, :manage_global_outcomes)
          hash[:parent_group] ||= LearningOutcomeGroup.global_root_outcome_group
          item ||= LearningOutcomeGroup.global.find_by_migration_id(hash[:migration_id]) if hash[:migration_id]
          item ||= LearningOutcomeGroup.global.find_by_vendor_guid(hash[:vendor_guid]) if hash[:vendor_guid]
          item ||= LearningOutcomeGroup.new
        else
          migration.add_warning(t(:no_global_permission, %{You're not allowed to manage global outcomes, can't add "%{title}"}, :title => hash[:title]))
          return
        end
      else
        context = migration.context
        root_outcome_group = context.root_outcome_group
        item ||= LearningOutcomeGroup.find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
        item ||= context.learning_outcome_groups.new
        item.context = context
      end
      item.migration_id = hash[:migration_id]
      item.title = hash[:title]
      item.description = hash[:description]
      item.vendor_guid = hash[:vendor_guid]
      item.low_grade = hash[:low_grade]
      item.high_grade = hash[:high_grade]

      item.save!
      if hash[:parent_group]
        hash[:parent_group].adopt_outcome_group(item)
      else
        root_outcome_group.adopt_outcome_group(item)
      end

      migration.add_imported_item(item) if migration && item.new_record?

      if hash[:outcomes]
        hash[:outcomes].each do |child|
          if child[:type] == 'learning_outcome_group'
            child[:parent_group] = item
            Importers::LearningOutcomeGroupImporter.import_from_migration(child, migration)
          else
            child[:learning_outcome_group] = item
            Importers::LearningOutcomeImporter.import_from_migration(child, migration)
          end
        end
      end

      item
    end
  end
end
