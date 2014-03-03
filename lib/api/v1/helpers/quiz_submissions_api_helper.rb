#
# Copyright (C) 2012 Instructure, Inc.
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

module Api::V1::Helpers::QuizSubmissionsApiHelper
  protected

  def require_overridden_quiz
    @quiz = @quiz.overridden_for(@current_user)
  end

  def require_quiz_submission
    collection = @quiz ? @quiz.quiz_submissions : QuizSubmission
    id = params[:quiz_submission_id] || params[:id] || ''
    query = {}

    if id.to_s == 'self'
      query[:user_id] = @current_user.id
    else
      query[:id] = id.to_i
    end

    unless @quiz_submission = collection.where(query).first
      raise ActiveRecord::RecordNotFound
    end
  end

  def prepare_service
    participant = QuizParticipant.new(@current_user, temporary_user_code)
    participant.access_code = params[:access_code]
    participant.ip_address = request.remote_ip
    participant.validation_token = params[:validation_token]

    @service = QuizSubmissionService.new(participant)
  end
end
