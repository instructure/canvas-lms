# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module OutcomesService
  class MigrationExtractor
    def initialize(migration)
      @migration = migration
    end

    def learning_outcomes(context)
      @migration.imported_migration_items_by_class(LearningOutcome).map do |item|
        outcome_attributes(item) if item.context == context
      end.compact
    end

    def learning_outcome_groups(context)
      @migration.imported_migration_items_by_class(LearningOutcomeGroup).map do |item|
        group_attributes(item)
      end.prepend(group_attributes(context.root_outcome_group))
    end

    def learning_outcome_links
      @migration.imported_migration_items_by_class(ContentTag).map do |item|
        link_attributes(item) if valid_link?(item)
      end.compact
    end

    private

    def outcome_attributes(learning_outcome)
      attrs = learning_outcome.attributes.transform_keys(&:to_sym)
      attrs[:'$canvas_learning_outcome_id'] = attrs.delete(:id)
      attrs[:rubric_criterion] = attrs.delete(:data)[:rubric_criterion]
      attrs.except(:migration_id_2, :vendor_guid_2, :root_account_id, :context_type, :context_id)
    end

    def group_attributes(learning_outcome_group)
      attrs = learning_outcome_group.attributes.transform_keys(&:to_sym)
      attrs[:'$canvas_learning_outcome_group_id'] = attrs.delete(:id)
      attrs[:parent_outcome_group_id] = attrs.delete(:learning_outcome_group_id)
      attrs.except(:root_learning_outcome_group_id, :root_account_id, :migration_id_2, :vendor_guid_2)
    end

    def valid_link?(item)
      item.tag_type == 'learning_outcome_association' && item.associated_asset_type == 'LearningOutcomeGroup' && item.content_type == 'LearningOutcome'
    end

    def link_attributes(learning_outcome_link)
      {
        '$canvas_learning_outcome_link_id': learning_outcome_link.id,
        '$canvas_learning_outcome_group_id': learning_outcome_link.associated_asset_id,
        '$canvas_learning_outcome_id': learning_outcome_link.content_id
      }
    end
  end
end
