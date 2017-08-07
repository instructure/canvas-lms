Types::TimeType = GraphQL::ScalarType.define do
  name "Time"
  description "an ISO8601 formatted time string"

  coerce_input ->(time_str, _) { time_str }
  coerce_result ->(time, _) { time.iso8601 }
end
