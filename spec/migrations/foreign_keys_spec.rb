# frozen_string_literal: true

# Copyright (C) 2023 - present Instructure, Inc.
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

describe "foreign keys" do
  it "all should have indexes" do
    shard_name = Shard.current.name
    query = <<~SQL
      WITH foreign_keys AS (SELECT c.conrelid::regclass AS table_from,
        c.conname,
        pg_get_constraintdef(c.oid) AS index_def,
        a.attname,
        not a.attnotnull as nullable,
        c.conkey
        FROM pg_constraint c
        INNER JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1]
        WHERE connamespace = '#{shard_name}'::regnamespace AND contype = 'f'
        ORDER BY c.contype),
      first_full_indexes AS (SELECT idx.indrelid::regclass AS table_from, relname, a.attname  FROM pg_index idx
        INNER JOIN pg_class pc on idx.indexrelid = pc.oid
        INNER JOIN pg_attribute a ON a.attrelid = idx.indrelid AND a.attnum = idx.indkey[0]
        -- We need unconditional indexes or indexes that only have a constraint that this column is not-null-anything else is unusable for a delete
        WHERE pc.relnamespace = '#{shard_name}'::regnamespace AND indpred IS NULL OR pg_get_expr(indpred, indrelid, true) = a.attname || ' IS NOT NULL')
      SELECT table_from, index_def, attname,
        'add_index :' || table_from || ', :' || attname || (CASE WHEN nullable THEN ', where: "' || attname || ' IS NOT NULL"' ELSE '' END) || ', algorithm: :concurrently, if_not_exists: true' AS rails_create_index
      FROM foreign_keys WHERE NOT exists(
        SELECT 1 FROM first_full_indexes WHERE first_full_indexes.table_from = foreign_keys.table_from AND first_full_indexes.attname = foreign_keys.attname)
        -- We don't expect any multi-column foreign keys, so just fail if they show up rather than trying to handle them
        OR array_length(conkey, 1) > 1
      ORDER by table_from::text, attname;
    SQL

    results = ActiveRecord::Base.connection.execute(query).to_a
    failure_message = lambda do
      "The following foreign keys are missing indexes:\n#{results.map { |r| "\t#{r["table_from"]} - #{r["index_def"]}" }.join("\n")}" \
      "\n\nCreate them with:\n" + results.map { |r| "\t" + r["rails_create_index"] }.join("\n")
    end
    expect(results).to be_empty, failure_message
  end
end
