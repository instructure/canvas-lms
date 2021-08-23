# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module DataFixup::PopulateFieldOnModelFromAssociation
  def self.run(table, association, column, old_value: nil)
    table.find_ids_in_ranges(batch_size: 100_000) do |min, max|
      if association.present?
        delay_if_production(
          priority: Delayed::MAX_PRIORITY,
          n_strand: ["root_account_id_backfill", Shard.current.database_server.id]).
          populate_column_from_association(table, association, min, max, column, old_value: old_value)
      end
    end
  end

  def self.populate_column_from_association(table, association, min, max, column, old_value: nil)
    primary_key_field = table.primary_key
    table.find_ids_in_ranges(start_at: min, end_at: max) do |batch_min, batch_max|
      reflection = table.reflections[association.to_s]
      from_column = DataFixup::PopulateRootAccountIdOnModels.create_column_names(reflection, column)
      scope = table.where(primary_key_field => batch_min..batch_max, column => old_value)
      scope.joins(association).update_all("#{column} = #{from_column}")
    end
  end
end
