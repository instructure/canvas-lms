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

module Api::V1::Submission
  include Api::V1::Json
  include Api::V1::Assignment
  include Api::V1::Attachment
  include Api::V1::DiscussionTopics
  include Api::V1::Course
  include Api::V1::User
  include Api::V1::SubmissionComment
  include CoursesHelper

  def submission_json(submission, assignment, current_user, session, context = nil, includes = [], params)
    context ||= assignment.context
    hash = submission_attempt_json(submission, assignment, current_user, session, context, params)

    if includes.include?("submission_history")
      if submission.quiz_submission && assignment.quiz && !assignment.quiz.anonymous_survey?
        hash['submission_history'] = submission.quiz_submission.versions.map do |ver|
          ver.model.submission && ver.model.submission.without_versioned_attachments do
            quiz_submission_attempt_json(ver.model, assignment, current_user, session, context, params)
          end
        end
      else
        histories = submission.submission_history
        if includes.include?("group")
          ActiveRecord::Associations::Preloader.new.preload(histories, :group)
        end
        hash['submission_history'] = histories.map do |ver|
          ver.without_versioned_attachments do
            submission_attempt_json(ver, assignment, current_user, session, context, params)
          end
        end
      end
    end

    if current_user && assignment && includes.include?('provisional_grades') && assignment.moderated_grading?
      hash['provisional_grades'] = submission_provisional_grades_json(submission, assignment, current_user, includes)
    end

    if includes.include?("submission_comments")
      published_comments = submission.comments_for(@current_user).published
      hash['submission_comments'] = submission_comments_json(published_comments, current_user)
    end

    if includes.include?("rubric_assessment") && submission.rubric_assessment && submission.user_can_read_grade?(current_user)
      hash['rubric_assessment'] = rubric_assessment_json(submission.rubric_assessment)
    end

    if includes.include?("assignment")
      hash['assignment'] = assignment_json(assignment, current_user, session)
    end

    if includes.include?("course")
      hash['course'] = course_json(submission.context, current_user, session, ['html_url'], nil)
    end

    if includes.include?("html_url")
      hash['html_url'] = course_assignment_submission_url(submission.context.id, assignment.id, submission.user.id)
    end

    if includes.include?("user")
      hash['user'] = user_json(submission.user, current_user, session, ['avatar_url'], submission.context, nil)
    end

    if assignment && includes.include?('user_summary')
      hash['user'] = user_display_json(submission.user, assignment.context)
    end

    if includes.include?("visibility")
      hash['assignment_visible'] = submission.assignment_visible_to_user?(submission.user)
    end

    if includes.include?('submission_status')
      hash['submission_status'] = submission.submission_status
    end

    if includes.include?('grading_status')
      hash['grading_status'] = submission.grading_status
    end

    if context.account_membership_allows(current_user)
      hash['anonymous_id'] = submission.anonymous_id
    end

    hash
  end

  SUBMISSION_JSON_FIELDS = %w(id user_id url score grade excused attempt submission_type submitted_at body
    assignment_id graded_at grade_matches_current_submission grader_id workflow_state late_policy_status
    points_deducted grading_period_id cached_due_date).freeze
  SUBMISSION_JSON_METHODS = %w(late missing seconds_late entered_grade entered_score).freeze
  SUBMISSION_OTHER_FIELDS = %w(attachments discussion_entries).freeze

  def submission_attempt_json(attempt, assignment, user, session, context = nil, params)
    context ||= assignment.context
    includes = Array.wrap(params[:include])

    json_fields = SUBMISSION_JSON_FIELDS
    json_methods = SUBMISSION_JSON_METHODS.dup # dup because AR#to_json modifies the :methods param in-place
    other_fields = SUBMISSION_OTHER_FIELDS

    if params[:response_fields]
      json_fields = json_fields & params[:response_fields]
      json_methods = json_methods & params[:response_fields]
      other_fields = other_fields & params[:response_fields]
    end
    if params[:exclude_response_fields]
      json_fields -= params[:exclude_response_fields]
      json_methods -= params[:exclude_response_fields]
      other_fields -= params[:exclude_response_fields]
    end

    attempt.assignment = assignment
    hash = api_json(attempt, user, session, :only => json_fields, :methods => json_methods)
    if hash['body'].present?
      hash['body'] = api_user_content(hash['body'], context, user)
    end

    hash['group'] = submission_minimal_group_json(attempt) if includes.include?("group")
    if hash.key?('grade_matches_current_submission')
      hash['grade_matches_current_submission'] = hash['grade_matches_current_submission'] != false
    end

    unless params[:exclude_response_fields] && params[:exclude_response_fields].include?('preview_url')
      preview_args = { 'preview' => '1' }
      preview_args['version'] = attempt.quiz_submission_version || attempt.version_number
      hash['preview_url'] = course_assignment_submission_url(
        context, assignment, attempt[:user_id], preview_args)
    end

    unless attempt.media_comment_id.blank?
      hash['media_comment'] = media_comment_json(:media_id => attempt.media_comment_id, :media_type => attempt.media_comment_type)
    end

    if show_originality_reports?(attempt)
       hash['has_originality_report'] = true
    end

    if attempt.originality_data.present? && attempt.grants_right?(@current_user, :view_turnitin_report)
      turnitin_hash = attempt.originality_data.dup
      turnitin_hash.delete(:last_processed_attempt)
      hash['turnitin_data'] = turnitin_hash
    end

    if attempt.vericite_data(false).present? &&
      attempt.can_view_plagiarism_report('vericite', @current_user, session) &&
      attempt.assignment.vericite_enabled?
      vericite_hash = attempt.vericite_data(false).dup
      vericite_hash.delete(:last_processed_attempt)
      hash['vericite_data'] = vericite_hash
    end

    if other_fields.include?('attachments')
      attachments = attempt.versioned_attachments.dup
      attachments << attempt.attachment if attempt.attachment && attempt.attachment.context_type == 'Submission' && attempt.attachment.context_id == attempt.id
      hash['attachments'] = attachments.map do |attachment|
        includes = includes.include?('canvadoc_document_id') ? ['preview_url', 'canvadoc_document_id'] : ['preview_url']
        atjson = attachment_json(attachment, user, {},
                                 skip_permission_checks: true,
                                 include: includes,
                                 enable_annotations: true, # we want annotations on submission's attachment preview_urls
                                 moderated_grading_whitelist: attempt.moderated_grading_whitelist,
                                 enrollment_type: user_type(context, user),
                                 anonymous_instructor_annotations: assignment.anonymous_instructor_annotations?
                                )
        atjson
      end.compact unless attachments.blank?
    end

    # include the discussion topic entries
    if other_fields.include?('discussion_entries') &&
           assignment.submission_types =~ /discussion_topic/ &&
           assignment.discussion_topic
      # group assignments will have a child topic for each group.
      # it's also possible the student posted in the main topic, as well as the
      # individual group one. so we search far and wide for all student entries.
      if assignment.discussion_topic.has_group_category?
        entries = assignment.discussion_topic.child_topics.map {|t| t.discussion_entries.active.for_user(attempt.user_id) }.flatten.sort_by{|e| e.created_at}
      else
        entries = assignment.discussion_topic.discussion_entries.active.for_user(attempt.user_id)
      end
      hash['discussion_entries'] = discussion_entry_api_json(entries, assignment.discussion_topic.context, user, session)
    end

    if attempt.submission_type == 'basic_lti_launch'
      hash['external_tool_url'] = attempt.external_tool_url
      hash['url'] = retrieve_course_external_tools_url(context.id,
                                                       assignment_id: assignment.id,
                                                       url: attempt.external_tool_url)
    end

    hash
  end

  def submission_minimal_group_json(attempt)
    # If one is including the group in the submission response, we can
    # assume they want the information for identification and sorting
    # issues and not the full group object.
    {
      id: attempt.group_id,
      name: attempt.group.try(:name)
    }
  end

  def quiz_submission_attempt_json(attempt, assignment, user, session, context = nil, params)
    hash = submission_attempt_json(attempt.submission, assignment, user, session, context, params)
    hash.each_key{|k| hash[k] = attempt[k] if attempt[k]}
    hash[:submission_data] = attempt[:submission_data]
    hash[:submitted_at] = attempt[:finished_at]
    hash[:body] = nil

    # since it is graded automatically the graded_at date should be the last time the
    # quiz_submission ended
    hash[:graded_at] = attempt[:end_at]

    hash
  end

  # Create an attachment with a ZIP archive of an assignment's submissions.
  # The attachment will be re-created if it's 1 hour old, or determined to be
  # "stale". See the argument descriptions for testing the staleness of the attachment.
  #
  # @param [Assignment] assignment
  # The assignment, or an object that implements its interface, for which the
  # submissions will be zipped.
  #
  # @param [DateTime] updated_at
  # A timestamp that marks the latest update to the assignment object which will
  # be used to determine whether the attachment will be re-created.
  #
  # Note that this timestamp will be ignored if the attachment is +submission_zip_ttl_minutes+ old.
  #
  # @return [Attachment] The attachment that contains the archive.
  def submission_zip(assignment, updated_at = nil)
    attachments = assignment.attachments.where({
      display_name: 'submissions.zip',
      workflow_state: %w[to_be_zipped zipping zipped errored unattached],
      user_id: @current_user
    }).order(:created_at).to_a

    attachment = attachments.pop
    attachments.each(&:destroy_permanently_plus)

    anonymous = assignment.anonymize_students?

    # Remove the earlier attachment and re-create it if it's "stale"
    if attachment
      stale = (attachment.locked != anonymous)
      stale ||= (attachment.created_at < Setting.get('submission_zip_ttl_minutes', '60').to_i.minutes.ago)
      stale ||= (attachment.created_at < (updated_at || assignment.submissions.maximum(:submitted_at)))
      if stale
        attachment.destroy_permanently_plus
        attachment = nil
      end
    end

    if !attachment
      attachment = assignment.attachments.build(:display_name => 'submissions.zip')
      attachment.workflow_state = 'to_be_zipped'
      attachment.file_state = '0'
      attachment.user = @current_user
      attachment.locked = anonymous
      attachment.save!

      ContentZipper.send_later_enqueue_args(:process_attachment, {
        priority: Delayed::LOW_PRIORITY,
        max_attempts: 1
      }, attachment)
    end

    attachment
  end

  def rubric_assessment_json(rubric_assessment)
    hash = {}
    rubric_assessment.data&.each do |rating|
      hash[rating[:criterion_id]] = rating.slice(:points, :comments)
    end
    hash
  end

  def provisional_grade_json(provisional_grade, submission, assignment, current_user, includes = [])
    json = provisional_grade.grade_attributes
    json.merge!(speedgrader_url: speed_grader_url(submission, assignment, provisional_grade, current_user))
    if includes.include?('submission_comments')
      json['submission_comments'] = submission_comments_json(provisional_grade.submission_comments, current_user)
    end
    if assignment.can_view_other_grader_identities?(current_user)
      if includes.include?('rubric_assessment')
        json['rubric_assessments'] = provisional_grade.rubric_assessments.map do |ra|
          ra.as_json(:methods => [:assessor_name], :include_root => false)
        end
      end
    else
      json.merge!(anonymous_grader_id: assignment.grader_ids_to_anonymous_ids[json.delete(:scorer_id).to_s])
    end

    if includes.include?('crocodoc_urls') && assignment.can_view_student_names?(current_user)
      json['crocodoc_urls'] = submission.versioned_attachments.map do |a|
        provisional_grade.attachment_info(current_user, a)
      end
    end
    json
  end

  def submission_provisional_grades_json(submission, assignment, current_user, includes)
    provisional_grades = submission.provisional_grades
    if assignment.permits_moderation?(current_user)
      provisional_grades = provisional_grades.sort_by { |pg| pg.final ? CanvasSort::Last : pg.created_at }
    else
      provisional_grades = provisional_grades.select { |pg| pg.scorer_id == current_user.id }
    end

    provisional_grades.map do |provisional_grade|
      provisional_grade_json(provisional_grade, submission, assignment, current_user, includes)
    end
  end

  private

  def show_originality_reports?(submission)
    submission.originality_reports.present?
  end

  def speed_grader_url(submission, assignment, provisional_grade, current_user)
    anchor = { provisional_grade_id: provisional_grade.id }
    if assignment.can_view_student_names?(current_user)
      anchor[:student_id] = submission.user_id
    else
      anchor[:anonymous_id] = submission.anonymous_id
    end
    speed_grader_course_gradebook_url(
      course_id: assignment.context.id,
      assignment_id: assignment.id,
      anchor: anchor.to_json
    )
  end
end
