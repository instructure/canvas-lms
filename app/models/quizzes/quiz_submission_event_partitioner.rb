class Quizzes::QuizSubmissionEventPartitioner
  cattr_accessor :logger

  def self.process
    Shackles.activate(:deploy) do
      Quizzes::QuizSubmissionEvent.transaction do
        log '*' * 80
        log '-' * 80

        partman = CanvasPartman::PartitionManager.create(Quizzes::QuizSubmissionEvent)

        partman.ensure_partitions(Setting.get('quiz_events_partitions_precreate_months', 2).to_i)

        partman.prune_partitions(Setting.get("quiz_events_partitions_keep_months", 6).to_i)

        log 'Done. Bye!'
        log '*' * 80
      end
    end
  end

  def self.log(*args)
    logger.info(*args) if logger
  end
end
