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

class QuizSubmissionsController < ApplicationController
  protect_from_forgery :except => [:create, :backup]
  before_filter :require_context
  
  def index
    @quiz = @context.quizzes.find(params[:quiz_id])
    redirect_to named_context_url(@context, :context_quiz_url, @quiz.id)
  end
  
  # submits the quiz as final
  def create
    @quiz = @context.quizzes.find(params[:quiz_id])
    if @quiz.grants_right?(@current_user, :submit)
      @submission = @quiz.quiz_submissions.find_by_user_id(@current_user.id) if @current_user
      # If the submission is a preview, we don't add it to the user's submission history,
      # and it actually gets keyed by the temporary_user_code column instead of 
      preview = params[:preview] && @quiz.grants_right?(@current_user, session, :update)
      @submission = nil if preview
      if !@current_user || preview
        @submission = @quiz.quiz_submissions.find_by_temporary_user_code(temporary_user_code(false))
        @submission ||= @quiz.generate_submission(temporary_user_code(false) || @current_user, preview)
      else
        @submission ||= @quiz.generate_submission(@current_user, preview)
      end

      @submission.snapshot!(params)
      if !@submission.completed? && @submission.attempt == params[:attempt].to_i #&& !@submission.overdue?
        @submission.mark_completed
        hash = {}
        hash = @submission.submission_data if @submission.submission_data.is_a?(Hash) && @submission.submission_data[:attempt] == @submission.attempt
        params_hash = hash.deep_merge(params) rescue params
        @submission.submission_data = params_hash if !@submission.overdue?
        flash[:notice] = "You submitted this quiz late, and your answers may not have been recorded." if @submission.overdue?
        @submission.grade_submission
      end
      if preview
        redirect_to course_quiz_url(@context, @quiz, :preview => 1)
      else
        redirect_to course_quiz_url(@context, @quiz)
      end
    else
      redirect_to course_quiz_url(@context, @quiz)
    end
  end
  
  def backup
    @quiz = @context.quizzes.find(params[:quiz_id])
    preview = params[:preview] && @quiz.grants_right?(@current_user, session, :update)
    if preview || !@current_user
      @submission = @quiz.quiz_submissions.find_by_temporary_user_code(temporary_user_code(false))
    else
      @submission = @quiz.quiz_submissions.find_by_user_id(@current_user.id)
    end

    if preview || (@submission && @submission.temporary_user_code == temporary_user_code(false)) || (@submission && @submission.grants_right?(@current_user, session, :update))
      if !@submission.completed? && !@submission.overdue?
        @submission.backup_submission_data(params)
        render :json => {:backup => true}.to_json
        return
      end
    end
    render :json => {:backup => false}.to_json
  end
  
  def add_attempts
    @quiz = @context.quizzes.find(params[:quiz_id])
    @submission = @quiz.quiz_submissions.find(params[:quiz_submission_id])
    if authorized_action(@submission, @current_user, :add_attempts)
      @submission.extra_attempts ||= 0
      @submission.extra_attempts += params[:extra_attempts].to_i
      @submission.save!
      redirect_to named_context_url(@context, :context_quiz_history_url, @quiz, :user_id => @submission.user_id)
    end
  end
  
  def update
    @quiz = @context.quizzes.find(params[:quiz_id])
    @submission = @quiz.quiz_submissions.find(params[:id])
    if authorized_action(@submission, @current_user, :update_scores)
      @submission.update_scores(params)
      if params[:headless]
        redirect_to named_context_url(@context, :context_quiz_history_url, @quiz, :user_id => @submission.user_id, :version => @submission.version_number, :headless => 1, :score_updated => 1)
      else
        redirect_to named_context_url(@context, :context_quiz_history_url, @quiz, :user_id => @submission.user_id, :version => @submission.version_number)
      end
    end
  end
  
  def show
    @quiz = @context.quizzes.find(params[:quiz_id])
    @submission = @quiz.quiz_submissions.find(params[:id])
    if authorized_action(@submission, @current_user, :read)
      redirect_to named_context_url(@context, :context_quiz_history_url, @quiz.id, :user_id => @submission.user_id)
    end
  end

end
