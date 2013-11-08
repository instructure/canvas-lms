class DueDateCacher
  def self.recompute(assignment)
    new([assignment]).send_later_if_production_enqueue_args(:recompute,
      :strand => "cached_due_date:calculator:#{assignment.context_type}:#{Shard.global_id_for(assignment.context_id)}")
  end

  def self.recompute_course(course, assignments = nil)
    assignments ||= Assignment.where(context_id: course, context_type: 'Course').pluck(:id)
    return if assignments.empty?
    new(assignments).send_later_if_production_enqueue_args(:recompute,
      :strand => "cached_due_date:calculator:Course:#{Shard.global_id_for(course)}")
  end

  def self.recompute_batch(assignments)
    new(assignments).send_later_if_production_enqueue_args(:recompute,
      :strand => "cached_due_date:calculator:batch:#{Shard.current.id}",
      :priority => Delayed::LOWER_PRIORITY)
  end

  # expects all assignments to be on the same shard
  def initialize(assignments)
    @assignments = assignments
    @shard = Shard.shard_for(assignments.first)
  end

  def shard
    @shard
  end

  def submissions
    Submission.where(:assignment_id => @assignments)
  end

  def recompute
    # in a transaction on the correct shard:
    shard.activate do
      Assignment.transaction do
        # create temporary table
        cast = Submission.connection.adapter_name == 'Mysql2' ? 'UNSIGNED INTEGER' : 'BOOL'
        Assignment.connection.execute("CREATE TEMPORARY TABLE calculated_due_ats AS (#{submissions.select([
          "submissions.id AS submission_id",
          "submissions.user_id",
          "submissions.assignment_id",
          "assignments.due_at",
          "CAST(#{Submission.sanitize(false)} AS #{cast}) AS overridden"
        ]).joins(:assignment).to_sql})")

        # create an ActiveRecord class around that temp table for the update_all
        scope = Class.new(ActiveRecord::Base) do
          set_table_name :calculated_due_ats
          set_primary_key :submission_id
        end

        # for each override, narrow to the affected subset of the table, and
        # apply
        AssignmentOverride.active.overriding_due_at.where(:assignment_id => @assignments).each do |override|
          override_scope(scope, override).update_all(
            :due_at => override.due_at,
            :overridden => true)
        end

        # copy the results back to the submission table
        submissions.
          joins("INNER JOIN calculated_due_ats ON calculated_due_ats.submission_id=submissions.id").
          update_all("cached_due_date=calculated_due_ats.due_at")

        # clean up
        temporary = "TEMPORARY " if Assignment.connection.adapter_name == 'Mysql2'
        Assignment.connection.execute("DROP #{temporary}TABLE calculated_due_ats")
      end
    end
  end

  def override_scope(scope, override)
    scope = scope.where(:assignment_id => override.assignment_id)

    # and the override's due_at is more lenient than any existing overridden
    # due_at
    if override.due_at
      scope = scope.where(
        "NOT overridden OR (due_at IS NOT NULL AND due_at<?)",
        override.due_at)
    end

    case override.set_type
    when 'ADHOC'
      # any student explicitly tagged by an adhoc override,
      scope.joins("INNER JOIN assignment_override_students ON assignment_override_students.user_id=calculated_due_ats.user_id").
        where(:assignment_override_students => {
          :assignment_override_id => override
        })
    when 'CourseSection'
      # any student in a section override's tagged section, or
      scope.joins("INNER JOIN enrollments ON enrollments.user_id=calculated_due_ats.user_id").
        where(:enrollments => {
          :workflow_state => 'active',
          :type => ['StudentEnrollment', 'StudentViewEnrollment'],
          :course_section_id => override.set_id
        })
    when 'Group'
      # any student in a group override's tagged group
      scope.joins("INNER JOIN group_memberships ON group_memberships.user_id=calculated_due_ats.user_id").
        where(:group_memberships => {
          :workflow_state => 'accepted',
          :group_id => override.set_id
        })
    end
  end
end
