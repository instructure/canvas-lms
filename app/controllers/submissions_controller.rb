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

require 'action_controller_test_process'

# @API Submissions
#
# @model MediaComment
#     {
#       "id": "MediaComment",
#       "description": "",
#       "properties": {
#         "content-type": {
#           "example": "audio/mp4",
#           "type": "string"
#         },
#         "display_name": {
#           "example": "something",
#           "type": "string"
#         },
#         "media_id": {
#           "example": "3232",
#           "type": "string"
#         },
#         "media_type": {
#           "example": "audio",
#           "type": "string"
#         },
#         "url": {
#           "example": "http://example.com/media_url",
#           "type": "string"
#         }
#       }
#     }
#
# @model SubmissionComment
#     {
#       "id": "SubmissionComment",
#       "description": "",
#       "properties": {
#         "id": {
#           "example": 37,
#           "type": "integer"
#         },
#         "author_id": {
#           "example": 134,
#           "type": "integer"
#         },
#         "author_name": {
#           "example": "Toph Beifong",
#           "type": "string"
#         },
#         "author": {
#           "description": "Abbreviated user object UserDisplay (see users API).",
#           "example": "{}",
#           "type": "string"
#         },
#         "comment": {
#           "example": "Well here's the thing...",
#           "type": "string"
#         },
#         "created_at": {
#           "example": "2012-01-01T01:00:00Z",
#           "type": "datetime"
#         },
#         "media_comment": {
#           "$ref": "MediaComment"
#         }
#       }
#     }
#
class SubmissionsController < ApplicationController
  include Submissions::ShowHelper
  before_filter :get_course_from_section, :only => :create
  before_filter :require_context

  include Api::V1::Submission

  def index
    @assignment = @context.assignments.active.find(params[:assignment_id])
    return render_unauthorized_action unless @assignment.user_can_read_grades?(@current_user, session)
    if params[:zip]
      generate_submission_zip(@assignment, @context)
    else
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_assignment_url, @assignment.id) }
      end
    end
  end

  rescue_from ActiveRecord::RecordNotFound, only: :show, with: :render_user_not_found
  def show
    service = Submissions::SubmissionForShow.new(
      @context, params.slice(:assignment_id, :id)
    )
    @assignment = service.assignment
    @submission = service.submission

    @rubric_association = @submission.rubric_association_with_assessing_user_id
    @visible_rubric_assessments = @submission.visible_rubric_assessments_for(@current_user)
    @assessment_request = @submission.assessment_requests.where(assessor_id: @current_user).first
    if authorized_action(@submission, @current_user, :read)
      respond_to do |format|
        @submission.limit_comments(@current_user, session)
        format.html
        format.json do
          @submission.limit_comments(@current_user, session)
          excludes = @assignment.grants_right?(@current_user, session, :grade) ? [:grade, :score] : []
          render :json => @submission.as_json(
            Submission.json_serialization_full_parameters(
              exclude: excludes,
              except: %w(quiz_submission submission_history)
            ).merge(permissions: {
              user: @current_user,
              session: session,
              include_permissions: false
            })
          )
        end
      end
    end
  end

  API_SUBMISSION_TYPES = {
    "online_text_entry" => ["body"].freeze,
    "online_url" => ["url"].freeze,
    "online_upload" => ["file_ids"].freeze,
    "media_recording" => ["media_comment_id", "media_comment_type"].freeze,
    "basic_lti_launch" => ["url"].freeze
  }.freeze

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
  # @argument comment[text_comment] [String]
  #   Include a textual comment with the submission.
  #
  # @argument submission[submission_type] [Required, String, "online_text_entry"|"online_url"|"online_upload"|"media_recording"|"basic_lti_launch"]
  #   The type of submission being made. The assignment submission_types must
  #   include this submission type as an allowed option, or the submission will be rejected with a 400 error.
  #
  #   The submission_type given determines which of the following parameters is
  #   used. For instance, to submit a URL, submission [submission_type] must be
  #   set to "online_url", otherwise the submission [url] parameter will be
  #   ignored.
  #
  # @argument submission[body] [String]
  #   Submit the assignment as an HTML document snippet. Note this HTML snippet
  #   will be sanitized using the same ruleset as a submission made from the
  #   Canvas web UI. The sanitized HTML will be returned in the response as the
  #   submission body. Requires a submission_type of "online_text_entry".
  #
  # @argument submission[url] [String]
  #   Submit the assignment as a URL. The URL scheme must be "http" or "https",
  #   no "ftp" or other URL schemes are allowed. If no scheme is given (e.g.
  #   "www.example.com") then "http" will be assumed. Requires a submission_type
  #   of "online_url" or "basic_lti_launch".
  #
  # @argument submission[file_ids][] [Integer]
  #   Submit the assignment as a set of one or more previously uploaded files
  #   residing in the submitting user's files section (or the group's files
  #   section, for group assignments).
  #
  #   To upload a new file to submit, see the submissions {api:SubmissionsApiController#create_file Upload a file API}.
  #
  #   Requires a submission_type of "online_upload".
  #
  # @argument submission[media_comment_id] [String]
  #   The media comment id to submit. Media comment ids can be submitted via
  #   this API, however, note that there is not yet an API to generate or list
  #   existing media comments, so this functionality is currently of limited use.
  #
  #   Requires a submission_type of "media_recording".
  #
  # @argument submission[media_comment_type] [String, "audio"|"video"]
  #   The type of media comment being submitted.
  #
  def create
    params[:submission] ||= {}

    @assignment = @context.assignments.active.find(params[:assignment_id])
    @assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @current_user)

    return unless authorized_action(@assignment, @current_user, :submit)

    if @assignment.locked_for?(@current_user) && !@assignment.grants_right?(@current_user, :update)
      flash[:notice] = t('errors.can_not_submit_locked_assignment', "You can't submit an assignment when it is locked")
      redirect_to named_context_url(@context, :context_assignment_url, @assignment.id)
      return
    end

    @group = @assignment.group_category.group_for(@current_user) if @assignment.has_group_category?

    return unless valid_text_entry?
    return unless process_api_submission_params if api_request?

    lookup_existing_attachments

    return unless verify_api_call_has_attachment if api_request?

    if !api_request?
      if online_upload?
        return unless extensions_allowed?
        return unless has_file_attached?
      elsif is_google_doc?
        params[:submission][:submission_type] = 'online_upload'
        attachment = submit_google_doc(params[:google_doc][:document_id])
        if attachment
          params[:submission][:attachments] << attachment
        else
          return
        end
      elsif is_media_recording? && !has_media_recording?
        flash[:error] = t('errors.media_file_attached', "There was no media recording in the submission")
        return redirect_to named_context_url(@context, :context_assignment_url, @assignment)
      end
    end

    params[:submission][:attachments] = params[:submission][:attachments].compact.uniq
    if @context.root_account.feature_enabled?(:submissions_folder)
      params[:submission][:attachments] = self.class.copy_attachments_to_submissions_folder(@context, params[:submission][:attachments])
    end

    begin
      @submission = @assignment.submit_homework(@current_user, params[:submission])
    rescue ActiveRecord::RecordInvalid => e
      respond_to do |format|
        format.html {
          flash[:error] = t('errors.assignment_submit_fail', "Assignment failed to submit")
          redirect_to course_assignment_url(@context, @assignment)
        }
        format.json { render :json => e.record.errors, :status => :bad_request }
      end
      return
    end

    respond_to do |format|
      if @submission.save
        log_asset_access(@assignment, "assignments", @assignment_group, 'submit')
        format.html do
          flash[:notice] = t('assignment_submit_success', 'Assignment successfully submitted.')
          redirect_to course_assignment_url(@context, @assignment)
        end
        format.json do
          if api_request?
            render :json => submission_json(@submission, @assignment, @current_user, session, @context, %{submission_comments attachments}),
              :status => :created, :location => api_v1_course_assignment_submission_url(@context, @assignment, @current_user)
          else
            render :json => @submission.as_json(:include => :submission_comments), :status => :created,
              :location => course_gradebook_url(@submission.assignment.context)
          end
        end
      else
        format.html do
          flash[:error] = t('errors.assignment_submit_fail', "Assignment failed to submit")
          render :show, id: @submission.assignment.context.id
        end
        format.json { render :json => @submission.errors, :status => :bad_request }
      end
    end
  end

  def lookup_existing_attachments
    if params[:submission][:file_ids].is_a?(Array)
      attachment_ids = params[:submission][:file_ids]
    else
      attachment_ids = (params[:submission][:attachment_ids] || "").split(",")
    end

    attachment_ids = attachment_ids.select(&:present?)
    params[:submission][:attachments] = []

    attachment_ids.each do |id|
      params[:submission][:attachments] << @current_user.attachments.active.where(id: id).first if @current_user
      params[:submission][:attachments] << @group.attachments.active.where(id: id).first if @group
      params[:submission][:attachments].compact!
    end
  end
  private :lookup_existing_attachments

  def self.copy_attachments_to_submissions_folder(assignment_context, attachments)
    attachments.map do |attachment|
      if attachment.folder && attachment.folder.for_submissions?
        attachment # already in a submissions folder
      elsif attachment.context.respond_to?(:submissions_folder)
        attachment.copy_to_folder!(attachment.context.submissions_folder(assignment_context))
      else
        attachment # in a weird context; leave it alone
      end
    end
  end

  def is_media_recording?
    return params[:submission][:submission_type] == 'media_recording'
  end
  private :is_media_recording?

  def has_media_recording?
    return params[:submission][:media_comment_id].present?
  end
  private :has_media_recording?

  def verify_api_call_has_attachment
    if params[:submission][:submission_type] == 'online_upload' && params[:submission][:attachments].blank?
      render(:json => { :message => "No valid file ids given" }, :status => :bad_request)
      return false
    end
    return true
  end
  private :verify_api_call_has_attachment

  def allowed_api_submission_type?(submission_type)
    valid_for_api = API_SUBMISSION_TYPES.key?(submission_type)
    allowed_for_assignment = @assignment.submission_types_array.include?(submission_type)
    basic_lti_launch = (@assignment.submission_types.include?('online') && submission_type == 'basic_lti_launch')
    valid_for_api && (allowed_for_assignment || basic_lti_launch)
  end
  private :allowed_api_submission_type?

  def process_api_submission_params
    # Verify submission_type is valid, and allowed by the assignment.
    # This should probably happen for non-api submissions as well, but
    # that'll take some further investigation/testing.
    submission_type = params[:submission][:submission_type]
    unless allowed_api_submission_type?(submission_type)
      render(:json => { :message => "Invalid submission[submission_type] given" }, :status => 400)
      return false
    end

    # Make sure that the submitted parameters match what we expect
    submission_params = (['submission_type'] + API_SUBMISSION_TYPES[submission_type]).sort
    params[:submission].slice!(*submission_params)
    if params[:submission].keys.sort != submission_params
      render(:json => {
        :message => "Invalid parameters for submission_type #{submission_type}. " +
          "Required: #{API_SUBMISSION_TYPES[submission_type].map { |p| "submission[#{p}]" }.join(", ") }"
      }, :status => 400)
      return false
    end
    params[:submission][:comment] = params[:comment].try(:delete, :text_comment)

    if params[:submission].has_key?(:body)
      params[:submission][:body] = process_incoming_html_content(params[:submission][:body])
    end
    return true
  end
  private :process_api_submission_params

  def online_upload?
    return params[:attachments] && params[:submission][:submission_type] == 'online_upload'
  end
  private :online_upload?

  def has_file_attached?
    # require at least one file to be attached
    if params[:attachments].blank?
      flash[:error] = t('errors.no_attached_file', "You must attach at least one file to this assignment")
      redirect_to named_context_url(@context, :context_assignment_url, @assignment)
      return false
    end
    return true
  end
  private :has_file_attached?

  def extensions_allowed?
    # if extensions are being restricted, check that the extension is whitelisted
    # The first check here is for web interface submissions that contain only one file
    # The second check is for multiple submissions and API calls that use the uploaded_data parameter to pass a filename
    if @assignment.allowed_extensions.present?
      if params[:submission][:attachments].any? {|a| !@assignment.allowed_extensions.include?((a.after_extension || '').downcase) } ||
         params[:attachments].any? do |i, a|
           !a[:uploaded_data].empty? &&
           !@assignment.allowed_extensions.include?((a[:uploaded_data].split('.').last || '').downcase)
         end
      flash[:error] = t('errors.invalid_file_type', "Invalid file type")
      redirect_to named_context_url(@context, :context_assignment_url, @assignment)
      return false
      end
    end
    return true
  end
  private :extensions_allowed?

  def valid_text_entry?
    sub_params = params[:submission]
    if sub_params[:submission_type] == 'online_text_entry' && sub_params[:body].blank?
      flash[:error] = t('Text entry submission cannot be empty')
      redirect_to named_context_url(@context, :context_assignment_url, @assignment)
      return false
    end
    return true
  end
  private :valid_text_entry?

  def is_google_doc?
    return params[:google_doc] && params[:google_doc][:document_id] && params[:submission][:submission_type] == "google_doc"
  end
  private :is_google_doc?

  def submit_google_doc(document_id)
    # fetch document from google
    # since google drive can have many different export types, we need to send along our preferred extensions
    document_response, display_name, file_extension, content_type = google_drive_connection.download(document_id,
                                                                                         @assignment.allowed_extensions)

    # error handling
    unless document_response.try(:is_a?, Net::HTTPOK) || document_response.status == 200
      flash[:error] = t('errors.assignment_submit_fail', 'Assignment failed to submit')
    end

    restriction_enabled           = @domain_root_account.feature_enabled?(:google_docs_domain_restriction)
    restricted_google_docs_domain = @domain_root_account.settings[:google_docs_domain]
    if restriction_enabled && !restricted_google_docs_domain.blank? && !@current_user.gmail.match(%r{@#{restricted_google_docs_domain}$})
      flash[:error] = t('errors.invalid_google_docs_domain', 'You cannot submit assignments from this google_docs domain')
    end

    if flash[:error]
      redirect_to(course_assignment_url(@context, @assignment))
      return false
    end

    # process the file and create an attachment
    filename = "google_doc_#{Time.now.strftime("%Y%m%d%H%M%S")}#{@current_user.id}.#{file_extension}"
    Dir.mktmpdir do |dirname|
      path     = File.join(dirname, filename)
      File.open(path, 'wb') do |f|
        f.write(document_response.body)
      end

      @attachment = @assignment.attachments.new(
        uploaded_data: Rack::Test::UploadedFile.new(path, content_type, true),
        display_name: display_name, user: @current_user
      )
      @attachment.save!
    end
    @attachment
  end
  protected :submit_google_doc

  def turnitin_report
    return render(:nothing => true, :status => 400) unless params_are_integers?(:assignment_id, :submission_id)

    @assignment = @context.assignments.active.find(params[:assignment_id])
    @submission = @assignment.submissions.where(user_id: params[:submission_id]).first
    @asset_string = params[:asset_string]
    if authorized_action(@submission, @current_user, :read)
      if (report_url = @submission.turnitin_data[@asset_string] && @submission.turnitin_data[@asset_string][:report_url])
        url = polymorphic_url([:retrieve, @context, :external_tools], url:report_url, display:'borderless')
      else
        url = @submission.turnitin_report_url(@asset_string, @current_user) rescue nil
      end
      if url
        redirect_to url
      else
        flash[:notice] = t('errors.no_report', "Couldn't find a report for that submission item")
        redirect_to named_context_url(@context, :context_assignment_submission_url, @assignment.id, @submission.user_id)
      end
    end
  end

  def resubmit_to_turnitin
    return render(:nothing => true, :status => 400) unless params_are_integers?(:assignment_id, :submission_id)

    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      @assignment = @context.assignments.active.find(params[:assignment_id])
      @submission = @assignment.submissions.where(user_id: params[:submission_id]).first
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
    provisional = @assignment.moderated_grading? && params[:submission][:provisional]

    if params[:submission][:student_entered_score] && @submission.grants_right?(@current_user, session, :comment)
      update_student_entered_score(params[:submission][:student_entered_score])
      render :json => @submission
      return
    end

    if authorized_action(@submission, @current_user, :comment)
      params[:submission][:commenter] = @current_user
      admin_in_context = !@context_enrollment || @context_enrollment.admin?
      if params[:attachments]
        attachments = []
        params[:attachments].each do |idx, attachment|
          attachment[:user] = @current_user
          attachments << @assignment.attachments.create(attachment)
        end
        params[:submission][:comment_attachments] = attachments#.map{|a| a.id}.join(",")
      end
      unless @submission.grants_right?(@current_user, session, :submit)
        @request = @submission.assessment_requests.where(assessor_id: @current_user).first if @current_user
        params[:submission] = {
          :comment => params[:submission][:comment],
          :comment_attachments => params[:submission][:comment_attachments],
          :media_comment_id => params[:submission][:media_comment_id],
          :media_comment_type => params[:submission][:media_comment_type],
          :commenter => @current_user,
          :assessment_request => @request,
          :group_comment => params[:submission][:group_comment],
          :hidden => @assignment.muted? && admin_in_context,
          :provisional => provisional,
          :final => params[:submission][:final],
          :draft_comment => Canvas::Plugin.value_to_boolean(params[:submission][:draft_comment])
        }
      end
      begin
        @submissions = @assignment.update_submission(@user, params[:submission])
      rescue => e
        Canvas::Errors.capture_exception(:submissions, e)
        logger.error(e)
      end
      respond_to do |format|
        if @submissions
          @submissions = @submissions.select{|s| s.grants_right?(@current_user, session, :read) }
          is_final = provisional && params[:submission][:final] && @context.grants_right?(@current_user, :moderate_grades)
          @submissions.each do |s|
            s.limit_comments(@current_user, session) unless @submission.grants_right?(@current_user, session, :submit)
            s.apply_provisional_grade_filter!(s.provisional_grade(@current_user, final: is_final)) if provisional
          end

          flash[:notice] = t('assignment_submitted', 'Assignment submitted.')

          format.html { redirect_to course_assignment_url(@context, @assignment) }

          json_args = Submission.json_serialization_full_parameters({
            :exclude => @assignment.grants_right?(@current_user, session, :grade) ? [:grade, :score, :turnitin_data] : [],
            :except => [:quiz_submission,:submission_history],
            :comments => admin_in_context ? :submission_comments : :visible_submission_comments
          }).merge(:permissions => { :user => @current_user, :session => session, :include_permissions => false })
          json_args[:methods] << :provisional_grade_id if provisional
          format.json {
            render :json => @submissions.map{ |s| s.as_json(json_args) }, :status => :created, :location => course_gradebook_url(@submission.assignment.context)
          }
          format.text {
            render :json => @submissions.map{ |s| s.as_json(json_args) }, :status => :created, :location => course_gradebook_url(@submission.assignment.context)
          }
        else
          @error_message = t('errors_update_failed', "Update Failed")
          flash[:error] = @error_message
          format.html { render :show, id: @assignment.context.id }
          format.json { render :json => {:errors => {:base => @error_message}}, :status => :bad_request }
          format.text { render :json => {:errors => {:base => @error_message}}, :status => :bad_request }
        end
      end
    end
  end

  protected

  def update_student_entered_score(score)
    if score.present? && score != "null"
      @submission.student_entered_score = score.to_f.round(2)
    else
      @submission.student_entered_score = nil
    end
    @submission.save
  end

  def generate_submission_zip(assignment, context)
    attachment = submission_zip(assignment)

    respond_to do |format|
      if attachment.zipped?
        if Attachment.s3_storage?
          format.html { redirect_to attachment.inline_url }
          format.zip { redirect_to attachment.inline_url }
        else
          cancel_cache_buster

          format.html do
            send_file(attachment.full_filename, {
              :type => attachment.content_type_with_encoding,
              :disposition => 'inline'
            })
          end

          format.zip do
            send_file(attachment.full_filename, {
              :type => attachment.content_type_with_encoding,
              :disposition => 'inline'
            })
          end
        end
        format.json { render :json => attachment.as_json(:methods => :readable_size) }
      else
        flash[:notice] = t('still_zipping', "File zipping still in process...")

        format.html do
          redirect_to named_context_url(context, :context_assignment_url, assignment.id)
        end

        format.zip do
          redirect_to named_context_url(context, :context_assignment_url, assignment.id)
        end

        format.json { render :json => attachment }
      end
    end
  end
end
