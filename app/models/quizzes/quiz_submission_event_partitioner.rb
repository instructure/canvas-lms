class Quizzes::QuizSubmissionEventPartitioner < ActiveRecord::Base
  cattr_accessor :logger

  def self.process
    Shackles.activate(:deploy) do
      log '*' * 80
      log '-' * 80

      partman = CanvasPartman::PartitionManager.new(Quizzes::QuizSubmissionEvent)

      [ Time.now, 1.month.from_now ].each do |date|
        log "Looking for a table for partition #{date.strftime('%Y/%m')}..."

        if partman.partition_exists?(date)
          log "\tPartition table exists, nothing to do. [OK]"
        else
          log "\tPartition table does not exist, creating..."
          partition_table_name = partman.create_partition(date)
          log "\tPartition table created: '#{partition_table_name}'. [OK]"
        end
      end

      [ 5.months.ago(Time.now.beginning_of_month) ].each do |date|
        log "Looking for old partition table (#{date.strftime('%Y/%m')})..."

        if partman.partition_exists?(date)
          log "\tPartition table exists, dropping..."
          partman.drop_partition(date)
          log "\tPartition table dropped. [OK]"
        end
      end

      log 'Done. Bye!'
      log '*' * 80
    end
  end

  def self.log(*args)
    logger.info(*args) if logger
  end
end
