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
#

class Loaders::AssociationCountLoader < GraphQL::Batch::Loader
  def initialize(model, association)
    super()
    @model = model
    @association = association
  end

  # returns a hash of the ids with the count from the association if it had any.
  # If there are 0 it will return nil
  # uses a join, and associations will not consider sharding, and it is
  # expected that all records will be on the same shard.
  def perform(records)
    reflection = @model.reflections[@association.to_s]
    quoted_table_name = reflection.klass.quoted_table_name
    join_statement = "INNER JOIN #{quoted_table_name} AS some_association ON #{@model.table_name}.#{reflection.join_foreign_key} = some_association.#{reflection.join_primary_key}"
    counts = @model.where(id: records).joins(join_statement).group("#{@model.table_name}.#{@model.primary_key}").count
    records.each { |record| fulfill(record, counts[record.id]) }
  end
end
