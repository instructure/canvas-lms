require File.expand_path(File.dirname(__FILE__) +
                         '/../app/models/varied_due_date.rb')
class SortsAssignments

  AssignmentsSortedByVariedDueDate = Struct.new(
    :past,
    :overdue,
    :undated,
    :ungraded,
    :upcoming,
    :future
  )

  VDDAssignment = Struct.new(:id,:due_at)

  def self.by_varied_due_date(opts)
    assignments = opts[:assignments]
    user = opts[:user]
    session = opts[:session]
    submissions = opts[:submissons]
    upcoming_limit = opts[:upcoming_limit] || 1.week.from_now

    vdd_assignments = vdd_map(assignments, user)
    past_assignments = past(vdd_assignments)
    undated_assignments = undated(vdd_assignments)
    ungraded_assignments = ungraded_for_user_and_session(assignments, user, session)
    upcoming_assignments = upcoming(vdd_assignments, upcoming_limit)
    future_assignments = future(vdd_assignments)
    overdue_assignments = overdue(assignments, user, session, submissions)

    AssignmentsSortedByVariedDueDate.new(
      select_originals(assignments, past_assignments),
      select_originals(assignments, overdue_assignments),
      select_originals(assignments, undated_assignments),
      ungraded_assignments,
      select_originals(assignments, upcoming_assignments),
      select_originals(assignments, future_assignments)
    )
  end

  def self.vdd_map(assignments, user)
    assignments ||= []
    assignments.map do |assignment|
      VDDAssignment.new(assignment.id, VariedDueDate.due_at_for?(assignment, user))
    end
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

  def self.select_originals(original, vdd_map)
    vdd_map_keys = vdd_map.map{ |assignment| assignment.id }
    original.select { |assignment| vdd_map_keys.include?(assignment.id) }
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
