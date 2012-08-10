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

# @API Submissions
#
# @object Submission
#     {
#       // The submission's assignment id
#       assignment_id: 23,
#
#       // The submission's assignment (see the assignments API) (optional)
#       assignment: Assignment
#
#       // The submission's course (see the course API) (optional)
#       course: Course
#
#       // This is the submission attempt number.
#       attempt: 1,
#
#       // The content of the submission, if it was submitted directly in a
#       // text field.
#       body: "There are three factors too...",
#
#       // The grade for the submission, translated into the assignment grading
#       // scheme (so a letter grade, for example).
#       grade: "A-",
#
#       // A boolean flag which is false if the student has re-submitted since
#       // the submission was last graded.
#       grade_matches_current_submission: true,
#
#       // URL to the submission. This will require the user to log in.
#       html_url: "http://example.com/courses/255/assignments/543/submissions/134",
#
#       // URL to the submission preview. This will require the user to log in.
#       preview_url: "http://example.com/courses/255/assignments/543/submissions/134?preview=1",
#
#       // The raw score
#       score: 13.5
#
#       // Associated comments for a submission (optional)
#       submission_comments: [
#         {
#           author_id: 134
#           author_name: "Toph Beifong",
#           comment: "Well here's the thing...",
#           created_at: "2012-01-01T01:00:00Z",
#           media_comment: {
#             content-type: "audio/mp4",
#             display_name: "something",
#             media_id: "3232",
#             media_type: "audio",
#             url:  "http://example.com/media_url"
#           }
#         }
#       ],
#
#       // The types of submission
#       // ex: ("online_text_entry"|"online_url"|"online_upload"|"media_recording")
#       submission_type: "online_text_entry",
#
#       // The timestamp when the assignment was submitted
#       submitted_at: "2012-01-01T01:00:00Z",
#
#       // The URL of the submission (for "online_url" submissions).
#       url: null,
#
#       // The id of the user who created the submission
#       user_id: 134
#
#       // The submissions user (see user API) (optional)
#       user: User
#     }
#
class SubmissionsController < ApplicationController
  include GoogleDocs
  before_filter :get_course_from_section, :only => :create
  before_filter :require_context

  include Api::V1::Submission
  
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
    if @context_enrollment && @context_enrollment.is_a?(ObserverEnrollment) && @context_enrollment.associated_user_id
      id = @context_enrollment.associated_user_id
    else
      id = @current_user.id
    end
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
    # can't just check the permission, because peer reviewiers can never read the grade
    if @assignment.muted? && !@submission.grants_right?(@current_user, :read_grade)
      @visible_rubric_assessments = []
    else
      @visible_rubric_assessments = @submission.rubric_assessments.select{|a| a.grants_rights?(@current_user, session, :read)[:read]}.sort_by{|a| [a.assessment_type == 'grading' ? '0' : '1', a.assessor_name] }
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

  API_SUBMISSION_TYPES = {
    "online_text_entry" => ["body"],
    "online_url" => ["url"],
    "online_upload" => ["file_ids"],
    "media_recording" => ["media_comment_id", "media_comment_type"],
  }

  # @API Submit an assignment
  #
  # Make a submission for an assignment. You must be enrolled as a student in
  # the course/section to do this.
  #
  # All online turn-in submission types are supported in this API. However,
  # there are a few things that are not yet supported:
  #
  # * Files can be submitted based on a file ID of a user or group file. However, there is no API yet for listing the user and group files, or uploading new files via the API. A file upload API is coming soon.
  # * Media comments can be submitted, however, there is no API yet for creating a media comment to submit.
  # * Integration with Google Docs is not yet supported.
  #
  # @argument comment[text_comment] Include a textual comment with the submission.
  #
  # @argument submission[submission_type] [Required, "online_text_entry"|"online_url"|"online_upload"|"media_recording"]
  #   The type of submission being made. The assignment submission_types must
  #   include this submission type as an allowed option, or the submission will be rejected with a 400 error.
  #
  #   The submission_type given determines which of the following parameters is
  #   used. For instance, to submit a URL, submission[submission_type] must be
  #   set to "online_url", otherwise the submission[url] parameter will be
  #   ignored.
  #
  # @argument submission[body] Submit the assignment as an HTML document
  #   snippet. Note this HTML snippet will be sanitized using the
  #   same ruleset as a submission made from the Canvas web UI. The sanitized
  #   HTML will be returned in the response as the submission body. Requires a
  #   submission_type of "online_text_entry".
  #
  # @argument submission[url] Submit the assignment as a URL. The URL scheme
  #   must be "http" or "https", no "ftp" or other URL schemes are allowed. If no
  #   scheme is given (e.g. "www.example.com") then "http" will be assumed.
  #   Requires a submission_type of "online_url".
  #
  # @argument submission[file_ids][] Submit the assignment as a set of
  #   one or more previously uploaded files residing in the submitting user's
  #   files section (or the group's files section, for group assignments).
  #
  #   To upload a new file to submit, see the submissions {api:SubmissionsApiController#create_file Upload a file API}.
  #
  #   Requires a submission_type of "online_upload".
  #
  # @argument submission[media_comment_id] The media comment id to submit.
  #   Media comment ids can be submitted via this API, however, note that there
  #   is not yet an API to generate or list existing media comments, so this
  #   functionality is currently of limited use.
  #
  #   Requires a submission_type of "media_recording".
  #
  # @argument submission[media_comment_type] ["audio"|"video"] The type of media comment being submitted.
  #
  def create
    params[:submission] ||= {}
    @assignment = @context.assignments.active.find(params[:assignment_id])
    if authorized_action(@assignment, @current_user, :submit)
      if @assignment.locked_for?(@current_user) && !@assignment.grants_right?(@current_user, nil, :update)
        flash[:notice] = t('errors.can_not_submit_locked_assignment', "You can't submit an assignment when it is locked")
        redirect_to named_context_url(@context, :context_assignment_user, @assignment.id)
        return
      end
      @group = @assignment.group_category.group_for(@current_user) if @assignment.has_group_category?

      if api_request?
        # Verify submission_type is valid, and allowed by the assignment.
        # This should probably happen for non-api submissions as well, but
        # that'll take some further investigation/testing.
        submission_type = params[:submission][:submission_type]
        unless API_SUBMISSION_TYPES.key?(submission_type) && @assignment.submission_types_array.include?(submission_type)
          return render(:json => { :message => "Invalid submission[submission_type] given" }, :status => 400)
        end

        submission_params = (['submission_type'] + API_SUBMISSION_TYPES[submission_type]).sort
        params[:submission].slice!(*submission_params)
        if params[:submission].keys.sort != submission_params
          return render(:json => { :message => "Invalid parameters for submission_type #{submission_type}. Required: #{API_SUBMISSION_TYPES[submission_type].map { |p| "submission[#{p}]" }.join(", ") }" }, :status => 400)
        end
        params[:submission][:comment] = params[:comment].try(:delete, :text_comment)
      end

      if params[:submission][:file_ids].is_a?(Array)
        attachment_ids = params[:submission][:file_ids]
      else
        attachment_ids = (params[:submission][:attachment_ids] || "").split(",")
      end
      attachment_ids = attachment_ids.select(&:present?)
      params[:submission][:attachments] = []
      attachment_ids.each do |id|
        params[:submission][:attachments] << @current_user.attachments.active.find_by_id(id) if @current_user
        params[:submission][:attachments] << @group.attachments.active.find_by_id(id) if @group
        params[:submission][:attachments].compact!
      end
      if !api_request? && params[:attachments] && params[:submission][:submission_type] == 'online_upload'
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

        # require at least one file to be attached
        if params[:attachments].blank?
          flash[:error] = t('errors.no_attached_file', "You must attach at least one file to this assignment")
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
      elsif !api_request? && params[:google_doc] && params[:google_doc][:document_id] && params[:submission][:submission_type] == "google_doc"
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

      if api_request? && submission_type == 'online_upload' && params[:submission][:attachments].blank?
        return render(:json => { :message => "No valid file ids given" }, :status => :bad_request)
      end

      begin
        @submission = @assignment.submit_homework(@current_user, params[:submission])
      rescue ActiveRecord::RecordInvalid => e
        respond_to do |format|
          format.html {
            flash[:error] = t('errors.assignment_submit_fail', "Assignment failed to submit")
            redirect_to course_assignment_url(@context, @assignment)
          }
          format.json { render :json => e.record.errors.to_json, :status => :bad_request }
        end
        return
      end
      respond_to do |format|
        if @submission.save
          log_asset_access(@assignment, "assignments", @assignment_group, 'submit')
          format.html {
            flash[:notice] = t('assignment_submit_success', 'Assignment successfully submitted.')
            redirect_to course_assignment_url(@context, @assignment)
          }
          format.json {
            if api_request?
              render :json => submission_json(@submission, @assignment, @current_user, session, @context, %{submission_comments attachments}), :status => :created, :location => api_v1_course_assignment_submission_url(@context, @assignment, @current_user)
            else
              render :json => @submission.to_json(:include => :submission_comments), :status => :created, :location => course_gradebook_url(@submission.assignment.context)
            end
          }
        else
          format.html {
            flash[:error] = t('errors.assignment_submit_fail', "Assignment failed to submit")
            render :action => "show", :id => @submission.assignment.context.id
          }
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

  def resubmit_to_turnitin
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      @assignment = @context.assignments.active.find(params[:assignment_id])
      @submission = @assignment.submissions.find_by_user_id(params[:submission_id])
      @submission.resubmit_to_turnitin
      respond_to do |format|
        format.html { 
          flash[:notice] = t('resubmitted_to_turnitin', "Successfully resubmitted to turnitin.")
          redirect_to named_context_url(@context, :context_assignment_submission_url, @assignment.id, @submission.user_id)
        }
        format.json { render :nothing => true, :status => :no_content }
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
      params[:submission][:commenter] = @current_user
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
          :commenter => @current_user,
          :assessment_request => @request,
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

          json_args = Submission.json_serialization_full_parameters({
            :exclude => @assignment.grants_right?(@current_user, session, :grade) ? [:grade, :score, :turnitin_data] : [],
            :except => [:quiz_submission,:submission_history],
            :comments => @context_enrollment.admin? ? :submission_comments : :visible_submission_comments
          }).merge(:permissions => { :user => @current_user, :session => session, :include_permissions => false })
          format.json { 
            render :json => @submissions.to_json(json_args), :status => :created, :location => course_gradebook_url(@submission.assignment.context)
          }
          format.text { 
            render :json => @submissions.to_json(json_args), :status => :created, :location => course_gradebook_url(@submission.assignment.context)
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
    @attachments = @assignment.attachments.find(:all, :conditions => ["display_name='submissions.zip' AND workflow_state IN ('to_be_zipped', 'zipping', 'zipped', 'errored') AND user_id=?", @current_user.id], :order => :created_at)
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
      @attachment.user = @current_user
      @attachment.save!
      ContentZipper.send_later_enqueue_args(:process_attachment, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1 }, @attachment)
      render :json => @attachment.to_json
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
