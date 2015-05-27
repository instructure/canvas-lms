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
    quiz_submission.save_with_versioning! if quiz_submission
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
        Rails.logger.info LOG_PREFIX + "#{id} data fix starting..."
        success = run(id)
      rescue => e
        Rails.logger.warn LOG_PREFIX + "#{id} failed with error: #{e}"
      ensure
        if success
          Rails.logger.info LOG_PREFIX + "#{id} completed successfully"
        else
          Rails.logger.warn LOG_PREFIX + "#{id} failed"
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

    def self.pick_questions(qs, seen_question_ids)
      # Parsing all the deets from events can do it though
      quiz_group_picks = Hash.new {|h, k| h[k] = []}
      quiz_group_pick_counts = {}
      picked_questions = qs.quiz.stored_questions.select do |question|
        if question["entry_type"] == "quiz_group"
          group_name = question["id"]
          quiz_group_pick_counts[group_name] = question["pick_count"]
          matching_questions = question["questions"].select {|q| seen_question_ids.include? q["id"].to_s}
          matching_questions.each {|q| q["points_possible"] = question["question_points"]}
          quiz_group_picks[group_name] += matching_questions
          false
        else
          true
        end
      end

      quiz_group_picks.each do |k,v|
        qs.quiz.stored_questions.select {|q| q["id"] == k }.map do |question|
          question["questions"].shuffle.each do |q|
            break if v.count == quiz_group_pick_counts[k]
            q["points_possible"] = question["question_points"]
            v << q unless v.include? q
          end
        end
      end

      picked_questions += quiz_group_picks.values.flatten
      if qs.quiz.question_count != picked_questions.size
        Rails.logger.error LOG_PREFIX + "#{qs.id} doesn't match it's question count"
      end
      picked_questions
    end

    # Because we can't regenerate quiz data without getting a different set of questions,
    # we need to select the quiz_questions from the questions we can know the student has
    # seen.
    def self.aggregate_quiz_data_from_events(qs, events)
      question_events = events.select {|e| ["question_answered", "question_viewed", "question_flagged"].include?(e.event_type)}
      seen_question_ids = []
      question_events.each do |event|
        if event.event_type == "question_viewed"
          seen_question_ids << event.answers
        else
          seen_question_ids << event.answers.flatten.map {|h| h["quiz_question_id"]}
        end
      end
      seen_question_ids = seen_question_ids.flatten.uniq

      builder = Quizzes::QuizQuestionBuilder.new({
        shuffle_answers: qs.quiz.shuffle_answers
      })

      if seen_question_ids.count > 0
        picked_questions = pick_questions(qs, seen_question_ids)

        raw_data = builder.shuffle_quiz_data!(picked_questions)
        raw_data.each_with_index do |question, index|
          Quizzes::QuizQuestionBuilder.decorate_question_for_submission(question, index)
        end
      else
        submission.quiz_data = begin
          qs.quiz.stored_questions = nil
          builder.build_submission_questions(qs.quiz.id, qs.quiz.stored_questions)
        end
      end
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

      aggregator = Quizzes::LogAuditing::EventAggregator.new(submission.assignment.quiz)
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
      qs.quiz_data = aggregate_quiz_data_from_events(qs, events)

      # Set reasonable timestamps
      qs.created_at = submission.created_at
      qs.started_at = times.first
      qs.finished_at = submission.submitted_at

      qs.submission_data = submission_data_hash
      qs.save!

      # grade the submission!
      grade_with_new_submission_data(qs, qs.finished_at, submission_data_hash)
    end
end
