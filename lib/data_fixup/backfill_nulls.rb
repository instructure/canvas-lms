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
# with this program. If not, see <http://www.gnu.org/licenses/>.

module DataFixup
  module BackfillNulls
    # if there are multiple fields, and existing non-NULL values might be toasted
    # (large values), you should call this fixup separately for each column.
    # if you were to combine it with other columns, unchanging non-NULL columns
    # would be copied for every row that another column _is_ changing
    #
    # you probably only want to use sleep if you're calling this manually to
    # get the bulk of work done ahead of deploying the actual migration that
    # calls this
    #
    # @param fields [Hash<Symbol => Object>, Array<Symbol>, Symbol]
    #   If a hash, it's column to default value. If an array or a single symbol, it's just
    #   the column(s), and the default_value is passed separately, and applied to all of
    #   the columns.
    def self.run(klass, fields, default_value: false, batch_size: 1000)
      case fields
      when Array
        fields = fields.index_with { default_value }
      when Hash
        # already correct type
      else
        fields = { fields => default_value }
      end
      scope = klass.where(fields.keys.map { |f| "#{f} IS NULL" }.join(" OR "))

      if fields.length == 1
        # don't bother with a joined coalesce if there's only one column; it will obviously always be NULL
        updates = { fields.first.first => fields.first.last } if fields.length == 1
      else
        # update all fields in a single query, by assigning the existing non-NULL values
        # over themselves, or the default value if it is NULL
        updates = fields.map { |(f, v)| "#{f}=COALESCE(#{f},#{klass.connection.quote(v)})" }.join(", ")
      end

      klass.find_ids_in_ranges(batch_size:) do |start_id, end_id|
        update_count = scope.where(klass.primary_key => start_id..end_id).update_all(updates)
        sleep_interval_per_batch = Setting.get("sleep_interval_per_backfill_nulls_batch", nil).presence&.to_f
        sleep(sleep_interval_per_batch) if update_count > 0 && sleep_interval_per_batch
      end
    end
  end
end
