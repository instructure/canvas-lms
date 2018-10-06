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

class SubmissionCommentsController < ApplicationController
  before_action :require_user

  def index
    submission = Submission.preload(assignment: :context, all_submission_comments: :author).find(params[:submission_id])
    return render_unauthorized_action if submission.assignment.anonymize_students?
    return render_unauthorized_action unless submission.grants_all_rights?(@current_user, :read_grade, :read_comments)

    render pdf: :index, locals: index_pdf_locals(submission)
  end

  def update
    submission_comment = SubmissionComment.find(params[:id])
    if authorized_action(submission_comment, @current_user, :update)
      submission_comment.updating_user = @current_user
      submission_comment.reload unless submission_comment.update(submission_comment_params)

      respond_to do |format|
        format.json { render json: submission_comment.as_json }
      end
    end
  end

  def destroy
    submission_comment = SubmissionComment.find(params[:id])
    if authorized_action(submission_comment, @current_user, :delete)
      submission_comment.updating_user = @current_user
      submission_comment.destroy
      respond_to do |format|
        format.json { render json: submission_comment }
      end
    end
  end

  private

  def submission_comment_params
    params.require(:submission_comment).permit(:draft, :comment)
  end

  # this is a workaround for i18nliner/i18n_extractor as they currently do
  # not support prawn templates.
  def index_pdf_locals(submission)
    submission_comments = submission.all_submission_comments.order(:created_at)
    student_name = submission.student.name
    {
      account_name: I18n.t("Account: %{account}", account: submission.assignment.course.account.name),
      assignment_title: I18n.t("Assignment: %{title}", title: submission.assignment.title),
      course_name: I18n.t("Course: %{course}", course: submission.assignment.course.name),
      draft: I18n.t('(draft)'),
      page_size: params[:page_size] || 'LETTER',
      score: submission.score ? I18n.t("Score: %{score}", score: submission.score) : I18n.t('Score: N/A'),
      student_name: student_name ? I18n.t("Student: %{name}", name: student_name) : I18n.t('Student: N/A'),
      submission_comments: submission_comments,
      timestamps_by_id: timestamps_by_id(submission_comments)
    }
  end

  def timestamps_by_id(submission_comments)
    submission_comments.order(:created_at).each_with_object({}) do |comment, timestamps_map|
      timestamps_map[comment.id] = I18n.t "(%{timestamp})", timestamp: datetime_string(comment.created_at, :full)
    end
  end
end
