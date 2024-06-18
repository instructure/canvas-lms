# frozen_string_literal: true

# Copyright (C) 2012 - present Instructure, Inc.
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
module CanvasCassandra
  class Database
    CONSISTENCY_CLAUSE = /%CONSISTENCY% ?/

    def initialize(fingerprint, servers, opts, logger)
      thrift_opts = {}
      thrift_opts[:retries] = opts.delete(:retries) if opts.key?(:retries)
      thrift_opts[:connect_timeout] = opts.delete(:connect_timeout) if opts.key?(:connect_timeout)
      thrift_opts[:timeout] = opts.delete(:timeout) if opts.key?(:timeout)

      @db = CassandraCQL::Database.new(servers, opts, thrift_opts)
      @fingerprint = fingerprint
      @logger = logger
    end

    attr_reader :db, :fingerprint

    # This just takes a raw query string, and params to replace `?` with.
    # Though cassandra isn't relational, it'd still be useful to be able to
    # build up queries using scopes. Maybe one of the ruby libs like datamapper
    # or arel is flexible enough for this, rather than rolling our own.
    def execute(query, *args)
      result = nil
      opts = (args.last.is_a?(Hash) && args.pop) || {}

      ms = 1000 * Benchmark.realtime do
        consistency_text = opts[:consistency]
        consistency = CanvasCassandra.consistency_level(consistency_text) if consistency_text

        if @db.use_cql3? || !consistency
          query = query.sub(CONSISTENCY_CLAUSE, "")
        elsif !@db.use_cql3?
          query = query.sub(CONSISTENCY_CLAUSE, "USING CONSISTENCY #{consistency_text} ")
        end

        result = if @db.use_cql3? && consistency
                   @db.execute_with_consistency(query, consistency, *args)
                 else
                   @db.execute(query, *args)
                 end
      end

      @logger.debug("  #{"CQL (%.2fms)" % [ms]}  #{sanitize(query, args)} #{opts.inspect} [#{fingerprint}]")
      result
    end

    def sanitize(query, args)
      ::CassandraCQL::Statement.sanitize(query, args)
    end

    def tables
      if @db.connection.describe_version >= "20.1.0" && @db.execute("SELECT cql_version FROM system.local").first["cql_version"] >= "3.4.4"
        @db.execute("SELECT table_name FROM system_schema.tables WHERE keyspace_name=?", keyspace).map do |row| # rubocop:disable Rails/Pluck
          row["table_name"]
        end
      elsif @db.use_cql3?
        @db.execute("SELECT columnfamily_name FROM system.schema_columnfamilies WHERE keyspace_name=?", keyspace).map do |row| # rubocop:disable Rails/Pluck
          row["columnfamily_name"]
        end
      else
        @db.schema.tables
      end
    end

    def available?
      db.active?
    end

    def keyspace
      db.keyspace.to_s.dup.force_encoding("UTF-8")
    end
    alias_method :name, :keyspace
  end
end
