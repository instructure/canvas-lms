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

ActiveSupport::Cache::Entry.class_eval do
  def value_with_untaint
    @value.untaint if @value
    value_without_untaint
  end
  alias_method_chain :value, :untaint
end

# Fix the behavior of association scope chaining off of a new record.
# Without this fix, rails3 will happily generate "WHERE fk IS NULL" queries such as:
#
# ContextModule.new.content_tags.not_deleted.count
# => SELECT COUNT(*) FROM "content_tags" WHERE "content_tags"."context_module_id" IS NULL AND (content_tags.workflow_state<>'deleted')
#
# (This is fixed in rails4, see https://github.com/rails/rails/commit/aae4f357b5dae389b91129258f9d6d3043e7631e)
if Rails.version < '4'
  ActiveRecord::Associations::CollectionAssociation.class_eval do
    def target_scope
      scope = super
      scope = scope.none if null_scope?
      scope
    end

    def null_scope?
      owner.new_record? && !foreign_key_present?
    end
  end
end

# Extend the query logger to add "SQL" back to the front, like it was in
# rails2, to make it easier to pull out those log lines for analysis.
ActiveRecord::LogSubscriber.class_eval do
  def sql_with_tag(event)
    name = event.payload[:name]
    if name != 'SCHEMA'
      event.payload[:name] = "SQL #{name}"
    end
    sql_without_tag(event)
  end
  alias_method_chain :sql, :tag
end
