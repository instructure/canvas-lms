# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module DataFixup::PopulateIdentityHashOnContextExternalTools
  def self.run(start_at, end_at)
    ContextExternalTool.where(id: start_at..end_at, identity_hash: nil).find_in_batches do |tools|
      dupe_set = Set.new
      identity_hashes = tools.each_with_object({}) do |tool, object|
        tool_hash = tool.calculate_identity_hash
        object[tool.id] = dupe_set.include?(tool_hash) ? "duplicate" : tool_hash
        dupe_set << tool_hash
      end
      ids_identity_hashes = sqlize(identity_hashes)

      query = <<~SQL.squish
        UPDATE #{ContextExternalTool.quoted_table_name} AS tool SET
          identity_hash = (
            case
            when hashes.calculated_hash::text = 'duplicate'::text OR EXISTS (
              SELECT 1
              FROM #{ContextExternalTool.quoted_table_name} AS cet
              WHERE cet.identity_hash IS NOT NULL
                AND cet.identity_hash <> 'duplicate'
                AND cet.identity_hash = hashes.calculated_hash::text
            )
            then 'duplicate'::text
            else hashes.calculated_hash::text
            end
          )
        FROM (values #{ContextExternalTool.sanitize_sql(ids_identity_hashes)} ) AS hashes(calculated_id, calculated_hash)
        WHERE tool.id = hashes.calculated_id
      SQL
      ContextExternalTool.connection.execute(query)
    end
  end

  def self.sqlize(hash)
    hash.map do |key, value|
      "(#{ContextExternalTool.connection.quote(key)}::bigint, #{ContextExternalTool.connection.quote(value)}::text)"
    end.join(",")
  end
end
