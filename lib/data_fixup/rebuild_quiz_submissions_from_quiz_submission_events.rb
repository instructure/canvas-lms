module DataFixup::RebuildQuizSubmissionsFromQuizSubmissionEvents
  LOG_PREFIX = "RebuildingQuizSubmissions - ".freeze

  SQL_SEARCH_STRING = <<-SQL
    select
      distinct submissions.id
    from
      submissions
    inner join
      assignments
    on submissions.assignment_id = assignments.id
      and submissions.workflow_state <> 'deleted'
      and assignments.workflow_state <> 'deleted'
    inner join
      quizzes
    on quizzes.assignment_id = assignments.id
      and quizzes.workflow_state <> 'deleted'
    inner join
      users
    on submissions.user_id = users.id
      and users.workflow_state<>'deleted'
    -- inner join quiz_submission_events on submissions.quiz_submission_id = quiz_submission_events.quiz_submission_id
    left outer join
      quiz_submissions
    on quiz_submissions.id = submissions.quiz_submission_id
    where submissions.quiz_submission_id is not null
      and quiz_submissions.id is null;
  SQL

#                                                      QUERY PLAN
#----------------------------------------------------------------------------------------------------------------------
# HashAggregate  (cost=1198723.44..1204367.96 rows=564452 width=8)
#   ->  Hash Anti Join  (cost=602912.26..1197312.31 rows=564452 width=8)
#         Hash Cond: (submissions.quiz_submission_id = quiz_submissions.id)
#         ->  Hash Join  (cost=180180.13..751795.23 rows=586146 width=16)
#               Hash Cond: (submissions.assignment_id = assignments.id)
#               ->  Hash Join  (cost=86921.79..653308.39 rows=940774 width=24)
#                     Hash Cond: (submissions.user_id = users.id)
#                     ->  Seq Scan on submissions  (cost=0.00..522689.55 rows=2493768 width=32)
#                           Filter: ((quiz_submission_id IS NOT NULL) AND ((workflow_state)::text <> 'deleted'::text))
#                     ->  Hash  (cost=79605.84..79605.84 rows=585276 width=8)
#                           ->  Seq Scan on users  (cost=0.00..79605.84 rows=585276 width=8)
#                                 Filter: ((workflow_state)::text <> 'deleted'::text)
#               ->  Hash  (cost=92047.36..92047.36 rows=96879 width=16)
#                     ->  Hash Join  (cost=16292.59..92047.36 rows=96879 width=16)
#                           Hash Cond: (assignments.id = quizzes.assignment_id)
#                           ->  Seq Scan on assignments  (cost=0.00..68611.24 rows=449072 width=8)
#                                 Filter: ((workflow_state)::text <> 'deleted'::text)
#                           ->  Hash  (cost=14348.93..14348.93 rows=155493 width=8)
#                                 ->  Seq Scan on quizzes  (cost=0.00..14348.93 rows=155493 width=8)
#                                       Filter: (id IS NOT NULL)
#         ->  Hash  (cost=384640.39..384640.39 rows=2321739 width=8)
#               ->  Seq Scan on quiz_submissions  (cost=0.00..384640.39 rows=2321739 width=8)
#(22 rows)

  def self.run(submission_id)
    submission = Submission.find(submission_id)

    # Run build script
    quiz_submission = build_new_submission_from_quiz_submission_events(submission)

    # save the result
    quiz_submission.save_with_versioning!
  end

  def self.find_missing_submissions_on_current_shard
    response = ActiveRecord::Base.connection.execute(SQL_SEARCH_STRING)
    response.values.flatten
  end

  def self.find_and_run
    ids = Shackles.activate(:slave) do
      find_missing_submissions_on_current_shard
    end
    ids.map do |id|
      begin
        Rails.logger.info "#{id} data fix starting..."
        success = run(id)
      ensure
        if success
          Rails.logger.info "#{id} completed successfully"
        else
          Rails.logger.warn "#{id} failed"
        end
      end
    end
  end

  private
    def self.grade_with_new_submission_data(qs, finished_at, submission_data=nil)
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

    def self.build_new_submission_from_quiz_submission_events(submission)
      if submission.submission_type != "online_quiz"
        Rails.logger.warn LOG_PREFIX + "Skipping because this isn't a quiz!\tsubmission_id: #{submission.id}"
        return false
      end

      qs_id = submission.quiz_submission_id

      # Get QLA events
      events = Quizzes::QuizSubmissionEvent.where(quiz_submission_id: qs_id)

      # Check if there are any events in the QLA
      if events.size == 0
        Rails.logger.warn LOG_PREFIX + "Skipping because there are no QLA events\tsubmission_id: #{submission.id}"
        return false
      end

      # Check if there are multiple attempts in the QLA
      attempts = events.map(&:attempt).uniq
      if attempts.size != 1
        Rails.logger.info LOG_PREFIX + "You have many attempts for qs: #{qs_id}\tsub: #{submission.id}\tattempts: #{attempts}"
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
