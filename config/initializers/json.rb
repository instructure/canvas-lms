String.class_eval do
  def to_json_with_html_safety(*args)
    to_json_without_html_safety(*args).gsub(/<|>/) { |m| m == '<' ? '\\u003C' : '\\u003E' }
  end
  alias_method_chain :to_json, :html_safety
end