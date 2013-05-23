# encoding: utf-8
#
# Copyright (C) 2012 Instructure, Inc.
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
module Canvas::Cassandra
  class Database
    def self.configured?(config_name)
      raise ArgumentError, "config name required" if config_name.blank?
      config = Setting.from_config('cassandra').try(:[], config_name)
      config && config['servers'] && config['keyspace']
    end

    def self.from_config(config_name)
      @connections ||= {}
      @connections[config_name] ||= begin
        config = Setting.from_config('cassandra').try(:[], config_name)
        raise ArgumentError, "No configuration for Cassandra for: #{config_name.inspect}" unless config
        servers = Array(config['servers'])
        raise "No Cassandra servers defined for: #{config_name.inspect}" unless servers.present?
        keyspace = config['keyspace']
        raise "No keyspace specified for: #{config_name.inspect}" unless keyspace.present?
        opts = {:keyspace => keyspace, :cql_version => '3.0.0'}
        thrift_opts = {}
        thrift_opts[:retries] = config['retries'] if config['retries']
        thrift_opts[:connect_timeout] = config['connect_timeout'] if config['connect_timeout']
        thrift_opts[:timeout] = config['timeout'] if config['timeout']
        self.new(servers, opts, thrift_opts)
      end
    end

    def self.config_names
      Setting.from_config('cassandra').try(:keys) || []
    end

    def initialize(servers, opts, thrift_opts)
      Bundler.require 'cassandra'
      @db = CassandraCQL::Database.new(servers, opts, thrift_opts)
    end

    attr_reader :db

    # This just takes a raw query string, and params to replace `?` with.
    # Though cassandra isn't relational, it'd still be useful to be able to
    # build up queries using scopes. Maybe one of the ruby libs like datamapper
    # or arel is flexible enough for this, rather than rolling our own.
    def execute(query, *args)
      result = nil
      ms = Benchmark.ms do
        result = @db.execute(query, *args)
      end
      Rails.logger.debug("  #{"CQL (%.2fms)" % [ms]}  #{::CassandraCQL::Statement.sanitize(query, args)}")
      result
    end

    # private Struct used to store batch information
    class Batch < Struct.new(:statements, :args)
      def initialize
        self.statements = []
        self.args = []
      end
      delegate :empty?, :present?, :blank?, :to => :statements

      def to_cql_ary
        case statements.size
        when 0
          raise "Cannot execute an empty batch"
        when 1
          statements + args
        else
          # http://www.datastax.com/docs/1.1/references/cql/BATCH
          # note there's no semicolons between statements in the batch
          cql = []
          cql << "BEGIN BATCH"
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
        @batch.statements << query
        @batch.args.concat args
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
          unless @batch.empty?
            execute(*@batch.to_cql_ary)
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
    def update_record(table_name, primary_key_attrs, changes)
      batch do
        do_update_record(table_name, primary_key_attrs, changes)
      end
    end

    # same as update_record, but preferred when doing inserts -- it skips
    # updating columns with nil values, rather than creating tombstone delete
    # records for them
    def insert_record(table_name, primary_key_attrs, changes)
      changes = changes.reject { |k,v| v.is_a?(Array) ? v.last.nil? : v.nil? }
      update_record(table_name, primary_key_attrs, changes)
    end

    def select_value(query, *args)
      result_row = execute(query, *args).fetch
      result_row && result_row.to_hash.values.first
    end

    def keyspace_information
      @db.keyspaces.find { |k| k.name == @db.keyspace }
    end

    # returns a CQL snippet and list of arguments given a hash of conditions
    # e.g.
    # build_where_conditions(name: "foo", state: "ut")
    # => ["name = ? AND state = ?", ["foo", "ut"]]
    def build_where_conditions(conditions)
      where_args = []
      where_clause = conditions.sort_by { |k,v| k.to_s }.map { |k,v| where_args << v; "#{k} = ?" }.join(" AND ")
      return where_clause, where_args
    end

    protected

    def do_update_record(table_name, primary_key_attrs, changes)
      primary_key_attrs = primary_key_attrs.with_indifferent_access
      changes = changes.with_indifferent_access
      where_clause, where_args = build_where_conditions(primary_key_attrs)

      primary_key_attrs.each do |key,value|
        if changes[key].is_a?(Array) && !changes[key].first.nil?
          raise ArgumentError, "Cannot change the primary key of a record, attempted to change #{key} #{changes[key].inspect}"
        end
      end

      deletes, updates = changes.
        # normalize the values since we accept two formats
        map { |key,val| [key.to_s, val.is_a?(Array) ? val.last : val] }.
        # reject values that are part of the primary key, since those are in the where clause
        reject { |key,val| primary_key_attrs.key?(key) }.
        # sort, just so the generated cql is deterministic
        sort_by(&:first).
        # split changes into updates and deletes
        partition { |key,val| val.nil? }

      # inserts and updates in cassandra are equivalent,
      # so no need to differentiate here
      if updates.present?
        args = []
        update_cql = updates.map { |key,val| args << val; "#{key} = ?" }.join(", ")
        statement = "UPDATE #{table_name} SET #{update_cql} WHERE #{where_clause}"
        args.concat where_args
        update(statement, *args)
      end

      if deletes.present?
        args = []
        delete_cql = deletes.map(&:first).join(", ")
        statement = "DELETE #{delete_cql} FROM #{table_name} WHERE #{where_clause}"
        args.concat where_args
        update(statement, *args)
      end
    end
  end

  module Migration
    module ClassMethods
      def cassandra
        @cassandra ||= Canvas::Cassandra::Database.from_config(cassandra_cluster)
      end

      def runnable?
        raise "cassandra_cluster is required to be defined" unless respond_to?(:cassandra_cluster) && cassandra_cluster.present?
        Shard.current == Shard.birth && Canvas::Cassandra::Database.configured?(cassandra_cluster)
      end
    end

    def self.included(migration)
      migration.tag :cassandra
      migration.extend ClassMethods
    end
  end
end
