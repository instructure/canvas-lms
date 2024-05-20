# frozen_string_literal: true

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
#         "edited_at" : {
#           "example": "2012-01-02T01:00:00Z",
#           "type": "datetime"
#         },
#         "media_comment": {
#           "$ref": "MediaComment"
#         }
#       }
#     }
#
class SubmissionsController < SubmissionsBaseController
  include Submissions::ShowHelper
  include Api::V1::Submission

  before_action :get_course_from_section, only: :create
  before_action :require_context

  include K5Mode

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

  def show
    @submission_for_show = Submissions::SubmissionForShow.new(
      assignment_id: params.fetch(:assignment_id),
      context: @context,
      id: params.fetch(:id)
    )
    begin
      @assignment = @submission_for_show.assignment
      @submission = @submission_for_show.submission
    rescue ActiveRecord::RecordNotFound
      return render_user_not_found
    end

    return render_unauthorized_action unless @submission.can_view_details?(@current_user)

    # If anonymous peer reviews are enabled, submissions must be peer-reviewed
    # via this controller's anonymous counterpart
    return render_unauthorized_action if @assignment.anonymous_peer_reviews? && @submission.peer_reviewer?(@current_user)

    super
  end

  API_SUBMISSION_TYPES = {
    "online_text_entry" => ["body"].freeze,
    "online_url" => ["url"].freeze,
    "online_upload" => ["file_ids"].freeze,
    "media_recording" => ["media_comment_id", "media_comment_type"].freeze,
    "basic_lti_launch" => ["url"].freeze,
    "student_annotation" => ["annotatable_attachment_id"].freeze
  }.freeze

  # @API Submit an assignment
  #
  # Make a submission for an assignment. You must be enrolled as a student in
  # the course/section to do this.
  #
  # All online turn-in submission types are supported in this API. However,
  # there are a few things that are not yet supported:
  #
  # * Files can be submitted based on a file ID of a user or group file or through the {api:SubmissionsApiController#create_file file upload API}. However, there is no API yet for listing the user and group files.
  # * Media comments can be submitted, however, there is no API yet for creating a media comment to submit.
  # * Integration with Google Docs is not yet supported.
  #
  # @argument comment[text_comment] [String]
  #   Include a textual comment with the submission.
  #
  # @argument submission[submission_type] [Required, String, "online_text_entry"|"online_url"|"online_upload"|"media_recording"|"basic_lti_launch"|"student_annotation"]
  #   The type of submission being made. The assignment submission_types must
  #   include this submission type as an allowed option, or the submission will be rejected with a 400 error.
  #
  #   The submission_type given determines which of the following parameters is
  #   used. For instance, to submit a URL, submission [submission_type] must be
  #   set to "online_url", otherwise the submission [url] parameter will be
  #   ignored.
  #
  #   "basic_lti_launch" requires the assignment submission_type "online" or "external_tool"
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
  # @argument submission[user_id] [Integer]
  #   Submit on behalf of the given user. Requires grading permission.
  #
  # @argument submission[annotatable_attachment_id] [Integer]
  #   The Attachment ID of the document being annotated. This should match
  #   the annotatable_attachment_id on the assignment.
  #
  #   Requires a submission_type of "student_annotation".
  #
  # @argument submission[submitted_at] [DateTime]
  #   Choose the time the submission is listed as submitted at.  Requires grading permission.

  def create
    params[:submission] ||= {}
    user_id = params[:submission].delete(:user_id)
    @submission_user = if user_id
                         get_user_considering_section(user_id)
                       else
                         @current_user
                       end

    @assignment = api_find(@context.assignments.active, params[:assignment_id])
    @assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @submission_user)

    return unless authorized_action(@assignment, @submission_user, :submit)

    submit_at = params.dig(:submission, :submitted_at)
    user_sub = @assignment.submissions.find_by(user: user_id)

    if user_id || submit_at
      unless user_sub
        if @assignment.students_with_visibility.where(id: user_id).exists?
          user_sub = @assignment.submissions.create!(user_id:)
        else
          return render_unauthorized_action
        end
      end

      return unless authorized_action(user_sub, @current_user, :grade)
    end

    if @assignment.locked_for?(@submission_user) && !@assignment.grants_right?(@current_user, :update)
      flash[:notice] = t("errors.can_not_submit_locked_assignment", "You can't submit an assignment when it is locked")
      redirect_to named_context_url(@context, :context_assignment_url, @assignment.id)
      return
    end

    @group = @assignment.group_category.group_for(@submission_user) if @assignment.has_group_category?

    return unless valid_text_entry?

    return if api_request? && !process_api_submission_params

    lookup_existing_attachments

    return if api_request? && !verify_api_call_has_attachment

    unless api_request?
      if online_upload?
        return unless extensions_allowed?
        return unless has_file_attached?
      elsif is_media_recording? && !has_media_recording?
        flash[:error] = t("errors.media_file_attached", "There was no media recording in the submission")
        return redirect_to named_context_url(@context, :context_assignment_url, @assignment)
      elsif params[:submission][:submission_type] == "student_annotation" && params[:submission][:annotatable_attachment_id].blank?
        flash[:error] = t("Student Annotation submissions require an annotatable_attachment_id to submit")
        return redirect_to(course_assignment_url(@context, @assignment))
      end

      unless @assignment.published?
        flash[:error] = t("You can't submit an assignment when it is unpublished")
        return redirect_to(course_assignment_url(@context, @assignment))
      end

      unless @assignment.accepts_submission_type?(params[:submission][:submission_type])
        flash[:error] = t("Assignment does not accept this submission type")
        return redirect_to(course_assignment_url(@context, @assignment))
      end
    end

    # When the `resource_link_lookup_uuid` is given, we need to validate if it exists,
    # in case not, we'll return an error and won't record the submission.
    return unless valid_resource_link_lookup_uuid?

    submission_params = params[:submission].permit(
      :body,
      :url,
      :submission_type,
      :submitted_at,
      :comment,
      :group_comment,
      :media_comment_type,
      :media_comment_id,
      :eula_agreement_timestamp,
      :resource_link_lookup_uuid,
      :annotatable_attachment_id,
      attachment_ids: []
    )
    submission_params[:group_comment] = value_to_boolean(submission_params[:group_comment])
    submission_params[:attachments] = Attachment.copy_attachments_to_submissions_folder(@context, params[:submission][:attachments].compact.uniq)

    if submission_params.key?(:body)
      submission_params[:body] = process_incoming_html_content(params[:submission][:body])
    end

    begin
      @submission = @assignment.submit_homework(@submission_user, submission_params)
    rescue ActiveRecord::RecordInvalid => e
      respond_to do |format|
        format.html do
          flash[:error] = t("errors.assignment_submit_fail", "Assignment failed to submit")
          redirect_to course_assignment_url(@context, @assignment)
        end
        format.json { render json: e.record.errors, status: :bad_request }
      end
      return
    end

    respond_to do |format|
      if @submission.persisted?
        log_asset_access(@assignment, "assignments", @assignment_group, "submit")
        format.html do
          flash[:notice] = t("assignment_submit_success", "Assignment successfully submitted.")
          tardiness = if @submission.late?
                        2 # late
                      elsif @submission.cached_due_date.nil?
                        0 # don't know
                      else
                        1 # on time
                      end

          if @submission.late? || !@domain_root_account&.feature_enabled?(:confetti_for_assignments)
            redirect_to course_assignment_url(@context, @assignment, submitted: tardiness)
          else
            redirect_to course_assignment_url(@context, @assignment, submitted: tardiness, confetti: true)
          end
        end
        format.json do
          if api_request?
            includes = %(submission_comments attachments)
            json = submission_json(@submission, @assignment, @current_user, session, @context, includes, params)
            render json:,
                   status: :created,
                   location: api_v1_course_assignment_submission_url(@context, @assignment, @current_user)
          else
            render json: @submission.as_json(include: :submission_comments, methods: :late),
                   status: :created,
                   location: course_gradebook_url(@submission.assignment.context)
          end
        end
      else
        format.html do
          flash[:error] = t("errors.assignment_submit_fail", "Assignment failed to submit")
          render :show, id: @submission.assignment.context.id
        end
        format.json { render json: @submission.errors, status: :bad_request }
      end
    end
  end

  def update
    @assignment = api_find(@context.assignments.active, params.fetch(:assignment_id))
    @user = @context.all_students.find(params.fetch(:id))
    @submission = @assignment.find_or_create_submission(@user)

    super
  end

  def redo_submission
    @assignment = api_find(@context.assignments.active, params.fetch(:assignment_id))
    @user = get_user_considering_section(params.fetch(:submission_id))
    @submission = @assignment.submission_for_student(@user)

    super
  end

  def audit_events
    return unless authorized_action(@context, @current_user, :view_audit_trail)

    submission = Submission.find(params[:submission_id])

    audit_events = AnonymousOrModerationEvent.events_for_submission(
      assignment_id: params[:assignment_id],
      submission_id: params[:submission_id]
    )

    user_data = User.find(audit_events.pluck(:user_id).compact)
    tool_data = ContextExternalTool.find(audit_events.pluck(:context_external_tool_id).compact)
    quiz_data = Quizzes::Quiz.find(audit_events.pluck(:quiz_id).compact)

    respond_to do |format|
      format.json do
        render json: {
                 audit_events: audit_events.as_json(include_root: false),
                 users: audit_event_data(data: user_data, submission:),
                 tools: audit_event_data(data: tool_data, role: "grader"),
                 quizzes: audit_event_data(data: quiz_data, role: "grader", name_field: :title),
               },
               status: :ok
      end
    end
  end

  def audit_event_data(data:, submission: nil, role: nil, name_field: :name)
    data.map do |datum|
      {
        id: datum.id,
        name: datum.public_send(name_field),
        role: role.presence || auditing_user_role(user: datum, submission:)
      }
    end
  end
  private :audit_event_data

  def auditing_user_role(user:, submission:)
    assignment = submission.assignment

    if submission.user == user
      "student"
    elsif assignment.moderated_grading? && assignment.final_grader == user
      "final_grader"
    elsif assignment.course.account_membership_allows(user)
      "admin"
    else
      "grader"
    end
  end
  private :auditing_user_role

  def lookup_existing_attachments
    attachment_ids = if params[:submission][:file_ids].is_a?(Array)
                       params[:submission][:file_ids]
                     else
                       (params[:submission][:attachment_ids] || "").split(",")
                     end

    attachment_ids = attachment_ids.select(&:present?)
    params[:submission][:attachments] = []

    attachment_ids.each do |id|
      params[:submission][:attachments] << @submission_user.attachments.active.where(id:).first if @submission_user
      params[:submission][:attachments] << @group.attachments.active.where(id:).first if @group
      params[:submission][:attachments].compact!
    end
  end
  private :lookup_existing_attachments

  def is_media_recording?
    params[:submission][:submission_type] == "media_recording"
  end
  private :is_media_recording?

  def has_media_recording?
    params[:submission][:media_comment_id].present?
  end
  private :has_media_recording?

  def verify_api_call_has_attachment
    if params[:submission][:submission_type] == "online_upload" && params[:submission][:attachments].blank?
      render(json: { message: "No valid file ids given" }, status: :bad_request)
      return false
    end
    true
  end
  private :verify_api_call_has_attachment

  def allowed_api_submission_type?(submission_type)
    API_SUBMISSION_TYPES.key?(submission_type) && @assignment.accepts_submission_type?(submission_type)
  end
  private :allowed_api_submission_type?

  def process_api_submission_params
    # Verify submission_type is valid, and allowed by the assignment.
    # This should probably happen for non-api submissions as well, but
    # that'll take some further investigation/testing.
    submission_type = params[:submission][:submission_type]
    unless allowed_api_submission_type?(submission_type)
      render(json: { message: "Invalid submission[submission_type] given" }, status: :bad_request)
      return false
    end

    always_permitted = always_permitted_create_params

    # Make sure that the submitted parameters match what we expect
    submission_params = (["submission_type"] + API_SUBMISSION_TYPES[submission_type]).sort
    params[:submission].slice!(*submission_params)
    if params[:submission].keys.sort != submission_params
      render(json: {
               message: "Invalid parameters for submission_type #{submission_type}. " \
                        "Required: #{API_SUBMISSION_TYPES[submission_type].map { |p| "submission[#{p}]" }.join(", ")}"
             },
             status: :bad_request)
      return false
    end
    params[:submission][:comment] = params[:comment].try(:delete, :text_comment)

    if params[:submission].key?(:body)
      params[:submission][:body] = process_incoming_html_content(params[:submission][:body])
    end

    params[:submission].merge!(always_permitted)
    true
  end
  private :process_api_submission_params

  def online_upload?
    params[:attachments] && params[:submission][:submission_type] == "online_upload"
  end
  private :online_upload?

  def has_file_attached?
    # require at least one file to be attached
    if params[:attachments].blank?
      flash[:error] = t("errors.no_attached_file", "You must attach at least one file to this assignment")
      redirect_to named_context_url(@context, :context_assignment_url, @assignment)
      return false
    end
    true
  end
  private :has_file_attached?

  def extensions_allowed?
    # if extensions are being restricted, check that the extension is allowed
    # The first check here is for web interface submissions that contain only one file
    # The second check is for multiple submissions and API calls that use the uploaded_data parameter to pass a filename
    if @assignment.allowed_extensions.present? &&
       (params[:submission][:attachments].any? { |a| !@assignment.allowed_extensions.include?((a.after_extension || "").downcase) } ||
          params[:attachments].values.any? do |a|
            !a[:uploaded_data].empty? &&
            !@assignment.allowed_extensions.include?((a[:uploaded_data].split(".").last || "").downcase)
          end)
      flash[:error] = t("errors.invalid_file_type", "Invalid file type")
      redirect_to named_context_url(@context, :context_assignment_url, @assignment)
      return false
    end
    true
  end
  private :extensions_allowed?

  def valid_text_entry?
    sub_params = params[:submission]
    if sub_params[:submission_type] == "online_text_entry" && sub_params[:body].blank?
      flash[:error] = t("Text entry submission cannot be empty")
      redirect_to named_context_url(@context, :context_assignment_url, @assignment)
      return false
    end
    true
  end
  private :valid_text_entry?

  def always_permitted_create_params
    always_permitted_params = %i[eula_agreement_timestamp submitted_at resource_link_lookup_uuid].freeze
    params.require(:submission).permit(always_permitted_params)
  end
  private :always_permitted_create_params

  def valid_resource_link_lookup_uuid?
    return true if params[:submission][:resource_link_lookup_uuid].nil?

    resource_link = Lti::ResourceLink.find_by(
      lookup_uuid: params[:submission][:resource_link_lookup_uuid],
      context: @context
    )

    return true if resource_link

    message = t("Resource link not found for given `resource_link_lookup_uuid`")

    # Homework submission is done by API request, but I saw other parts of code
    # that are handling HTML and JSON format. So, I kept the same logic here...
    if api_request?
      render(json: { message: }, status: :bad_request)
    else
      flash[:error] = message
      redirect_to named_context_url(@context, :context_assignment_url, @assignment)
    end

    false
  end
  private :valid_resource_link_lookup_uuid?

  protected

  def generate_submission_zip(assignment, context)
    attachment = submission_zip(assignment)

    respond_to do |format|
      if attachment.zipped?
        if attachment.stored_locally?
          cancel_cache_buster

          format.html do
            send_file(attachment.full_filename, {
                        type: attachment.content_type_with_encoding,
                        disposition: "inline"
                      })
          end

          format.zip do
            send_file(attachment.full_filename, {
                        type: attachment.content_type_with_encoding,
                        disposition: "inline"
                      })
          end
        else
          inline_url = authenticated_inline_url(attachment)
          format.html { redirect_to inline_url }
          format.zip { redirect_to inline_url }
        end
        format.json { render json: attachment.as_json(methods: :readable_size) }
      else
        flash[:notice] = t("still_zipping", "File zipping still in process...")

        format.html do
          redirect_to named_context_url(context, :context_assignment_url, assignment.id)
        end

        format.zip do
          redirect_to named_context_url(context, :context_assignment_url, assignment.id)
        end

        format.json { render json: attachment }
      end
    end
  end

  def plagiarism_report(type)
    return head(:bad_request) unless params_are_integers?(:assignment_id, :submission_id)

    @assignment = @context.assignments.active.find(params.require(:assignment_id))
    @submission = @assignment.submissions.find_by(user_id: params.require(:submission_id))

    super(type)
  end

  def resubmit_to_plagiarism(type)
    return head(:bad_request) unless params_are_integers?(:assignment_id)

    @assignment = @context.assignments.active.find(params.require(:assignment_id))
    @submission = @assignment.submissions.find_by(user_id: params.require(:submission_id))

    super(type)
  end
end
