module Importers
  class LearningOutcomeImporter < Importer

    self.item_class = LearningOutcome

    def self.process_migration(data, migration)
      outcomes = data['learning_outcomes'] ? data['learning_outcomes'] : []
      migration.outcome_to_id_map = {}
      outcomes.each do |outcome|
        next unless migration.import_object?('learning_outcomes', outcome['migration_id'])
        begin
          if outcome[:type] == 'learning_outcome_group'
            Importers::LearningOutcomeGroupImporter.import_from_migration(outcome, migration)
          else
            Importers::LearningOutcomeImporter.import_from_migration(outcome, migration)
          end
        rescue
          migration.add_import_warning(t('#migration.learning_outcome_type', "Learning Outcome"), outcome[:title], $!)
        end
      end
    end

    def self.import_from_migration(hash, migration, item=nil)
      context = migration.context
      hash = hash.with_indifferent_access
      outcome = nil
      if !item && hash[:external_identifier]
        unless migration.cross_institution?
          if hash[:is_global_outcome]
            outcome = LearningOutcome.active.find_by_id_and_context_id(hash[:external_identifier], nil)
          else
            outcome = context.available_outcome(hash[:external_identifier])
          end

          if outcome
            # Help prevent linking to the wrong outcome if copying into a different install of canvas
            # (using older migration packages that lack the root account uuid)
            outcome = nil if outcome.short_description != hash[:title]
          end
        end

        if !outcome
          migration.add_warning(t(:no_context_found, %{The external Learning Outcome couldn't be found for "%{title}", creating a copy.}, :title => hash[:title]))
        end
      end

      if !outcome
        if hash[:is_global_standard]
          if Account.site_admin.grants_right?(migration.user, :manage_global_outcomes)
            # import from vendor with global outcomes
            context = nil
            hash[:learning_outcome_group] ||= LearningOutcomeGroup.global_root_outcome_group
            item ||= LearningOutcome.global.find_by_migration_id(hash[:migration_id]) if hash[:migration_id] && !migration.cross_institution?
            item ||= LearningOutcome.global.find_by_vendor_guid(hash[:vendor_guid]) if hash[:vendor_guid]
            item ||= LearningOutcome.new
          else
            migration.add_warning(t(:no_global_permission, %{You're not allowed to manage global outcomes, can't add "%{title}"}, :title => hash[:title]))
            return
          end
        else
          item ||= LearningOutcome.find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, hash[:migration_id]) if hash[:migration_id]
          item ||= context.created_learning_outcomes.new
          item.context = context
        end
        item.migration_id = hash[:migration_id]
        item.vendor_guid = hash[:vendor_guid]
        item.low_grade = hash[:low_grade]
        item.high_grade = hash[:high_grade]
        item.workflow_state = 'active' if item.deleted?
        item.short_description = hash[:title]
        item.description = hash[:description]

        if hash[:ratings]
          item.data = {:rubric_criterion=>{}}
          item.data[:rubric_criterion][:ratings] = hash[:ratings] ? hash[:ratings].map(&:symbolize_keys) : []
          item.data[:rubric_criterion][:mastery_points] = hash[:mastery_points]
          item.data[:rubric_criterion][:points_possible] = hash[:points_possible]
          item.data[:rubric_criterion][:description] = item.short_description || item.description
        end

        item.save!

        migration.add_imported_item(item) if migration
      else
        item = outcome
      end

      if hash[:alignments]
        alignments = hash[:alignments].sort_by{|a| a[:position].to_i}
        alignments.each do |alignment|
          next unless alignment[:content_type] && alignment[:content_id]
          asset = nil

          case alignment[:content_type]
          when 'Assignment'
            asset = Assignment.find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, alignment[:content_id])
          when 'AssessmentQuestionBank'
            asset = AssessmentQuestionBank.find_by_context_id_and_context_type_and_migration_id(context.id, context.class.to_s, alignment[:content_id])
          end

          if asset
            options = alignment.slice(*[:mastery_type, :mastery_score])
            item.align(asset, context, options)
          end
        end
      end

      log = hash[:learning_outcome_group] || context.root_outcome_group
      log.add_outcome(item)

      migration.outcome_to_id_map[hash[:migration_id]] = item.id

      item
    end
  end
end
