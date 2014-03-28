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
class SubmissionsApiController < ApplicationController
  before_filter :get_course_from_section, :require_context
  batch_jobs_in_actions :only => :update, :batch => { :priority => Delayed::LOW_PRIORITY }

  include Api::V1::Submission

  # @API List assignment submissions
  #
  # Get all existing submissions for an assignment.
  #
  # @argument include[] [String, "submission_history"|"submission_comments"|"rubric_assessment"|"assignment"]
  #   Associations to include with the group.
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
  def index
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      @assignment = @context.assignments.active.find(params[:assignment_id])
      @submissions = @assignment.submissions.where(:user_id => visible_user_ids).all

      includes = Array(params[:include])

      result = @submissions.map { |s| submission_json(s, @assignment, @current_user, session, @context, includes) }

      render :json => result
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
  # @argument include[] [String, "submission_history"|"submission_comments"|"rubric_assessment"|"assignment"|"total_scores"]
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

    can_view_all = is_authorized_action?(@context, @current_user, [:manage_grades, :view_all_grades])
    if all && can_view_all
      opts = { include_priors: true }
      if @section
        opts[:section_ids] = [@section.id]
      end
      # this is a scope, and will generate subqueries
      student_ids = @context.enrollments_visible_to(@current_user, opts).select(:user_id)
    elsif can_view_all
      inaccessible_students = student_ids - visible_user_ids(:include_priors => true)
      if !inaccessible_students.empty?
        return render_unauthorized_action
      end
    else
      # can view observees
      allowed_student_ids = @context.observer_enrollments.where(:user_id => @current_user.id, :workflow_state => 'active').where("associated_user_id IS NOT NULL").pluck(:associated_user_id)
      # can view self, if a student
      allowed_student_ids << @current_user.id if is_authorized_action?(@context, @current_user, :participate_as_student)
      return render_unauthorized_action if allowed_student_ids.empty?
      if all
        student_ids = allowed_student_ids
      else
        inaccessible_students = student_ids - allowed_student_ids
        return render_unauthorized_action if !inaccessible_students.empty?
      end
    end

    if Array === student_ids
      return render json: { error: 'too many students' }, status: 400 if student_ids.length > Api.max_per_page
    end

    includes = Array(params[:include])

    assignment_scope = @context.assignments.active
    requested_assignment_ids = Array(params[:assignment_ids]).map(&:to_i)
    if requested_assignment_ids.present?
      assignment_scope = assignment_scope.where(:id => requested_assignment_ids)
    end
    assignments = assignment_scope.all
    # preload with stuff already in memory
    assignments.each { |a| a.context = @context }
    assignments_hash = assignments.index_by(&:id)

    if params[:grouped].present?
      scope = (@section || @context).all_student_enrollments.
          includes(:user).
          where('users.id' => student_ids)

      submissions = if requested_assignment_ids.present?
                      Submission.where(
                        :user_id => student_ids,
                        :assignment_id => assignments
                      ).all
                    else
                      Submission.joins(:assignment).where(
                        :user_id => student_ids,
                        "assignments.context_type" => @context.class.name,
                        "assignments.context_id" => @context.id
                      ).where(
                        "assignments.workflow_state != 'deleted'"
                      ).all
                    end
      Submission.bulk_load_versioned_attachments(submissions)
      submissions_for_user = submissions.group_by(&:user_id)

      seen_users = Set.new
      result = []
      scope.each do |enrollment|
        student = enrollment.user
        next if seen_users.include?(student.id)
        seen_users << student.id
        hash = { :user_id => student.id, :submissions => [] }
        student_submissions = submissions_for_user[student.id] || []
        student_submissions.each do |submission|
          # we've already got all the assignments loaded, so bypass AR loading
          # here and just give the submission its assignment
          submission.assignment = assignments_hash[submission.assignment_id]
          submission.user = student

          hash[:submissions] << submission_json(submission, submission.assignment, @current_user, session, @context, includes)
        end unless assignments.empty?
        if includes.include?('total_scores') && params[:grouped].present?
          hash.merge!(
            :computed_final_score => enrollment.computed_final_score,
            :computed_current_score => enrollment.computed_current_score)
        end
        result << hash
      end
    else
      submissions = @context.submissions.except(:order).where(:user_id => student_ids).includes(:user).order(:id)
      submissions = submissions.where(:assignment_id => assignments) unless assignments.empty?
      submissions = Api.paginate(submissions, self, polymorphic_url([:api_v1, @section || @context, :student_submissions]))
      Submission.bulk_load_versioned_attachments(submissions)
      result = submissions.map do |s|
        s.assignment = assignments_hash[s.assignment_id]
        submission_json(s, s.assignment, @current_user, session, @context, includes)
      end
    end

    render :json => result
  end

  # @API Get a single submission
  #
  # Get a single submission, based on user id.
  #
  # @argument include[] [String, "submission_history"|"submission_comments"|"rubric_assessment"]
  #   Associations to include with the group.
  def show
    @assignment = @context.assignments.active.find(params[:assignment_id])
    @user = get_user_considering_section(params[:user_id])
    @submission = @assignment.submission_for_student(@user)

    if authorized_action(@submission, @current_user, :read)
      includes = Array(params[:include])
      render :json => submission_json(@submission, @assignment, @current_user, session, @context, includes)
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
      api_attachment_preflight(@user, request, :check_quota => false, :do_submit_to_scribd => true)
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
  # @argument comment[group_comment] [Optional, Boolean]
  #   Whether or not this comment should be sent to the entire group (defaults
  #   to false). Ignored if this is not a group assignment or if no text_comment
  #   is provided.
  #
  # @argument comment[media_comment_id] [Integer]
  #   Add an audio/video comment to the submission. Media comments can be added
  #   via this API, however, note that there is not yet an API to generate or
  #   list existing media comments, so this functionality is currently of
  #   limited use.
  #
  # @argument comment[media_comment_type] [String, "audio"|"video"]
  #   The type of media comment being added.
  #
  # @argument comment[file_ids][] [Optional,Integer]
  #   Attach files to this comment that were previously uploaded using the
  #   Submission Comment API's files action
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
  # @argument rubric_assessment [RubricAssessment]
  #   Assign a rubric assessment to this assignment submission. The
  #   sub-parameters here depend on the rubric for the assignment. The general
  #   format is, for each row in the rubric:
  #
  #   rubric_assessment[criterion_id][points]:: The points awarded for this row.
  #   rubric_assessment[criterion_id][comments]:: Comments to add for this row.
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
    @submission = @assignment.submissions.where(user_id: @user).first || @assignment.submissions.build(user: @user)

    if params[:submission] || params[:rubric_assessment]
      authorized = authorized_action(@submission, @current_user, :grade)
    else
      authorized = authorized_action(@submission, @current_user, :comment)
    end

    if authorized
      submission = { :grader => @current_user }
      if params[:submission].is_a?(Hash)
        submission[:grade] = params[:submission].delete(:posted_grade)
      end
      if submission[:grade]
        @submissions = @assignment.grade_student(@user, submission)
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
          :assessor => @current_user, :user => @user, :artifact => @submission,
          :assessment => assessment.merge(:assessment_type => 'grading'))
      end

      comment = params[:comment]
      if comment.is_a?(Hash)
        admin_in_context = !@context_enrollment || @context_enrollment.admin?
        comment = {
          :comment => comment[:text_comment], :author => @current_user,
          :hidden => @assignment.muted? && admin_in_context,
        }.merge(
          comment.slice(:media_comment_id, :media_comment_type, :group_comment)
        ).with_indifferent_access
        if file_ids = params[:comment][:file_ids]
          attachments = Attachment.where(id: file_ids).all
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

      json = submission_json(@submission, @assignment, @current_user, session, @context, %w(submission_comments))
      json[:all_submissions] = @submissions.map { |submission| submission_json(submission, @assignment, @current_user, session, @context) }
      render :json => json
    end
  end

  def map_user_ids(user_ids)
    Api.map_ids(user_ids, User, @domain_root_account)
  end

  def get_user_considering_section(user_id)
    scope = @context.students_visible_to(@current_user)
    if @section
      scope = scope.where(:enrollments => { :course_section_id => @section })
    end
    api_find(scope, user_id)
  end

  def visible_user_ids(opts = {})
    if @section
      opts[:section_ids] = [@section.id]
    end
    scope = @context.enrollments_visible_to(@current_user, opts)
    scope.pluck(:user_id)
  end
end
