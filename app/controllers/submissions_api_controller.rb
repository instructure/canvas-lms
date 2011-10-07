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

  # @API
  #
  # Get all existing submissions for an assignment.
  #
  # @argument include[] ["submission_history"|"submission_comments"|"rubric_assessment"] Associations to include with the group.
  def index
    if authorized_action(@context, @current_user, :manage_grades)
      @assignment = @context.assignments.active.find(params[:assignment_id])
      @submissions = @assignment.submissions.all(
        :conditions => { :user_id => (@section || @context).student_ids })

      includes = Array(params[:include])

      result = @submissions.map { |s| submission_json(s, @assignment, includes) }

      render :json => result.to_json
    end
  end

  # @API
  #
  # Get all existing submissions for a given set of students and assignments.
  #
  # @argument student_ids[] List of student ids to return submissions for. At least one is required.
  # @argument assignment_ids[] List of assignments to return submissions for. If none are given, submissions for all assignments are returned.
  # @argument grouped If this argument is present, the response will be grouped by student, rather than a flat array of submissions.
  # @argument include[] ["submission_history"|"submission_comments"|"rubric_assessment"|"total_scores"] Associations to include with the group. `total_scores` requires the `grouped` argument.
  #
  # @example_response
  #
  # Without grouped:
  #
  # [
  #   { "assignment_id": 100, grade: 5, "user_id": 1, ... },
  #   { "assignment_id": 101, grade: 6, "user_id": 2, ... }
  #
  # With grouped:
  #
  # [
  #   {
  #     "user_id": 1,
  #     "submissions: [
  #       { "assignment_id": 100, grade: 5, ... },
  #       { "assignment_id": 101, grade: 6, ... }
  #     ]
  #   }
  # ]
  def for_students
    if authorized_action(@context, @current_user, :manage_grades)
      student_ids = map_user_ids(params[:student_ids])
      raise ActiveRecord::RecordNotFound if student_ids.blank?

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
          hash[:submissions] << submission_json(submission, submission.assignment, includes)
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

  # @API
  #
  # Get a single submission, based on user id.
  #
  # @argument include[] ["submission_history"|"submission_comments"|"rubric_assessment"] Associations to include with the group.
  def show
    @assignment = @context.assignments.active.find(params[:assignment_id])
    @user = get_user_considering_section(params[:id])
    @submission = @assignment.submissions.find_by_user_id(@user.id) or raise ActiveRecord::RecordNotFound
    if authorized_action(@submission, @current_user, :read)
      includes = Array(params[:include])
      render :json => submission_json(@submission, @assignment, includes).to_json
    end
  end

  # @API
  #
  # Update the grading for a student's assignment submission.
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
  #
  #   rubric_assessment[crit1][points]=3&rubric_assessment[crit2][points]=5&rubric_assessment[crit2][comments]=Well%20Done.
  #
  # @argument comment[text_comment] Add a textual comment to the submission.
  def update
    if authorized_action(@context, @current_user, :manage_grades)
      @assignment = @context.assignments.active.find(params[:assignment_id])
      @user = get_user_considering_section(params[:id])

      submission = {}
      if params[:submission].is_a?(Hash)
        submission[:grade] = params[:submission].delete(:posted_grade)
      end
      if submission[:grade]
        @submission = @assignment.grade_student(@user, submission).first
      else
        @submission = @assignment.find_or_create_submission(@user)
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
          comment.slice(:media_comment_id, :media_comment_type))
          @submission.add_comment(comment)
      end
      # We need to reload because some of this stuff is getting set on the
      # submission without going through the model instance -- it'd be nice to
      # fix this at some point.
      @submission.reload

      render :json => submission_json(@submission, @assignment, %w(submission_comments)).to_json
    end
  end

  protected

  # We might want to make a Helper that holds all these methods to convert AR
  # objects to the API json formatting.
  def submission_json(submission, assignment, includes = [])
    hash = submission_attempt_json(submission, assignment)

    if includes.include?("submission_history")
      hash['submission_history'] = []
      submission.submission_history.each_with_index do |ver, idx|
        hash['submission_history'] << submission_attempt_json(ver, assignment, idx)
      end
    end

    if includes.include?("submission_comments")
      hash['submission_comments'] = submission.submission_comments.map do |sc|
        sc_hash = sc.as_json(
          :include_root => false,
          :only => %w(author_id author_name created_at comment))
        if sc.media_comment?
          sc_hash['media_comment'] = media_comment_json(:media_id => sc.media_comment_id, :media_type => sc.media_comment_type)
        end
        sc_hash['attachments'] = sc.attachments.map do |a|
          attachment_json(a)
        end unless sc.attachments.blank?
        sc_hash
      end
    end

    if includes.include?("rubric_assessment") && submission.rubric_assessment
      ra = submission.rubric_assessment.data
      hash['rubric_assessment'] = {}
      ra.each { |rating| hash['rubric_assessment'][rating[:criterion_id]] = rating.slice(:points, :comments) }
    end

    hash
  end

  SUBMISSION_JSON_FIELDS = %w(user_id url score grade attempt submission_type submitted_at body assignment_id grade_matches_current_submission).freeze
  SUBMISSION_OTHER_FIELDS = %w(attachments discussion_entries)

  def submission_attempt_json(attempt, assignment, version_idx = nil)
    json_fields = SUBMISSION_JSON_FIELDS
    if params[:response_fields]
      json_fields = json_fields & params[:response_fields]
    end
    if params[:exclude_response_fields]
      json_fields -= params[:exclude_response_fields]
    end

    other_fields = SUBMISSION_OTHER_FIELDS
    if params[:response_fields]
      other_fields = other_fields & params[:response_fields]
    end
    if params[:exclude_response_fields]
      other_fields -= params[:exclude_response_fields]
    end

    hash = attempt.as_json(
      :include_root => false,
      :only => json_fields)

    hash['preview_url'] = course_assignment_submission_url(
      @context, assignment, attempt[:user_id], 'preview' => '1',
      'version' => version_idx)

    unless attempt.media_comment_id.blank?
      hash['media_comment'] = media_comment_json(:media_id => attempt.media_comment_id, :media_type => attempt.media_comment_type)
    end
    if other_fields.include?('attachments')
      attachments = attempt.versioned_attachments.dup
      attachments << attempt.attachment if attempt.attachment && attempt.attachment.context_type == 'Submission' && attempt.attachment.context_id == attempt.id
      hash['attachments'] = attachments.map do |attachment|
        attachment_json(attachment)
      end.compact unless attachments.blank?
    end

    # include the discussion topic entries
    if other_fields.include?('discussion_entries') &&
           assignment.submission_types =~ /discussion_topic/ &&
           assignment.discussion_topic
      # group assignments will have a child topic for each group.
      # it's also possible the student posted in the main topic, as well as the
      # individual group one. so we search far and wide for all student entries.
      if assignment.has_group_category?
        entries = assignment.discussion_topic.child_topics.map {|t| t.discussion_entries.active.for_user(attempt.user_id) }.flatten.sort_by{|e| e.created_at}
      else
        entries = assignment.discussion_topic.discussion_entries.active.for_user(attempt.user_id)
      end
      hash['discussion_entries'] = entries.map do |entry|
        ehash = entry.as_json(
          :include_root => false,
          :only => %w(message user_id created_at updated_at)
        )
        attachments = (entry.attachments.dup + [entry.attachment]).compact
        ehash['attachments'] = attachments.map do |attachment|
          attachment_json(attachment)
        end.compact unless attachments.blank?
        ehash
      end
    end

    hash
  end

  def map_user_ids(user_ids)
    Api.map_ids(user_ids, User).compact unless user_ids.blank?
  end

  def get_course_from_section
    if params[:section_id]
      @section = api_find(CourseSection, params.delete(:section_id))
      params[:course_id] = @section.course_id
    end
  end

  def get_user_considering_section(user_id)
    scope = @context.students_visible_to(@current_user)
    if @section
      scope = scope.scoped(:conditions => { 'enrollments.course_section_id' => @section.id })
    end
    api_find(scope, user_id)
  end
end
