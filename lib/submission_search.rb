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
    end

    if @options[:enrollment_types].present?
      search_scope = search_scope.where(user_id:
        @course.enrollments.select(:user_id).where(type: @options[:enrollment_types]))
    end

    search_scope = if @course.grants_any_right?(@searcher, @session, :manage_grades, :view_all_grades) || @course.participating_observers.map(&:id).include?(@searcher.id)
                     # a user with manage_grades, view_all_grades, or an observer can see other users' submissions
                     # TODO: may want to add a preloader for this
                     search_scope.where(user_id: allowed_users)
                   elsif @course.grants_right?(@searcher, @session, :read_grades)
                     # a user can see their own submission
                     search_scope.where(user_id: @searcher.id)
                   else
                     Submission.none # return nothing
                   end

    if @options[:scored_less_than]
      search_scope = search_scope.where("submissions.score < ?", @options[:scored_less_than])
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
      direction = (order_field_direction[:direction] == "descending") ? "DESC NULLS LAST" : "ASC"
      search_scope =
        case field
        when "username"
          order_clause = User.sortable_name_order_by_clause("users")
          search_scope.joins(:user).order(Arel.sql("#{order_clause} #{direction}"))
        when "score"
          search_scope.order(Arel.sql("submissions.score #{direction}"))
        when "submitted_at"
          search_scope.order(Arel.sql("submissions.submitted_at #{direction}"))
        else
          raise "submission search field '#{field}' is not supported"
        end
    end
    search_scope.order(:user_id)
  end

  private

  def allowed_users
    if @options[:apply_gradebook_enrollment_filters]
      @course.users_visible_to(@searcher, true, exclude_enrollment_state: excluded_enrollment_states_from_gradebook_settings)
    elsif @options[:include_concluded] || @options[:include_deactivated]
      @course.users_visible_to(@searcher, true, exclude_enrollment_state: excluded_enrollment_states_from_filters)
    else
      @course.users_visible_to(@searcher)
    end
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
