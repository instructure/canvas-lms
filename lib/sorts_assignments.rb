#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

class SortsAssignments

  VALID_BUCKETS = [:past, :overdue, :undated, :ungraded, :unsubmitted, :upcoming, :future]
  AssignmentsSortedByDueDate = Struct.new(*VALID_BUCKETS)

  def self.by_due_date(opts)
    assignments = opts.fetch( :assignments )
    user = opts.fetch( :user )
    current_user = opts[:current_user] || opts.fetch( :user )
    session = opts.fetch( :session )
    submissions = opts.fetch( :submissions )
    upcoming_limit = opts[:upcoming_limit] || 1.week.from_now

    AssignmentsSortedByDueDate.new(
      past(assignments),
      overdue(assignments, user, session, submissions),
      undated(assignments),
      ungraded_for_user_and_session(assignments, user, current_user, session),
      unsubmitted_for_user_and_session(assignments, user, current_user, session),
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

  def self.unsubmitted_for_user_and_session(assignments, user, current_user, session)
    assignments ||= []
    assignments.select do |assignment|
      assignment.grants_right?(current_user, session, :grade) &&
        assignment.expects_submission? &&
        assignment.submission_for_student(user)[:id].blank?
    end
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

  def self.ungraded_for_user_and_session(assignments, user, current_user, session)
    assignments ||= []
    assignments.select do |assignment|
      assignment.grants_right?(current_user, session, :grade) &&
        assignment.expects_submission? &&
        Assignments::NeedsGradingCountQuery.new(assignment, user).count > 0
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

  def self.bucket_filter(given_scope, bucket, session, user, current_user, context, submissions_for_user)
    overridden_assignments = given_scope.map{|a| a.overridden_for(user)}

    observed_students = ObserverEnrollment.observed_students(context, user)
    user_for_sorting = if observed_students.count == 1
      observed_students.keys.first
    else
      user
    end

    sorted_assignments = self.by_due_date(
      :assignments => overridden_assignments,
      :user => user_for_sorting,
      :current_user => current_user,
      :session => session,
      :submissions => submissions_for_user
    )
    filtered_assignment_ids = sorted_assignments.send(bucket).map(&:id)
    given_scope.where(id: filtered_assignment_ids)
  end

  private
  def self.due_between?(assignment,start_time,end_time)
    assignment.due_at >= start_time && assignment.due_at <= end_time
  end

end
