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
  protect_from_forgery :except => [:create, :backup, :record_answer]
  before_filter :require_context
  batch_jobs_in_actions :only => [:update, :create], :batch => { :priority => Delayed::LOW_PRIORITY }

  def index
    @quiz = @context.quizzes.find(params[:quiz_id])
    if params[:zip] && authorized_action(@quiz, @current_user, :grade)
      submission_zip
    else
      redirect_to named_context_url(@context, :context_quiz_url, @quiz.id)
    end
  end
  
  # submits the quiz as final
  def create
    @quiz = @context.quizzes.find(params[:quiz_id])
    if @quiz.access_code.present?
      session.delete(@quiz.access_code_key_for_user(@current_user))
    end
    if @quiz.ip_filter && !@quiz.valid_ip?(request.remote_ip)
      flash[:error] = t('errors.protected_quiz', "This quiz is protected and is only available from certain locations.  The computer you are currently using does not appear to be at a valid location for taking this quiz.")
    elsif @quiz.grants_right?(@current_user, :submit)
      # If the submission is a preview, we don't add it to the user's submission history,
      # and it actually gets keyed by the temporary_user_code column instead of 
      if @current_user.nil? || is_previewing?
        @submission = @quiz.quiz_submissions.find_by_temporary_user_code(temporary_user_code(false))
        @submission ||= @quiz.generate_submission(temporary_user_code(false) || @current_user, is_previewing?)
      else
        @submission = @quiz.quiz_submissions.find_by_user_id(@current_user.id) if @current_user.present?
        @submission ||= @quiz.generate_submission(@current_user, is_previewing?)
        if @submission.present? && !@submission.valid_token?(params[:validation_token])
          flash[:error] = t('errors.invalid_submissions', "This quiz submission could not be verified as belonging to you.  Please try again.")
          return redirect_to course_quiz_url(@context, @quiz, previewing_params)
        end
      end

      sanitized_params = @submission.sanitize_params(params)
      @submission.snapshot!(sanitized_params)
      if @submission.preview? || (@submission.untaken? && @submission.attempt == sanitized_params[:attempt].to_i)
        @submission.mark_completed
        hash = {}
        hash = @submission.submission_data if @submission.submission_data.is_a?(Hash) && @submission.submission_data[:attempt] == @submission.attempt
        params_hash = hash.deep_merge(sanitized_params) rescue sanitized_params
        @submission.submission_data = params_hash unless @submission.overdue?
        flash[:notice] = t('errors.late_quiz', "You submitted this quiz late, and your answers may not have been recorded.") if @submission.overdue?
        @submission.grade_submission
      end
    end
    if session.delete('lockdown_browser_popup')
      return render(:action => 'close_quiz_popup_window')
    end
    redirect_to course_quiz_url(@context, @quiz, previewing_params)
  end
  
  def backup
    @quiz = @context.quizzes.find(params[:quiz_id])
    if authorized_action(@quiz, @current_user, :submit)
      if @current_user.nil? || is_previewing?
        @submission = @quiz.quiz_submissions.find_by_temporary_user_code(temporary_user_code(false))
      else
        @submission = @quiz.quiz_submissions.find_by_user_id(@current_user.id)
        if @submission.present? && !@submission.valid_token?(params[:validation_token])
          if params[:action] == 'record_answer'
            flash[:error] = t('errors.invalid_submissions', "This quiz submission could not be verified as belonging to you.  Please try again.")
            return redirect_to polymorphic_path([@context, @quiz])
          else
            return render_json_unauthorized
          end
        end
      end

      if @quiz.ip_filter && !@quiz.valid_ip?(request.remote_ip)
      elsif is_previewing? || (@submission && @submission.temporary_user_code == temporary_user_code(false)) ||
                              (@submission && @submission.grants_right?(@current_user, session, :update))
        if !@submission.completed? && !@submission.overdue?
          if params[:action] == 'record_answer'
            if last_question = params[:last_question_id]
              params[:"_question_#{last_question}_read"] = true
            end

            @submission.backup_submission_data(params)
            next_page = params[:next_question_path] || course_quiz_take_path(@context, @quiz)
            return redirect_to next_page
          else
            @submission.backup_submission_data(params)
            render :json => {:backup => true,
                             :end_at => @submission && @submission.end_at,
                             :time_left => @submission && @submission.time_left}
            return
          end
        end
      end

      render :json => {:backup => false,
                       :end_at => @submission && @submission.end_at,
                       :time_left => @submission && @submission.time_left}
    end
  end

  def record_answer
    # temporary fix for CNVS-8651 while we rewrite front-end quizzes
    if request.get?
      @quiz = @context.quizzes.find(params[:quiz_id])
      user_id = @current_user && @current_user.id
      redirect_to polymorphic_url([@context, @quiz, :take], :user_id => user_id)
    else
      backup
    end
  end

  def extensions
    @quiz = @context.quizzes.find(params[:quiz_id])
    @student = @context.students.find(params[:user_id])
    @submission = @quiz.find_or_create_submission(@student || @current_user, nil, 'settings_only')
    if authorized_action(@submission, @current_user, :add_attempts)
      @submission.extra_attempts ||= 0
      @submission.extra_attempts = params[:extra_attempts].to_i if params[:extra_attempts]
      @submission.extra_time = params[:extra_time].to_i if params[:extra_time]
      @submission.manually_unlocked = params[:manually_unlocked] == '1' if params[:manually_unlocked]
      if @submission.extendable? && (params[:extend_from_now] || params[:extend_from_end_at]).to_i > 0
        if params[:extend_from_now].to_i > 0
          @submission.end_at = Time.now + params[:extend_from_now].to_i.minutes
        else
          @submission.end_at += params[:extend_from_end_at].to_i.minutes
        end
      end
      @submission.save!
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_quiz_history_url, @quiz, :user_id => @submission.user_id) }
        format.json { render :json => @submission.as_json(:include_root => false, :exclude => :submission_data, :methods => ['extendable?', :finished_in_words, :attempts_left]) }
      end
    end
  end
  
  def update
    @quiz = @context.quizzes.find(params[:quiz_id])
    @submission = @quiz.quiz_submissions.find(params[:id])
    if authorized_action(@submission, @current_user, :update_scores)
      @submission.update_scores(params)
      if params[:headless]
        redirect_to named_context_url(@context, :context_quiz_history_url, @quiz, :user_id => @submission.user_id, :version => (params[:submission_version_number] || @submission.version_number), :headless => 1, :score_updated => 1)
      else
        redirect_to named_context_url(@context, :context_quiz_history_url, @quiz, :user_id => @submission.user_id, :version => (params[:submission_version_number] || @submission.version_number))
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

  protected

  def is_previewing?
    @previewing ||= params[:preview] && @quiz.grants_right?(@current_user, session, :update)
  end

  def previewing_params
    is_previewing? ? { :preview => 1 } : {}
  end

  # TODO: this is mostly copied and pasted from submission_controller.rb. pull
  # out common code
  def submission_zip
    @attachments = @quiz.attachments.where(:display_name => 'submissions.zip', :workflow_state => ['to_be_zipped', 'zipping', 'zipped', 'errored', 'unattached'], :user_id => @current_user).order(:created_at).all
    @attachment = @attachments.pop
    @attachments.each{|a| a.destroy! }
    if @attachment && (@attachment.created_at < 1.hour.ago || @attachment.created_at < (@quiz.quiz_submissions.map{|s| s.finished_at}.compact.max || @attachment.created_at))
      @attachment.destroy!
      @attachment = nil
    end
    if !@attachment
      @attachment = @quiz.attachments.build(:display_name => 'submissions.zip')
      @attachment.workflow_state = 'to_be_zipped'
      @attachment.file_state = '0'
      @attachment.user = @current_user
      @attachment.save!
      ContentZipper.send_later_enqueue_args(:process_attachment, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1 }, @attachment)
      render :json => @attachment
    else
      respond_to do |format|
        if @attachment.zipped?
          if Attachment.s3_storage?
            format.html { redirect_to @attachment.cacheable_s3_inline_url }
            format.zip { redirect_to @attachment.cacheable_s3_inline_url }
          else
            cancel_cache_buster
            format.html { send_file(@attachment.full_filename, :type => @attachment.content_type_with_encoding, :disposition => 'inline') }
            format.zip { send_file(@attachment.full_filename, :type => @attachment.content_type_with_encoding, :disposition => 'inline') }
          end
          format.json { render :json => @attachment.as_json(:methods => :readable_size) }
        else
          flash[:notice] = t('still_zipping', "File zipping still in process...")
          format.html { redirect_to named_context_url(@context, :context_quiz_url, @quiz.id) }
          format.zip { redirect_to named_context_url(@context, :context_quiz_url, @quiz.id) }
          format.json { render :json => @attachment }
        end
      end
    end
  end
end
