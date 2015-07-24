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

module Api::V1::Submission
  include Api::V1::Json
  include Api::V1::Assignment
  include Api::V1::Attachment
  include Api::V1::DiscussionTopics
  include Api::V1::Course
  include Api::V1::User
  include Api::V1::SubmissionComment

  def submission_json(submission, assignment, user, session, context = nil, includes = [])
    context ||= assignment.context
    hash = submission_attempt_json(submission, assignment, user, session, context)

    if includes.include?("submission_history")
      hash['submission_history'] = []
      submission.submission_history.each do |ver|
        ver.without_versioned_attachments do
          hash['submission_history'] << submission_attempt_json(ver, assignment, user, session, context)
        end
      end
    end

    if includes.include?("submission_comments")
      hash['submission_comments'] = submission_comments_json(submission.comments_for(@current_user), user)
    end

    if includes.include?("rubric_assessment") && submission.rubric_assessment && submission.grants_right?(user, :read_grade)
      ra = submission.rubric_assessment.data
      hash['rubric_assessment'] = {}
      ra.each { |rating| hash['rubric_assessment'][rating[:criterion_id]] = rating.slice(:points, :comments) }
    end

    if includes.include?("assignment")
      hash['assignment'] = assignment_json(assignment, user, session)
    end

    if includes.include?("course")
      hash['course'] = course_json(submission.context, user, session, ['html_url'], nil)
    end

    if includes.include?("html_url")
      hash['html_url'] = course_assignment_submission_url(submission.context.id, assignment.id, submission.user.id)
    end

    if includes.include?("user")
      hash['user'] = user_json(submission.user, user, session, ['avatar_url'], submission.context, nil)
    end

    if includes.include?("visibility")
      hash['assignment_visible'] = submission.assignment_visible_to_user?(submission.user)
    end

    hash
  end

  SUBMISSION_JSON_FIELDS = %w(id user_id url score grade excused attempt submission_type submitted_at body assignment_id graded_at grade_matches_current_submission grader_id workflow_state).freeze
  SUBMISSION_JSON_METHODS = %w(late).freeze
  SUBMISSION_OTHER_FIELDS = %w(attachments discussion_entries).freeze

  def submission_attempt_json(attempt, assignment, user, session, context = nil)
    context ||= assignment.context

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

    hash = api_json(attempt, user, session, :only => json_fields, :methods => json_methods)
    if hash['body'].present?
      hash['body'] = api_user_content(hash['body'], context, user)
    end

    preview_args = { 'preview' => '1' }
    preview_args['version'] = attempt.version_number
    hash['preview_url'] = course_assignment_submission_url(
      context, assignment, attempt[:user_id], preview_args)

    unless attempt.media_comment_id.blank?
      hash['media_comment'] = media_comment_json(:media_id => attempt.media_comment_id, :media_type => attempt.media_comment_type)
    end

    if attempt.turnitin_data.present? && attempt.grants_right?(@current_user, :view_turnitin_report)
      turnitin_hash = attempt.turnitin_data.dup
      turnitin_hash.delete(:last_processed_attempt)
      hash['turnitin_data'] = turnitin_hash
    end

    if other_fields.include?('attachments')
      attachments = attempt.versioned_attachments.dup
      attachments << attempt.attachment if attempt.attachment && attempt.attachment.context_type == 'Submission' && attempt.attachment.context_id == attempt.id
      hash['attachments'] = attachments.map do |attachment|
        attachment.skip_submission_attachment_lock_checks = true
        atjson = attachment_json(attachment, user, {},
                                 submission_attachment: true,
                                 include: ['preview_url'])
        attachment.skip_submission_attachment_lock_checks = false
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
  # Note that this timestamp will be ignored if the attachment is 1 hour old.
  #
  # @return [Attachment] The attachment that contains the archive.
  def submission_zip(assignment, updated_at = nil)
    attachments = assignment.attachments.where({
      display_name: 'submissions.zip',
      workflow_state: %w[to_be_zipped zipping zipped errored unattached],
      user_id: @current_user
    }).order(:created_at).to_a

    attachment = attachments.pop
    attachments.each { |a| a.destroy! }

    # Remove the earlier attachment and re-create it if it's "stale"
    if attachment
      created_at = attachment.created_at
      updated_at ||= assignment.submissions.map { |s| s.submitted_at }.compact.max

      if created_at < 1.hour.ago || (updated_at && created_at < updated_at)
        attachment.destroy!
        attachment = nil
      end
    end

    if !attachment
      attachment = assignment.attachments.build(:display_name => 'submissions.zip')
      attachment.workflow_state = 'to_be_zipped'
      attachment.file_state = '0'
      attachment.user = @current_user
      attachment.save!

      ContentZipper.send_later_enqueue_args(:process_attachment, {
        priority: Delayed::LOW_PRIORITY,
        max_attempts: 1
      }, attachment)
    end

    attachment
  end
end
