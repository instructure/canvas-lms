module Messages
  class Partitioner
    cattr_accessor :logger

    def self.precreate_tables
      Setting.get('messages_precreate_tables', 2).to_i
    end

    def self.process
      Shackles.activate(:deploy) do
        log '*' * 80
        log '-' * 80

        partman = CanvasPartman::PartitionManager.create(Message)

        partman.ensure_partitions(precreate_tables)

        partman.prune_partitions(Setting.get("messages_partitions_keep_weeks", 52).to_i)

        log 'Done. Bye!'
        log '*' * 80
        ActiveRecord::Base.connection_pool.current_pool.disconnect! unless Rails.env.test?
      end
    end

    def self.log(*args)
      logger.info(*args) if logger
    end
  end
end
