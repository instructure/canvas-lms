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

# @API Quiz Submission Files
# @beta
#

class Quizzes::QuizSubmissionFilesController < ApplicationController
  include Api::V1::Submission

  before_action :require_user, :require_context

  # @API Upload a file
  # @beta
  #
  # Associate a new quiz submission file
  #
  # This API endpoint is the first step in uploading a quiz submission file.
  # See the {file:file_uploads.html File Upload Documentation} for details on
  # the file upload workflow as these parameters are interpreted as per the
  # documentation there.
  #
  # @argument name [String]
  #   The name of the quiz submission file
  #
  # @argument on_duplicate [String]
  #   How to handle duplicate names
  #
  # @example_response
  #   {
  #     "attachments": [
  #       {
  #         "upload_url": "https://some-bucket.s3.amazonaws.com/",
  #         "upload_params": {
  #           "key": "/users/1234/files/answer_pic.jpg",
  #           "acl": "private",
  #           "Filename": "answer_pic.jpg",
  #           "AWSAccessKeyId": "some_id",
  #           "Policy": "some_opaque_string",
  #           "Signature": "another_opaque_string",
  #           "Content-Type": "image/jpeg"
  #         }
  #       }
  #     ]
  #   }
  def create
    quiz = @context.quizzes.active.find(params[:quiz_id])
    quiz_submission = quiz.quiz_submissions.where(:user_id => @current_user).first
    raise ActiveRecord::RecordNotFound unless quiz_submission

    if authorized_action(quiz, @current_user, :submit)
      json =  api_attachment_preflight_json quiz_submission, request, :file_param => 'file'

      render :json => json
    end
  end

end
