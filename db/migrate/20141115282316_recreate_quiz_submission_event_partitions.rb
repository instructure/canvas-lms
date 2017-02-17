class RecreateQuizSubmissionEventPartitions < ActiveRecord::Migration[4.2]
  tag :predeploy
  BAD_PARTITIONS = [
    Time.new(2014, 11),
    Time.new(2014, 12),
    Time.new(2015, 1)
  ]

  def up
    partman = CanvasPartman::PartitionManager.create(Quizzes::QuizSubmissionEvent)

    # This is a continuation of the manual fix for the first two partitions
    # documented in:
    #
    #   20141115100802_drop_broken_quiz_submission_event_partitions.rb
    #
    # In this migration, we re-create those partitions.
    BAD_PARTITIONS.each do |date|
      partman.create_partition(date) unless partman.partition_exists?(date)
    end
  end

  def down
    partman = CanvasPartman::PartitionManager.create(Quizzes::QuizSubmissionEvent)

    BAD_PARTITIONS.each do |date|
      partman.drop_partition(date) if partman.partition_exists?(date)
    end
  end
end
