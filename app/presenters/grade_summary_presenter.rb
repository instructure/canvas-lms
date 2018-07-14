#
# Copyright (C) 2013 - present Instructure, Inc.
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
#

class GradeSummaryPresenter

  attr_reader :groups_assignments, :assignment_order

  def initialize(context, current_user, id_param, assignment_order: :due_at)
    @context = context
    @current_user = current_user
    @id_param = id_param
    @groups_assignments = []
    @periods_assignments = []
    @assignment_order = assignment_order
  end

  def user_has_elevated_permissions?
    @context.grants_any_right?(@current_user, :manage_grades, :view_all_grades)
  end

  def user_needs_redirection?
    user_has_elevated_permissions? && !@id_param
  end

  def user_an_observer_of_student?
    observed_students.key? student
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
    unless defined?(@turnitin_enabled)
      @turnitin_enabled = @context.turnitin_enabled? && assignments.any?(&:turnitin_enabled)
    end
    @turnitin_enabled
  end

  def vericite_enabled?
    unless defined?(@vericite_enabled)
      @vericite_enabled = @context.vericite_enabled? && assignments.any?(&:vericite_enabled)
    end
    @vericite_enabled
  end

  def observed_students
    @observed_students ||= ObserverEnrollment.observed_students(@context, @current_user)
  end

  def observed_student
    # be consistent about which student we return by default
    (observed_students.to_a.sort_by {|e| e[0].sortable_name}.first)[1].first
  end

  def linkable_observed_students
    observed_students.keys.select{ |student| observed_students[student].all? { |e| e.grants_right?(@current_user, :read_grades) } }
  end

  def student_enrollment_for(course, user)
    enrollment = course.all_student_enrollments.where(user_id: user)
    enrollment = enrollment.where.not(workflow_state: "inactive") unless user_has_elevated_permissions?
    enrollment.first
  end

  def student_enrollment
    @student_enrollment ||= begin
      if @id_param # always use id if given
        validate_id
        user_id = Shard.relative_id_for(@id_param, @context.shard, @context.shard)
        @context.shard.activate { student_enrollment_for(@context, user_id) }
      elsif observed_students.present? # otherwise try to find an observed student
        observed_student
      else # or just fall back to @current_user
        @context.shard.activate { student_enrollment_for(@context, @current_user) }
      end
    end
  end

  def students
    if multiple_observed_students?
      linkable_observed_students
    else
      Array.wrap(student)
    end
  end

  def validate_id
    raise ActiveRecord::RecordNotFound if ( !@id_param.is_a?(User) && (@id_param.to_s =~ Api::ID_REGEX).nil? )
    true
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
    all_groups
  end

  def assignments
    @assignments ||= begin
      visible_assignments = assignments_visible_to_student
      overridden_assignments = assignments_overridden_for_student(visible_assignments)
      sorted_assignments(overridden_assignments)
    end
  end

  def assignments_visible_to_student
    includes = [:assignment_overrides]
    includes << :assignment_group if @assignment_order == :assignment_group
    AssignmentGroup.
      visible_assignments(student, @context, all_groups, includes).
      where.not(submission_types: %w(not_graded wiki_page)).
      except(:order)
  end


  def assignments_overridden_for_student(assignments)
    group_index = all_groups.index_by(&:id)
    assignments.map do |assignment|
      assignment.context = @context
      assignment.assignment_group = group_index.fetch(assignment.assignment_group_id)
      assignment.overridden_for(student)
    end
  end

  def sorted_assignments(assignments)
    case @assignment_order
    when :due_at
      assignments.sort_by { |a| [a.due_at || CanvasSort::Last, Canvas::ICU.collation_key(a.title)] }
    when :title
      Canvas::ICU.collate_by(assignments, &:title)
    when :module
      sorted_by_modules(assignments)
    when :assignment_group
      assignments.sort_by { |a| [a.assignment_group.position, a.position] }
    end
  end

  def sort_options
    options = [[I18n.t('Due Date'), 'due_at'], [I18n.t('Title'), 'title']]
    if @context.active_record_types[:assignments] && assignments.uniq(&:assignment_group_id).length > 1
      options << [I18n.t('Assignment Group'), 'assignment_group']
    end
    options << [I18n.t('Module'), 'module'] if @context.active_record_types[:modules]
    Canvas::ICU.collate_by(options, &:first)
  end

  def submissions
    @submissions ||= begin
      ss = @context.submissions
      .preload(:visible_submission_comments,
                {:rubric_assessments => [:rubric, :rubric_association]},
                :content_participations)
      .where("assignments.workflow_state != 'deleted'")
      .where(user_id: student).to_a

      if vericite_enabled? || turnitin_enabled?
        ActiveRecord::Associations::Preloader.new.preload(ss, :originality_reports)
      end

      visible_assignment_ids = AssignmentStudentVisibility.visible_assignment_ids_for_user(student_id, @context.id)
      ss.select!{ |submission| visible_assignment_ids.include?(submission.assignment_id) }

      assignments_index = assignments.index_by(&:id)

      # preload submission comment stuff
      comments = ss.map { |s|
        assign = assignments_index[s.assignment_id]
        s.assignment = assign if assign.present?

        s.visible_submission_comments.map { |c|
          c.submission = s
          c
        }
      }.flatten
      SubmissionComment.preload_attachments comments

      ss
    end
  end

  def rubric_assessments
    assignment_presenters.flat_map(&:rubric_assessments)
  end

  def rubrics
    rubric_assessments.map(&:rubric).uniq
  end

  # Called by external classes that want to make sure we clear out
  # cached data. Most likely this is only the GradeCalculator
  def self.invalidate_cache(context)
    Rails.cache.delete(cache_key(context, 'assignment_stats'))
  end

  def assignment_stats
    @stats ||= ScoreStatistic.where(assignment: @context.assignments.active.except(:order)).index_by(&:assignment_id)
  end

  def assignment_presenters
    submission_index = submissions.index_by(&:assignment_id)
    assignments.map do |a|
      GradeSummaryAssignmentPresenter.new(self, @current_user, a, submission_index[a.id])
    end
  end

  def has_muted_assignments?
    assignments.any?(&:muted?)
  end

  def courses_with_grades
    @courses_with_grades ||= begin
      student.shard.activate do
        course_list = if student_is_user?
          Course.preload(:enrollment_term, :grading_period_groups).
            where(id: student.participating_student_current_and_concluded_course_ids).to_a
        elsif user_an_observer_of_student?
          observed_courses = []
          Shard.partition_by_shard(student.participating_student_current_and_concluded_course_ids) do |course_ids|
            observed_course_ids = ObserverEnrollment.
              not_deleted.
              where(course_id: course_ids, user_id: @current_user, associated_user_id: student).
              pluck(:course_id)
            next unless observed_course_ids.any?
            observed_courses += Course.preload(:enrollment_term, :grading_period_groups).
              where(id: observed_course_ids).to_a
          end
          observed_courses
        else
          []
        end

        course_list.select { |c| c.grants_right?(student, :read) }
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
    @groups_assignments.empty? && @periods_assignments.empty?
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

  def periods_assignments=(value)
    @periods_assignments = value
    assignments.concat(value)
  end

  def grading_periods
    @all_grading_periods ||= GradingPeriod.for(@context).order(:start_date).to_a
  end

  private

  def all_groups
    @all_groups ||= @context.assignment_groups.active.to_a
  end

  def sorted_by_modules(assignments)
    Assignment.preload_context_module_tags(assignments, include_context_modules: true)
    assignments.sort do |a, b|
      a_tags = a.all_context_module_tags
      b_tags = b.all_context_module_tags
      # assignments without modules come after assignments with modules
      next -1 if a_tags.present? && b_tags.empty?
      next 1 if a_tags.empty? && b_tags.present?
      # if both assignments do not belong to a module, compare by
      # assignment title
      next a.title.downcase <=> b.title.downcase if a_tags.empty? && b_tags.empty?

      # if both assignments belong to modules, compare the module
      # position of the first module they each belong to
      compare_by_module_position(a_tags.first, b_tags.first)
    end
  end

  def compare_by_module_position(module_tag1, module_tag2)
    module_position_comparison =
      module_tag1.context_module.position <=> module_tag2.context_module.position
    # if module position above is the same, compare by assignment
    # position within the module
    if module_position_comparison.zero?
      module_tag1.position <=> module_tag2.position
    else
      module_position_comparison
    end
  end

  private_class_method

  def self.cache_key(context, method)
    ['grade_summary_presenter', context, method].cache_key
  end
end
