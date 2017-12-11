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
    extend OutcomeImporter

    self.item_class = LearningOutcomeGroup

    def self.import_from_migration(hash, migration, item=nil)
      hash = hash.with_indifferent_access
      if hash[:is_global_standard]
        if Account.site_admin.grants_right?(migration.user, :manage_global_outcomes)
          hash[:parent_group] ||= LearningOutcomeGroup.global_root_outcome_group
          item ||= LearningOutcomeGroup.global.where(migration_clause(hash[:migration_id])).first if hash[:migration_id]
          item ||= LearningOutcomeGroup.global.where(vendor_clause(hash[:vendor_guid])).first if hash[:vendor_guid]
          item ||= LearningOutcomeGroup.new
        else
          migration.add_warning(t(:no_global_permission, %{You're not allowed to manage global outcomes, can't add "%{title}"}, :title => hash[:title]))
          return
        end
      else
        context = migration.context
        root_outcome_group = context.root_outcome_group
        item ||= LearningOutcomeGroup.where(context_id: context, context_type: context.class.to_s).
          where(migration_clause(hash[:migration_id])).first if hash[:migration_id]
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
