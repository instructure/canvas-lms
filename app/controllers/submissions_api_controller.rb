#
# Copyright (C) 2011 - present Instructure, Inc.
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

# @API Submissions
#
# API for accessing and updating submissions for an assignment. The submission
# id in these URLs is the id of the student in the course, there is no separate
# submission id exposed in these APIs.
#
# All submission actions can be performed with either the course id, or the
# course section id. SIS ids can be used, prefixed by "sis_course_id:" or
# "sis_section_id:" as described in the API documentation on SIS IDs.
#
# @model Submission
#     {
#       "id": "Submission",
#       "description": "",
#       "properties": {
#         "assignment_id": {
#           "description": "The submission's assignment id",
#           "example": 23,
#           "type": "integer"
#         },
#         "assignment": {
#           "description": "The submission's assignment (see the assignments API) (optional)",
#           "example": "Assignment",
#           "type": "string"
#         },
#         "course": {
#           "description": "The submission's course (see the course API) (optional)",
#           "example": "Course",
#           "type": "string"
#         },
#         "attempt": {
#           "description": "This is the submission attempt number.",
#           "example": 1,
#           "type": "integer"
#         },
#         "body": {
#           "description": "The content of the submission, if it was submitted directly in a text field.",
#           "example": "There are three factors too...",
#           "type": "string"
#         },
#         "grade": {
#           "description": "The grade for the submission, translated into the assignment grading scheme (so a letter grade, for example).",
#           "example": "A-",
#           "type": "string"
#         },
#         "grade_matches_current_submission": {
#           "description": "A boolean flag which is false if the student has re-submitted since the submission was last graded.",
#           "example": true,
#           "type": "boolean"
#         },
#         "html_url": {
#           "description": "URL to the submission. This will require the user to log in.",
#           "example": "http://example.com/courses/255/assignments/543/submissions/134",
#           "type": "string"
#         },
#         "preview_url": {
#           "description": "URL to the submission preview. This will require the user to log in.",
#           "example": "http://example.com/courses/255/assignments/543/submissions/134?preview=1",
#           "type": "string"
#         },
#         "score": {
#           "description": "The raw score",
#           "example": 13.5,
#           "type": "number"
#         },
#         "submission_comments": {
#           "description": "Associated comments for a submission (optional)",
#           "type": "array",
#           "items": { "$ref": "SubmissionComment" }
#         },
#         "submission_type": {
#           "description": "The types of submission ex: ('online_text_entry'|'online_url'|'online_upload'|'media_recording')",
#           "example": "online_text_entry",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "online_text_entry",
#               "online_url",
#               "online_upload",
#               "media_recording"
#             ]
#           }
#         },
#         "submitted_at": {
#           "description": "The timestamp when the assignment was submitted",
#           "example": "2012-01-01T01:00:00Z",
#           "type": "datetime"
#         },
#         "url": {
#           "description": "The URL of the submission (for 'online_url' submissions).",
#           "type": "string"
#         },
#         "user_id": {
#           "description": "The id of the user who created the submission",
#           "example": 134,
#           "type": "integer"
#         },
#         "grader_id": {
#           "description": "The id of the user who graded the submission. This will be null for submissions that haven't been graded yet. It will be a positive number if a real user has graded the submission and a negative number if the submission was graded by a process (e.g. Quiz autograder and autograding LTI tools).  Specifically autograded quizzes set grader_id to the negative of the quiz id.  Submissions autograded by LTI tools set grader_id to the negative of the tool id.",
#           "example": 86,
#           "type": "integer"
#         },
#         "graded_at" : {
#           "example": "2012-01-02T03:05:34Z",
#           "type": "datetime"
#         },
#         "user": {
#           "description": "The submissions user (see user API) (optional)",
#           "example": "User",
#           "type": "string"
#         },
#         "late": {
#           "description": "Whether the submission was made after the applicable due date",
#           "example": false,
#           "type": "boolean"
#         },
#         "assignment_visible": {
#           "description": "Whether the assignment is visible to the user who submitted the assignment. Submissions where `assignment_visible` is false no longer count towards the student's grade and the assignment can no longer be accessed by the student. `assignment_visible` becomes false for submissions that do not have a grade and whose assignment is no longer assigned to the student's section.",
#           "example": true,
#           "type": "boolean"
#         },
#         "excused": {
#           "description": "Whether the assignment is excused.  Excused assignments have no impact on a user's grade.",
#           "example": true,
#           "type": "boolean"
#         },
#         "missing": {
#           "description": "Whether the assignment is missing.",
#           "example": true,
#           "type": "boolean"
#         },
#         "late_policy_status": {
#           "description": "The status of the submission in relation to the late policy. Can be late, missing, none, or null.",
#           "example": "missing",
#           "type": "string"
#         },
#         "points_deducted": {
#           "description": "The amount of points automatically deducted from the score by the missing/late policy for a late or missing assignment.",
#           "example": 12.3,
#           "type": "number"
#         },
#         "seconds_late": {
#           "description": "The amount of time, in seconds, that an submission is late by.",
#           "example": 300,
#           "type": "number"
#         },
#         "workflow_state": {
#           "description": "The current state of the submission",
#           "example": "submitted",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "graded",
#               "submitted",
#               "unsubmitted",
#               "pending_review"
#             ]
#           }
#         }
#       }
#     }
#
class SubmissionsApiController < ApplicationController
  before_action :get_course_from_section, :require_context, :require_user
  batch_jobs_in_actions :only => [:update], :batch => { :priority => Delayed::LOW_PRIORITY }

  include Api::V1::Progress
  include Api::V1::Submission

  # @API List assignment submissions
  #
  # A paginated list of all existing submissions for an assignment.
  #
  # @argument include[] [String, "submission_history"|"submission_comments"|"rubric_assessment"|"assignment"|"visibility"|"course"|"user"|"group"]
  #   Associations to include with the group.  "group" will add group_id and group_name.
  #
  # @argument grouped [Boolean]
  #   If this argument is true, the response will be grouped by student groups.
  #
  # @response_field assignment_id The unique identifier for the assignment.
  # @response_field user_id The id of the user who submitted the assignment.
  # @response_field grader_id The id of the user who graded the submission. This will be null for submissions that haven't been graded yet. It will be a positive number if a real user has graded the submission and a negative number if the submission was graded by a process (e.g. Quiz autograder and autograding LTI tools).  Specifically autograded quizzes set grader_id to the negative of the quiz id.  Submissions autograded by LTI tools set grader_id to the negative of the tool id.
  # @response_field canvadoc_document_id The id for the canvadoc document associated with this submission, if it was a file upload.
  # @response_field submitted_at The timestamp when the assignment was submitted, if an actual submission has been made.
  # @response_field score The raw score for the assignment submission.
  # @response_field attempt If multiple submissions have been made, this is the attempt number.
  # @response_field body The content of the submission, if it was submitted directly in a text field.
  # @response_field grade The grade for the submission, translated into the assignment grading scheme (so a letter grade, for example).
  # @response_field grade_matches_current_submission A boolean flag which is false if the student has re-submitted since the submission was last graded.
  # @response_field preview_url Link to the URL in canvas where the submission can be previewed. This will require the user to log in.
  # @response_field url If the submission was made as a URL.
  # @response_field late Whether the submission was made after the applicable due date.
  # @response_field assignment_visible Whether this assignment is visible to the user who submitted the assignment.
  # @response_field workflow_state The current status of the submission. Possible values: “submitted”, “unsubmitted”, “graded”, “pending_review”
  #
  # @returns [Submission]
  def index
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      @assignment = @context.assignments.active.find(params[:assignment_id])
      includes = Array.wrap(params[:include])

      student_ids = if value_to_boolean(params[:grouped])
                      # this provides one assignment object(and
                      # submission object within), per user group
                      @assignment.representatives(@current_user).map(&:id)
                    else
                      @context.apply_enrollment_visibility(@context.student_enrollments,
                                                           @current_user, section_ids).
                        pluck(:user_id)
                    end
      submissions = @assignment.submissions.where(user_id: student_ids).preload(:originality_reports)
      submissions = submissions.preload(:quiz_submission) if @assignment.quiz?

      json = if includes.include?("visibility")
        bulk_process_submissions_for_visibility(submissions, includes)
      else
        submissions = submissions.order(:user_id)

        submissions = submissions.preload(:group) if includes.include?("group")

        submissions = Api.paginate(submissions, self,
                                   polymorphic_url([:api_v1, @section || @context, @assignment, :submissions]))
        bulk_load_attachments_and_previews(submissions)

        submissions.map do |s|
          s.visible_to_user = true
          submission_json(s, @assignment, @current_user, session, @context, includes, params)
        end
      end

      render :json => json
    end
  end

  # @API List submissions for multiple assignments
  #
  # A paginated list of all existing submissions for a given set of students and assignments.
  #
  # @argument student_ids[] [String]
  #   List of student ids to return submissions for. If this argument is
  #   omitted, return submissions for the calling user. Students may only list
  #   their own submissions. Observers may only list those of associated
  #   students. The special id "all" will return submissions for all students
  #   in the course/section as appropriate.
  #
  # @argument assignment_ids[] [String]
  #   List of assignments to return submissions for. If none are given,
  #   submissions for all assignments are returned.
  #
  # @argument grouped [Boolean]
  #   If this argument is present, the response will be grouped by student,
  #   rather than a flat array of submissions.
  #
  # @argument post_to_sis [Boolean]
  #   If this argument is set to true, the response will only include
  #   submissions for assignments that have the post_to_sis flag set to true and
  #   user enrollments that were added through sis.
  #
  # @argument submitted_since [DateTime]
  #   If this argument is set, the response will only include submissions that
  #   were submitted after the specified date_time. This will exclude
  #   submissions that do not have a submitted_at which will exclude unsubmitted
  #   submissions.
  #   The value must be formatted as ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  #
  # @argument graded_since [DateTime]
  #   If this argument is set, the response will only include submissions that
  #   were graded after the specified date_time. This will exclude
  #   submissions that have not been graded.
  #   The value must be formatted as ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  #
  # @argument grading_period_id [Integer]
  #   The id of the grading period in which submissions are being requested
  #   (Requires grading periods to exist on the account)
  #
  # @argument workflow_state [String, "submitted"|"unsubmitted"|"graded"|"pending_review"]
  #   The current status of the submission
  #
  # @argument enrollment_state [String, "active"|"concluded"|]
  #   The current state of the enrollments. If omitted will include all
  #   enrollments that are not deleted.
  #
  # @argument state_based_on_date [Boolean]
  #   If omitted it is set to true. When set to false it will ignore the effective
  #   state of the student enrollments and use the workflow_state for the
  #   enrollments. The argument is ignored unless enrollment_state argument is
  #   also passed.
  #
  # @argument order [String, "id"|"graded_at"]
  #   The order submissions will be returned in.  Defaults to "id".  Doesn't
  #   affect results for "grouped" mode.
  #
  # @argument order_direction [String, "ascending"|"descending"]
  #   Determines whether ordered results are returned in ascending or descending
  #   order.  Defaults to "ascending".  Doesn't affect results for "grouped" mode.
  #
  # @argument include[] [String, "submission_history"|"submission_comments"|"rubric_assessment"|"assignment"|"total_scores"|"visibility"|"course"|"user"]
  #   Associations to include with the group. `total_scores` requires the
  #   `grouped` argument.
  #
  # @example_response
  #     # Without grouped:
  #
  #     [
  #       { "assignment_id": 100, grade: 5, "user_id": 1, ... },
  #       { "assignment_id": 101, grade: 6, "user_id": 2, ... }
  #
  #     # With grouped:
  #
  #     [
  #       {
  #         "user_id": 1,
  #         "submissions": [
  #           { "assignment_id": 100, grade: 5, ... },
  #           { "assignment_id": 101, grade: 6, ... }
  #         ]
  #       }
  #     ]
  def for_students
    if params[:student_ids].try(:include?, 'all')
      all = true
    else
      student_ids = map_user_ids(params[:student_ids] || []).map(&:to_i)
      student_ids << @current_user.id if student_ids.empty?
    end

    can_view_all = @context.grants_any_right?(@current_user, session, :manage_grades, :view_all_grades)
    if all && can_view_all
      # this is a scope, and will generate subqueries
      student_ids = @context.apply_enrollment_visibility(@context.all_student_enrollments, @current_user, section_ids).select(:user_id)
    elsif can_view_all
      visible_student_ids = @context.apply_enrollment_visibility(@context.all_student_enrollments, @current_user, section_ids).pluck(:user_id)
      inaccessible_students = student_ids - visible_student_ids
      unless inaccessible_students.empty?
        return render_unauthorized_action
      end
    else
      # can view observees
      allowed_student_ids = @context.observer_enrollments
        .where(:user_id => @current_user.id, :workflow_state => 'active')
        .where("associated_user_id IS NOT NULL")
        .pluck(:associated_user_id)

      # can view self?
      if @context.grants_right?(@current_user, session, :read_grades)
        allowed_student_ids << @current_user.id
      end
      return render_unauthorized_action if allowed_student_ids.empty?

      if all
        student_ids = allowed_student_ids
      else
        # if any student_ids exist that the current_user shouldn't have access to, return an error
        # (student looking at other students, observer looking at student out of their scope)
        inaccessible_students = student_ids - allowed_student_ids
        return render_unauthorized_action unless inaccessible_students.empty?
      end
    end

    if student_ids.is_a?(Array) && student_ids.length > Api.max_per_page
      return render json: { error: 'too many students' }, status: 400
    end

    if (enrollment_state = params[:enrollment_state].presence)
      enrollments = (@section || @context).all_student_enrollments
      state_based_on_date = params[:state_based_on_date] ? value_to_boolean(params[:state_based_on_date]) : true
      case [enrollment_state, state_based_on_date]
      when ['active', true]
        enrollments = enrollments.active_by_date
      when ['concluded', true]
        enrollments = enrollments.completed_by_date
      when ['active', false]
        enrollments = enrollments.where(workflow_state: 'active')
      when ['concluded', false]
        enrollments = enrollments.where(workflow_state: 'completed')
      else
        return render json: {error: 'invalid enrollment_state'}, status: :bad_request
      end
      student_ids = enrollments.where(user_id: student_ids).select(:user_id)
    end

    if value_to_boolean(params[:post_to_sis])
      if student_ids.is_a?(Array)
        student_ids = (@section || @context).all_student_enrollments.
          where(user_id: student_ids).where.not(sis_batch_id: nil).select(:user_id)
      else
        student_ids = student_ids.where.not(sis_batch_id: nil)
      end
    end

    includes = Array(params[:include])

    assignment_scope = @context.assignments.published
    assignment_scope = assignment_scope.where(post_to_sis: true) if value_to_boolean(params[:post_to_sis])
    requested_assignment_ids = Array(params[:assignment_ids]).map(&:to_i)
    if requested_assignment_ids.present?
      assignment_scope = assignment_scope.where(:id => requested_assignment_ids)
    end

    if params[:grading_period_id].present?
      assignments = GradingPeriod.active.find(params[:grading_period_id]).assignments(assignment_scope)
    else
      assignments = assignment_scope.to_a
    end

    if requested_assignment_ids.present? && (requested_assignment_ids - assignments.map(&:id)).present?
      return render json: { error: 'invalid assignment ids requested'}, status: :forbidden
    end

    assignment_visibilities = {}
    assignment_visibilities = AssignmentStudentVisibility.users_with_visibility_by_assignment(course_id: @context.id, user_id: student_ids, assignment_id: assignments.map(&:id))

    # unless teacher, filter assignments down to only assignments current user can see
    unless @context.grants_any_right?(@current_user, :read_as_admin, :manage_grades, :manage_assignments)
      assignments = assignments.select{ |a| (assignment_visibilities.fetch(a.id,[]) & student_ids).any?}
    end

    # preload with stuff already in memory
    assignments.each { |a| a.context = @context }
    assignments_hash = assignments.index_by(&:id)

    if params[:submitted_since].present?
      if params[:submitted_since] !~ Api::ISO8601_REGEX
        return render(json: {errors: {submitted_since: t('Invalid datetime for submitted_since')}}, status: 400)
      else
        submitted_since_date = Time.zone.parse(params[:submitted_since])
      end
    end

    if params[:graded_since].present?
      if params[:graded_since] !~ Api::ISO8601_REGEX
        return render(json: {errors: {graded_since: t('Invalid datetime for graded_since')}}, status: 400)
      else
        graded_since_date = Time.zone.parse(params[:graded_since])
      end
    end

    if params[:grouped].present?
      scope = (@section || @context).all_student_enrollments.
        preload(:root_account, :sis_pseudonym, :user => :pseudonyms).
        where(:user_id => student_ids)
      student_enrollments = Api.paginate(scope, self, polymorphic_url([:api_v1, @section || @context, :student_submissions]))

      submissions_scope = Submission.active.where(user_id: student_enrollments.map(&:user_id), assignment_id: assignments)
      submissions_scope = submissions_scope.where("submitted_at>?", submitted_since_date) if submitted_since_date
      submissions_scope = submissions_scope.where("graded_at>?", graded_since_date) if graded_since_date
      if params[:workflow_state].present?
        submissions_scope = submissions_scope.where(:workflow_state => params[:workflow_state])
      end
      submissions = submissions_scope.preload(:originality_reports, :quiz_submission).to_a
      bulk_load_attachments_and_previews(submissions)
      submissions_for_user = submissions.group_by(&:user_id)

      seen_users = Set.new
      result = []
      show_sis_info = context.grants_any_right?(@current_user, :read_sis, :manage_sis)
      student_enrollments.each do |enrollment|
        student = enrollment.user
        next if seen_users.include?(student.id)
        seen_users << student.id
        hash = { :user_id => student.id, :section_id => enrollment.course_section_id, :submissions => [] }

        pseudonym = SisPseudonym.for(student, enrollment)
        if pseudonym && show_sis_info
          hash[:integration_id] = pseudonym.integration_id
          hash[:sis_user_id] = pseudonym.sis_user_id
        end

        student_submissions = submissions_for_user[student.id] || []
        student_submissions = student_submissions.select{ |s|
          assignment_visibilities.fetch(s.assignment_id, []).include?(s.user_id) || can_view_all
        }

        if assignments.present?
          student_submissions.each do |submission|
            # we've already got all the assignments loaded, so bypass AR loading
            # here and just give the submission its assignment
            next unless (assignment = assignments_hash[submission.assignment_id])
            submission.assignment = assignment
            submission.user = student

            visible_assignments = assignment_visibilities.fetch(submission.user_id, [])
            submission.visible_to_user = visible_assignments.include? submission.assignment_id
            hash[:submissions] << submission_json(submission, submission.assignment, @current_user, session, @context, includes, params)
          end
        end
        if includes.include?('total_scores')
          hash[:computed_final_score] = enrollment.computed_final_score
          hash[:computed_current_score] = enrollment.computed_current_score

          if can_view_all
            hash[:unposted_final_score] = enrollment.unposted_final_score
            hash[:unposted_current_score] = enrollment.unposted_current_score
          end
        end
        result << hash
      end
    else
      order_by = params[:order] == "graded_at" ? "graded_at" : :id
      order_direction = params[:order_direction] == "descending" ? "desc nulls last" : "asc"
      order = "#{order_by} #{order_direction}"
      submissions = @context.submissions.except(:order).where(user_id: student_ids).order(order)
      submissions = submissions.where(:assignment_id => assignments)
      submissions = submissions.where(:workflow_state => params[:workflow_state]) if params[:workflow_state].present?
      submissions = submissions.where("submitted_at>?", submitted_since_date) if submitted_since_date
      submissions = submissions.where("graded_at>?", graded_since_date) if graded_since_date
      submissions = submissions.preload(:user, :originality_reports, :quiz_submission)

      # this will speed up pagination for large collections when order_direction is asc
      if order_by == 'graded_at' && order_direction == 'asc'
        submissions = BookmarkedCollection.wrap(Submission::GradedAtBookmarker, submissions)
      elsif order_by == :id && order_direction == 'asc'
        submissions = BookmarkedCollection.wrap(Submission::IdBookmarker, submissions)
      end

      submissions = Api.paginate(submissions, self, polymorphic_url([:api_v1, @section || @context, :student_submissions]))
      Submission.bulk_load_versioned_attachments(submissions)
      Version.preload_version_number(submissions)
      result = submissions.select{ |s|
        assignment_visibilities.fetch(s.assignment_id, []).include?(s.user_id) || can_view_all
      }.map { |s|
        s.assignment = assignments_hash[s.assignment_id]
        visible_assignments = assignment_visibilities.fetch(s.user_id, [])
        s.visible_to_user = visible_assignments.include? s.assignment_id
        submission_json(s, s.assignment, @current_user, session, @context, includes, params)
      }
    end

    render :json => result
  end

  # @API Get a single submission
  #
  # Get a single submission, based on user id.
  #
  # @argument include[] [String, "submission_history"|"submission_comments"|"rubric_assessment"|"visibility"|"course"|"user"]
  #   Associations to include with the group.
  def show
    @assignment = @context.assignments.active.find(params[:assignment_id])
    @user = get_user_considering_section(params[:user_id])
    @submission = @assignment.submission_for_student(@user)
    bulk_load_attachments_and_previews([@submission])

    if authorized_action(@submission, @current_user, :read)
      if @context.grants_any_right?(@current_user, :read_as_admin, :manage_grades, :manage_assignments) ||
           @submission.assignment_visible_to_user?(@current_user)
        includes = Array(params[:include])
        @submission.visible_to_user = includes.include?("visibility") ? @assignment.visible_to_user?(@submission.user) : true
        render :json => submission_json(@submission, @assignment, @current_user, session, @context, includes, params)
      else
        @unauthorized_message = t('#application.errors.submission_unauthorized', "You cannot access this submission.")
        return render_unauthorized_action
      end
    end
  end

  # @API Upload a file
  #
  # Upload a file to a submission.
  #
  # This API endpoint is the first step in uploading a file to a submission as a student.
  # See the {file:file_uploads.html File Upload Documentation} for details on the file upload workflow.
  #
  # The final step of the file upload workflow will return the attachment data,
  # including the new file id. The caller can then POST to submit the
  # +online_upload+ assignment with these file ids.
  #
  def create_file
    @assignment = @context.assignments.active.find(params[:assignment_id])
    @user = get_user_considering_section(params[:user_id])
    permission = @assignment.submission_types.include?("online_upload") ? :submit : :nothing
    # rationale for allowing other user ids at all: eventually, you'll be able
    # to use this api for uploading an attachment to a submission comment.
    # teachers will be able to do that for any submission they can grade, so
    # they need to be able to specify the target user.
    permission = :nothing if @user != @current_user
    if authorized_action(@assignment, @current_user, permission)
      api_attachment_preflight(
        @user, request,
        check_quota: false, # we don't check quota when uploading a file for assignment submission
        folder: @user.submissions_folder(@context), # organize attachment into the course submissions folder
        assignment: @assignment
      )
    end
  end

  # @model RubricAssessment
  #  {
  #     "id" : "RubricAssessment",
  #     "required": ["criterion_id"],
  #     "properties": {
  #       "criterion_id": {
  #         "description": "The ID of the quiz question.",
  #         "example": 1,
  #         "type": "integer",
  #         "format": "int64"
  #       },
  #     }
  #  }
  #
  #
  # @API Grade or comment on a submission
  #
  # Comment on and/or update the grading for a student's assignment submission.
  # If any submission or rubric_assessment arguments are provided, the user
  # must have permission to manage grades in the appropriate context (course or
  # section).
  #
  # @argument comment[text_comment] [String]
  #   Add a textual comment to the submission.
  #
  # @argument comment[group_comment] [Boolean]
  #   Whether or not this comment should be sent to the entire group (defaults
  #   to false). Ignored if this is not a group assignment or if no text_comment
  #   is provided.
  #
  # @argument comment[media_comment_id] [String]
  #   Add an audio/video comment to the submission. Media comments can be added
  #   via this API, however, note that there is not yet an API to generate or
  #   list existing media comments, so this functionality is currently of
  #   limited use.
  #
  # @argument comment[media_comment_type] [String, "audio"|"video"]
  #   The type of media comment being added.
  #
  # @argument comment[file_ids][] [Integer]
  #   Attach files to this comment that were previously uploaded using the
  #   Submission Comment API's files action
  #
  # @argument include[visibility] [String]
  #   Whether this assignment is visible to the owner of the submission
  #
  # @argument submission[posted_grade] [String]
  #   Assign a score to the submission, updating both the "score" and "grade"
  #   fields on the submission record. This parameter can be passed in a few
  #   different formats:
  #
  #   points:: A floating point or integral value, such as "13.5". The grade
  #     will be interpreted directly as the score of the assignment.
  #     Values above assignment.points_possible are allowed, for awarding
  #     extra credit.
  #   percentage:: A floating point value appended with a percent sign, such as
  #      "40%". The grade will be interpreted as a percentage score on the
  #      assignment, where 100% == assignment.points_possible. Values above 100%
  #      are allowed, for awarding extra credit.
  #   letter grade:: A letter grade, following the assignment's defined letter
  #      grading scheme. For example, "A-". The resulting score will be the high
  #      end of the defined range for the letter grade. For instance, if "B" is
  #      defined as 86% to 84%, a letter grade of "B" will be worth 86%. The
  #      letter grade will be rejected if the assignment does not have a defined
  #      letter grading scheme. For more fine-grained control of scores, pass in
  #      points or percentage rather than the letter grade.
  #   "pass/complete/fail/incomplete":: A string value of "pass" or "complete"
  #      will give a score of 100%. "fail" or "incomplete" will give a score of
  #      0.
  #
  #   Note that assignments with grading_type of "pass_fail" can only be
  #   assigned a score of 0 or assignment.points_possible, nothing inbetween. If
  #   a posted_grade in the "points" or "percentage" format is sent, the grade
  #   will only be accepted if the grade equals one of those two values.
  #
  # @argument submission[excuse] [Boolean]
  #   Sets the "excused" status of an assignment.
  #
  # @argument submission[late_policy_status] [String]
  #   Sets the late policy status to either "late", "missing", "none", or null.
  #
  # @argument submission[seconds_late_override] [Integer]
  #   Sets the seconds late if late policy status is "late"
  #
  # @argument rubric_assessment [RubricAssessment]
  #   Assign a rubric assessment to this assignment submission. The
  #   sub-parameters here depend on the rubric for the assignment. The general
  #   format is, for each row in the rubric:
  #
  #   The points awarded for this row.
  #     rubric_assessment[criterion_id][points]
  #
  #   Comments to add for this row.
  #     rubric_assessment[criterion_id][comments]
  #
  #
  #   For example, if the assignment rubric is (in JSON format):
  #     !!!javascript
  #     [
  #       {
  #         'id': 'crit1',
  #         'points': 10,
  #         'description': 'Criterion 1',
  #         'ratings':
  #         [
  #           { 'description': 'Good', 'points': 10 },
  #           { 'description': 'Poor', 'points': 3 }
  #         ]
  #       },
  #       {
  #         'id': 'crit2',
  #         'points': 5,
  #         'description': 'Criterion 2',
  #         'ratings':
  #         [
  #           { 'description': 'Complete', 'points': 5 },
  #           { 'description': 'Incomplete', 'points': 0 }
  #         ]
  #       }
  #     ]
  #
  #   Then a possible set of values for rubric_assessment would be:
  #       rubric_assessment[crit1][points]=3&rubric_assessment[crit2][points]=5&rubric_assessment[crit2][comments]=Well%20Done.
  def update
    @assignment = @context.assignments.active.find(params[:assignment_id])

    if params[:submission] && params[:submission][:posted_grade] && !params[:submission][:provisional] &&
        @assignment.moderated_grading && !@assignment.grades_published?
      render_unauthorized_action
      return
    end

    @user = get_user_considering_section(params[:user_id])

    @submission = @assignment.all_submissions.find_or_create_by!(user: @user)

    authorized = if params[:submission] || params[:rubric_assessment]
      authorized_action(@submission, @current_user, :grade)
    else
      authorized_action(@submission, @current_user, :comment)
    end

    if authorized
      submission = { grader: @current_user }
      if params[:submission].is_a?(ActionController::Parameters)
        submission[:grade] = params[:submission].delete(:posted_grade)
        submission[:excuse] = params[:submission].delete(:excuse)
        if params[:submission].key?(:late_policy_status)
          submission[:late_policy_status] = params[:submission].delete(:late_policy_status)
        end
        if params[:submission].key?(:seconds_late_override)
          submission[:seconds_late_override] = params[:submission].delete(:seconds_late_override)
        end
        submission[:provisional] = value_to_boolean(params[:submission][:provisional])
        submission[:final] = value_to_boolean(params[:submission][:final]) && @assignment.permits_moderation?(@current_user)
        if params[:submission][:submission_type] == 'basic_lti_launch' && (!@submission.has_submission? || @submission.submission_type == 'basic_lti_launch')
          submission[:submission_type] = params[:submission][:submission_type]
          submission[:url] = params[:submission][:url]
        end
      end
      if submission[:grade] || submission[:excuse]
        begin
          @submissions = @assignment.grade_student(@user, submission)
        rescue Assignment::GradeError => e
          logger.info "GRADES: grade_student failed because '#{e.message}'"
          return render json: { error: e.to_s }, status: 400
        end
        @submission = @submissions.first
      else
        @submission = @assignment.find_or_create_submission(@user) if @submission.new_record?
        @submissions ||= [@submission]
      end
      if submission.key?(:late_policy_status) || submission.key?(:seconds_late_override)
        @submission.late_policy_status = submission[:late_policy_status] if submission.key?(:late_policy_status)
        if @submission.late_policy_status == 'late' && submission[:seconds_late_override].present?
          @submission.seconds_late_override = submission[:seconds_late_override]
        end
        @submission.save!
      end

      assessment = params[:rubric_assessment]
      if assessment.is_a?(ActionController::Parameters) && @assignment.rubric_association
        if (assessment.keys & @assignment.rubric_association.rubric.criteria_object.map{|c| c.id.to_s}).empty?
          return render :json => {:message => "invalid rubric_assessment"}, :status => :bad_request
        end

        # prepend each key with "criterion_", which is required by the current
        # RubricAssociation#assess code.
        assessment.keys.each do |crit_name|
          assessment["criterion_#{crit_name}"] = assessment.delete(crit_name)
        end

        @rubric_assessment = @assignment.rubric_association.assess(
          assessor: @current_user,
          user: @user,
          artifact: @submission,
          assessment: assessment.merge(assessment_type: 'grading')
        )
      end

      comment = params[:comment]
      if comment.is_a?(ActionController::Parameters)
        admin_in_context = !@context_enrollment || @context_enrollment.admin?
        comment = {
          comment: comment[:text_comment],
          author: @current_user,
          hidden: @assignment.muted? && admin_in_context
        }.merge(
          comment.permit(:media_comment_id, :media_comment_type, :group_comment).to_unsafe_h
        ).with_indifferent_access
        comment[:provisional] = value_to_boolean(submission[:provisional])
        if (file_ids = params[:comment][:file_ids])
          attachments = Attachment.where(id: file_ids).to_a
          attachable = attachments.all? { |a|
            a.grants_right?(@current_user, :attach_to_submission_comment)
          }
          unless attachable
            render_unauthorized_action
            return
          end
          attachments.each { |a| a.ok_for_submission_comment = true }
          comment[:attachments] = attachments
        end
        @assignment.update_submission(@submission.user, comment)
      end
      # We need to reload because some of this stuff is getting set on the
      # submission without going through the model instance -- it'd be nice to
      # fix this at some point.
      @submission.reload
      bulk_load_attachments_and_previews([@submission])

      includes = %w(submission_comments)
      includes.concat(Array.wrap(params[:include]) & ['visibility'])
      includes << 'provisional_grades' if submission[:provisional]

      visiblity_included = includes.include?("visibility")
      if visiblity_included
        user_ids = @submissions.map(&:user_id)
        users_with_visibility = AssignmentStudentVisibility.where(course_id: @context, assignment_id: @assignment, user_id: user_ids).pluck(:user_id).to_set
      end
      json = submission_json(@submission, @assignment, @current_user, session, @context, includes, params)

      includes.delete("submission_comments")
      Version.preload_version_number(@submissions)
      json[:all_submissions] = @submissions.map do |submission|
        if visiblity_included
          submission.visible_to_user = users_with_visibility.include?(submission.user_id)
        end

        submission_json(submission, @assignment, @current_user, session, @context, includes, params)
      end
      render :json => json
    end
  end

  # @API List gradeable students
  #
  # A paginated list of students eligible to submit the assignment. The caller must have permission to view grades.
  #
  # Section-limited instructors will only see students in their own sections.
  #
  # returns [UserDisplay]
  def gradeable_students
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      @assignment = @context.assignments.active.find(params[:assignment_id])
      includes = Array(params[:include])

      # When mobile supports new anonymous we can remove the allow_new flag
      allow_new_anonymous_id = value_to_boolean(params[:allow_new_anonymous_id])
      can_view_student_names = allow_new_anonymous_id ? @assignment.can_view_student_names?(@current_user) : true

      student_scope = context.students_visible_to(@current_user, include: :inactive)
      submission_scope = @assignment.submissions.except(:preload).where(user_id: student_scope).
        order(can_view_student_names ? :user_id : :anonymous_id)
      submission_scope = submission_scope.preload(:user) if can_view_student_names
      if (include_pg = includes.include?('provisional_grades'))
        render_unauthorized_action and return unless @assignment.permits_moderation?(@current_user)
        submission_scope = submission_scope.preload(provisional_grades: :selection)
      end
      submissions = Api.paginate(submission_scope, self, api_v1_course_assignment_gradeable_students_url(@context, @assignment))
      render json: submissions.map { |submission|
        json = can_view_student_names ? user_display_json(submission.user, @context) : anonymous_user_display_json(submission.anonymous_id)
        if include_pg
          selection = submission.provisional_grades.find(&:selection)
          json.merge!(in_moderation_set: selection.present?,
                      selected_provisional_grade_id: selection&.provisional_grade_id)
          pg_list = submission_provisional_grades_json(submission, @assignment, @current_user, includes)
          json.merge!({ provisional_grades: pg_list })
        end
        json
      }
    end
  end

  # @API List multiple assignments gradeable students
  #
  # @argument assignment_ids[] [String]
  #   Assignments being requested
  #
  # A paginated list of students eligible to submit a list of assignments. The caller must have
  # permission to view grades for the requested course.
  #
  # Section-limited instructors will only see students in their own sections.
  #
  # @example_response
  #   A [UserDisplay] with an extra assignment_ids field to indicate what assignments
  #   that user can submit
  #
  #   [
  #     {
  #       "id": 2,
  #       "display_name": "Display Name",
  #       "avatar_image_url": "http://avatar-image-url.jpeg",
  #       "html_url": "http://canvas.com",
  #       "assignment_ids": [1, 2, 3]
  #     }
  #   ]
  def multiple_gradeable_students
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      assignment_ids = Array(params[:assignment_ids])

      student_scope = context.students_visible_to(@current_user, include: :inactive)
      student_scope = student_scope.
        preload(:assignment_student_visibilities).
        joins(:assignment_student_visibilities).
        where(:assignment_student_visibilities =>
              {
                :assignment_id => assignment_ids,
                :course_id => @context.id
              }).
        distinct.
        order(:id)

      students = Api.paginate(student_scope, self, api_v1_multiple_assignments_gradeable_students_url(@context))

      student_displays = students.map do |student|
        user_display = user_display_json(student, @context)
        user_display['assignment_ids'] = student.assignment_student_visibilities.
          select { |visibility| assignment_ids.include?(visibility.assignment_id.to_s) }.
          map(&:assignment_id)
        user_display
      end

      render :json => student_displays
    end
  end

  # @API Grade or comment on multiple submissions
  #
  # Update the grading and comments on multiple student's assignment
  # submissions in an asynchronous job.
  #
  # The user must have permission to manage grades in the appropriate context
  # (course or section).
  #
  # @argument grade_data[<student_id>][posted_grade] [String]
  #   See documentation for the posted_grade argument in the
  #   {api:SubmissionsApiController#update Submissions Update} documentation
  #
  # @argument grade_data[<student_id>][excuse] [Boolean]
  #   See documentation for the excuse argument in the
  #   {api:SubmissionsApiController#update Submissions Update} documentation
  #
  # @argument grade_data[<student_id>][rubric_assessment] [RubricAssessment]
  #   See documentation for the rubric_assessment argument in the
  #   {api:SubmissionsApiController#update Submissions Update} documentation
  #
  # @argument grade_data[<student_id>][text_comment] [String]
  # @argument grade_data[<student_id>][group_comment] [Boolean]
  # @argument grade_data[<student_id>][media_comment_id] [String]
  # @argument grade_data[<student_id>][media_comment_type] [String, "audio"|"video"]
  # @argument grade_data[<student_id>][file_ids][] [Integer]
  #   See documentation for the comment[] arguments in the
  #   {api:SubmissionsApiController#update Submissions Update} documentation
  # @argument grade_data[<student_id>][assignment_id] [Integer]
  #   Specifies which assignment to grade.  This argument is not necessary when
  #   using the assignment-specific endpoints.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/1/assignments/2/submissions/update_grades' \
  #        -X POST \
  #        -F 'grade_data[3][posted_grade]=88' \
  #        -F 'grade_data[4][posted_grade]=95' \
  #        -H "Authorization: Bearer <token>"
  #
  # @returns Progress
  def bulk_update
    grade_data = params[:grade_data].to_unsafe_h
    unless grade_data.is_a?(Hash) && grade_data.present?
      return render :json => "'grade_data' parameter required", :status => :bad_request
    end

    # singular case doesn't require the user to pass an assignment_id in
    # grade_data, so we do it for them
    if params[:assignment_id]
      grade_data = {params[:assignment_id] => grade_data}
    end

    assignment_ids = grade_data.keys
    @assignments = @context.assignments.active.find(assignment_ids)

    unless @assignments.all?(&:published?) &&
           @context.grants_right?(@current_user, session, :manage_grades)
      return render_unauthorized_action
    end

    progress = Submission.queue_bulk_update(@context, @section, @current_user, grade_data)
    render :json => progress_json(progress, @current_user, session)
  end

  # @API Mark submission as read
  #
  # No request fields are necessary.
  #
  # On success, the response will be 204 No Content with an empty body.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/assignments/<assignment_id>/submissions/<user_id>/read.json' \
  #        -X PUT \
  #        -H "Authorization: Bearer <token>" \
  #        -H "Content-Length: 0"
  def mark_submission_read
    change_topic_read_state("read")
  end

  # @API Mark submission as unread
  #
  # No request fields are necessary.
  #
  # On success, the response will be 204 No Content with an empty body.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/assignments/<assignment_id>/submissions/<user_id>/read.json' \
  #        -X DELETE \
  #        -H "Authorization: Bearer <token>"
  def mark_submission_unread
    change_topic_read_state("unread")
  end

  def map_user_ids(user_ids)
    Api.map_ids(user_ids, User, @domain_root_account, @current_user)
  end

  # @API Submission Summary
  #
  # Returns the number of submissions for the given assignment based on gradeable students
  # that fall into three categories: graded, ungraded, not submitted.
  #
  # @argument grouped [Boolean]
  #   If this argument is true, the response will take into account student groups.
  #
  # @example_response
  #   {
  #     "graded": 5,
  #     "ungraded": 10,
  #     "not_submitted": 42
  #   }
  def submission_summary
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      @assignment = @context.assignments.active.find(params[:assignment_id])
      student_ids = if should_group?
                      @assignment.representatives(@current_user).map(&:id)
                    else
                      student_scope = @context.students_visible_to(@current_user).
                        where("enrollments.type<>'StudentViewEnrollment' AND enrollments.workflow_state = 'active'").distinct
                      student_scope = @assignment.students_with_visibility(student_scope)
                      student_scope.pluck(:id)
                    end

      graded = @context.submissions.graded.where(user_id: student_ids, assignment_id: @assignment).count
      ungraded = @context.submissions.
        needs_grading.having_submission.
        where(user_id: student_ids, assignment_id: @assignment, excused: [nil, false]).
        except(:order).
        count
      total = if should_group?
                @assignment.group_category.groups.count
              else
                student_ids.count
              end
      not_submitted = total - graded - ungraded

      render json: {graded: graded, ungraded: ungraded, not_submitted: not_submitted}
    end
  end

  def should_group?
    value_to_boolean(params[:grouped]) && @assignment.group_category_id && !@assignment.grade_group_students_individually
  end

  private

  def change_topic_read_state(new_state)
    @assignment = @context.assignments.active.find(params[:assignment_id])
    @user = get_user_considering_section(params[:user_id])
    @submission = @assignment.submissions.find_or_create_by!(user: @user)

    render_state_change_result @submission.change_read_state(new_state, @current_user)
  end

  # the result of several state change functions are the following:
  #  nil - no current user
  #  true - state is already set to the requested state
  #  participant with errors - something went wrong with the participant
  #  participant with no errors - the change went through
  # this function renders a 204 No Content for a success, or a Bad Request
  # for failure with participant errors if there are any
  def render_state_change_result(result)
    if result == true || result.try(:errors).blank?
      head :no_content
    else
      render :json => result.try(:errors) || {}, :status => :bad_request
    end
  end

  def get_user_considering_section(user_id)
    students = @context.students_visible_to(@current_user, include: :priors)
    if @section
      students = students.where(:enrollments => { :course_section_id => @section })
    end
    api_find(students, user_id)
  end

  def section_ids
    @section ? [@section.id] : nil
  end

  def bulk_load_attachments_and_previews(submissions)
    Submission.bulk_load_versioned_attachments(submissions)
    attachments = submissions.flat_map &:versioned_attachments
    ActiveRecord::Associations::Preloader.new.preload(attachments,
      [:canvadoc, :crocodoc_document])
    Version.preload_version_number(submissions)
  end

  def bulk_process_submissions_for_visibility(submissions_scope, includes)
    result = []

    submissions_scope.find_in_batches(batch_size: 100) do |submission_batch|
      bulk_load_attachments_and_previews(submission_batch)
      user_ids = submission_batch.map(&:user_id)
      users_with_visibility = AssignmentStudentVisibility.where(
        course_id: @context,
        assignment_id: @assignment,
        user_id: user_ids
      ).pluck(:user_id).to_set

      submission_array = submission_batch.map do |submission|
        submission.visible_to_user = users_with_visibility.include?(submission.user_id)
        submission_json(submission, @assignment, @current_user, session, @context, includes, params)
      end

      result.concat(submission_array)
    end

    result
  end

end
