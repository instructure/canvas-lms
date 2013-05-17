class SortsAssignments

  AssignmentsSortedByDueDate = Struct.new(
    :past,
    :overdue,
    :undated,
    :ungraded,
    :upcoming,
    :future
  )

  def self.by_due_date(opts)
    assignments = opts.fetch( :assignments )
    user = opts.fetch( :user )
    session = opts.fetch( :session )
    submissions = opts.fetch( :submissions )
    upcoming_limit = opts[:upcoming_limit] || 1.week.from_now

    AssignmentsSortedByDueDate.new(
      past(assignments),
      overdue(assignments, user, session, submissions),
      undated(assignments),
      ungraded_for_user_and_session(assignments, user, session),
      upcoming(assignments, upcoming_limit),
      future(assignments)
    )
  end

  def self.past(assignments)
    assignments ||= []
    dated(assignments).select{ |assignment| assignment.due_at < Time.now }
  end

  def self.dated(assignments)
    assignments ||= []
    assignments.reject{ |assignment| assignment.due_at == nil }
  end

  def self.undated(assignments)
    assignments ||= []
    assignments.select{ |assignment| assignment.due_at == nil }
  end

  def self.upcoming(assignments, limit=1.week.from_now)
    assignments ||= []
    dated(assignments).select{ |a| due_between?(a,Time.now,limit) }
  end

  def self.future(assignments)
    assignments - past(assignments)
  end

  def self.up_to(assignments, time)
    dated(assignments).select{ |assignment| assignment.due_at < time }
  end

  def self.down_to(assignments, time)
    dated(assignments).select{ |assignment| assignment.due_at > time }
  end

  def self.ungraded_for_user_and_session(assignments,user,session)
    assignments ||= []
    assignments.select do |assignment|
      assignment.grants_right?(user, session, :grade) &&
        assignment.expects_submission? &&
        assignment.needs_grading_count_for_user(user) > 0
    end
  end

  def self.without_graded_submission(assignments, submissions)
    assignments ||= []; submissions ||= [];
    submissions_by_assignment = submissions.inject({}) do |memo, sub|
      memo[sub.assignment_id] = sub
      memo
    end
    assignments.select do |assignment|
      match = submissions_by_assignment[assignment.id]
      !match || match.without_graded_submission?
    end
  end

  def self.user_allowed_to_submit(assignments, user, session)
    assignments ||= []
    assignments.select do |assignment|
      assignment.expects_submission? && assignment.grants_right?(user, session, :submit)
    end
  end

  def self.overdue(assignments, user, session, submissions)
    submissions ||= []
    assignments = past(assignments)
    user_allowed_to_submit(assignments, user, session) &
      without_graded_submission(assignments, submissions)
  end

  private
  def self.due_between?(assignment,start_time,end_time)
    assignment.due_at >= start_time && assignment.due_at <= end_time
  end

end
