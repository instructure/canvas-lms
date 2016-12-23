partman = CanvasPartman::PartitionManager.create(Quizzes::QuizSubmissionEvent)
partman.create_partition(Time.now, graceful: true)
