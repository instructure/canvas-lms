# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

class SubmissionSearch
  ASC_SORT = "ASC"
  DESC_SORT = "DESC NULLS LAST"

  def initialize(assignment, searcher, session, options)
    @assignment = assignment
    @course = assignment.context
    @searcher = searcher
    @session = session
    @options = options
  end

  def search
    # use all_submissions so state: deleted can be found
    submission_search_scope = @assignment.all_submissions
    submission_search_scope = add_filters(submission_search_scope)
    add_order_bys(submission_search_scope)
  end

  def user_search_scope
    UserSearch
      .for_user_in_context(@options[:user_search], @assignment.context, @searcher, @session, @options)
      .except(:order)
  end

  def add_filters(search_scope)
    if @options[:states]
      search_scope = search_scope.where(workflow_state: @options[:states])
    end

    if @options[:section_ids].present?
      sections = @course.course_sections.where(id: @options[:section_ids])
      student_ids = @course.student_enrollments.where(course_section: sections).pluck(:user_id)
      search_scope = search_scope.where(user_id: student_ids)
    end

    if @options[:user_search]
      search_scope = search_scope
                     .where("submissions.user_id IN (SELECT id FROM (#{user_search_scope.to_sql}) AS user_search_ids)")
    end

    if @options[:user_id]
      # Since user_id requires an ID and not just a partial name, the user_search_scope is not needed and the 3 characters limit is not applied
      search_scope = search_scope.where(user_id: @options[:user_id])
    elsif @options[:user_representative_id]
      search_scope = search_scope.where(user_id: representative_id(@options[:user_representative_id]))
    end

    if @options[:anonymous_id].present?
      search_scope = search_scope.where(anonymous_id: @options[:anonymous_id])
    end

    if @options[:enrollment_types].present?
      search_scope = search_scope.where(user_id:
        @course.enrollments.select(:user_id).where(type: @options[:enrollment_types]))
    end
    if @options[:apply_gradebook_group_filter] && @course.filter_speed_grader_by_student_group?
      # namely used for SG2 filtering when the filter SG by group option is enabled
      group_selection = SpeedGrader::StudentGroupSelection.new(current_user: @searcher, course: @course)
      # return all submissions for the selected group
      search_scope = search_scope.where(user_id: group_selection.initial_group.user_ids) if group_selection.initial_group.present?
    end

    can_manage_or_view_grades = @course.grants_any_right?(@searcher, @session, :manage_grades, :view_all_grades)

    if @options[:posting_status].present? && can_manage_or_view_grades
      case @options[:posting_status]
      when :postable
        search_scope = search_scope.postable.unposted
      when :hideable
        search_scope = search_scope.posted
      else
        raise "posting_status '#{@options[:posting_status]}' is not supported"
      end
    end

    search_scope = if can_manage_or_view_grades || @course.participating_observers.map(&:id).include?(@searcher.id)
                     # a user with manage_grades, view_all_grades, or an observer can see other users' submissions
                     # TODO: may want to add a preloader for this
                     user_scope = filter_section_enrollment_states(allowed_users)
                     search_scope.where(user_id: user_scope.select(:id))
                   elsif @course.grants_right?(@searcher, @session, :read_grades)
                     # a user can see their own submission
                     search_scope.where(user_id: @searcher.id)
                   else
                     Submission.none # return nothing
                   end

    if @options[:scored_less_than]
      search_scope = search_scope.where(submissions: { score: ...@options[:scored_less_than] })
    end

    if @options[:scored_more_than]
      search_scope = search_scope.where("submissions.score > ?", @options[:scored_more_than])
    end

    if @options[:late].present?
      search_scope = @options[:late] ? search_scope.late : search_scope.not_late
    end

    if @options[:grading_status].present?
      case @options[:grading_status]
      when "needs_grading"
        search_scope = search_scope.where(Submission.needs_grading_conditions)
      when "excused"
        search_scope = search_scope.where(excused: true)
      when "needs_review"
        search_scope = search_scope.where(workflow_state: "pending_review")
      when "graded"
        search_scope = search_scope.where(workflow_state: "graded")
      end
    end

    search_scope
  end

  def add_order_bys(search_scope)
    order_bys = Array(@options[:order_by])
    order_bys.each do |order_field_direction|
      field = order_field_direction[:field]
      direction = (order_field_direction[:direction] == "descending") ? DESC_SORT : ASC_SORT
      search_scope =
        case field
        when "group_name"
          order_by_group_name(search_scope:, direction:)
        when "random"
          search_scope.order(Arel.sql("hashint8(submissions.id)"))
        when "submission_status"
          order_by_submission_status(search_scope:, direction:)
        when "needs_grading"
          order_by_needs_grading(search_scope:, direction:)
        when "username_first_last"
          order_by_username(search_scope:, direction:)
        when "username"
          order_by_username(search_scope:, direction:, sortable_name: true)
        when "score"
          search_scope.order(Arel.sql("submissions.score #{direction}"))
        when "submitted_at"
          search_scope.order(Arel.sql("submissions.submitted_at #{direction}"))
        when "test_student"
          order_by_test_student(search_scope:, direction:)
        else
          raise "submission search field '#{field}' is not supported"
        end
    end

    if @assignment.anonymize_students?
      search_scope.order(Arel.sql("#{Submission.anonymous_id_order_clause} ASC"))
    else
      search_scope.order(:user_id)
    end
  end

  private

  def order_by_group_name(search_scope:, direction:)
    return search_scope unless @assignment.has_group_category? && @assignment.group_category.deleted_at.nil?

    ComputedSubmissionColumnBuilder.add_group_name_column(search_scope, @assignment) => { scope:, column: group_name_column }
    scope.order(Arel.sql("#{group_name_column} #{direction}"))
  end

  def order_by_needs_grading(search_scope:, direction:)
    ComputedSubmissionColumnBuilder.add_needs_grading_column(search_scope, @searcher) => { scope:, column: needs_grading_column }
    # students needing grading come first when sorting ascending, last when sorting descending
    direction = reverse_direction(direction)
    scope.order(Arel.sql("#{needs_grading_column} #{direction}"))
  end

  def order_by_submission_status(search_scope:, direction:)
    priorities = { not_graded: 1, resubmitted: 2, not_submitted: 3, graded: 4, not_gradeable: 5, other: 6 }
    ComputedSubmissionColumnBuilder.add_submission_status_priority_column(
      search_scope,
      @searcher,
      priorities
    ) => { scope:, column: status_priority_column }
    scope.order(Arel.sql("#{status_priority_column} #{direction}"))
  end

  def order_by_username(search_scope:, direction:, sortable_name: false)
    return order_by_anonymous_username(search_scope:, direction:) if @assignment.anonymize_students?

    order_clause = sortable_name ? User.sortable_name_order_by_clause("users") : User.name_order_by_clause("users")
    search_scope.joins(:user).order(Arel.sql("#{order_clause} #{direction}"))
  end

  def order_by_anonymous_username(search_scope:, direction:)
    search_scope.order(Arel.sql("#{Submission.anonymous_id_order_clause} #{direction}"))
  end

  def order_by_test_student(search_scope:, direction:)
    test_student = @course.student_view_students.active.first
    return search_scope unless test_student

    # test students come first when sorting ascending, last when sorting descending
    direction = reverse_direction(direction)
    search_scope.order(Arel.sql("submissions.user_id = ? #{direction}", test_student.id))
  end

  def reverse_direction(direction)
    case direction
    when ASC_SORT
      DESC_SORT
    when DESC_SORT
      ASC_SORT
    else
      raise "Unknown sort direction: #{direction}"
    end
  end

  def allowed_users
    users = if @options[:apply_gradebook_enrollment_filters]
              @course.users_visible_to(@searcher, true, exclude_enrollment_state: excluded_enrollment_states_from_gradebook_settings)
            elsif @options[:include_concluded] || @options[:include_deactivated]
              @course.users_visible_to(@searcher, true, exclude_enrollment_state: excluded_enrollment_states_from_filters)
            else
              @course.users_visible_to(@searcher)
            end

    if @options[:representatives_only] && @assignment.grade_as_group?
      rep_ids = representatives.map { |rep, _members| rep.id }
      users = users.where(id: rep_ids)
    end

    users
  end

  def user_ids_by_enrollment_section_filters(section_ids)
    # Use base enrollments association to avoid default scope that excludes inactive enrollments
    @course.enrollments
           .where(course_section_id: section_ids)
           .where.not(workflow_state: excluded_enrollment_states_from_gradebook_settings)
           .select(:user_id)
  end

  def filter_section_enrollment_states(user_scope)
    return user_scope unless @options[:apply_gradebook_enrollment_filters]
    return user_scope unless @assignment.only_visible_to_overrides?
    return user_scope unless @assignment.active_assignment_overrides.where.not(set_type: AssignmentOverride::SET_TYPE_COURSE_SECTION).none?

    section_ids = @assignment.active_assignment_overrides.where(set_type: AssignmentOverride::SET_TYPE_COURSE_SECTION).pluck(:set_id)
    return User.none if section_ids.empty?

    enrollment_scope = user_ids_by_enrollment_section_filters(section_ids)

    user_scope.where(id: enrollment_scope)
  end

  def representative_id(user_id)
    user_id_str = user_id.to_s
    return user_id_str unless @assignment.grade_as_group?

    rep, = representatives.find do |(rep, members)|
      rep.id.to_s == user_id_str || members.any? { |member| member.id.to_s == user_id_str }
    end

    rep&.id&.to_s || user_id_str
  end

  def representatives
    includes = [:inactive]
    settings = @searcher.get_preference(:gradebook_settings, @course.global_id) || {}
    includes << :completed if settings["show_concluded_enrollments"] == "true"
    @representatives ||= @assignment.representatives(user: @searcher, includes:, ignore_student_visibility: true, include_others: true)
  end

  def excluded_enrollment_states_from_gradebook_settings
    settings = @searcher.get_preference(:gradebook_settings, @course.global_id) || {}
    excluded_enrollment_states(
      completed: settings["show_concluded_enrollments"] != "true",
      inactive: settings["show_inactive_enrollments"] != "true"
    )
  end

  def excluded_enrollment_states_from_filters
    excluded_enrollment_states(
      completed: !@options[:include_concluded],
      inactive: !@options[:include_deactivated]
    )
  end

  def excluded_enrollment_states(states)
    excluded_states = states.filter_map { |state, excluded| state if excluded }
    excluded_states << :rejected
  end
end
