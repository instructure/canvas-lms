require_dependency 'importers'

module Importers
  class RubricImporter < Importer

    self.item_class = Rubric

    def self.process_migration(data, migration)
      rubrics = data['rubrics'] ? data['rubrics']: []
      migration.outcome_to_id_map ||= {}
      rubrics.each do |rubric|
        if migration.import_object?("rubrics", rubric['migration_id'])
          begin
            self.import_from_migration(rubric, migration)
          rescue
            migration.add_import_warning(t('#migration.rubric_type', "Rubric"), rubric[:title], $!)
          end
        end
      end
    end

    def self.import_from_migration(hash, migration, item=nil)
      context = migration.context
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:rubrics_to_import] && !hash[:rubrics_to_import][hash[:migration_id]]

      rubric = nil
      if !item && hash[:external_identifier]
        rubric = context.available_rubric(hash[:external_identifier]) unless migration.cross_institution?

        if !rubric
          Rails.logger.warn("The external Rubric couldn't be found for \"#{hash[:title]}\", creating a copy.")
        end
      end

      if rubric
        item = rubric
      else
        item ||= Rubric.where(context_id: context, context_type: context.class.to_s, id: hash[:id]).first
        item ||= Rubric.where(context_id: context, context_type: context.class.to_s, migration_id: hash[:migration_id]).first if hash[:migration_id]
        item ||= Rubric.new(:context => context)
        item.migration_id = hash[:migration_id]
        item.workflow_state = 'active' if item.deleted?
        item.title = hash[:title]
        item.populate_rubric_title # just in case
        item.description = hash[:description]
        item.points_possible = hash[:points_possible].to_f
        item.read_only = hash[:read_only] unless hash[:read_only].nil?
        item.reusable = hash[:reusable] unless hash[:reusable].nil?
        item.public = hash[:public] unless hash[:public].nil?
        item.hide_score_total = hash[:hide_score_total] unless hash[:hide_score_total].nil?
        item.free_form_criterion_comments = hash[:free_form_criterion_comments] unless hash[:free_form_criterion_comments].nil?

        item.data = hash[:data]
        item.data.each do |crit|
          if crit[:learning_outcome_migration_id]
            if migration.respond_to?(:outcome_to_id_map) && id = migration.outcome_to_id_map[crit[:learning_outcome_migration_id]]
              crit[:learning_outcome_id] = id
            elsif lo = context.created_learning_outcomes.where(migration_id: crit[:learning_outcome_migration_id]).first
              crit[:learning_outcome_id] = lo.id
            end
            crit.delete :learning_outcome_migration_id
          end
        end

        item.skip_updating_points_possible = true
        migration.add_imported_item(item)
        item.save!
      end

      if association = context.rubric_associations.where(rubric_id: item).first
        unless association.bookmarked
          association.bookmarked = true
          association.save!
        end
      else
        item.associate_with(context, context)
      end

      item
    end
  end
end
