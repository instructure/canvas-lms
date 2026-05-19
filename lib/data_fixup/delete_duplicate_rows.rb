# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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
#

module DataFixup
  module DeleteDuplicateRows
    # reassign_references: optional hash of { Model => :foreign_key_column } for tables
    # that reference the base scope's table. Before deleting duplicates, foreign key
    # references pointing to duplicate rows will be updated to reference the kept row.
    def self.run(base_scope, *unique_columns, order: nil, strategy: nil, batch_size: 10_000, reassign_references: nil)
      model = base_scope.is_a?(ActiveRecord::Relation) ? base_scope.klass : base_scope
      partition_by = unique_columns.map { |c| model.connection.quote_column_name(c) }.join(", ")
      order ||= model.primary_key

      if reassign_references
        reassign_duplicate_references(model, base_scope, partition_by, order, reassign_references)
      end

      inner_scope = base_scope
                    .select(model.primary_key)
                    .select("ROW_NUMBER() OVER (PARTITION BY #{partition_by} ORDER BY #{order}) AS row_num")
      middle_scope = model.from(inner_scope).select(:id).where("row_num>1")
      outer_scope = model.where(id: middle_scope)
      outer_scope.in_batches(of: batch_size, strategy:).delete_all
    end

    def self.reassign_duplicate_references(model, base_scope, partition_by, order, reassign_references)
      pk = model.connection.quote_column_name(model.primary_key)
      mapping_sql = base_scope
                    .select("#{model.table_name}.#{pk} AS duplicate_id")
                    .select("FIRST_VALUE(#{model.table_name}.#{pk}) OVER (PARTITION BY #{partition_by} ORDER BY #{order}) AS keeper_id")
                    .to_sql

      reassign_references.each do |ref_model, foreign_key|
        fk = ref_model.connection.quote_column_name(foreign_key)
        ref_table = ref_model.quoted_table_name
        ref_model.connection.execute(<<~SQL.squish)
          UPDATE #{ref_table}
          SET #{fk} = mapping.keeper_id
          FROM (
            SELECT duplicate_id, keeper_id
            FROM (#{mapping_sql}) AS ranked
            WHERE duplicate_id != keeper_id
          ) AS mapping
          WHERE #{ref_table}.#{fk} = mapping.duplicate_id
        SQL
      end
    end
    private_class_method :reassign_duplicate_references
  end
end
