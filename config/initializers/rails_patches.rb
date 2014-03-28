if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
    # Force things with (approximate) integer representations (Floats,
    # BigDecimals, Times, etc.) into those representations. Raise
    # ActiveRecord::StatementInvalid for any other non-integer things.
    def quote_with_integer_enforcement(value, column = nil)
      if column && column.type == :integer && !value.respond_to?(:quoted_id)
        case value
          when String, ActiveSupport::Multibyte::Chars, nil, true, false
            # these already have branches for column.type == :integer (or don't
            # need one)
            quote_without_integer_enforcement(value, column)
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
        quote_without_integer_enforcement(value, column)
      end
    end
    alias_method_chain :quote, :integer_enforcement

    if Rails.version < '4'
      # Handle quoting properly for Infinity and NaN. This fix exists in Rails 4.0
      # and can be safely removed once we upgrade.
      #
      # This patch is covered by tests in spec/initializers/active_record_quoting_spec.rb
      def quote_with_infinity_and_nan(value, column = nil) #:nodoc:
        if value.kind_of?(Float)
          if value.infinite? && column && column.type == :datetime
            "'#{value.to_s.downcase}'"
          elsif value.infinite? || value.nan?
            "'#{value.to_s}'"
          else
            quote_without_infinity_and_nan(value, column)
          end
        else
          quote_without_infinity_and_nan(value, column)
        end
      end
      alias_method_chain :quote, :infinity_and_nan
    end
  end
end

if CANVAS_RAILS2

  module ActiveSupport
    HashWithIndifferentAccess = ::HashWithIndifferentAccess
  end

  # bug submitted to rails: https://rails.lighthouseapp.com/projects/8994/tickets/5802-activerecordassociationsassociationcollectionload_target-doesnt-respect-protected-attributes#ticket-5802-1
  # This fix has been merged into rails trunk and will be in the rails 3.1 release.
  class ActiveRecord::Associations::AssociationCollection
    def load_target
      if !@owner.new_record? || foreign_key_present
        begin
          if !loaded?
            if @target.is_a?(Array) && @target.any?
              @target = find_target.map do |f|
                i = @target.index(f)
                if i
                  @target.delete_at(i).tap do |t|
                    keys = ["id"] + t.changes.keys + (f.attribute_names - t.attribute_names)
                    f.attributes.except(*keys).each do |k,v|
                      t.write_attribute(k, v)
                    end
                  end
                else
                  f
                end
              end + @target
            else
              @target = find_target
            end
          end
        rescue ActiveRecord::RecordNotFound
          reset
        end
      end

      loaded if target
      target
    end
  end

  # Fix for has_many :through where the through and target reflections are the
  # same table (the through table needs to be aliased)
  # https://github.com/rails/rails/issues/669 (fixed in rails 3.1)
  ActiveRecord::Associations::HasManyThroughAssociation.module_eval do
    protected

    def aliased_through_table_name
      @reflection.table_name == @reflection.through_reflection.table_name ?
          ActiveRecord::Base.connection.quote_table_name(@reflection.through_reflection.table_name + '_join') :
          ActiveRecord::Base.connection.quote_table_name(@reflection.through_reflection.table_name)
    end

    def construct_conditions
      conditions = construct_quoted_owner_attributes(@reflection.through_reflection).map do |attr, value|
        "#{aliased_through_table_name}.#{attr} = #{value}"
      end
      conditions << sql_conditions if sql_conditions
      "(" + conditions.join(') AND (') + ")"
    end

    def construct_joins(custom_joins = nil)
      polymorphic_join = nil
      if @reflection.source_reflection.macro == :belongs_to
        reflection_primary_key = @reflection.klass.primary_key
        source_primary_key     = @reflection.source_reflection.primary_key_name
        if @reflection.options[:source_type]
          polymorphic_join = "AND %s.%s = %s" % [
            aliased_through_table_name, "#{@reflection.source_reflection.options[:foreign_type]}",
            @owner.class.quote_value(@reflection.options[:source_type])
          ]
        end
      else
        reflection_primary_key = @reflection.source_reflection.primary_key_name
        source_primary_key     = @reflection.through_reflection.klass.primary_key
        if @reflection.source_reflection.options[:as]
          polymorphic_join = "AND %s.%s = %s" % [
            @reflection.quoted_table_name, "#{@reflection.source_reflection.options[:as]}_type",
            @owner.class.quote_value(@reflection.through_reflection.klass.name)
          ]
        end
      end

      "INNER JOIN %s %s ON %s.%s = %s.%s %s #{@reflection.options[:joins]} #{custom_joins}" % [
        @reflection.through_reflection.quoted_table_name,
        aliased_through_table_name,
        @reflection.quoted_table_name, reflection_primary_key,
        aliased_through_table_name, source_primary_key,
        polymorphic_join
      ]
    end
  end

  # Patch for CVE-2013-0155
  # https://groups.google.com/d/topic/rubyonrails-security/c7jT-EeN9eI/discussion
  # Also fixes problem with nested conditions containing ?
  class ActiveRecord::Base
    class << self
      def sanitize_sql_hash_for_conditions(attrs, default_table_name = quoted_table_name, top_level = true)
        attrs = expand_hash_conditions_for_aggregates(attrs)

        # This is the one modified line
        raise(ActiveRecord::StatementInvalid, "non-top-level hash is empty") if !top_level && attrs.is_a?(Hash) && attrs.empty?

        nested_conditions = []
        conditions = attrs.map do |attr, value|
          table_name = default_table_name

          if not value.is_a?(Hash)
            attr = attr.to_s

            # Extract table name from qualified attribute names.
            if attr.include?('.') and top_level
              attr_table_name, attr = attr.split('.', 2)
              attr_table_name = connection.quote_table_name(attr_table_name)
            else
              attr_table_name = table_name
            end

            attribute_condition("#{attr_table_name}.#{connection.quote_column_name(attr)}", value)
          elsif top_level
            nested_conditions << sanitize_sql_hash_for_conditions(value, connection.quote_table_name(attr.to_s), false)
            nil
          else
            raise ActiveRecord::StatementInvalid
          end
        end.compact.join(' AND ').presence

        conditions = replace_bind_variables(conditions, expand_range_bind_variables(attrs.values)) if conditions
        [conditions, *nested_conditions].compact.join(' AND ')
      end
      alias_method :sanitize_sql_hash, :sanitize_sql_hash_for_conditions
    end
  end

  # ensure that the query cache is cleared on inserts, even if there's a db
  # error. this is fixed in rails 3.1. unfortunately we have to reproduce
  # whole method here and can't just alias it, since it calls super :(
  # https://github.com/rails/rails/commit/1f3d3eb49d16b62250c24e3374cc36de99b397b8
  if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
      remove_method :insert
      def insert_sql(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
        # Extract the table from the insert sql. Yuck.
        table = sql.split(" ", 4)[2].gsub('"', '')

        # Try an insert with 'returning id' if available (PG >= 8.2)
        if supports_insert_with_returning?
          pk, sequence_name = *pk_and_sequence_for(table) unless pk
          if pk
            id = select_value("#{sql} RETURNING #{quote_column_name(pk)}")
            return id
          end
        end

        # Otherwise, insert then grab last_insert_id.
        if insert_id = super
          insert_id
        else
          # If neither pk nor sequence name is given, look them up.
          unless pk || sequence_name
            pk, sequence_name = *pk_and_sequence_for(table)
          end

          # If a pk is given, fallback to default sequence name.
          # Don't fetch last insert id for a table without a pk.
          if pk && sequence_name ||= default_sequence_name(table, pk)
            last_insert_id(table, sequence_name)
          end
        end
      end
    end
  end

  # This change allows us to use whatever is in the latest tzinfo gem
  # (like the Moscow change to always be on daylight savings)
  # instead of the hard-coded list in ActiveSupport::TimeZone.zones_map
  #
  # Fixed in Rails 3
  ActiveSupport::TimeZone.class_eval do
    instance_variable_set '@zones', nil
    instance_variable_set '@zones_map', nil
    instance_variable_set '@us_zones', nil

    def self.zones_map
      @zones_map ||= begin
        zone_names = ActiveSupport::TimeZone::MAPPING.keys
        Hash[zone_names.map { |place| [place, create(place)] }]
      end
    end
  end

else
  ActiveSupport::Cache::Entry.class_eval do
    def value_with_untaint
      @value.untaint if @value
      value_without_untaint
    end
    alias_method_chain :value, :untaint
  end

end
