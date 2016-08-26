ActiveSupport::Cache::Entry.class_eval do
  def value_with_untaint
    @value.untaint if @value
    value_without_untaint
  end
  alias_method_chain :value, :untaint
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

if CANVAS_RAILS4_0
  # CVE-2016-6316
  ActionView::Helpers::TagHelper.module_eval do
    def tag_option(key, value, escape)
      value = value.join(" ") if value.is_a?(Array)
      value = ERB::Util.h(value) if escape
      %(#{key}="#{value.gsub(/"/, '&quot;'.freeze)}")
    end
  end
end