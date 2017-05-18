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

class QuotedValue < String
end

module PostgreSQLAdapterExtensions
  def readonly?(table = nil, column = nil)
    return @readonly unless @readonly.nil?
    @readonly = (select_value("SELECT pg_is_in_recovery();") == "t")
  end

  def bulk_insert(table_name, records)
    keys = records.first.keys
    quoted_keys = keys.map{ |k| quote_column_name(k) }.join(', ')
    execute "COPY #{quote_table_name(table_name)} (#{quoted_keys}) FROM STDIN"
    raw_connection.put_copy_data records.inject(''){ |result, record|
                                   result << keys.map{ |k| quote_text(record[k]) }.join("\t") << "\n"
                                 }
    ActiveRecord::Base.connection.clear_query_cache
    raw_connection.put_copy_end
  end

  def quote_text(value)
    if value.nil?
      "\\N"
    else
      hash = {"\n" => "\\n", "\r" => "\\r", "\t" => "\\t", "\\" => "\\\\"}
      value.to_s.gsub(/[\n\r\t\\]/){ |c| hash[c] }
    end
  end

  def supports_delayed_constraint_validation?
    postgresql_version >= 90100
  end

  def add_foreign_key(from_table, to_table, options = {})
    raise ArgumentError, "Cannot specify custom options with :delay_validation" if options[:options] && options[:delay_validation]

    options.delete(:delay_validation) unless supports_delayed_constraint_validation?
    # pointless if we're in a transaction
    options.delete(:delay_validation) if open_transactions > 0
    options[:column] ||= "#{to_table.to_s.singularize}_id"
    column = options[:column]

    foreign_key_name = foreign_key_name(from_table, options)

    if options[:delay_validation]
      options[:options] = 'NOT VALID'
      # NOT VALID doesn't fully work through 9.3 at least, so prime the cache to make
      # it as fast as possible. Note that a NOT EXISTS would be faster, but this is
      # the query postgres does for the VALIDATE CONSTRAINT, so we want exactly this
      # query to be warm
      execute("SELECT fk.#{column} FROM #{quote_table_name(from_table)} fk LEFT OUTER JOIN #{quote_table_name(to_table)} pk ON fk.#{column}=pk.id WHERE pk.id IS NULL AND fk.#{column} IS NOT NULL LIMIT 1")
    end

    super(from_table, to_table, options)

    execute("ALTER TABLE #{quote_table_name(from_table)} VALIDATE CONSTRAINT #{quote_column_name(foreign_key_name)}") if options[:delay_validation]
  end

  def rename_index(table_name, old_name, new_name)
    return execute "ALTER INDEX #{quote_table_name(old_name)} RENAME TO #{quote_column_name(new_name)}";
  end

  def set_standard_conforming_strings
    super unless postgresql_version >= 90100
  end

  # we always use the default sequence name, so override it to not actually query the db
  # (also, it doesn't matter if you're using PG 8.2+)
  def default_sequence_name(table, pk)
    "#{table}_#{pk}_seq"
  end

  # postgres doesn't support limit on text columns, but it does on varchars. assuming we don't exceed
  # the varchar limit, change the type. otherwise drop the limit. not a big deal since we already
  # have max length validations in the models.
  def type_to_sql(type, limit = nil, *args)
    if type == :text && limit
      if limit <= 10485760
        type = :string
      else
        limit = nil
      end
    end
    super(type, limit, *args)
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
    schema = shard.name if @config[:use_qualified_names]

    result = query(<<-SQL, 'SCHEMA')
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

      columns = Hash[query(<<-SQL, "SCHEMA")]
        SELECT a.attnum, a.attname
        FROM pg_attribute a
        WHERE a.attrelid = #{oid}
        AND a.attnum IN (#{indkey.join(",")})
      SQL

      column_names = columns.stringify_keys.values_at(*indkey).compact

      # add info on sort order for columns (only desc order is explicitly specified, asc is the default)
      desc_order_columns = inddef.scan(/(\w+) DESC/).flatten
      orders = desc_order_columns.any? ? Hash[desc_order_columns.map {|order_column| [order_column, :desc]}] : {}

      ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, index_name, unique, column_names, [], orders)
    end
  end

  def index_exists?(_table_name, columns, _options = {})
    raise ArgumentError.new("if you're identifying an index by name only, you should use index_name_exists?") if columns.is_a?(Hash) && columns[:name]
    raise ArgumentError.new("columns should be a string, a symbol, or an array of those ") unless columns.is_a?(String) || columns.is_a?(Symbol) || columns.is_a?(Array)
    super
  end

  # some migration specs test migrations that add concurrent indexes; detect that, and strip the concurrent
  # but _only_ if there isn't another transaction in the stack
  def add_index_options(_table_name, _column_name, _options = {})
    index_name, index_type, index_columns, index_options, algorithm, using = super
    algorithm = nil if Rails.env.test? && algorithm == "CONCURRENTLY" && !ActiveRecord::Base.in_transaction_in_test?
    [index_name, index_type, index_columns, index_options, algorithm, using]
  end

  # Force things with (approximate) integer representations (Floats,
  # BigDecimals, Times, etc.) into those representations. Raise
  # ActiveRecord::StatementInvalid for any other non-integer things.
  def quote(value, column = nil)
    return value if value.is_a?(QuotedValue)

    if CANVAS_RAILS4_2
      if column && column.type == :integer && !value.respond_to?(:quoted_id)
        case value
          when String, ActiveSupport::Multibyte::Chars, nil, true, false
            # these already have branches for column.type == :integer (or don't
            # need one)
            super(value, column)
          else
            if value.respond_to?(:to_i)
              # quote the value in its integer representation
              value.to_i.to_s
            else
              # doesn't have a (known) integer representation, can't quote it
              # for an integer column
              raise ActiveRecord::StatementInvalid, "#{value.inspect} cannot be interpreted as an integer"
            end
        end
      else
        super
      end
    else
      # rails 5 doesn't have a column argument; when we remove rails 4.2 support, just a regular
      # super call will work
      super(value)
    end
  end

  def extension_installed?(extension)
    @extensions ||= {}
    @extensions.fetch(extension) do
      select_value(<<-SQL)
        SELECT nspname
        FROM pg_extension
          INNER JOIN pg_namespace ON extnamespace=pg_namespace.oid
        WHERE extname='#{extension}'
      SQL
    end
  end

  def extension_available?(extension)
    select_value("SELECT 1 FROM pg_available_extensions WHERE name='#{extension}'").to_i == 1
  end

  def set_search_path_on_function(function, args = "()", search_path = Shard.current.name)
    execute("ALTER FUNCTION #{quote_table_name(function)}#{args} SET search_path TO #{search_path}")
  end

  # temporarily adds schema to the search_path (i.e. so you can use an extension that won't work
  # using qualified names)
  def add_schema_to_search_path(schema)
    if schema_search_path.split(',').include?(schema)
      yield
    else
      old_search_path = schema_search_path
      transaction(requires_new: true) do
        begin
          self.schema_search_path += ",#{schema}"
          yield
        ensure
          # the transaction rolling back or committing will revert the search path change;
          # we don't need to do another query to set it
          @schema_search_path = old_search_path
        end
      end
    end
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

  # does a query first to warm the db cache, to make the actual constraint adding fast
  def change_column_null(table, column, nullness, default = nil)
    # no point in pre-warming the cache to avoid locking if we're already in a transaction
    return super if nullness != false || default || open_transactions != 0
    execute("SELECT COUNT(*) FROM #{quote_table_name(table)} WHERE #{column} IS NULL")
    super
  end

  private

  OID = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID
end
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PostgreSQLAdapterExtensions)

module TypeMapInitializerExtensions
  def query_conditions_for_initial_load(type_map)
    known_type_names = type_map.keys.map { |n| "'#{n}'" } + type_map.keys.map { |n| "'_#{n}'" }
    known_type_types = %w('r' 'e' 'd')
    <<-SQL % [known_type_names.join(", "), known_type_types.join(", ")]
    WHERE
      t.typname IN (%s)
      OR t.typtype IN (%s)
    SQL
  end
end
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::TypeMapInitializer.prepend(TypeMapInitializerExtensions)
