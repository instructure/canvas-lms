module Onceler
  class ConnectionEnumerator < Array
    def each
      super do |shard|
        shard.activate do
          yield ActiveRecord::Base.connection
        end
      end
    end
  end

  module Sharding
    def self.included(klass)
      klass.onceler_connections = ->(_) do
        shard1 = Switchman::RSpecHelper.class_variable_get(:@@shard1)
        shard2 = Switchman::RSpecHelper.class_variable_get(:@@shard2)
        # mirror logic of https://github.com/instructure/switchman/blob/61f2e9d/lib/switchman/r_spec_helper.rb#L94
        shards = [shard2]
        shards << shard1 unless shard1.database_server == Shard.default.database_server
        ConnectionEnumerator.new(shards)
      end

      klass.before :record do
        @shard1 = Shard.find(Switchman::RSpecHelper.class_variable_get(:@@shard1))
        @shard2 = Shard.find(Switchman::RSpecHelper.class_variable_get(:@@shard2))
      end
    end
  end
end



