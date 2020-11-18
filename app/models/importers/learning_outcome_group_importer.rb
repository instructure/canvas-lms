# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_dependency 'importers'

module Importers
  class LearningOutcomeGroupImporter < Importer
    self.item_class = LearningOutcomeGroup

    def self.import_from_migration(hash, migration, item=nil, skip_import=false)
      hash = hash.with_indifferent_access
      if skip_import
        Importers::LearningOutcomeGroupImporter.process_children(hash, hash[:parent_group], migration, skip_import)
        return
      end
      if hash[:is_global_standard]
        if Account.site_admin.grants_right?(migration.user, :manage_global_outcomes)
          hash[:parent_group] ||= LearningOutcomeGroup.global_root_outcome_group
          item ||= LearningOutcomeGroup.global.where(migration_id: hash[:migration_id]).first if hash[:migration_id]
          item ||= LearningOutcomeGroup.global.where(vendor_guid: hash[:vendor_guid]).first if hash[:vendor_guid]
          item ||= LearningOutcomeGroup.new
        else
          migration.add_warning(t(:no_global_permission, %{You're not allowed to manage global outcomes, can't add "%{title}"}, :title => hash[:title]))
          return
        end
      else
        context = migration.context
        root_outcome_group = context.root_outcome_group
        parent_group = hash[:parent_group] || root_outcome_group

        item ||= LearningOutcomeGroup.where(context_id: context, context_type: context.class.to_s).
          where(migration_id: hash[:migration_id]).first if hash[:migration_id]
        item ||= LearningOutcomeGroup.find_by(vendor_guid: hash[:vendor_guid],
            context: context, learning_outcome_group: parent_group) if check_for_duplicate_guids?(context, hash)
        item ||= context.learning_outcome_groups.temp_record
        item.context = context
        item.mark_as_importing!(migration)
      end
      item.workflow_state = 'active' # restore deleted ones
      item.migration_id = hash[:migration_id]
      item.title = hash[:title]
      item.description = hash[:description]
      item.vendor_guid = hash[:vendor_guid]
      item.low_grade = hash[:low_grade]
      item.high_grade = hash[:high_grade]

      # For some reason the top level authority for the United Kingdom
      # gets returned back from Academic Benchmarks with a GUID of
      # "ENG", with no title and no description.  Because of this, our
      # model validation fails that requires a title.  Since "ENG" is
      # always from the UK, we can safely set the title here to avoid
      # the breakage and make imports of UK standards work again
      unless item.title
        if item.vendor_guid == "ENG"
          item.title = "United Kingdom"
          item.description = "United Kingdom Authority"
        end
      end

      item.save!

      # don't import contents of deleted outcome groups
      # (blueprint migration will not undelete outcome groups deleted downstream)
      return item if item.deleted?

      if hash[:parent_group]
        hash[:parent_group].adopt_outcome_group(item)
      else
        root_outcome_group.adopt_outcome_group(item)
      end

      item.skip_parent_group_touch = true
      migration.add_imported_item(item)

      Importers::LearningOutcomeGroupImporter.process_children(hash, item, migration)

      item
    end

    def self.process_children(hash, item, migration, skip_import=false)
      if hash[:outcomes]
        hash[:outcomes].each do |child|
          if child[:type] == 'learning_outcome_group'
            child[:parent_group] = item
            Importers::LearningOutcomeGroupImporter.import_from_migration(
              child,
              migration,
              nil,
              skip_import && !migration.import_object?('learning_outcome_groups', child['migration_id'])
            )
          else
            child[:learning_outcome_group] = item
            if !skip_import || migration.import_object?('learning_outcomes', child['migration_id'])
              Importers::LearningOutcomeImporter.import_from_migration(child, migration)
            end
          end
        end
      end
    end

    def self.check_for_duplicate_guids?(context, hash)
      context.root_account.feature_enabled?(:outcome_guid_course_exports) &&
      hash[:vendor_guid].present?
    end
  end
end
