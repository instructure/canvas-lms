class CreateInitialQuizSubmissionEventPartitions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    Quizzes::QuizSubmissionEventPartitioner.process
  end

  def down
    # We can't delete the partitions because we no longer know which partitions
    # we created in this first place at this stage; Time.now() which was used
    # in #up may not be in the same month #down() is called.
  end
end
