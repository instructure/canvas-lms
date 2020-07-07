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
#
module EventStream::Backend
  class Cassandra
    include Strategy
    attr_accessor :stream

    def initialize(stream_obj)
      @stream = stream_obj
    end

    delegate :database, :table, :id_column, :read_consistency_level, :record_type, to: :stream

    class Unavailable < RuntimeError; end

    def available?
      !!database && database.available?
    end

    def database_fingerprint
      database && database.fingerprint
    end

    def fetch_cql
      "SELECT * FROM #{table} %CONSISTENCY% WHERE #{id_column} IN (?)"
    end

    def fetch_one_cql
      "SELECT * FROM #{table} %CONSISTENCY% WHERE #{id_column} = ?"
    end

    def fetch(ids, strategy: :batch)
      rows = []
      if available? && ids.present?
        if strategy == :batch
          database.execute(fetch_cql, ids, consistency: read_consistency_level).fetch do |row|
            rows << record_type.from_attributes(row.to_hash)
          end
        elsif strategy == :serial
          ids.each do |record_id|
            database.execute(fetch_one_cql, record_id, consistency: read_consistency_level).fetch do |row|
              rows << record_type.from_attributes(row.to_hash)
            end
          end
        else
          raise "Unrecognized Fetch Strategy: #{strategy}"
        end
      end
      rows
    end

    def execute(operation, record)
      unless stream.available?
        stream.run_callbacks(:error, operation, record, Unavailable.new)
        return
      end

      ttl_seconds = stream.ttl_seconds(record.created_at)
      return if ttl_seconds < 0

      database.batch do
        stream.database.send(:"#{operation}_record", stream.table, {stream.id_column => record.id}, stream.operation_payload(operation, record), ttl_seconds)
        stream.run_callbacks(operation, record)
      end
    rescue StandardError => exception
      stream.run_callbacks(:error, operation, record, exception)
      raise if stream.raise_on_error
    end

    def index_on_insert(index, record)
      if (entry = index.entry_proc.call(record))
        key = index.key_proc ? index.key_proc.call(*entry) : entry
        index.strategy_for(:cassandra).insert(record, key)
      end
    end

    def find_with_index(index, args)
      options = args.extract_options!
      options[:strategy] = :cassandra
      index.find_with(args, options)
    end

    def find_ids_with_index(index, args)
      options = args.extract_options!
      options[:strategy] = :cassandra
      index.find_ids_with(args, options)
    end
  end
end