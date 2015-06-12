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
    column  = options[:column] || "#{to_table.to_s.singularize}_id"
    foreign_key_name = foreign_key_name(from_table, column, options)

    if options[:delay_validation]
      options[:options] = 'NOT VALID'
      # NOT VALID doesn't fully work through 9.3 at least, so prime the cache to make
      # it as fast as possible. Note that a NOT EXISTS would be faster, but this is
      # the query postgres does for the VALIDATE CONSTRAINT, so we want exactly this
      # query to be warm
      execute("SELECT fk.#{column} FROM #{from_table} fk LEFT OUTER JOIN #{to_table} pk ON fk.#{column}=pk.id WHERE pk.id IS NULL AND fk.#{column} IS NOT NULL LIMIT 1")
    end

    super(from_table, to_table, options)

    execute("ALTER TABLE #{quote_table_name(from_table)} VALIDATE CONSTRAINT #{quote_column_name(foreign_key_name)}") if options[:delay_validation]
  end

  def rename_index(table_name, old_name, new_name)
    return execute "ALTER INDEX #{quote_column_name(old_name)} RENAME TO #{quote_table_name(new_name)}";
  end

  # have to replace the entire method to support concurrent
  def add_index(table_name, column_name, options = {})
    column_names = Array(column_name)
    index_name   = index_name(table_name, :column => column_names)

    if Hash === options # legacy support, since this param was a string
      index_type = options[:unique] ? "UNIQUE" : ""
      index_name = options[:name].to_s if options[:name]
      concurrently = "CONCURRENTLY " if options[:algorithm] == :concurrently && self.open_transactions == 0
      conditions = options[:where]
      if conditions
        sql_conditions = options[:where]
        unless sql_conditions.is_a?(String)
          model_class = table_name.classify.constantize rescue nil
          model_class ||= ActiveRecord::Base.all_models.detect{|m| m.table_name.to_s == table_name.to_s}
          model_class ||= ActiveRecord::Base
          sql_conditions = model_class.send(:sanitize_sql, conditions, table_name.to_s.dup)
        end
        conditions = " WHERE #{sql_conditions}"
      end
    else
      index_type = options
    end

    if index_name.length > index_name_length
      warning = "Index name '#{index_name}' on table '#{table_name}' is too long; the limit is #{index_name_length} characters. Skipping."
      @logger.warn(warning)
      raise warning unless Rails.env.production?
      return
    end
    if index_exists?(table_name, index_name, false)
      @logger.warn("Index name '#{index_name}' on table '#{table_name}' already exists. Skipping.")
      return
    end
    quoted_column_names = quoted_columns_for_index(column_names, options).join(", ")

    execute "CREATE #{index_type} INDEX #{concurrently}#{quote_column_name(index_name)} ON #{quote_table_name(table_name)} (#{quoted_column_names})#{conditions}"
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
    result = query(<<-SQL, 'SCHEMA')
         SELECT distinct i.relname, d.indisunique, d.indkey, pg_get_indexdef(d.indexrelid), t.oid
         FROM pg_class t
         INNER JOIN pg_index d ON t.oid = d.indrelid
         INNER JOIN pg_class i ON d.indexrelid = i.oid
         WHERE i.relkind = 'i'
           AND d.indisprimary = 'f'
           AND t.relname = '#{table_name}'
           AND i.relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname = ANY (current_schemas(false)) )
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

      column_names = columns.values_at(*indkey).compact

      # add info on sort order for columns (only desc order is explicitly specified, asc is the default)
      desc_order_columns = inddef.scan(/(\w+) DESC/).flatten
      orders = desc_order_columns.any? ? Hash[desc_order_columns.map {|order_column| [order_column, :desc]}] : {}

      ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, index_name, unique, column_names, [], orders)
    end
  end

  # Force things with (approximate) integer representations (Floats,
  # BigDecimals, Times, etc.) into those representations. Raise
  # ActiveRecord::StatementInvalid for any other non-integer things.
  def quote(value, column = nil)
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
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PostgreSQLAdapterExtensions)

if CANVAS_RAILS3
  module PostgreSQLAdapterFloatFixes
    # Handle quoting properly for Infinity and NaN. This fix exists in Rails 4.0
    # and can be safely removed once we upgrade.
    #
    # This patch is covered by tests in spec/initializers/active_record_quoting_spec.rb
    def quote(value, column = nil) #:nodoc:
      if value.kind_of?(Float)
        if value.infinite? && column && column.type == :datetime
          "'#{value.to_s.downcase}'"
        elsif value.infinite? || value.nan?
          "'#{value}'"
        else
          super
        end
      else
        super
      end
    end
  end

  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PostgreSQLAdapterFloatFixes)
end
