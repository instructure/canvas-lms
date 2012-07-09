#
# Copyright (C) 2011 Instructure, Inc.
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

  include Api::V1::Submission

  # @API List assignment submissions
  #
  # Get all existing submissions for an assignment.
  #
  # @argument include[] ["submission_history"|"submission_comments"|"rubric_assessment"|"assignment"] Associations to include with the group.
  #
  # Fields include:
  # assignment_id:: The unique identifier for the assignment.
  # user_id:: The id of the user who submitted the assignment.
  # submitted_at:: The timestamp when the assignment was submitted, if an actual submission has been made.
  # score:: The raw score for the assignment submission.
  # attempt:: If multiple submissions have been made, this is the attempt number.
  # body:: The content of the submission, if it was submitted directly in a text field.
  # grade:: The grade for the submission, translated into the assignment grading scheme (so a letter grade, for example).
  # grade_matches_current_submission:: A boolean flag which is false if the student has re-submitted since the submission was last graded.
  # preview_url:: Link to the URL in canvas where the submission can be previewed. This will require the user to log in.
  # submitted_at:: Timestamp when the submission was made.
  # url:: If the submission was made as a URL.
  def index
    if authorized_action(@context, @current_user, :manage_grades)
      @assignment = @context.assignments.active.find(params[:assignment_id])
      @submissions = @assignment.submissions.all(
        :conditions => { :user_id => visible_user_ids })

      includes = Array(params[:include])

      result = @submissions.map { |s| submission_json(s, @assignment, @current_user, session, @context, includes) }

      render :json => result.to_json
    end
  end

  # @API List submissions for multiple assignments
  #
  # Get all existing submissions for a given set of students and assignments.
  #
  # @argument student_ids[] List of student ids to return submissions for. At least one is required.
  # @argument assignment_ids[] List of assignments to return submissions for. If none are given, submissions for all assignments are returned.
  # @argument grouped If this argument is present, the response will be grouped by student, rather than a flat array of submissions.
  # @argument include[] ["submission_history"|"submission_comments"|"rubric_assessment"|"assignment"|"total_scores"] Associations to include with the group. `total_scores` requires the `grouped` argument.
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
    if authorized_action(@context, @current_user, :manage_grades)
      raise ActiveRecord::RecordNotFound if params[:student_ids].blank?
      student_ids = map_user_ids(params[:student_ids]).map(&:to_i) & visible_user_ids
      return render(:json => []) if student_ids.blank?

      includes = Array(params[:include])

      assignment_scope = @context.assignments.active
      requested_assignment_ids = Array(params[:assignment_ids]).map(&:to_i)
      if requested_assignment_ids.present?
        assignment_scope = assignment_scope.scoped(:conditions => { 'assignments.id' => requested_assignment_ids })
      end
      assignments = assignment_scope.all
      assignments_hash = {}
      assignments.each { |a| assignments_hash[a.id] = a }

      # sadly hackish -- see User.submissions_for_given_assignments
      Api.assignment_ids_for_students_api = assignments.map(&:id)
      sql_includes = { :user => [] }
      sql_includes[:user] << :submissions_for_given_assignments unless assignments.empty?
      scope = (@section || @context).student_enrollments.scoped(
        :include => sql_includes,
        :conditions => { 'users.id' => student_ids })

      result = scope.map do |enrollment|
        student = enrollment.user
        hash = { :user_id => student.id, :submissions => [] }
        student.submissions_for_given_assignments.each do |submission|
          # we've already got all the assignments loaded, so bypass AR loading
          # here and just give the submission its assignment
          submission.assignment = assignments_hash[submission.assignment_id]
          hash[:submissions] << submission_json(submission, submission.assignment, @current_user, session, @context, includes)
        end unless assignments.empty?
        if includes.include?('total_scores') && params[:grouped].present?
          hash.merge!(
            :computed_final_score => enrollment.computed_final_score,
            :computed_current_score => enrollment.computed_current_score)
        end
        hash
      end

      unless params[:grouped].present?
        result = result.inject([]) { |arr, user_info| arr.concat(user_info[:submissions]) }
      end

      render :json => result
    end
  end

  # @API Get a single submission
  #
  # Get a single submission, based on user id.
  #
  # @argument include[] ["submission_history"|"submission_comments"|"rubric_assessment"] Associations to include with the group.
  def show
    @assignment = @context.assignments.active.find(params[:assignment_id])
    @user = get_user_considering_section(params[:id])
    @submission = @assignment.submission_for_student(@user)

    if authorized_action(@submission, @current_user, :read)
      includes = Array(params[:include])
      render :json => submission_json(@submission, @assignment, @current_user, session, @context, includes).to_json
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
      api_attachment_preflight(@user, request, :check_quota => false)
    end
  end

  # @API Grade a submission
  #
  # Comment on and/or update the grading for a student's assignment submission.
  # If any submission or rubric_assessment arguments are provided, the user
  # must have permission to manage grades in the appropriate context (course or
  # section).
  #
  # @argument comment[text_comment] Add a textual comment to the submission.
  #
  # @argument comment[group_comment] [Boolean] Whether or not this comment should be sent to the entire group (defaults to false). Ignored if this is not a group assignment or if no text_comment is provided.
  #
  # @argument submission[posted_grade] Assign a score to the submission,
  #   updating both the "score" and "grade" fields on the submission record.
  #   This parameter can be passed in a few different formats:
  #   points:: A floating point or integral value, such as "13.5". The grade will be interpreted directly as the score of the assignment. Values above assignment.points_possible are allowed, for awarding extra credit.
  #   percentage:: A floating point value appended with a percent sign, such as "40%". The grade will be interpreted as a percentage score on the assignment, where 100% == assignment.points_possible. Values above 100% are allowed, for awarding extra credit.
  #   letter grade:: A letter grade, following the assignment's defined letter grading scheme. For example, "A-". The resulting score will be the high end of the defined range for the letter grade. For instance, if "B" is defined as 86% to 84%, a letter grade of "B" will be worth 86%. The letter grade will be rejected if the assignment does not have a defined letter grading scheme. For more fine-grained control of scores, pass in points or percentage rather than the letter grade.
  #   "pass/complete/fail/incomplete":: A string value of "pass" or "complete" will give a score of 100%. "fail" or "incomplete" will give a score of 0.
  #
  #   Note that assignments with grading_type of "pass_fail" can only be
  #   assigned a score of 0 or assignment.points_possible, nothing inbetween. If
  #   a posted_grade in the "points" or "percentage" format is sent, the grade
  #   will only be accepted if the grade equals one of those two values.
  #
  # @argument rubric_assessment Assign a rubric assessment to this assignment
  #   submission. The sub-parameters here depend on the rubric for the
  #   assignment. The general format is, for each row in the rubric:
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
    @user = get_user_considering_section(params[:id])

    authorized = false
    if params[:submission] || params[:rubric_assessment]
      authorized = authorized_action(@context, @current_user, :manage_grades)
    else
      @submission = @assignment.find_or_create_submission(@user)
      authorized = authorized_action(@submission, @current_user, :comment)
    end

    if authorized
      submission = {}
      if params[:submission].is_a?(Hash)
        submission[:grade] = params[:submission].delete(:posted_grade)
      end
      if submission[:grade]
        @submission = @assignment.grade_student(@user, submission).first
      else
        @submission ||= @assignment.find_or_create_submission(@user)
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
        comment = {
          :comment => comment[:text_comment], :author => @current_user }.merge(
          # Undocumented API feature: adding media comments given the kaltura
          # media id. Eventually we'll expose a public API for media comments,
          # but we need to implement a way to abstract it away from kaltura and
          # make it generic. This will probably involve a proxy outside of
          # rails.
          comment.slice(:media_comment_id, :media_comment_type, :group_comment)
        ).with_indifferent_access
        @assignment.update_submission(@submission.user, comment)
      end
      # We need to reload because some of this stuff is getting set on the
      # submission without going through the model instance -- it'd be nice to
      # fix this at some point.
      @submission.reload

      render :json => submission_json(@submission, @assignment, @current_user, session, @context, %w(submission_comments)).to_json
    end
  end

  def map_user_ids(user_ids)
    Api.map_ids(user_ids, User, @domain_root_account)
  end

  def get_user_considering_section(user_id)
    scope = @context.students_visible_to(@current_user)
    if @section
      scope = scope.scoped(:conditions => { 'enrollments.course_section_id' => @section.id })
    end
    api_find(scope, user_id)
  end

  def visible_user_ids
    scope = if @section
      @context.enrollments_visible_to(@current_user, :section_ids => [@section.id])
    else
      @context.enrollments_visible_to(@current_user)
    end
    scope.all(:select => :user_id).map(&:user_id)
  end
end
