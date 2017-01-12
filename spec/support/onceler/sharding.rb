module Onceler
  module Sharding
    def self.included(klass)
      klass.onceler_connections = ->(_) do
        next [] if Switchman::RSpecHelper.class_variable_get(:@@sharding_failed)
        shard1 = Switchman::RSpecHelper.class_variable_get(:@@shard1)
        shard2 = Switchman::RSpecHelper.class_variable_get(:@@shard2)
        # mirror logic of https://github.com/instructure/switchman/blob/61f2e9d/lib/switchman/r_spec_helper.rb#L94
        # also include the default shard (since we're replacing onceler_connections)
        shards = [Shard.default, shard2]
        shards << shard1 unless shard1.database_server == Shard.default.database_server
        shards.map { |shard| shard.activate { ActiveRecord::Base.connection } }
      end

      klass.before :record do
        sharding_failed = Switchman::RSpecHelper.class_variable_get(:@@sharding_failed)
        raise "Sharding did not set up correctly" if sharding_failed
        @shard1 = Shard.find(Switchman::RSpecHelper.class_variable_get(:@@shard1))
        @shard2 = Shard.find(Switchman::RSpecHelper.class_variable_get(:@@shard2))
      end
    end
  end
end



