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
  # when changing this, you need to re-apply the latest migration creating the guard_excessive_updates function
  DEFAULT_MAX_UPDATE_LIMIT = 1000

  def initialize(*)
    super
    @max_update_limit = DEFAULT_MAX_UPDATE_LIMIT
  end

  def configure_connection
    super

    conn = (Rails.version < "7.1") ? @connection : @raw_connection
    conn.set_notice_receiver do |result|
      severity = result.result_error_field(PG::PG_DIAG_SEVERITY_NONLOCALIZED)
      rails_severity = case severity
                       when "WARNING", "NOTICE"
                         :warn
                       when "DEBUG"
                         :debug
                       when "INFO", "LOG"
                         :info
                       else
                         :error
                       end
      logger.send(rails_severity, "PG notice: " + result.result_error_message.strip)

      primary_message = result.result_error_field(PG::PG_DIAG_MESSAGE_PRIMARY)
      detail_message = result.result_error_field(PG::PG_DIAG_MESSAGE_DETAIL)
      formatted_message = if detail_message
                            primary_message + "\n" + detail_message
                          else
                            primary_message
                          end
      Sentry.capture_message(formatted_message, level: rails_severity)
    end
  end

  def receive_timeout_wrapper(&)
    return yield unless @config[:receive_timeout]

    Timeout.timeout(@config[:receive_timeout], PG::ConnectionBad, "receive timeout", &)
  end

  %I[begin_db_transaction create_savepoint active?].each do |method|
    class_eval <<~RUBY, __FILE__, __LINE__ + 1
      def #{method}(*)
        receive_timeout_wrapper { super }
      end
    RUBY
  end

  def explain(arel, binds = [], analyze: false)
    sql = "EXPLAIN #{"ANALYZE " if analyze}#{to_sql(arel, binds)}"
    ActiveRecord::ConnectionAdapters::PostgreSQL::ExplainPrettyPrinter.new
                                                                      .pp(exec_query(sql, "EXPLAIN", binds))
  end

  def readonly?
    return @readonly unless @readonly.nil?

    @readonly = in_recovery?
  end

  def bulk_insert(table_name, records)
    keys = records.first.keys
    quoted_keys = keys.map { |k| quote_column_name(k) }.join(", ")
    execute "COPY #{quote_table_name(table_name)} (#{quoted_keys}) FROM STDIN"
    raw_connection.put_copy_data records.inject(+"") { |result, record|
                                   result << keys.map { |k| quote_text(record[k]) }.join("\t") << "\n"
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
      hash = { "\n" => "\\n", "\r" => "\\r", "\t" => "\\t", "\\" => "\\\\" }
      value.to_s.gsub(/[\n\r\t\\]/) { |c| hash[c] }
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
      if limit <= 10_485_760
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
      "string_agg((#{func_arg_esc(args.first)})::text, #{quote(args[1] || ",")})"
    else
      super
    end
  end

  def group_by(*columns)
    # although postgres 9.1 lets you omit columns that are functionally
    # dependent on the primary keys, that's only true if the FROM items are
    # all tables (i.e. not subselects). to keep things simple, we always
    # specify all columns for postgres
    infer_group_by_columns(columns).flatten.join(", ")
  end

  def indexes(table_name) # :nodoc:
    scope = quoted_scope(table_name)

    result = query(<<~SQL.squish, "SCHEMA")
      SELECT distinct i.relname, d.indisunique, d.indkey, pg_get_indexdef(d.indexrelid), t.oid,
                      pg_catalog.obj_description(i.oid, 'pg_class') AS comment, d.indisvalid, d.indisreplident
      FROM pg_class t
      INNER JOIN pg_index d ON t.oid = d.indrelid
      INNER JOIN pg_class i ON d.indexrelid = i.oid
      LEFT JOIN pg_namespace n ON n.oid = t.relnamespace
      WHERE i.relkind IN ('i', 'I')
        AND d.indisprimary = 'f'
        AND t.relname = #{scope[:name]}
        AND n.nspname = #{scope[:schema]}
      ORDER BY i.relname
    SQL

    result.map do |row|
      index_name = row[0]
      unique = row[1]
      indkey = row[2].split.map(&:to_i)
      inddef = row[3]
      oid = row[4]
      comment = row[5]
      valid = row[6]
      replica_identity = row[7]
      using, expressions, include, nulls_not_distinct, where = inddef.scan(/ USING (\w+?) \((.+?)\)(?: INCLUDE \((.+?)\))?( NULLS NOT DISTINCT)?(?: WHERE (.+))?\z/m).flatten

      orders = {}
      opclasses = {}
      include_columns = include ? include.split(",").map(&:strip) : []

      if indkey.include?(0)
        columns = expressions
      else
        columns = if $canvas_rails == "7.0"
                    query(<<~SQL.squish, "SCHEMA").to_h.values_at(*indkey).compact
                      SELECT a.attnum, a.attname
                      FROM pg_attribute a
                      WHERE a.attrelid = #{oid}
                      AND a.attnum IN (#{indkey.join(",")})
                    SQL
                  else
                    column_names_from_column_numbers(oid, indkey)
                  end

        # prevent INCLUDE columns from being matched
        columns.reject! { |c| include_columns.include?(c) }

        # add info on sort order (only desc order is explicitly specified, asc is the default)
        # and non-default opclasses
        expressions.scan(/(?<column>\w+)"?\s?(?<opclass>\w+_ops(?:_\w+)?)?\s?(?<desc>DESC)?\s?(?<nulls>NULLS (?:FIRST|LAST))?/).each do |column, opclass, desc, nulls|
          opclasses[column] = opclass.to_sym if opclass
          if nulls
            orders[column] = [desc, nulls].compact.join(" ")
          elsif desc
            orders[column] = :desc
          end
        end
      end

      ActiveRecord::ConnectionAdapters::IndexDefinition.new(
        table_name,
        index_name,
        unique,
        columns,
        orders:,
        opclasses:,
        where:,
        using: using.to_sym,
        include: include_columns.presence,
        nulls_not_distinct: nulls_not_distinct.present?,
        comment: comment.presence,
        valid:,
        replica_identity:
      )
    end
  end

  def index_exists?(table_name, column_name = nil, **options)
    raise ArgumentError, "if you're identifying an index by name only, you should use index_name_exists?" if column_name.nil? && options.size == 1 && options.key?(:name)

    super
  end

  # some migration specs test migrations that add concurrent indexes; detect that, and strip the concurrent
  # but _only_ if there isn't another transaction in the stack
  def add_index_options(_table_name, _column_name, **)
    index_name, index_type, index_columns, index_options, algorithm, using = super
    algorithm = nil if Rails.env.test? && algorithm == "CONCURRENTLY" && !ActiveRecord::Base.in_transaction_in_test?
    [index_name, index_type, index_columns, index_options, algorithm, using]
  end

  def index_algorithm(algorithm)
    return nil if open_transactions > 0

    super
  end

  def set_replica_identity(table, identity = "index_#{table}_replica_identity")
    super
  end

  def add_column(table_name, column_name, type, if_not_exists: false, **options)
    return if if_not_exists && column_exists?(table_name, column_name)

    super(table_name, column_name, type, **options)
  end

  def remove_column(table_name, column_name, type = nil, if_exists: false, **options)
    return if if_exists && !column_exists?(table_name, column_name)

    super
  end

  def create_table(table_name, id: :primary_key, primary_key: nil, force: nil, **options)
    super

    add_guard_excessive_updates(table_name)
  end

  def add_guard_excessive_updates(table_name)
    # Don't try to install this on rails-internal tables; they need to be created for
    # internal_metadata to exist and this guard isn't really useful there either
    return if [ActiveRecord::Base.internal_metadata_table_name, ActiveRecord::Base.schema_migrations_table_name].include?(table_name)
    # If the function doesn't exist yet it will be backfilled
    return unless ((Rails.version < "7.1") ? ::ActiveRecord::InternalMetadata : ::ActiveRecord::InternalMetadata.new(self))[:guard_dangerous_changes_installed]

    ["UPDATE", "DELETE"].each do |operation|
      trigger_name = "guard_excessive_#{operation.downcase}s"

      execute(<<~SQL.squish)
        CREATE TRIGGER #{trigger_name}
          AFTER #{operation}
          ON #{quote_table_name(table_name)}
          REFERENCING OLD TABLE AS oldtbl
          FOR EACH STATEMENT
          EXECUTE PROCEDURE #{quote_table_name("guard_excessive_updates")}();
      SQL
    end
  end

  def with_max_update_limit(limit)
    return yield if limit == @max_update_limit

    old_limit = @max_update_limit
    @max_update_limit = limit

    if transaction_open?
      execute("SET LOCAL inst.max_update_limit = #{limit}")
      ret = yield
      execute("SET LOCAL inst.max_update_limit = DEFAULT")
    else
      transaction do
        execute("SET LOCAL inst.max_update_limit = #{limit}")
        ret = yield
      end
    end
    ret
  ensure
    @max_update_limit = old_limit if old_limit
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
    @collations ||= select_rows <<~SQL.squish, "SCHEMA"
      SELECT nspname, collname
      FROM pg_collation
      INNER JOIN pg_namespace ON collnamespace=pg_namespace.oid
      WHERE
        collprovider='i' AND
        NOT collisdeterministic AND
        collname LIKE '%-u-kn-true'
    SQL
  end

  def create_icu_collations
    collation = "und-u-kn-true"
    unless icu_collations.find { |_schema, extant_collation| extant_collation == collation }
      update("CREATE COLLATION public.#{quote_column_name(collation)} (LOCALE=#{quote(collation)}, PROVIDER='icu', DETERMINISTIC=false)")
    end

    I18n.available_locales.each do |locale|
      next if locale.to_s.include?("-x-")

      I18n.with_locale(locale) do
        next if Canvas::ICU.collator.rules.empty?

        collation = "#{locale}-u-kn-true"
        next if icu_collations.find { |_schema, extant_collation| extant_collation == collation }

        update("CREATE COLLATION public.#{quote_column_name(collation)} (LOCALE=#{quote(collation)}, PROVIDER='icu', DETERMINISTIC=false)")
      end
    end
  ensure
    @collations = nil
  end

  class AbortExceptionMatcher
    def self.===(other)
      return true if defined?(IRB::Abort) && other.is_a?(IRB::Abort)

      false
    end
  end

  def execute(...)
    super
  rescue AbortExceptionMatcher
    (($canvas_rails == "7.1") ? @raw_connection : @connection).cancel
    raise
  end

  def exec_query(...)
    super
  rescue AbortExceptionMatcher
    (($canvas_rails == "7.1") ? @raw_connection : @connection).cancel
    raise
  end

  BLOCKED_INSPECT_IVS = %i[
    @transaction_manager
    @query_cache
    @logger
    @instrumenter
    @pool
    @visitor
    @statements
    @type_map
    @schema_cache
    @type_map_for_results
  ].freeze

  private_constant :BLOCKED_INSPECT_IVS

  def inspect
    "#{to_s[0...-1]} " \
      "#{(instance_variables - BLOCKED_INSPECT_IVS).map { |iv| "#{iv}=#{instance_variable_get(iv).inspect}" }.join(", ")}" \
      ">"
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
    sql << " #{action_sql("DELETE", o.on_delete)}" if o.on_delete
    sql << " #{action_sql("UPDATE", o.on_update)}" if o.on_update
    sql << " DEFERRABLE INITIALLY #{o.deferrable.to_s.upcase}" if o.deferrable

    sql
  end

  def foreign_key_column_constraint(from_table, to_table, options)
    prefix = ActiveRecord::Base.table_name_prefix
    suffix = ActiveRecord::Base.table_name_suffix
    to_table = "#{prefix}#{to_table}#{suffix}"

    options = @conn.foreign_key_options(from_table, to_table, options)
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
      table.index(column_names, **index_options(table.name))
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
  # TODO: move this to activerecord-pg-extensions
  def valid_column_definition_options
    super + [:delay_validation]
  end

  def add_column_for_alter(table_name, column_name, type, **options)
    td = create_table_definition(table_name)
    cd = td.new_column_definition(column_name, type, **options)
    schema = schema_creation
    schema.set_table_context(table_name)
    schema.accept(ActiveRecord::ConnectionAdapters::AddColumnDefinition.new(cd))
  end
end

module IndexDefinitionExtensions
  def self.prepended(klass)
    super

    klass.attr_reader :replica_identity
  end

  def initialize(*args, replica_identity: false, **kwargs)
    @replica_identity = replica_identity
    if $canvas_rails == "7.0"
      kwargs.delete(:include)
      kwargs.delete(:nulls_not_distinct)
      kwargs.delete(:valid)
    end

    super(*args, **kwargs)
  end

  def defined_for?(*, replica_identity: nil, **)
    return false unless replica_identity.nil? || self.replica_identity == replica_identity

    super
  end
end

module TableDefinitionExtensions
  def replica_identity_index(column = :root_account_id)
    primary_keys = self.primary_keys&.name || [columns.find(&:primary_key?)&.name || :id]
    index([column] + primary_keys, unique: true, name: "index_#{name}_replica_identity")
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaCreation.prepend(SchemaCreationExtensions)
ActiveRecord::ConnectionAdapters::ColumnDefinition.prepend(ColumnDefinitionExtensions)
ActiveRecord::ConnectionAdapters::IndexDefinition.prepend(IndexDefinitionExtensions)
ActiveRecord::ConnectionAdapters::ReferenceDefinition.prepend(ReferenceDefinitionExtensions)
ActiveRecord::ConnectionAdapters::TableDefinition.prepend(TableDefinitionExtensions)
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(SchemaStatementsExtensions)
