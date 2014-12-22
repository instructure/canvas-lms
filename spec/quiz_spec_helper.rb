partman = CanvasPartman::PartitionManager.new(Quizzes::QuizSubmissionEvent)
partman.create_partition(Time.now, graceful: true)