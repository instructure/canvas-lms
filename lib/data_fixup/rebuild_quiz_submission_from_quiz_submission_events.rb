module DataFixup::RebuildQuizSubmissionsFromQuizSubmissionEvents
  def self.run(submission_id)
    submission = Submission.find(submission_id)

    # Run build script
    quiz_submission = build_new_submission_from_quiz_sub_events(submission)

    # save the result
    quiz_submission.save_with_versioning!
  end

  private
    def grade_with_new_submission_data(qs, finished_at, submission_data=nil)
      qs.manually_scored = false
      tally = 0
      submission_data ||= qs.submission_data
      user_answers = []
      qs.questions_as_object.each do |q|
        user_answer = Quizzes::SubmissionGrader.score_question(q, submission_data)
        user_answers << user_answer
        tally += (user_answer[:points] || 0) if user_answer[:correct]
      end
      qs.score = tally
      qs.score = qs.quiz.points_possible if qs.quiz && qs.quiz.quiz_type == 'graded_survey'
      qs.submission_data = user_answers
      qs.workflow_state = "complete"
      user_answers.each do |answer|
        if answer[:correct] == "undefined" && !qs.quiz.survey?
          qs.workflow_state = 'pending_review'
        end
      end
      qs.score_before_regrade = nil
      qs.manually_unlocked = nil
      qs.finished_at = finished_at
      qs
    end

    def build_new_submission_from_quiz_sub_events(submission)
      if submission.submission_type != "online_quiz"
        $stderr.puts "Skipping because this isn't a quiz!\tsubmission_id: #{submission.id}"
        return false
      end

      qs_id = submission.quiz_submission_id

      # Get QLA events
      events = Quizzes::QuizSubmissionEvent.where(quiz_submission_id: qs_id)

      # Check if there are any events in the QLA
      if events.size == 0
        $stderr.puts "Skipping because there are no QLA events\tsubmission_id: #{submission.id}"
        return false
      end

      # Check if there are multiple attempts in the QLA
      attempts = events.map(&:attempt).uniq
      if attempts.size != 1
        $stderr.puts "Yikes!  You have many attempts for qs: #{qs_id}\tsub: #{submission.id}\tattempts: #{attempts}"
      end

      # Assume final attempt
      attempt = attempts.sort.last
      events.select!(&:attempt)

      times = events.map(&:created_at).sort

      aggregator = Quizzes::LogAuditing::EventAggregator.new
      submission_data_hash = aggregator.run(qs_id, attempt, submission.updated_at)

      # Put it all together
      qs = Quizzes::QuizSubmission.new
      # Set the associations
      qs.submission = submission
      qs.id = qs_id
      qs.quiz = submission.assignment.quiz
      qs.user = submission.user

      # This is sad, but I don't want to recreate all the attempts, nor do I
      # want to cause an error setting this to a non-concurrent number.
      qs.attempt = attempt

      # This is sad because assumptions
      qs.quiz_version = qs.versions.map {|v| v.model.quiz_version}.sort.last

      # Set reasonable timestamps
      qs.created_at = submission.created_at
      qs.started_at = times.first
      qs.finished_at = submission.submitted_at

      # Set internal data for grading
      qs.quiz_data = submission.assignment.quiz.quiz_data
      qs.submission_data = submission_data_hash
      qs.save!

      # grade the submission!
      grade_with_new_submission_data(qs, qs.finished_at, submission_data_hash)
    end
end
