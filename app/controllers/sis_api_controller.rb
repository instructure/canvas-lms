# @API SIS Integration
#
# Includes helpers for integration with SIS systems.
#
class SisApiController < ApplicationController
  include Api::V1::SisAssignment

  before_filter :require_view_all_grades, only: [:sis_assignments]
  before_filter :require_grade_export, only: [:sis_assignments]
  before_filter :require_published_course, only: [:sis_assignments]

  GRADE_EXPORT_NOT_ENABLED_ERROR = {
    error: 'A SIS integration is not configured and the bulk SIS Grade Export feature is not enabled'.freeze
  }.freeze

  COURSE_NOT_PUBLISHED_ERROR = {
    error: 'Grade data is not available for non-published courses'.freeze
  }.freeze

  # @API Retrieve assignments enabled for grade export to SIS
  # @beta
  #
  # Retrieve a list of published assignments flagged as "post_to_sis". Assignment group and section information are
  # included for convenience.
  #
  # Each section includes course information for the origin course and the cross-listed course, if applicable. The
  # `origin_course` is the course to which the section belongs or the course from which the section was cross-listed.
  # Generally, the `origin_course` should be preferred when performing integration work. The `xlist_course` is provided
  # for consistency and is only present when the section has been cross-listed.
  #
  # @argument account_id [Integer] The ID of the account to query.
  # @argument course_id [Integer] The ID of the course to query.
  #
  # @argument starts_before [DateTime, Optional] When searching on an account, restricts to courses that start before this date (if they have a start date)
  # @argument ends_after [DateTime, Optional] When searching on an account, restricts to courses that end after this date (if they have an end date)
  #
  # @example_response
  #   [
  #     {
  #       "id": 4,
  #       "course_id": 6,
  #       "name": "Assignment Title",
  #       "description": "Assignment Description",
  #       "due_at": "2015-01-01T17:00:00Z",
  #       "points_possible": 100,
  #       "integration_id": "IA-100",
  #       "integration_data": {
  #         "other_data": "values"
  #       },
  #       "assignment_group": {
  #         "id": 12,
  #         "name": "Assignments Group"
  #       }
  #       "sections": [
  #         {
  #           "id": 27,
  #           "name": "Section C2-S16",
  #           "sis_id": "C2-S16",
  #           "integration_id": "S-16",
  #           "origin_course": {
  #             "id": 2,
  #             "sis_id": "C2",
  #             "integration_id": "I-2"
  #           },
  #           "xlist_course": {
  #             "id": 6,
  #             "sis_id": "C6",
  #             "integration_id": "I-6"
  #           }
  #         },
  #
  #         ...
  #
  #       ]
  #     },
  #
  #     ...
  #
  #   ]
  #
  def sis_assignments
    render json: sis_assignments_json(paginated_assignments)
  end

  private

  def context
    if params[:account_id]
      Account.find(params[:account_id])
    elsif params[:course_id]
      Course.find(params[:course_id])
    else
      fail ActiveRecord::RecordNotFound, 'unknown context type'
    end
  end

  def published_course_ids
    if context.is_a?(Account)
      course_scope = Course.published.where(account_id: [context.id] + Account.sub_account_ids_recursive(context.id))
      if starts_before = CanvasTime.try_parse(params[:starts_before])
        course_scope = course_scope.where("
        (courses.start_at IS NULL AND enrollment_terms.start_at IS NULL)
        OR courses.start_at < ? OR enrollment_terms.start_at < ?", starts_before, starts_before)
      end
      if ends_after = CanvasTime.try_parse(params[:ends_after])
        course_scope = course_scope.where("
        (courses.conclude_at IS NULL AND enrollment_terms.end_at IS NULL)
        OR courses.conclude_at > ? OR enrollment_terms.end_at > ?", ends_after, ends_after)
      end

      if starts_before || ends_after
        course_scope = course_scope.joins(:enrollment_term)
      end
      course_scope
    elsif context.is_a?(Course)
      [context.id]
    end
  end

  def published_assignments
    Assignment.published.where(
      post_to_sis: true,
      context_type: 'Course',
      context_id: published_course_ids
    ).preload(assignment_group: [], context: { course_sections: [:nonxlist_course] })
  end

  def paginated_assignments
    Api.paginate(
      published_assignments.order(:context_id, :id),
      self,
      polymorphic_url([:sis, context, :assignments])
    )
  end

  def sis_grade_export_enabled?
    Assignment.sis_grade_export_enabled?(context)
  end

  def require_view_all_grades
    authorized_action(context, @current_user, :view_all_grades)
  end

  def require_grade_export
    render json: GRADE_EXPORT_NOT_ENABLED_ERROR, status: :bad_request unless sis_grade_export_enabled?
  end

  def require_published_course
    render json: COURSE_NOT_PUBLISHED_ERROR, status: :bad_request if context.is_a?(Course) && !context.published?
  end
end
