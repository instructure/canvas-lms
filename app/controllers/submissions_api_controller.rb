#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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
#           "description": "The id of the user who graded the submission",
#           "example": 86,
#           "type": "integer"
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
#         }
#       }
#     }
#
class SubmissionsApiController < ApplicationController
  before_filter :get_course_from_section, :require_context, :require_user
  batch_jobs_in_actions :only => [:update], :batch => { :priority => Delayed::LOW_PRIORITY }

  include Api::V1::Progress
  include Api::V1::Submission

  # @API List assignment submissions
  #
  # Get all existing submissions for an assignment.
  #
  # @argument include[] [String, "submission_history"|"submission_comments"|"rubric_assessment"|"assignment"|"visibility"|"course"|"user"|"group"]
  #   Associations to include with the group.  "group" will add group_id and group_name.
  #
  # @argument grouped [Boolean]
  #   If this argument is true, the response will be grouped by student groups.
  #
  # @response_field assignment_id The unique identifier for the assignment.
  # @response_field user_id The id of the user who submitted the assignment.
  # @response_field grader_id The id of the user who graded the assignment.
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
                                                           @current_user, section_ids)
                        .pluck(:user_id)
                    end
      submissions = @assignment.submissions.where(user_id: student_ids)

      if includes.include?("visibility")
        json = bulk_process_submissions_for_visibility(submissions, includes)
      else
        submissions = submissions.order(:user_id)

        submissions = submissions.preload(:group) if includes.include?("group")

        submissions = Api.paginate(submissions, self,
                                   api_v1_course_assignment_submissions_url(@context, @assignment))
        bulk_load_attachments_and_previews(submissions)

        json = submissions.map { |s|
          s.visible_to_user = true
          submission_json(s, @assignment, @current_user, session, @context, includes)
        }
      end

      render :json => json
    end
  end

  # @API List submissions for multiple assignments
  #
  # Get all existing submissions for a given set of students and assignments.
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
  # @argument grading_period_id [Integer]
  #   The id of the grading period in which submissions are being requested
  #   (Requires the Multiple Grading Periods account feature turned on)
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
      if !inaccessible_students.empty?
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
        # if any student_ids exist that the current_user shouldnt have access to, return an error
        # (student looking at other students, observer looking at student out of their scope)
        inaccessible_students = student_ids - allowed_student_ids
        return render_unauthorized_action if !inaccessible_students.empty?
      end
    end

    if student_ids.is_a?(Array) && student_ids.length > Api.max_per_page
      return render json: { error: 'too many students' }, status: 400
    end

    includes = Array(params[:include])

    assignment_scope = @context.assignments.published
    requested_assignment_ids = Array(params[:assignment_ids]).map(&:to_i)
    if requested_assignment_ids.present?
      assignment_scope = assignment_scope.where(:id => requested_assignment_ids)
    end

    if params[:grading_period_id].present? && multiple_grading_periods?
      assignments = GradingPeriod.active.find(params[:grading_period_id]).assignments(assignment_scope)
    else
      assignments = assignment_scope.to_a
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

    if params[:grouped].present?
      scope = (@section || @context).all_student_enrollments.
          eager_load(:user => :pseudonyms).
          where("users.id" => student_ids)

      submissions = if requested_assignment_ids.present?
                      Submission.where(
                        :user_id => student_ids,
                        :assignment_id => assignments
                      ).to_a
                    else
                      Submission.joins(:assignment).where(
                        :user_id => student_ids,
                        "assignments.context_type" => @context.class.name,
                        "assignments.context_id" => @context.id
                      ).where(
                        "assignments.workflow_state != 'deleted'"
                      ).to_a
                    end
      bulk_load_attachments_and_previews(submissions)
      submissions_for_user = submissions.group_by(&:user_id)

      seen_users = Set.new
      result = []
      show_sis_info = context.grants_any_right?(@current_user, :read_sis, :manage_sis)
      scope.each do |enrollment|
        student = enrollment.user
        next if seen_users.include?(student.id)
        seen_users << student.id
        hash = { :user_id => student.id, :section_id => enrollment.course_section_id, :submissions => [] }

        pseudonym = SisPseudonym.for(student, context)
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
            hash[:submissions] << submission_json(submission, submission.assignment, @current_user, session, @context, includes)
          end
        end
        if includes.include?('total_scores') && params[:grouped].present?
          hash.merge!(
            :computed_final_score => enrollment.computed_final_score,
            :computed_current_score => enrollment.computed_current_score
          )
        end
        result << hash
      end
    else
      submissions = @context.submissions.except(:order).where(:user_id => student_ids).order(:id)
      submissions = submissions.where(:assignment_id => assignments) unless assignments.empty?
      submissions = submissions.preload(:user)

      submissions = Api.paginate(submissions, self, polymorphic_url([:api_v1, @section || @context, :student_submissions]))
      Submission.bulk_load_versioned_attachments(submissions)
      result = submissions.select{ |s|
        assignment_visibilities.fetch(s.assignment_id, []).include?(s.user_id) || can_view_all
      }.map { |s|
        s.assignment = assignments_hash[s.assignment_id]
        visible_assignments = assignment_visibilities.fetch(s.user_id, [])
        s.visible_to_user = visible_assignments.include? s.assignment_id
        submission_json(s, s.assignment, @current_user, session, @context, includes)
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
        render :json => submission_json(@submission, @assignment, @current_user, session, @context, includes)
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
    # we don't check quota when uploading a file for assignment submission
    if authorized_action(@assignment, @current_user, permission)
      api_attachment_preflight(@user, request, :check_quota => false, :submission_context => @context)
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
    @user = get_user_considering_section(params[:user_id])

    authorized = false
    @submission = @assignment.submissions.where(user_id: @user).first ||
      @assignment.submissions.build(user: @user)

    if params[:submission] || params[:rubric_assessment]
      authorized = authorized_action(@submission, @current_user, :grade)
    else
      authorized = authorized_action(@submission, @current_user, :comment)
    end

    if authorized
      submission = { grader: @current_user }
      if params[:submission].is_a?(Hash)
        submission[:grade] = params[:submission].delete(:posted_grade)
        submission[:excuse] = params[:submission].delete(:excuse)
        submission[:provisional] = value_to_boolean(params[:submission][:provisional])
        submission[:final] = value_to_boolean(params[:submission][:final]) && @context.grants_right?(@current_user, :moderate_grades)
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

      assessment = params[:rubric_assessment]
      if assessment.is_a?(Hash) && @assignment.rubric_association
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
      if comment.is_a?(Hash)
        admin_in_context = !@context_enrollment || @context_enrollment.admin?
        comment = {
          comment: comment[:text_comment],
          author: @current_user,
          hidden: @assignment.muted? && admin_in_context
        }.merge(
          comment.slice(:media_comment_id, :media_comment_type, :group_comment)
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
      json = submission_json(@submission, @assignment, @current_user, session, @context, includes)

      includes.delete("submission_comments")
      json[:all_submissions] = @submissions.map { |submission|

        if visiblity_included
          submission.visible_to_user = users_with_visibility.include?(submission.user_id)
        end

        submission_json(submission, @assignment, @current_user, session, @context, includes)
      }
      render :json => json
    end
  end

  # @API List gradeable students
  #
  # List students eligible to submit the assignment. The caller must have permission to view grades.
  #
  # Section-limited instructors will only see students in their own sections.
  #
  # returns [UserDisplay]
  def gradeable_students
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      @assignment = @context.assignments.active.find(params[:assignment_id])
      includes = Array(params[:include])
      student_scope = context.students_visible_to(@current_user, include: :inactive)
      student_scope = @assignment.students_with_visibility(student_scope)
      student_scope = student_scope.order(:id)
      students = Api.paginate(student_scope, self, api_v1_course_assignment_gradeable_students_url(@context, @assignment))
      if (include_pg = includes.include?('provisional_grades'))
        return unless authorized_action(@context, @current_user, :moderate_grades)
        submissions = @assignment.submissions.where(user_id: students).preload(:provisional_grades).index_by(&:user_id)
        selections = @assignment.moderated_grading_selections.where(student_id: students).index_by(&:student_id)
      end
      render :json => students.map { |student|
        json = user_display_json(student, @context)
        if include_pg
          selection = selections[student.id]
          json.merge!(in_moderation_set: selection.present?,
                      selected_provisional_grade_id: selection && selection.selected_provisional_grade_id)
          sub = submissions[student.id]
          pg_list = if sub
            submission_provisional_grades_json(sub, @assignment, @current_user, includes)
          else
            []
          end
          json.merge!({ provisional_grades: pg_list })
        end
        json
      }
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
    grade_data = params[:grade_data]
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

  private

  def change_topic_read_state(new_state)
    @assignment = @context.assignments.active.find(params[:assignment_id])
    @user = get_user_considering_section(params[:user_id])
    @submission = @assignment.submissions.where(user_id: @user).first || @assignment.submissions.build(user: @user)

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
      render :nothing => true, :status => :no_content
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
        submission_json(
          submission,
          @assignment,
          @current_user,
          session,
          @context,
          includes
        )
      end

      result.concat(submission_array)
    end

    result
  end

end
