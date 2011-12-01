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

class SubmissionsController < ApplicationController
  include GoogleDocs
  before_filter :require_context
  
  def index
    @assignment = @context.assignments.active.find(params[:assignment_id])
    if authorized_action(@assignment, @current_user, :grade)
      if params[:zip]
        submission_zip
      else
        respond_to do |format|
          format.html { redirect_to named_context_url(@context, :context_assignment_url, @assignment.id) }
        end
      end
    end
  end
  
  def show
    @assignment = @context.assignments.active.find(params[:assignment_id])
    @user = @context.all_students.find(params[:id]) rescue nil
    if !@user
      flash[:error] = t('errors.student_not_enrolled', "The specified user is not a student in this course")
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_assignment_url, @assignment.id) }
        format.json { render :json => {:errors => t('errors.student_not_enrolled_id', "The specified user (%{id}) is not a student in this course", :id => params[:id])}}
      end
      return
    end
    @submission = @assignment.find_submission(@user) #_params[:.find(:first, :conditions => {:assignment_id => @assignment.id, :user_id => params[:id]})
    @submission ||= @context.submissions.build(:user => @user, :assignment_id => @assignment.id)
    @submission.grants_rights?(@current_user, session)
    @rubric_association = @assignment.rubric_association
    @rubric_association.assessing_user_id = @submission.user_id if @rubric_association
    @visible_rubric_assessments = @submission.rubric_assessments.select{|a| a.grants_rights?(@current_user, session, :read)[:read]}.sort_by{|a| [a.assessment_type == 'grading' ? '0' : '1', a.assessor_name] }

    unless @submission.grants_right?(@current_user, :read_grade)
      @visible_rubric_assessments = []
    end

    @assessment_request = @submission.assessment_requests.find_by_assessor_id(@current_user.id) rescue nil
    if authorized_action(@submission, @current_user, :read)
      respond_to do |format|
        json_handled = false
        if params[:preview]
          # this if was put it by ryan, it makes it so if they pass a ?preview=true&version=2 in the url that it will load the second version in the
          # submission_history of that submission
          if params[:version]
            @submission = @submission.submission_history[params[:version].to_i]
          end

          @headers = false
          if @assignment.quiz && @context.class.to_s == 'Course' && @context.user_is_student?(@current_user)
            format.html { redirect_to(named_context_url(@context, :context_quiz_url, @assignment.quiz.id, :headless => 1)) }
          elsif @submission.submission_type == "online_quiz" && @submission.quiz_submission_version
            format.html { redirect_to(named_context_url(@context, :context_quiz_history_url, @assignment.quiz.id, :user_id => @submission.user_id, :headless => 1, :version => @submission.quiz_submission_version)) }
          else
            format.html { render :action => "show_preview" }
          end
        elsif params[:download]
          if params[:comment_id]
            @attachment = @submission.submission_comments.find(params[:comment_id]).attachments.find{|a| a.id == params[:download].to_i }
          else
            @attachment = @submission.attachment if @submission.attachment_id == params[:download].to_i
            prior_attachment_id = @submission.submission_history.map(&:attachment_id).find{|a| a == params[:download].to_i }
            @attachment ||= Attachment.find_by_id(prior_attachment_id) if prior_attachment_id
            @attachment ||= @submission.attachments.find_by_id(params[:download]) if params[:download].present?
            @attachment ||= @submission.submission_history.map(&:versioned_attachments).flatten.find{|a| a.id == params[:download].to_i }
          end
          raise ActiveRecord::RecordNotFound unless @attachment
          format.html {
            if @attachment.context == @submission || @attachment.context == @assignment
              redirect_to(file_download_url(@attachment, :verifier => @attachment.uuid, :inline => params[:inline]))
            else
              redirect_to(named_context_url(@attachment.context, :context_file_download_url, @attachment, :verifier => @attachment.uuid, :inline => params[:inline]))
            end
          }
          json_handled = true
          format.json { render :json => @attachment.to_json(:permissions => {:user => @current_user}) }
        else
          @submission.limit_comments(@current_user, session)
          format.html
        end
        if !json_handled
          format.json { 
            @submission.limit_comments(@current_user, session)
            excludes = @assignment.grants_right?(@current_user, session, :grade) ? [:grade, :score] : []
            render :json => @submission.to_json(
              Submission.json_serialization_full_parameters(
                :exclude => excludes,
                :except  => %w(quiz_submission submission_history)
              ).merge(:permissions => {:user => @current_user, :session => session, :include_permissions => false})
            )
          }
        end
      end
    end
  end
  
  def create
    @assignment = @context.assignments.active.find(params[:assignment_id])
    if authorized_action(@assignment, @current_user, :submit)
      if @assignment.locked_for?(@current_user) && !@assignment.grants_right?(@current_user, nil, :update)
        flash[:notice] = t('errors.can_not_submit_locked_assignment', "You can't submit an assignment when it is locked")
        redirect_to named_context_url(@context, :context_assignment_user, @assignment.id)
        return
      end
      @group = @assignment.group_category.groups.active.to_a.find{|g| g.users.include?(@current_user)} if @assignment.has_group_category?
      attachment_ids = (params[:submission][:attachment_ids] || "").split(",").select(&:present?)
      params[:submission][:attachments] = []
      attachment_ids.each do |id|
        params[:submission][:attachments] << @current_user.attachments.active.find_by_id(id) if @current_user
        params[:submission][:attachments] << @group.attachments.active.find_by_id(id) if @group
        params[:submission][:attachments].compact!
      end
      if params[:attachments] && params[:submission][:submission_type] == 'online_upload'
        # check that the attachments are in allowed formats. we do this here
        # so the attachments don't get saved and possibly uploaded to
        # S3, etc. if they're invalid.
        if @assignment.allowed_extensions.present? && params[:attachments].any? {|i, a|
            !a[:uploaded_data].empty? &&
            !@assignment.allowed_extensions.include?((a[:uploaded_data].split('.').last || '').downcase)
          }
          flash[:error] = t('errors.invalid_file_type', "Invalid file type")
          return redirect_to named_context_url(@context, :context_assignment_url, @assignment)
        end
        params[:attachments].each do |idx, attachment|
          if attachment[:uploaded_data] && !attachment[:uploaded_data].is_a?(String)
            attachment[:user] = @current_user
            if @group
              attachment = @group.attachments.new(attachment)
            else
              attachment = @current_user.attachments.new(attachment)
            end
            attachment.save
            params[:submission][:attachments] << attachment
          end
        end
      elsif params[:google_doc] && params[:google_doc][:document_id] && params[:submission][:submission_type] == "google_doc"
        params[:submission][:submission_type] = 'online_upload'
        doc_response, display_name, file_extension = google_docs_download(params[:google_doc][:document_id])
        unless doc_response && doc_response.is_a?(Net::HTTPOK)
          # couldn't get document
          flash[:error] = t('errors.assignment_submit_fail', "Assignment failed to submit")
          redirect_to course_assignment_url(@context, @assignment)
          return
        end
        filename = "google_doc_#{Time.now.strftime("%Y%m%d%H%M%S")}#{@current_user.id}.#{file_extension}"
        path = File.join("tmp", filename)
        f = File.new(path, 'wb')
        f.write doc_response.body
        f.close

        require 'action_controller'
        require 'action_controller/test_process.rb'
        @attachment = @assignment.attachments.new(
          :uploaded_data => ActionController::TestUploadedFile.new(path, doc_response.content_type, true), 
          :display_name => "#{display_name}",
          :user => @current_user
        )
        @attachment.save!
        params[:submission][:attachments] << @attachment
      end
      params[:submission][:attachments] = params[:submission][:attachments].compact.uniq
      begin
        @submission = @assignment.submit_homework(@current_user, params[:submission])
      rescue ActiveRecord::RecordInvalid => e
        respond_to do |format|
          flash[:error] = t('errors.assignment_submit_fail', "Assignment failed to submit")
          format.html { redirect_to course_assignment_url(@context, @assignment) }
          format.json { render :json => e.record.errors.to_json, :status => :bad_request }
        end
        return
      end
      respond_to do |format|
        if @submission.save
          log_asset_access(@assignment, "assignments", @assignment_group, 'submit')
          flash[:notice] = t('assignment_submit_success', 'Assignment successfully submitted.')
          format.html { redirect_to course_assignment_url(@context, @assignment) }
          format.json { render :json => @submission.to_json(:include => :submission_comments), :status => :created, :location => course_gradebook_url(@submission.assignment.context) }
        else
          flash[:error] = t('errors.assignment_submit_fail', "Assignment failed to submit")
          format.html { render :action => "show", :id => @submission.assignment.context.id }
          format.json { render :json => @submission.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def turnitin_report
    @assignment = @context.assignments.active.find(params[:assignment_id])
    @submission = @assignment.submissions.find_by_user_id(params[:submission_id])
    @asset_string = params[:asset_string]
    if authorized_action(@submission, @current_user, :read)
      url = @submission.turnitin_report_url(@asset_string, @current_user) rescue nil
      if url
        redirect_to url
      else
        flash[:notice] = t('errors.no_report', "Couldn't find a report for that submission item")
        redirect_to named_context_url(@context, :context_assignment_submission_url, @assignment.id, @submission.user_id)
      end
    end
  end
  
  def update
    @assignment = @context.assignments.active.find(params[:assignment_id])
    @user = @context.all_students.find(params[:id])
    @submission = @assignment.find_or_create_submission(@user)
    if params[:submission][:student_entered_score] && @submission.grants_right?(@current_user, session, :comment)#&& @submission.user == @current_user
      @submission.student_entered_score = params[:submission][:student_entered_score].to_f
      @submission.student_entered_score = nil if !params[:submission][:student_entered_score] || params[:submission][:student_entered_score] == "" || params[:submission][:student_entered_score] == "null"
      @submission.save
      render :json => @submission.to_json
      return
    end
    if authorized_action(@submission, @current_user, :comment)
      if params[:attachments]
        attachments = []
        params[:attachments].each do |idx, attachment|
          attachment[:user] = @current_user
          attachments << @assignment.attachments.create(attachment)
        end
        params[:submission][:comment_attachments] = attachments#.map{|a| a.id}.join(",")
      end
      unless @submission.grants_rights?(@current_user, session, :submit)[:submit]
        @request = @submission.assessment_requests.find_by_assessor_id(@current_user.id) if @current_user
        params[:submission] = {
          :comment => params[:submission][:comment],
          :comment_attachments => params[:submission][:comment_attachments],
          :media_comment_id => params[:submission][:media_comment_id],
          :media_comment_type => params[:submission][:media_comment_type],
          :assessment_request => @request,
          :commenter => @current_user,
          :group_comment => params[:submission][:group_comment],
          :hidden => @assignment.muted? && @context_enrollment.admin?
        }
      end
      begin
        @submissions = @assignment.update_submission(@user, params[:submission])
      rescue => e
        ErrorReport.log_exception(:submissions, e)
        logger.error(e)
      end
      respond_to do |format|
        if @submissions
          @submissions.each{|s| s.limit_comments(@current_user, session) unless @submission.grants_rights?(@current_user, session, :submit)[:submit] }
          @submissions = @submissions.select{|s| s.grants_right?(@current_user, session, :read) }
          flash[:notice] = t('assignment_submitted', 'Assignment submitted.')
          format.html { redirect_to course_assignment_url(@context, @assignment) }
          excludes = @assignment.grants_right?(@current_user, session, :grade) ? [:grade, :score] : []
          comments_type = @context_enrollment.admin? ? :submission_comments : :visible_submission_comments
          format.json { 
            render :json => @submissions.to_json(Submission.json_serialization_full_parameters(:exclude => excludes, :except => [:quiz_submission,:submission_history], :comments => comments_type).merge(:permissions => {:user => @current_user, :session => session, :include_permissions => false})), :status => :created, :location => course_gradebook_url(@submission.assignment.context)
          }
          format.text { 
            render :json => @submissions.to_json(Submission.json_serialization_full_parameters(:exclude => excludes, :except => [:quiz_submission,:submission_history], :comments => comments_type).merge(:permissions => {:user => @current_user, :session => session, :include_permissions => false})), :status => :created, :location => course_gradebook_url(@submission.assignment.context)
          }
        else
          @error_message = t('errors_update_failed', "Update Failed")
          flash[:error] = @error_message
          format.html { render :action => "show", :id => @assignment.context.id }
          format.json { render :json => {:errors => {:base => @error_message}}.to_json, :status => :bad_request }
          format.text { render :json => {:errors => {:base => @error_message}}.to_json, :status => :bad_request }
        end
      end
    end
  end

  protected

  def submission_zip
    @attachments = @assignment.attachments.find_all_by_display_name("submissions.zip").select{|a| ['to_be_zipped', 'zipping', 'zipped', 'errored'].include?(a.workflow_state) }.sort_by{|a| a.created_at }
    @attachment = @attachments.pop
    @attachments.each{|a| a.destroy! }
    if @attachment && (@attachment.created_at < 1.hour.ago || @attachment.created_at < (@assignment.submissions.map{|s| s.submitted_at}.compact.max || @attachment.created_at))
      @attachment.destroy!
      @attachment = nil
    end
    if !@attachment
      @attachment = @assignment.attachments.build(:display_name => 'submissions.zip')
      @attachment.workflow_state = 'to_be_zipped'
      @attachment.file_state = '0'
      @attachment.save!
    end
    if params[:compile] && @attachment.to_be_zipped?
      ContentZipper.send_later_enqueue_args(:process_attachment, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1 }, @attachment)
      render :json => @attachment.to_json
    else
      respond_to do |format|
        if @attachment.zipped?
          if Attachment.s3_storage?
            format.html { redirect_to @attachment.cacheable_s3_url }
            format.zip { redirect_to @attachment.cacheable_s3_url }
          else
            cancel_cache_buster
            format.html { send_file(@attachment.full_filename, :type => @attachment.content_type, :disposition => 'inline') }
            format.zip { send_file(@attachment.full_filename, :type => @attachment.content_type, :disposition => 'inline') }
          end
          format.json { render :json => @attachment.to_json(:methods => :readable_size) }
        else
          flash[:notice] = t('still_zipping', "File zipping still in process...")
          format.html { redirect_to named_context_url(@context, :context_assignment_url, @assignment.id) }
          format.zip { redirect_to named_context_url(@context, :context_assignment_url, @assignment.id) }
          format.json { render :json => @attachment.to_json }
        end
      end
    end
  end
end
