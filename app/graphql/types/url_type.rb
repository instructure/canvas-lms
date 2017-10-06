Types::UrlType = GraphQL::ScalarType.define do
  name "URL"

  coerce_input ->(url_str, _) { url_str }
  coerce_result ->(url, _) { url.to_s }
end
