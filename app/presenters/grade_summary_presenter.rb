class GradeSummaryPresenter

  attr_reader :groups_assignments

  def initialize(context, current_user, id_param)
    @context = context
    @current_user = current_user
    @id_param = id_param
    @groups_assignments = []
  end

  def user_has_elevated_permissions?
    (@context.grants_right?(@current_user, nil, :manage_grades) || @context.grants_right?(@current_user, nil, :view_all_grades))
  end

  def user_needs_redirection?
    user_has_elevated_permissions? && !@id_param
  end

  def student_is_user?
    student == @current_user
  end

  def multiple_observed_students?
    observed_students && observed_students.keys.length > 1
  end

  def has_courses_with_grades?
    courses_with_grades && courses_with_grades.length > 1
  end

  def editable?
    student_is_user? && !no_calculations?
  end

  def turnitin_enabled?
    @context.turnitin_enabled? && assignments.any?(&:turnitin_enabled)
  end

  def observed_students
    @observed_students ||= ObserverEnrollment.observed_students(@context, @current_user)
  end

  def observed_student
    # be consistent about which student we return by default
    (observed_students.to_a.sort_by {|e| e[0].sortable_name}.first)[1].first
  end

  def linkable_observed_students
    observed_students.keys.select{ |student| observed_students[student].all? { |e| e.grants_right?(@current_user, nil, :read_grades) } }
  end

  def selectable_courses
    courses_with_grades.select do |course|
      student_enrollment = course.all_student_enrollments.find_by_user_id(student)
      student_enrollment.grants_right?(@current_user, nil, :read_grades)
    end
  end

  def student_enrollment
    @student_enrollment ||= begin
      if @id_param # always use id if given
        user_id = Shard.relative_id_for(@id_param, @context.shard)
        @context.all_student_enrollments.find_by_user_id(user_id)
      elsif observed_students.present? # otherwise try to find an observed student
        observed_student
      else # or just fall back to @current_user
        @context.all_student_enrollments.find_by_user_id(@current_user)
      end
    end
  end

  def student
    @student ||= (student_enrollment && student_enrollment.user)
  end

  def student_name
    student ? student.name : nil
  end

  def student_id
    student ? student.id : nil
  end

  def groups
    @groups ||= @context.assignment_groups.
      active.includes(:active_assignments => :assignment_overrides).all
  end

  def assignments
    @assignments ||= begin
      group_index = groups.index_by(&:id)

      groups.flat_map(&:active_assignments).select { |a|
        a.submission_types != 'not_graded'
      }.map { |a|
        # prevent extra loads
        a.context = @context
        a.assignment_group = group_index[a.assignment_group_id]

        a.overridden_for(student)
      }.sort
    end
  end

  def submissions
    @submissions ||= begin
      ss = @context.submissions
      .except(:includes)
      .includes(:visible_submission_comments,
                {:rubric_assessments => [:rubric, :rubric_association]},
                :content_participations)
      .find_all_by_user_id(student)

      assignments_index = assignments.index_by(&:id)

      # preload submission comment stuff
      comments = ss.map { |s|
        s.assignment = assignments_index[s.assignment_id]

        s.visible_submission_comments.map { |c|
          c.submission = s
          c
        }
      }.flatten
      SubmissionComment.preload_attachments comments

      ss
    end
  end

  def submission_counts
    @submission_counts ||= @context.assignments.active
      .joins(:submissions)
      .group("assignments.id")
      .count("submissions.id")
  end

  def assignment_stats
    @stats ||= @context.active_assignments
    .joins(:submissions)
    .group("assignments.id")
    .select("assignments.id, max(score), min(score), avg(score)")
    .index_by(&:id)
  end

  def assignment_presenters
    submission_index = submissions.index_by(&:assignment_id)
    assignments.map{ |a|
      GradeSummaryAssignmentPresenter.new(self, @current_user, a, submission_index[a.id])
    }
  end

  def has_muted_assignments?
    assignments.any?(&:muted?)
  end

  def courses_with_grades
    @courses_with_grades ||= begin
      if student_is_user?
        student.courses_with_grades
      else
        nil
      end
    end
  end

  def unread_submission_ids
    @unread_submission_ids ||= begin
      if student_is_user?
        # remember unread submissions and then mark all as read
        subs = submissions.select{ |s| s.unread?(@current_user) }
        subs.each{ |s| s.change_read_state("read", @current_user) }
        subs.map(&:id)
      else
        []
      end
    end
  end

  def no_calculations?
    @groups_assignments.empty?
  end

  def total_weight
    @total_weight ||= begin
      if @context.group_weighting_scheme == "percent"
        groups.sum(&:group_weight)
      else
        0
      end
    end
  end

  def groups_assignments=(value)
    @groups_assignments = value
    assignments.concat(value)
  end
end
