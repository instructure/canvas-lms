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
    def self.run(base_scope, *unique_columns, order: nil, strategy: nil, batch_size: 10_000)
      model = base_scope.is_a?(ActiveRecord::Relation) ? base_scope.klass : base_scope
      partition_by = unique_columns.map { |c| model.connection.quote_column_name(c) }.join(", ")
      order ||= model.primary_key
      inner_scope = base_scope
                    .select(model.primary_key)
                    .select("ROW_NUMBER() OVER (PARTITION BY #{partition_by} ORDER BY #{order}) AS row_num")
      middle_scope = model.from(inner_scope).select(:id).where("row_num>1")
      outer_scope = model.where(id: middle_scope)
      outer_scope.in_batches(of: batch_size, strategy:).delete_all
    end
  end
end
