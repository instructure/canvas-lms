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
