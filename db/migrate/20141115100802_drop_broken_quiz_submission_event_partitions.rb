class DropBrokenQuizSubmissionEventPartitions < ActiveRecord::Migration[4.2]
  tag :predeploy
  BAD_PARTITIONS = [
    Time.new(2014, 11),
    Time.new(2014, 12),
    Time.new(2015, 1)
  ]

  def up
    partman = CanvasPartman::PartitionManager.create(Quizzes::QuizSubmissionEvent)

    # This is a manual fix needed for the very first two partitions created
    # before canvas-partman supported real migrations for managing partition
    # schemas.
    #
    # We have to manually drop them now and recreate them in a later migration
    # using the partition migrations.
    #
    # See also:
    #   - 20141109202906_create_initial_quiz_submission_event_partitions.rb
    #   - 20141115282316_recreate_quiz_submission_event_partitions.rb
    BAD_PARTITIONS.each do |date|
      partman.drop_partition(date) if partman.partition_exists?(date)
    end
  end

  def down
  end
end
