#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Api::V1::SubmissionComment
  def submission_comment_json(submission_comment, user)
    sc_hash = submission_comment.as_json(
      :include_root => false,
      :only => %w(id author_id author_name created_at edited_at comment)
    )

    if submission_comment.media_comment?
      sc_hash['media_comment'] = media_comment_json(
        :media_id => submission_comment.media_comment_id,
        :media_type => submission_comment.media_comment_type
      )
    end

    sc_hash['attachments'] = submission_comment.attachments.map do |a|
      attachment_json(a, user)
    end unless submission_comment.attachments.blank?
    if submission_comment.grants_right?(@current_user, :read_author)
      sc_hash['author'] = user_display_json(submission_comment.author, submission_comment.context)
    else
      if sc_hash.delete('avatar_path')
        sc_hash['avatar_path'] = User.default_avatar_fallback
      end
      sc_hash.merge!({
                      author: {},
                      author_id: nil,
                      author_name: I18n.t("Anonymous User")
                     })
    end
    sc_hash
  end

  def submission_comments_json(submission_comments, user)
    submission_comments.map{ |submission_comment| submission_comment_json(submission_comment, user) }
  end

  def anonymous_moderated_submission_comments(assignment:, submissions:, submission_comments:, current_user:, course:, avatars:)
    @comment_methods ||= avatars ? [:avatar_path] : []
    @comment_fields ||= %i(attachments author_id author_name cached_attachments comment created_at
                           draft group_comment_id id media_comment_id media_comment_type)

    comments = visible_submission_comments(
      assignment: assignment,
      current_user: current_user,
      submission_comments: submission_comments,
      submissions: submissions,
      course: course
    )
    comments.map do |comment|
      json = comment.as_json(include_root: false, methods: @comment_methods, only: @comment_fields)
      author_id = comment.author_id.to_s

      json[:publishable] = comment.publishable_for?(current_user)
      if (
          anonymous_students?(current_user: current_user, assignment: assignment) &&
          student_ids_to_anonymous_ids(current_user: current_user, submissions: submissions, assignment: assignment, course: course).key?(author_id)
      )
        json.delete(:author_id)
        json.delete(:author_name)
        json[:anonymous_id] = student_ids_to_anonymous_ids(current_user: current_user, submissions: submissions, assignment: assignment, course: course)[author_id]
        json[:avatar_path] = User.default_avatar_fallback if avatars
      elsif anonymous_graders?(current_user: current_user, assignment: assignment) && assignment.grader_ids_to_anonymous_ids.key?(author_id)
        json.delete(:author_id)
        json[:anonymous_id] = assignment.grader_ids_to_anonymous_ids[author_id]
        unless author_id == current_user.id.to_s
          json[:avatar_path] = User.default_avatar_fallback if avatars
          json.delete(:author_name)
        end
      end

      json
    end
  end

  private

  def anonymous_students?(current_user:, assignment:)
    return @anonymous_students if defined? @anonymous_students
    @anonymous_students = !assignment.can_view_student_names?(current_user)
  end

  def anonymous_graders?(current_user:, assignment:)
    return @anonymous_graders if defined? @anonymous_graders
    @anonymous_graders = !assignment.can_view_other_grader_identities?(current_user)
  end

  def grader_comments_hidden?(current_user:, assignment:)
    return @grader_comments_hidden if defined? @grader_comments_hidden
    @grader_comments_hidden = !assignment.can_view_other_grader_comments?(current_user)
  end

  def visible_submission_comments(submission_comments:, submissions:, current_user:, assignment:, course:)
    return submission_comments unless grader_comments_hidden?(current_user: current_user, assignment: assignment)
    submission_comments.reject do |submission_comment|
      other_grader?(
        user_id: submission_comment.author_id,
        current_user: current_user,
        course: course,
        assignment: assignment,
        submissions: submissions
      )
    end
  end

  def student_ids_to_anonymous_ids(current_user:, assignment:, course:, submissions:)
    return @student_ids_to_anonymous_ids if defined? @student_ids_to_anonymous_ids
    # ensure each student has membership, even without a submission
    students = students(current_user: current_user, assignment: assignment, course: course)
    @student_ids_to_anonymous_ids = students.each_with_object({}) {|student, map| map[student.id.to_s] = nil}
    submissions.each do |submission|
      @student_ids_to_anonymous_ids[submission.user_id.to_s] = submission.anonymous_id
    end
    @student_ids_to_anonymous_ids
  end

  def students(course:, assignment:, current_user:)
    @students ||= begin
      includes = gradebook_includes(user: current_user, course: course)
      assignment.representatives(current_user, includes: includes)
    end
  end

  def other_grader?(user_id:, current_user:, course:, assignment:, submissions:)
    anonymous_ids = student_ids_to_anonymous_ids(
      current_user: current_user,
      assignment: assignment,
      course: course,
      submissions: submissions
    )
    !anonymous_ids.key?(user_id.to_s) && user_id != current_user.id
  end
end
