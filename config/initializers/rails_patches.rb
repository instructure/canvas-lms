module UntaintCacheEntries
  def value
    @value.untaint if @value
    super
  end
end
ActiveSupport::Cache::Entry.prepend(UntaintCacheEntries)

# Extend the query logger to add "SQL" back to the front, like it was in
# rails2, to make it easier to pull out those log lines for analysis.
module AddSQLToLogLines
  def sql(event)
    name = event.payload[:name]
    if name != 'SCHEMA'
      event.payload[:name] = "SQL #{name}"
    end
    super
  end
end
ActiveRecord::LogSubscriber.prepend(AddSQLToLogLines)
