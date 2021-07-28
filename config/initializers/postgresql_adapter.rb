# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require "active_record/pg_extensions/all"

class QuotedValue < String
end

module PostgreSQLAdapterExtensions
  def receive_timeout_wrapper
    return yield unless @config[:receive_timeout]
    Timeout.timeout(@config[:receive_timeout], PG::ConnectionBad, "receive timeout") { yield }
  end

  %I{begin_db_transaction create_savepoint active?}.each do |method|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{method}(*)
        receive_timeout_wrapper { super }
      end
    RUBY
  end


  def explain(arel, binds = [], analyze: false)
    sql = "EXPLAIN #{"ANALYZE " if analyze}#{to_sql(arel, binds)}"
    ActiveRecord::ConnectionAdapters::PostgreSQL::ExplainPrettyPrinter.new.pp(exec_query(sql, "EXPLAIN", binds))
  end

  def readonly?(table = nil, column = nil)
    return @readonly unless @readonly.nil?
    @readonly = in_recovery?
  end

  def bulk_insert(table_name, records)
    keys = records.first.keys
    quoted_keys = keys.map{ |k| quote_column_name(k) }.join(', ')
    execute "COPY #{quote_table_name(table_name)} (#{quoted_keys}) FROM STDIN"
    raw_connection.put_copy_data records.inject(+''){ |result, record|
                                   result << keys.map{ |k| quote_text(record[k]) }.join("\t") << "\n"
                                 }
    ActiveRecord::Base.connection.clear_query_cache
    raw_connection.put_copy_end
    result = raw_connection.get_result
    begin
      result.check
    rescue => e
      raise translate_exception(e, message: e.message, sql: "COPY FROM STDIN", binds: [])
    end
    result.cmd_tuples
  end

  def quote_text(value)
    if value.nil?
      "\\N"
    elsif value.is_a?(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array::Data)
      quote_text(encode_array(value))
    else
      hash = {"\n" => "\\n", "\r" => "\\r", "\t" => "\\t", "\\" => "\\\\"}
      value.to_s.gsub(/[\n\r\t\\]/){ |c| hash[c] }
    end
  end

  def set_standard_conforming_strings
    # not needed in PG 9.1+
  end

  # we always use the default sequence name, so override it to not actually query the db
  # (also, it doesn't matter if you're using PG 8.2+)
  def default_sequence_name(table, pk)
    "#{table}_#{pk}_seq"
  end

  # postgres doesn't support limit on text columns, but it does on varchars. assuming we don't exceed
  # the varchar limit, change the type. otherwise drop the limit. not a big deal since we already
  # have max length validations in the models.
  def type_to_sql(type, limit: nil, **)
    if type == :text && limit
      if limit <= 10485760
        type = :string
      else
        limit = nil
      end
    end
    super
  end

  def func(name, *args)
    case name
      when :group_concat
        "string_agg((#{func_arg_esc(args.first)})::text, #{quote(args[1] || ',')})"
      else
        super
    end
  end

  def group_by(*columns)
    # although postgres 9.1 lets you omit columns that are functionally
    # dependent on the primary keys, that's only true if the FROM items are
    # all tables (i.e. not subselects). to keep things simple, we always
    # specify all columns for postgres
    infer_group_by_columns(columns).flatten.join(', ')
  end

  # ActiveRecord 3.2 ignores indexes if it cannot parse the column names
  # (for instance when using functions like LOWER)
  # this will lead to problems if we try to remove the index (index_exists? will return false)
  def indexes(table_name)
    schema = shard.name

    result = query(<<~SQL, 'SCHEMA')
         SELECT distinct i.relname, d.indisunique, d.indkey, pg_get_indexdef(d.indexrelid), t.oid
         FROM pg_class t
         INNER JOIN pg_index d ON t.oid = d.indrelid
         INNER JOIN pg_class i ON d.indexrelid = i.oid
         WHERE i.relkind = 'i'
           AND d.indisprimary = 'f'
           AND t.relname = '#{table_name}'
           AND i.relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname = #{schema ? "'#{schema}'" : 'ANY (current_schemas(false))'} )
        ORDER BY i.relname
    SQL

    result.map do |row|
      index_name = row[0]
      unique = row[1] == 't'
      indkey = row[2].split(" ")
      inddef = row[3]
      oid = row[4]

      columns = Hash[query(<<~SQL, "SCHEMA")]
        SELECT a.attnum, a.attname
        FROM pg_attribute a
        WHERE a.attrelid = #{oid}
        AND a.attnum IN (#{indkey.join(",")})
      SQL

      column_names = columns.stringify_keys.values_at(*indkey).compact

      # add info on sort order for columns (only desc order is explicitly specified, asc is the default)
      desc_order_columns = inddef.scan(/(\w+) DESC/).flatten
      orders = desc_order_columns.any? ? Hash[desc_order_columns.map {|order_column| [order_column, :desc]}] : {}

      ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, index_name, unique, column_names, orders: orders)
    end
  end

  def index_exists?(_table_name, columns, _options = {})
    raise ArgumentError.new("if you're identifying an index by name only, you should use index_name_exists?") if columns.is_a?(Hash) && columns[:name]
    raise ArgumentError.new("columns should be a string, a symbol, or an array of those ") unless columns.is_a?(String) || columns.is_a?(Symbol) || columns.is_a?(Array)
    super
  end

  # some migration specs test migrations that add concurrent indexes; detect that, and strip the concurrent
  # but _only_ if there isn't another transaction in the stack
  def add_index_options(_table_name, _column_name, **)
    index_name, index_type, index_columns, index_options, algorithm, using = super
    algorithm = nil if Rails.env.test? && algorithm == "CONCURRENTLY" && !ActiveRecord::Base.in_transaction_in_test?
    [index_name, index_type, index_columns, index_options, algorithm, using]
  end

  if CANVAS_RAILS6_0
    def remove_index(table_name, options = {})
      table = ActiveRecord::ConnectionAdapters::PostgreSQL::Utils.extract_schema_qualified_name(table_name.to_s)

      if options.is_a?(Hash) && options.key?(:name)
        provided_index = ActiveRecord::ConnectionAdapters::PostgreSQL::Utils.extract_schema_qualified_name(options[:name].to_s)

        options[:name] = provided_index.identifier
        table = ActiveRecord::ConnectionAdapters::PostgreSQL::Name.new(provided_index.schema, table.identifier) unless table.schema.present?

        if provided_index.schema.present? && table.schema != provided_index.schema
          raise ArgumentError.new("Index schema '#{provided_index.schema}' does not match table schema '#{table.schema}'")
        end
      end

      name = index_name_for_remove(table.to_s, options)
      return if name.nil? && options[:if_exists]

      index_to_remove = ActiveRecord::ConnectionAdapters::PostgreSQL::Name.new(table.schema, name)
      algorithm =
        if options.is_a?(Hash) && options.key?(:algorithm)
          index_algorithms.fetch(options[:algorithm]) do
            raise ArgumentError.new("Algorithm must be one of the following: #{index_algorithms.keys.map(&:inspect).join(', ')}")
          end
        end
      algorithm = nil if open_transactions > 0
      if_exists = " IF EXISTS" if options.is_a?(Hash) && options[:if_exists]
      execute "DROP INDEX #{algorithm} #{if_exists} #{quote_table_name(index_to_remove)}"
    end
  else
    def index_algorithm(algorithm)
      return nil if open_transactions > 0

      super
    end
  end

  def index_name_for_remove(table_name, options = {})
    return options[:name] if can_remove_index_by_name?(options)

    checks = []

    if options.is_a?(Hash)
      checks << lambda { |i| i.name == options[:name].to_s } if options.key?(:name)
      column_names = index_column_names(options[:column])
    else
      column_names = index_column_names(options)
    end

    if column_names.present?
      checks << lambda { |i| index_name(table_name, i.columns) == index_name(table_name, column_names) }
    end

    raise ArgumentError, "No name or columns specified" if checks.none?

    matching_indexes = indexes(table_name).select { |i| checks.all? { |check| check[i] } }

    if matching_indexes.count > 1
      raise ArgumentError, "Multiple indexes found on #{table_name} columns #{column_names}. " \
                                 "Specify an index name from #{matching_indexes.map(&:name).join(', ')}"
    elsif matching_indexes.none?
      return if options.is_a?(Hash) && options[:if_exists]
      raise ArgumentError, "No indexes found on #{table_name} with the options provided."
    else
      matching_indexes.first.name
    end
  end

  def can_remove_index_by_name?(options)
    options.is_a?(Hash) && options.key?(:name) && options.except(:name, :algorithm, :if_exists).empty?
  end

  def add_column(table_name, column_name, type, if_not_exists: false, **options)
    return if if_not_exists && column_exists?(table_name, column_name)
    super(table_name, column_name, type, **options)
  end

  def remove_column(table_name, column_name, type = nil, if_exists: false, **options)
    return if if_exists && !column_exists?(table_name, column_name)
    super
  end

  def quote(*args)
    value = args.first
    return value if value.is_a?(QuotedValue)

    super
  end

  # we no longer use any triggers, so we removed hair_trigger,
  # but don't want to go modifying all the old migrations, so just
  # make them dummies
  class CreateTriggerChain
    def on(*)
      self
    end

    def after(*)
      self
    end

    def where(*)
      self
    end
  end

  def create_trigger(*)
    CreateTriggerChain.new
  end

  def drop_trigger(name, table, generated: false)
    execute("DROP TRIGGER IF EXISTS #{name} ON #{quote_table_name(table)};\nDROP FUNCTION IF EXISTS #{quote_table_name(name)}();\n")
  end

  def icu_collations
    return [] if postgresql_version < 120000
    @collations ||= select_rows <<~SQL, "SCHEMA"
      SELECT nspname, collname
      FROM pg_collation
      INNER JOIN pg_namespace ON collnamespace=pg_namespace.oid
      WHERE
        collprovider='i' AND
        NOT collisdeterministic AND
        collcollate LIKE '%-u-kn-true'
    SQL
  end

  def create_icu_collations
    return if postgresql_version < 120000
    original_locale = I18n.locale

    collation = "und-u-kn-true"
    unless icu_collations.find { |_schema, extant_collation| extant_collation == collation }
      update("CREATE COLLATION public.#{quote_column_name(collation)} (LOCALE=#{quote(collation)}, PROVIDER='icu', DETERMINISTIC=false)")
    end

    I18n.available_locales.each do |locale|
      next if locale =~ /-x-/
      I18n.locale = locale
      next if Canvas::ICU.collator.rules.empty?
      collation = "#{locale}-u-kn-true"
      next if icu_collations.find { |_schema, extant_collation| extant_collation == collation }
      update("CREATE COLLATION public.#{quote_column_name(collation)} (LOCALE=#{quote(collation)}, PROVIDER='icu', DETERMINISTIC=false)")
    end
  ensure
    @collations = nil
    I18n.locale = original_locale
  end

  class AbortExceptionMatcher
    def self.===(other)
      return true if defined?(IRB::Abort) && other.is_a?(IRB::Abort)

      false
    end
  end

  def execute(*)
    super
  rescue AbortExceptionMatcher
    @connection.cancel
    raise
  end

  def exec_query(*)
    super
  rescue AbortExceptionMatcher
    @connection.cancel
    raise
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PostgreSQLAdapterExtensions)


module SchemaCreationExtensions
  def set_table_context(table)
    @table = table
  end

  def visit_AlterTable(o)
    set_table_context(o.name)
    super
  end

  def visit_TableDefinition(o)
    set_table_context(o.name)
    super
  end

  def visit_ColumnDefinition(o)
    column_sql = super
    column_sql << " " << foreign_key_column_constraint(@table, o.foreign_key[:to_table], column: o.name, **o.foreign_key) if o.foreign_key
    column_sql
  end

  def visit_ForeignKeyDefinition(o, constraint_type: :table)
    sql = +"CONSTRAINT #{quote_column_name(o.name)}"
    sql << " FOREIGN KEY (#{quote_column_name(o.column)})" if constraint_type == :table
    sql << " REFERENCES #{quote_table_name(o.to_table)} (#{quote_column_name(o.primary_key)})"
    sql << " #{action_sql('DELETE', o.on_delete)}" if o.on_delete
    sql << " #{action_sql('UPDATE', o.on_update)}" if o.on_update
    sql
  end

  def foreign_key_column_constraint(from_table, to_table, options)
    prefix = ActiveRecord::Base.table_name_prefix
    suffix = ActiveRecord::Base.table_name_suffix
    to_table = "#{prefix}#{to_table}#{suffix}"

    options = foreign_key_options(from_table, to_table, options)
    fk = ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(from_table, to_table, options)
    visit_ForeignKeyDefinition(fk, constraint_type: :column)
  end
end

module ColumnDefinitionExtensions
  def foreign_key
    options[:foreign_key]
  end

  def foreign_key=(value)
    options[:foreign_key] = value
  end
end

module ReferenceDefinitionExtensions
  def add_to(table)
    columns.each do |name, type, options|
      options = options.merge(foreign_key: foreign_key_options) if foreign_key
      table.column(name, type, **options)
    end

    if index
      if CANVAS_RAILS6_0
        table.index(column_names, index_options)
      else
        table.index(column_names, **index_options(table.name))
      end
    end
  end

  def foreign_key_options
    as_options(foreign_key).merge(column: column_name, to_table: foreign_table_name)
  end

  def foreign_table_name
    as_options(foreign_key).fetch(:to_table) do
      ActiveRecord::Base.pluralize_table_names ? name.to_s.pluralize : name
    end
  end
end

module SchemaStatementsExtensions
  def add_column_for_alter(table_name, column_name, type, **options)
    td = create_table_definition(table_name)
    cd = td.new_column_definition(column_name, type, **options)
    schema = schema_creation
    schema.set_table_context(table_name)
    schema.accept(AddColumnDefinition.new(cd))
  end
end

if CANVAS_RAILS6_0
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::SchemaCreation.prepend(SchemaCreationExtensions)
else
  ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaCreation.prepend(SchemaCreationExtensions)
end
ActiveRecord::ConnectionAdapters::ColumnDefinition.prepend(ColumnDefinitionExtensions)
ActiveRecord::ConnectionAdapters::ReferenceDefinition.prepend(ReferenceDefinitionExtensions)
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(SchemaStatementsExtensions)
