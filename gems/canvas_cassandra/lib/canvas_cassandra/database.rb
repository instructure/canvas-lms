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

    # private Struct used to store batch information
    Batch = Struct.new(:statements, :args, :counter_statements, :counter_args, :execute_options) do
      def initialize
        super([], [], [], [], {})
      end

      def to_cql_ary(field = nil)
        field = "#{field}_" if field
        statements = send(:"#{field}statements")
        args = send(:"#{field}args")
        case statements.size
        when 0
          raise "Cannot execute an empty batch"
        when 1
          statements + args
        else
          # http://www.datastax.com/docs/1.1/references/cql/BATCH
          # note there's no semicolons between statements in the batch
          cql = []
          cql << "BEGIN #{"COUNTER " if field == "counter_"}BATCH"
          cql.concat statements
          cql << "APPLY BATCH"
          # join with spaces rather than newlines, because cassandra doesn't care
          # and syslog doesn't like newlines
          [cql.join(" ")] + args
        end
      end
    end

    # Update, insert or delete from cassandra. The only difference between this
    # and execute above is that this doesn't return a result set, so it can be
    # batched up.
    def update(query, *args)
      if in_batch?
        execute_options = (args.last.is_a?(Hash) && args.pop) || {}
        @batch.statements << query
        @batch.args.concat args
        @batch.execute_options.merge!(execute_options)
      else
        execute(query, *args)
      end
      nil
    end

    def update_counter(query, *args)
      return update(query, *args) unless db.use_cql3?

      if in_batch?
        @batch.counter_statements << query
        @batch.counter_args.concat args
      else
        execute(query, *args)
      end
      nil
    end

    # Batch up all execute statements inside the given block, executing when
    # the block returns successfully.
    # Note that this only batches up update calls, not execute calls, since
    # execute expects to return results immediately.
    # If this method is called again while already in a batch, the same batch
    # will be re-used and changes won't be executed until the outer batch
    # returns.
    # (It may be useful to add a force_new option later)
    def batch
      if in_batch?
        yield
      else
        begin
          @batch = Batch.new
          yield
          unless @batch.statements.empty?
            execute(*@batch.to_cql_ary + [@batch.execute_options])
          end
          unless @batch.counter_statements.empty?
            execute(*@batch.to_cql_ary(:counter) + [@batch.execute_options])
          end
        ensure
          @batch = nil
        end
      end
      nil
    end

    def in_batch?
      !!@batch
    end

    # update an AR-style record in cassandra
    # table_name is the cassandra table name
    # primary_key_attrs is a hash of { key => value } attributes to uniquely identify the record
    # changes is a list of updates to apply, in the AR#changes format (so typically you can just call record.changes) or as just straight alues
    # in other words, changes is a hash in either of these formats (mixing is ok):
    #   { "colname" => newvalue }
    #   { "colname" => [oldvalue, newvalue] }
    def update_record(table_name, primary_key_attrs, changes, ttl_seconds = nil, execute_options: {})
      batch do
        do_update_record(table_name, primary_key_attrs, changes, ttl_seconds, execute_options:)
      end
    end

    # same as update_record, but preferred when doing inserts -- it skips
    # updating columns with nil values, rather than creating tombstone delete
    # records for them
    def insert_record(table_name, primary_key_attrs, changes, ttl_seconds = nil, execute_options: {})
      changes = changes.reject { |_k, v| v.is_a?(Array) ? v.last.nil? : v.nil? }
      update_record(table_name, primary_key_attrs, changes, ttl_seconds, execute_options:)
    end

    def select_value(query, *args)
      result_row = execute(query, *args).fetch
      result_row && result_row.to_hash.values.first
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

    # returns a CQL snippet and list of arguments given a hash of conditions
    # e.g.
    # build_where_conditions(name: "foo", state: "ut")
    # => ["name = ? AND state = ?", ["foo", "ut"]]
    def build_where_conditions(conditions)
      where_args = []
      where_clause = conditions.sort.map do |k, v|
        where_args << v
        "#{k} = ?"
      end.join(" AND ")
      [where_clause, where_args]
    end

    def available?
      db.active?
    end

    def keyspace
      db.keyspace.to_s.dup.force_encoding("UTF-8")
    end
    alias_method :name, :keyspace

    protected

    def do_update_record(table_name, primary_key_attrs, changes, ttl_seconds, execute_options: {})
      primary_key_attrs = primary_key_attrs.stringify_keys
      changes = changes.stringify_keys
      where_clause, where_args = build_where_conditions(primary_key_attrs)

      primary_key_attrs.each_key do |key|
        if changes[key].is_a?(Array) && !changes[key].first.nil?
          raise ArgumentError, "Cannot change the primary key of a record, attempted to change #{key} #{changes[key].inspect}"
        end
      end

      deletes, updates = changes.
                         # normalize the values since we accept two formats
                         transform_values { |val| val.is_a?(Array) ? val.last : val }.
                         # reject values that are part of the primary key, since those are in the where clause
                         except(*primary_key_attrs.keys).
                         # sort, just so the generated cql is deterministic
                         sort_by(&:first).
                         # split changes into updates and deletes
                         partition { |_key, val| val.nil? }

      # inserts and updates in cassandra are equivalent,
      # so no need to differentiate here
      if updates.present?
        args = []
        statement = +"UPDATE #{table_name}"
        if ttl_seconds
          args << ttl_seconds
          statement << " USING TTL ?"
        end
        update_cql = updates.map do |key, val|
          args << val
          "#{key} = ?"
        end.join(", ")
        statement << " SET #{update_cql} WHERE #{where_clause}"
        args.concat where_args
        args.push execute_options
        update(statement, *args)
      end

      if deletes.present?
        args = []
        delete_cql = deletes.map(&:first).join(", ")
        statement = "DELETE #{delete_cql} FROM #{table_name} WHERE #{where_clause}"
        args.concat where_args
        args.push execute_options
        update(statement, *args)
      end
    end
  end
end
