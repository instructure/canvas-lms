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
    def self.run(klass, fields, default_value: false, batch_size: 1000, sleep_interval_per_batch: nil)
      fields = Array.wrap(fields)
      scope = klass.where(fields.map { |f| "#{f} IS NULL" }.join(" OR "))

      if fields.length == 1
        # don't bother with a joined coalesce if there's only one column; it will obviously always be NULL
        updates = { fields.first => default_value } if fields.length == 1
      else
        # update all fields in a single query, by assigning the existing non-NULL values
        # over themselves, or the default value if it is NULL
        updates = fields.map { |f| "#{f}=COALESCE(#{f},#{klass.connection.quote(default_value)})" }.join(', ')
      end

      klass.find_ids_in_ranges(batch_size: batch_size) do |start_id, end_id|
        scope.where(id: start_id..end_id).update_all(updates)
        sleep(sleep_interval_per_batch) if sleep_interval_per_batch
      end
    end
  end
end
