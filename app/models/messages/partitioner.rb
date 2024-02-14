# frozen_string_literal: true

module Messages
  class Partitioner
    cattr_accessor :logger

    PRECREATE_TABLES = 2
    KEEP_WEEKS = 52

    def self.process(prune: false)
      Shard.current.database_server.unguard do
        GuardRail.activate(:deploy) do
          log "*" * 80
          log "-" * 80

          partman = CanvasPartman::PartitionManager.create(Message)

          partman.ensure_partitions(PRECREATE_TABLES)

          if prune
            Shard.current.database_server.unguard do
              partman.prune_partitions(KEEP_WEEKS)
            end
          end

          log "Done. Bye!"
          log "*" * 80
          unless Rails.env.test?
            ActiveRecord::Base.connection_pool.disconnect!
          end
        end
      end
    end

    def self.prune
      process(prune: true)
    end

    def self.log(*args)
      logger&.info(*args)
    end

    def self.processed?
      partman = CanvasPartman::PartitionManager.create(Message)
      partman.partitions_created?(PRECREATE_TABLES - 1)
    end
  end
end
