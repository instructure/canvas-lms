# frozen_string_literal: true

module Messages
  class Partitioner
    cattr_accessor :logger

    def self.precreate_tables
      Setting.get("messages_precreate_tables", 2).to_i
    end

    def self.process
      Shard.current.database_server.unguard do
        GuardRail.activate(:deploy) do
          log "*" * 80
          log "-" * 80

          partman = CanvasPartman::PartitionManager.create(Message)

          partman.ensure_partitions(precreate_tables)

          Shard.current.database_server.unguard { partman.prune_partitions(Setting.get("messages_partitions_keep_weeks", 52).to_i) }

          log "Done. Bye!"
          log "*" * 80
          unless Rails.env.test?
            ActiveRecord::Base.connection_pool.disconnect!
          end
        end
      end
    end

    def self.log(*args)
      logger&.info(*args)
    end

    def self.processed?
      partman = CanvasPartman::PartitionManager.create(Message)
      partman.partitions_created?(precreate_tables - 1)
    end
  end
end
