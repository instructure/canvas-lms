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

class QuizSubmissionsApiController < ApplicationController
  include Api::V1::Submission

  before_filter :require_user, :require_context

  # not doing api documentation for this until there is more quiz_submission
  # api stuff to talk about
  def create_file
    quiz = @context.quizzes.active.find(params[:quiz_id])
    quiz_submission = quiz.quiz_submissions.where(:user_id => @current_user).first
    raise ActiveRecord::RecordNotFound unless quiz_submission

    if authorized_action(quiz, @current_user, :submit)
      api_attachment_preflight quiz_submission, request,
        :check_quota => true, :do_submit_to_scribd => false
    end
  end
end
