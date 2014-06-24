# Initialize CavasEventStream gem

Rails.configuration.to_prepare do
  EventStream.current_shard_lookup = -> { Shard.current }
end
