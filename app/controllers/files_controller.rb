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

require 'dynamic_form'
require 'securerandom'

# @API Files
# An API for managing files and folders
# See the File Upload Documentation for details on the file upload workflow.
#
# @model File
#     {
#       "id": "File",
#       "description": "",
#       "properties": {
#         "size": {
#           "example": 4,
#           "type": "integer"
#         },
#         "content-type": {
#           "example": "text/plain",
#           "type": "string"
#         },
#         "url": {
#           "example": "http://www.example.com/files/569/download?download_frd=1&verifier=c6HdZmxOZa0Fiin2cbvZeI8I5ry7yqD7RChQzb6P",
#           "type": "string"
#         },
#         "id": {
#           "example": 569,
#           "type": "integer"
#         },
#         "display_name": {
#           "example": "file.txt",
#           "type": "string"
#         },
#         "created_at": {
#           "example": "2012-07-06T14:58:50Z",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "example": "2012-07-06T14:58:50Z",
#           "type": "datetime"
#         },
#         "unlock_at": {
#           "type": "datetime"
#         },
#         "modified_at": {
#           "example": "2012-07-06T14:58:50Z",
#           "type": "datetime"
#         },
#         "locked": {
#           "example": false,
#           "type": "boolean"
#         },
#         "hidden": {
#           "example": false,
#           "type": "boolean"
#         },
#         "lock_at": {
#           "type": "datetime"
#         },
#         "locked_for_user": {
#           "example": false,
#           "type": "boolean"
#         },
#         "lock_info": {
#           "$ref": "LockInfo"
#         },
#         "lock_explanation": {
#           "example": "This assignment is locked until September 1 at 12:00am",
#           "type": "string"
#         },
#         "hidden_for_user": {
#           "example": false,
#           "type": "boolean"
#         },
#         "thumbnail_url": {
#           "type": "string"
#         },
#         "mime_class": {
#           "type": "string",
#           "description": "simplified content-type mapping"
#         },
#         "media_entry_id": {
#           "type": "string",
#           "description": "identifier for file in third-party transcoding service"
#         },
#         "preview_url": {
#           "type": "string",
#           "description": "optional: url to the document preview. This url is specific to the user making the api call. Only included in submission endpoints."
#         }
#       }
#     }
#
class FilesController < ApplicationController
  # show_relative is exempted from protect_from_forgery in order to allow
  # brand-config-uploaded JS to work
  # verify_authenticity_token is manually-invoked where @context is not
  # an Account in show_relative
  protect_from_forgery :except => [:api_capture, :show_relative], with: :exception

  before_action :require_user, only: :create_pending
  before_action :require_context, except: [
    :assessment_question_show, :image_thumbnail, :show_thumbnail,
    :create_pending, :s3_success, :show, :api_create, :api_create_success, :api_create_success_cors,
    :api_show, :api_index, :destroy, :api_update, :api_file_status, :public_url, :api_capture
  ]

  before_action :check_file_access_flags, only: [:show_relative, :show]
  before_action :open_cors, only: [
    :api_create, :api_create_success, :api_create_success_cors, :show_thumbnail
  ]

  prepend_around_action :load_pseudonym_from_policy, only: :create
  skip_before_action :verify_authenticity_token, only: :api_create
  before_action :verify_api_id, only: [
    :api_show, :api_create_success, :api_file_status, :api_update, :destroy
  ]

  include Api::V1::Attachment
  include Api::V1::Avatar
  include AttachmentHelper

  before_action { |c| c.active_tab = "files" }

  def verify_api_id
    raise ActiveRecord::RecordNotFound unless params[:id] =~ Api::ID_REGEX
  end

  def quota
    get_quota
    if authorized_action(@context.attachments.temp_record, @current_user, :create)
      h = ActionView::Base.new
      h.extend ActionView::Helpers::NumberHelper
      result = {
        :quota => h.number_to_human_size(@quota),
        :quota_used => h.number_to_human_size(@quota_used),
        :quota_full => (@quota_used >= @quota)
      }
      render :json => result
    end
  end

  # @API Get quota information
  # Returns the total and used storage quota for the course, group, or user.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/1/files/quota' \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #
  #  { "quota": 524288000, "quota_used": 402653184 }
  #
  def api_quota
    if authorized_action(@context.attachments.build, @current_user, :create)
      get_quota
      render json: {quota: @quota, quota_used: @quota_used}
    end
  end

  def check_file_access_flags
    if params[:user_id] && params[:ts] && params[:sf_verifier]
      user = api_find(User, params[:user_id]) if params[:user_id].present?
      if user && user.valid_access_verifier?(params[:ts], params[:sf_verifier])
        # attachment.rb checks for this session attribute when determining
        # permissions, but it should be ignored by the rest of the models'
        # permission checks
        session['file_access_user_id'] = user.id
        session['file_access_expiration'] = 1.hour.from_now.to_i
        session[:permissions_key] = SecureRandom.uuid
      end
    end
    # These sessions won't get deleted when the user logs out since this
    # is on a separate domain, so we've added our own (stricter) timeout.
    if session && session['file_access_user_id'] && session['file_access_expiration'].to_i > Time.now.to_i
      session['file_access_expiration'] = 1.hour.from_now.to_i
      session[:permissions_key] = SecureRandom.uuid
    end
    true
  end
  protected :check_file_access_flags

  def index
    # This is only used by the old wiki sidebar, see
    # public/javascripts/wikiSidebar.js#loadFolders
    if request.format == :json
      if authorized_action(@context.attachments.build, @current_user, :read)
        root_folder = Folder.root_folders(@context).first
        if authorized_action(root_folder, @current_user, :read)
          file_structure = {
            :folders => @context.active_folders.
              reorder("COALESCE(parent_folder_id, 0), COALESCE(position, 0), COALESCE(name, ''), created_at").
              select(:id, :parent_folder_id, :name)
          }

          render :json => file_structure
        end
      end
    else
      return react_files
    end
  end

  # @API List files
  # Returns the paginated list of files for the folder or course.
  #
  # @argument content_types[] [String]
  #   Filter results by content-type. You can specify type/subtype pairs (e.g.,
  #   'image/jpeg'), or simply types (e.g., 'image', which will match
  #   'image/gif', 'image/jpeg', etc.).
  #
  # @argument search_term [String]
  #   The partial name of the files to match and return.
  #
  # @argument include[] ["user"]
  #   Array of additional information to include.
  #
  #   "user":: the user who uploaded the file or last edited its content
  #   "usage_rights":: copyright and license information for the file (see UsageRights)
  #
  # @argument only[] [Array]
  #   Array of information to restrict to. Overrides include[]
  #
  #   "names":: only returns file name information
  #
  # @argument sort [String, "name"|"size"|"created_at"|"updated_at"|"content_type"|"user"]
  #   Sort results by this field. Defaults to 'name'. Note that `sort=user` implies `include[]=user`.
  #
  # @argument order [String, "asc"|"desc"]
  #   The sorting order. Defaults to 'asc'.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/folders/<folder_id>/files?content_types[]=image&content_types[]=text/plain \
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns [File]
  def api_index
    get_context
    verify_api_id unless @context.present?
    @folder = Folder.from_context_or_id(@context, params[:id])

    if authorized_action(@folder, @current_user, :read_contents)
      params[:sort] ||= params[:sort_by] # :sort_by was undocumented; :sort is more consistent with other APIs such as wikis
      params[:include] = Array(params[:include])
      params[:include] << 'user' if params[:sort] == 'user'

      scope = Attachments::ScopedToUser.new(@context || @folder, @current_user).scope
      scope = scope.preload(:user) if params[:include].include?('user') && params[:sort] != 'user'
      scope = scope.preload(:usage_rights) if params[:include].include?('usage_rights')
      scope = Attachment.search_by_attribute(scope, :display_name, params[:search_term])

      order_clause = case params[:sort]
        when 'position' # undocumented; kept for compatibility
          "attachments.position, #{Attachment.display_name_order_by_clause('attachments')}"
        when 'size'
          "attachments.size"
        when 'created_at'
          "attachments.created_at"
        when 'updated_at'
          "attachments.updated_at"
        when 'content_type'
          "attachments.content_type"
        when 'user'
        scope.primary_shard.activate do
            scope = scope.joins("LEFT OUTER JOIN #{User.quoted_table_name} ON attachments.user_id=users.id")
          end
          "users.sortable_name IS NULL, #{User.sortable_name_order_by_clause('users')}"
        else
          Attachment.display_name_order_by_clause('attachments')
      end
      order_clause += ' DESC' if params[:order] == 'desc'
      scope = scope.order(order_clause)

      if params[:content_types].present?
        scope = scope.by_content_types(Array(params[:content_types]))
      end

      url = @context ? context_files_url : api_v1_list_files_url(@folder)
      @files = Api.paginate(scope, self, url)
      render json: attachments_json(@files, @current_user, {}, {
        can_view_hidden_files: can_view_hidden_files?(@context || @folder, @current_user, session),
        context: @context || @folder.context,
        include: params[:include],
        only: params[:only],
        omit_verifier_in_app: !value_to_boolean(params[:use_verifiers])
      })
    end
  end

  def images
    if authorized_action(@context.attachments.temp_record, @current_user, :read)
      if Folder.root_folders(@context).first.grants_right?(@current_user, session, :read_contents)
        if @context.grants_right?(@current_user, session, :manage_files)
          @images = @context.active_images.paginate :page => params[:page]
        else
          @images = @context.active_images.not_hidden.not_locked.where(:folder_id => @context.active_folders.not_hidden.not_locked).paginate :page => params[:page]
        end
      else
        @images = [].paginate
      end
      headers['X-Total-Pages'] = @images.total_pages.to_s
      render :partial => "shared/wiki_image", :collection => @images
    end
  end

  def react_files
    if authorized_action(@context, @current_user, [:read, :manage_files]) && tab_enabled?(@context.class::TAB_FILES)
      @contexts = [@context]
      get_all_pertinent_contexts(include_groups: true, cross_shard: true) if @context == @current_user
      files_contexts = @contexts.map do |context|

        tool_context = if context.is_a?(Course)
          context
        elsif context.is_a?(User)
          @domain_root_account
        elsif context.is_a?(Group)
          context.context
        end

        has_external_tools = !context.is_a?(Group) && tool_context

        file_menu_tools = (has_external_tools ? external_tools_display_hashes(:file_menu, tool_context, [:accept_media_types]) : [])

        {
          asset_string: context.asset_string,
          name: context == @current_user ? t('my_files', 'My Files') : context.name,
          usage_rights_required: context.feature_enabled?(:usage_rights_required),
          permissions: {
            manage_files: context.grants_right?(@current_user, session, :manage_files),
          },
          file_menu_tools: file_menu_tools
        }
      end

      @page_title = t('files_page_title', 'Files')
      @body_classes << 'full-width padless-content'
      js_bundle :react_files
      css_bundle :react_files
      js_env({
        :FILES_CONTEXTS => files_contexts,
        :NEW_FOLDER_TREE => @context.feature_enabled?(:use_new_tree),
        :COURSE_ID => context.id.to_s
      })
      log_asset_access([ "files", @context ], "files", "other")

      set_tutorial_js_env

      render html: "".html_safe, layout: true
    end
  end

  def assessment_question_show
    @context = AssessmentQuestion.find(params[:assessment_question_id])
    @attachment = @context.attachments.find(params[:id])
    @skip_crumb = true
    if @attachment.deleted?
      flash[:notice] = t 'notices.deleted', "The file %{display_name} has been deleted", :display_name => @attachment.display_name
      return redirect_to dashboard_url
    end
    show
  end

  # @API Get public inline preview url
  # Determine the URL that should be used for inline preview of the file.
  #
  # @argument submission_id [Optional, Integer]
  #   The id of the submission the file is associated with.  Provide this argument to gain access to a file
  #   that has been submitted to an assignment (Canvas will verify that the file belongs to the submission
  #   and the calling user has rights to view the submission).
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/files/1/public_url' \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #
  #  { "public_url": "https://example-bucket.s3.amazonaws.com/example-namespace/attachments/1/example-filename?AWSAccessKeyId=example-key&Expires=1400000000&Signature=example-signature" }
  #
  def public_url
    @attachment = Attachment.find(params[:id])
    # if the attachment is part of a submisison, its 'context' will be the student that submmited the assignment.  so if  @current_user is a
    # teacher authorized_action(@attachment, @current_user, :download) will be false, we need to actually check if they have perms to see the
    # submission.
    @submission = Submission.active.find(params[:submission_id]) if params[:submission_id]
    # verify that the requested attachment belongs to the submission
    return render_unauthorized_action if @submission && !@submission.includes_attachment?(@attachment)
    if @submission ? authorized_action(@submission, @current_user, :read) : authorized_action(@attachment, @current_user, :download)
      render :json  => { :public_url => @attachment.public_url(:secure => request.ssl?) }
    end
  end

  # @API Get file
  # Returns the standard attachment json object
  #
  # @argument include[] ["user"]
  #   Array of additional information to include.
  #
  #   "user":: the user who uploaded the file or last edited its content
  #   "usage_rights":: copyright and license information for the file (see UsageRights)
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/files/<file_id>' \
  #         -H 'Authorization: Bearer <token>'
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/files/<file_id>' \
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns File
  def api_show
    get_context
    @attachment = @context ? @context.attachments.find(params[:id]) : Attachment.find(params[:id])
    raise ActiveRecord::RecordNotFound if @attachment.deleted?
    params[:include] = Array(params[:include])
    if authorized_action(@attachment,@current_user,:read)
      render :json => attachment_json(@attachment, @current_user, {}, { include: params[:include], omit_verifier_in_app: !value_to_boolean(params[:use_verifiers]) })
    end
  end

  def show
    original_params = params.dup
    params[:id] ||= params[:file_id]
    get_context
    # note that the /files/XXX URL implicitly uses the current user as the
    # context, even though it doesn't search for the file using
    # @current_user.attachments.find , since it might not actually be a user
    # attachment.
    # this implicit context magic happens in ApplicationController#get_context
    if @context && !@context.is_a?(User)
      # note that Attachment#find has special logic to find overwriting files; see FindInContextAssociation
      @attachment = @context.attachments.find(params[:id])
    else
      @attachment = Attachment.find(params[:id])
      @skip_crumb = true unless @context
    end

    params[:download] ||= params[:preview]
    add_crumb(t('#crumbs.files', "Files"), named_context_url(@context, :context_files_url)) unless @skip_crumb
    if @attachment.deleted?
      if @current_user.nil? || @attachment.user_id != @current_user.id
        @not_found_message = t('could_not_find_file', "This file has been deleted")
        render status: 404, template: "shared/errors/404_message", formats: [:html]
        return
      end
      flash[:notice] = t 'notices.deleted', "The file %{display_name} has been deleted", display_name: @attachment.display_name
      if params[:preview] && @attachment.mime_class == 'image'
        redirect_to '/images/blank.png'
      elsif request.format == :json
        render :json => {:deleted => true}
      else
        redirect_to named_context_url(@context, :context_files_url)
      end
      return
    end

    verifier_checker = Attachments::Verification.new(@attachment)
    if (params[:verifier] && verifier_checker.valid_verifier_for_permission?(params[:verifier], :read, session)) ||
        @attachment.attachment_associations.where(:context_type => 'Submission').
          any? { |aa| aa.context && aa.context.grants_right?(@current_user, session, :read) } ||
        authorized_action(@attachment, @current_user, :read)

      @attachment.ensure_media_object

      if params[:download]
        if (params[:verifier] && verifier_checker.valid_verifier_for_permission?(params[:verifier], :download, session)) ||
            (@attachment.grants_right?(@current_user, session, :download))
          disable_page_views if params[:preview]
          begin
            send_attachment(@attachment)
          rescue => e
            @headers = false if params[:ts] && params[:verifier]
            @not_found_message = t 'errors.not_found', "It looks like something went wrong when this file was uploaded, and we can't find the actual file.  You may want to notify the owner of the file and have them re-upload it."
            logger.error "Error downloading a file: #{e} - #{e.backtrace}"
            render 'shared/errors/404_message',
              status: :bad_request,
              formats: [:html]
          end
          return
        elsif authorized_action(@attachment, @current_user, :read)
          render_attachment(@attachment)
        end
      # This action is a callback used in our system to help record when
      # a user views an inline preview of a file instead of downloading
      # it, since this should also count as an access.
      elsif params[:inline]
        @attachment.context_module_action(@current_user, :read) if @current_user
        log_asset_access(@attachment, 'files', 'files')
        render :json => {:ok => true}
      else
        render_attachment(@attachment)
      end
    end
  end

  def render_attachment(attachment)
    respond_to do |format|
      if params[:preview] && attachment.mime_class == 'image'
        format.html { redirect_to '/images/svg-icons/icon_lock.svg' }
      else
        if @files_domain
          @headers = false
          @show_left_side = false
        end
        if attachment.content_type && attachment.content_type.match(/\Avideo\/|audio\//)
          attachment.context_module_action(@current_user, :read)
        end
        format.html { render :show }
      end
      format.json do
        json = {
          :attachment => {
            :workflow_state => attachment.workflow_state,
            :content_type => attachment.content_type
          }
        }

        json[:attachment][:media_entry_id] = attachment.media_entry_id if attachment.media_entry_id

        verifier_checker = Attachments::Verification.new(@attachment)
        if (params[:verifier] && verifier_checker.valid_verifier_for_permission?(params[:verifier], :download, session)) ||
            attachment.grants_right?(@current_user, session, :download)
          # Right now we assume if they ask for json data on the attachment
          # then that means they have viewed or are about to view the file in
          # some form.
          if @current_user &&
             (attachment.canvadocable? ||
              GoogleDocsPreview.previewable?(@domain_root_account, attachment))
            attachment.context_module_action(@current_user, :read)
          end
          if GoogleDocsPreview.previewable?(@domain_root_account, attachment)
            json[:attachment][:public_url] = GoogleDocsPreview.url_for(attachment)
          end

          json_include = if @attachment.context.is_a?(User) || @attachment.context.is_a?(Course)
                           { include: %w(enhanced_preview_url) }
                         else
                           {}
                         end

          [json[:attachment],
           doc_preview_json(attachment, @current_user),
           attachment_json(attachment, @current_user, {}, json_include)].reduce &:merge!

          log_asset_access(attachment, "files", "files")
        end
        render :json => json
      end
    end
  end
  protected :render_attachment

  def show_relative
    path = params[:file_path]
    file_id = params[:file_id]
    file_id = nil unless file_id.to_s =~ Api::ID_REGEX

    # Manually-invoke verify_authenticity_token for non-Account contexts
    # This is to allow Account-level file downloads to skip request forgery protection
    verify_authenticity_token unless @context.is_a?(Account)

    #if the relative path matches the given file id use that file
    if file_id && @attachment = @context.attachments.where(id: file_id).first
      unless @attachment.matches_full_display_path?(path) || @attachment.matches_full_path?(path)
        @attachment = nil
      end
    end

    @attachment ||= Folder.find_attachment_in_context_with_path(@context, path)

    unless @attachment
      # if the file doesn't exist, don't leak its existence (and the context's name) to an unauthenticated user
      # (note that it is possible to have access to the file without :read on the context, e.g. with submissions)
      return unless authorized_action(@context, @current_user, :read)
      @include_js_env = true
      return render 'shared/errors/file_not_found',
        status: :bad_request,
        formats: [:html]
    end

    params[:id] = @attachment.id

    params[:download] = '1'
    show
  end

  def attachment_content
    @attachment = @context.attachments.active.find(params[:file_id])
    if authorized_action(@attachment, @current_user, :update)
      # The files page lets you edit text content inline by firing off a json
      # request to get the data.
      # Protect ourselves against reading huge files into memory -- if the
      # attachment is too big, don't return it.
      if @attachment.size > Setting.get('attachment_json_response_max_size', 1.megabyte.to_s).to_i
        render :json => { :error => t('errors.too_large', "The file is too large to edit") }
        return
      end

      stream = @attachment.open
      json = { :body => stream.read.force_encoding(Encoding::ASCII_8BIT) }
      render json: json
    end
  end

  def send_attachment(attachment)
    # check for download_frd param and, if it's present, force the user to download the
    # file and don't display it inline. we use download_frd instead of looking to the
    # download param because the download param is used all over the place to mean stuff
    # other than actually download the file. Long term we probably ought to audit the files
    # controller, make download mean download, and remove download_frd.
    if params[:inline] && !params[:download_frd] && attachment.content_type && (attachment.content_type.match(/\Atext/) || attachment.mime_class == 'text' || attachment.mime_class == 'html' || attachment.mime_class == 'code' || attachment.mime_class == 'image')
      send_stored_file(attachment)
    elsif attachment.inline_content? && !params[:download_frd] && !@context.is_a?(AssessmentQuestion)
      if params[:file_path] || !params[:wrap]
        send_stored_file(attachment)
      else
        # If the file is inlineable then redirect to the 'show' action
        # so we can wrap it in all the Canvas header/footer stuff
        redirect_to(named_context_url(@context, :context_file_url, attachment.id))
      end
    else
      send_stored_file(attachment, false)
    end
  end
  protected :send_attachment

  def send_stored_file(attachment, inline=true)
    user = @current_user
    user ||= api_find(User, params[:user_id]) if params[:user_id].present?
    attachment.context_module_action(user, :read) if user && !params[:preview]
    log_asset_access(@attachment, "files", "files") unless params[:preview]
    render_or_redirect_to_stored_file(
      attachment: attachment,
      verifier: params[:verifier],
      inline: inline
    )
  end
  protected :send_stored_file

  def create_pending
    @context = Context.find_by_asset_string(params[:attachment][:context_code])
    @asset = Context.find_asset_by_asset_string(params[:attachment][:asset_string], @context) if params[:attachment][:asset_string]
    @check_quota = true
    permission_object = nil
    permission = :create
    intent = params[:attachment][:intent]

    # Using workflow_state we can keep track of the files that have been built
    # but we don't know that there's an s3 component for yet (it's still being
    # uploaded)
    workflow_state = 'unattached'
    # There are multiple reasons why we could be building a file. The default
    # is to upload it to a context.  In the other cases we need to check the
    # permission related to the purpose to make sure the file isn't being
    # uploaded just to disappear later
    if @asset.is_a?(Assignment) && intent == 'comment'
      permission_object = @asset
      permission = :attach_submission_comment_files
      @context = @asset
      @check_quota = false
    elsif @asset.is_a?(Assignment) && intent == 'submit'
      permission_object = @asset
      permission = (@asset.submission_types || "").match(/online_upload/) ? :submit : :nothing
      @group = @asset.group_category.group_for(@current_user) if @asset.has_group_category?
      @context = @group || @current_user
      @check_quota = false
    elsif @context && intent == 'attach_discussion_file'
      permission_object = @context.discussion_topics.temp_record
      permission = :attach
    elsif @context && intent == 'message'
      permission_object = @context
      permission = :send_messages
      @check_quota = false
    elsif @context && intent && intent != 'upload'
      # In other cases (like unzipping a file, extracting a QTI, etc.
      # we don't actually want the uploaded file to show up in the context's
      # file listings.  If you set its workflow_state to unattached_temporary
      # then it will never be activated.
      workflow_state = 'unattached_temporary'
      @check_quota = false
    end

    @attachment = @context.attachments.build
    permission_object ||= @attachment
    @attachment.user = @current_user
    @attachment.modified_at = Time.now.utc
    if authorized_action(permission_object, @current_user, permission)
      if @context.respond_to?(:is_a_context?) && @check_quota
        get_quota
        return if quota_exceeded(@context, named_context_url(@context, :context_files_url))
      end
      @attachment.filename = params[:attachment][:filename]
      @attachment.file_state = 'deleted'
      @attachment.workflow_state = workflow_state
      if @context.respond_to?(:folders)
        if params[:attachment][:folder_id].present?
          @folder = @context.folders.active.where(id: params[:attachment][:folder_id]).first
          return unless authorized_action(@folder, @current_user, :manage_contents)
        end
        if intent == 'submit' && context.respond_to?(:submissions_folder) && @asset
          @folder ||= @context.submissions_folder(@asset.context)
        end
        @folder ||= Folder.unfiled_folder(@context)
        @attachment.folder_id = @folder.id
      end
      @attachment.content_type = params[:attachment][:content_type].presence || Attachment.mimetype(@attachment.filename)
      @attachment.set_publish_state_for_usage_rights
      @attachment.save!

      res = @attachment.ajax_upload_params(@current_pseudonym,
              named_context_url(@context, :context_files_url, :format => :text, :duplicate_handling => params[:attachment][:duplicate_handling]),
              s3_success_url(@attachment.id, :uuid => @attachment.uuid, :duplicate_handling => params[:attachment][:duplicate_handling]),
              :no_redirect => params[:no_redirect],
              :upload_params => {
                'attachment[folder_id]' => params[:attachment][:folder_id] || '',
                'attachment[unattached_attachment_id]' => @attachment.id,
                'check_quota_after' => @check_quota ? '1' : '0'
              },
              :default_content_type => params[:default_content_type],
              :ssl => request.ssl?)
      render :json => res
    end
  end

  def s3_success
    if params[:id].present?
      verify_api_id
      @attachment = Attachment.where(id: params[:id], workflow_state: 'unattached', uuid: params[:uuid]).first
    end
    details = @attachment.s3object.data rescue nil
    if @attachment && details
      deleted_attachments = @attachment.handle_duplicates(params[:duplicate_handling])
      @attachment.process_s3_details!(details)
      render_attachment_json(@attachment, deleted_attachments)
    else
      render :json => {:errors => [{:attribute => 'attachment', :message => 'upload failed'}]}
    end
  end

  # for local file uploads
  def api_create
    @policy, @attachment = Attachment.decode_policy(params[:Policy], params[:Signature])
    if !@policy
      return head :bad_request
    end
    @context = @attachment.context
    @attachment.workflow_state = nil
    @attachment.uploaded_data = params[:file] || params[:attachment] && params[:attachment][:uploaded_data]
    if @attachment.save
      # for consistency with the s3 upload client flow, we redirect to the success url here to finish up
      redirect_to api_v1_files_create_success_url(@attachment, :uuid => @attachment.uuid, :on_duplicate => params[:on_duplicate], :quota_exemption => params[:quota_exemption])
    else
      head :bad_request
    end
  end

  def api_create_success_cors
    head :ok
  end

  def api_capture
    unless InstFS.enabled?
      head :not_found
      return
    end

    # check service authorization
    begin
      Canvas::Security.decode_jwt(params[:token], [ InstFS.jwt_secret ])
    rescue
      head :forbidden
      return
    end

    # validate params
    unless params[:user_id] && params[:context_type] && params[:context_id]
      head :bad_request
      return
    end

    case params[:context_type]
    when 'ContentMigration'
      @context = ContentMigration.find(params[:context_id])
      @attachment = Attachment.where(context: @context).build
    when 'Quizzes::QuizSubmission'
      @context = Quizzes::QuizSubmission.find(params[:context_id])
      @attachment = @context.attachments.build
    else
      @context = Context.find_polymorphic(params[:context_type], params[:context_id])
      @attachment = @context.attachments.build
    end

    # service metadata
    @attachment.filename = params[:name]
    @attachment.display_name = params[:display_name] || params[:name]
    @attachment.size = params[:size]
    @attachment.content_type = params[:content_type]
    @attachment.instfs_uuid = params[:instfs_uuid]
    @attachment.modified_at = Time.zone.now

    # check non-exempt quota usage now that we have an actual size
    return unless value_to_boolean(params[:quota_exempt]) || check_quota_after_attachment

    # capture params
    @attachment.folder = Folder.where(id: params[:folder_id]).first
    @attachment.user = api_find(User, params[:user_id])
    @attachment.set_publish_state_for_usage_rights
    @attachment.save!

    # apply duplicate handling
    @attachment.handle_duplicates(params[:on_duplicate])

    # trigger upload success callbacks
    if @context.respond_to?(:file_upload_success_callback)
      @context.file_upload_success_callback(@attachment)
    end

    url_params = {}
    url_params[:include] = 'enhanced_preview_url' if @context.is_a?(User) || @context.is_a?(Course)
    render json: {}, status: :created, location: api_v1_attachment_url(@attachment, url_params)
  end

  def api_create_success
    @attachment = Attachment.where(id: params[:id], uuid: params[:uuid]).first
    return head :bad_request unless @attachment.try(:file_state) == 'deleted'
    return unless validate_on_duplicate(params)

    quota_exempt = @attachment.verify_quota_exemption_key(params[:quota_exemption])
    return unless quota_exempt || check_quota_after_attachment

    if Attachment.s3_storage?
      return head(:bad_request) unless @attachment.state == :unattached
      details = @attachment.s3object.data
      @attachment.process_s3_details!(details)
    else
      @attachment.file_state = 'available'
      @attachment.save!
    end
    @attachment.handle_duplicates(infer_on_duplicate(params))

    if @attachment.context.respond_to?(:file_upload_success_callback)
      @attachment.context.file_upload_success_callback(@attachment)
    end

    json_params = { omit_verifier_in_app: true }

    if @attachment.context.is_a?(User) || @attachment.context.is_a?(Course) || @attachment.context.is_a?(Group)
      json_params[:include] ||= []
      json_params[:include] << 'enhanced_preview_url'
    end

    if @attachment.usage_rights_id.present?
      json_params[:include] ||= []
      json_params[:include] << 'usage_rights'
    end

    if @attachment.context.is_a?(Course)
      json_params[:master_course_status] = setup_master_course_restrictions([@attachment], @attachment.context)
    end

    json = attachment_json(@attachment, @current_user, {}, json_params)

    # render as_text for IE, otherwise it'll prompt
    # to download the JSON response
    render :json => json, :as_text => in_app?
  end

  def api_file_status
    @attachment = Attachment.where(id: params[:id], uuid: params[:uuid]).first!
    if @attachment.file_state == 'available'
      render :json => { :upload_status => 'ready', :attachment => attachment_json(@attachment, @current_user) }
    elsif @attachment.file_state == 'deleted'
      render :json => { :upload_status => 'pending' }
    else
      render :json => { :upload_status => 'errored', :message => @attachment.upload_error_message }
    end
  end

  def create
    if (folder_id = params[:attachment].delete(:folder_id)) && folder_id.present?
      @folder = @context.folders.active.where(id: folder_id).first
      return unless authorized_action(@folder, @current_user, :manage_contents)
    end
    @folder ||= Folder.unfiled_folder(@context)
    params[:attachment][:uploaded_data] ||= params[:attachment_uploaded_data]
    params[:attachment][:uploaded_data] ||= params[:file]
    params[:attachment][:user] = @current_user
    params[:attachment].delete :context_id
    params[:attachment].delete :context_type
    duplicate_handling = params.delete :duplicate_handling
    if (unattached_attachment_id = params[:attachment].delete(:unattached_attachment_id)) && unattached_attachment_id.present?
      @attachment = @context.attachments.where(id: unattached_attachment_id, workflow_state: 'unattached').first
    end
    @attachment ||= @context.attachments.build
    if authorized_action(@attachment, @current_user, :create)
      get_quota
      return if (params[:check_quota_after].nil? || params[:check_quota_after] == '1') &&
                  quota_exceeded(@context, named_context_url(@context, :context_files_url))

      respond_to do |format|
        @attachment.folder_id ||= @folder.id
        @attachment.workflow_state = nil
        @attachment.file_state = 'available'
        @attachment.set_publish_state_for_usage_rights
        success = nil
        if params[:attachment] && params[:attachment][:source_attachment_id]
          a = Attachment.find(params[:attachment].delete(:source_attachment_id))
          if a.root_attachment_id && att = @folder.attachments.where(id: a.root_attachment_id).first
            @attachment = att
            success = true
          elsif a.grants_right?(@current_user, session, :download)
            @attachment = a.clone_for(@context, @attachment)
            success = @attachment.save
          end
        end
        if params[:attachment][:uploaded_data]
          if (@attachment.workflow_state_was != 'unattached' || params[:check_quota_after] != '0') &&
              Attachment.over_quota?(@context, params[:attachment][:uploaded_data].size)
            @attachment.errors.add(:base, t('Upload failed, quota exceeded'))
          else
            success = @attachment.update_attributes(strong_attachment_params)
            @attachment.errors.add(:base, t('errors.server_error', "Upload failed, server error, please try again.")) unless success
          end
        else
          @attachment.errors.add(:base, t('errors.missing_field', "Upload failed, expected form field missing"))
        end
        deleted_attachments = @attachment.handle_duplicates(duplicate_handling) if success
        unless @attachment.downloadable?
          success = false
          unless @attachment.errors.any?
            if (params[:attachment][:uploaded_data].size == 0 rescue false)
              @attachment.errors.add(:base, t('errors.empty_file', "That file is empty.  Please upload a different file."))
            else
              @attachment.errors.add(:base, t('errors.upload_failed', "Upload failed, please try again."))
            end
          end
          unless @attachment.new_record?
            @attachment.destroy rescue @attachment.delete
          end
        end
        if success
          @attachment.move_to_bottom
          format.html { return_to(params[:return_to], named_context_url(@context, :context_files_url)) }
          format.json do
            render_attachment_json(@attachment, deleted_attachments, @folder)
          end
          format.text do
            render_attachment_json(@attachment, deleted_attachments, @folder)
          end
        else
          format.html { render :new }
          format.json { render :json => @attachment.errors, :status => :bad_request }
          format.text { render :json => @attachment.errors, :status => :bad_request }
        end
      end
    end
  end

  def update
    @attachment = @context.attachments.find(params[:id])
    @folder = @context.folders.active.find(params[:attachment][:folder_id]) rescue nil
    return unless authorized_action(@folder, @current_user, :manage_contents) if @folder
    @folder ||= @attachment.folder
    @folder ||= Folder.unfiled_folder(@context)
    if authorized_action(@attachment, @current_user, :update)
      respond_to do |format|

        just_hide = params[:attachment][:just_hide]
        hidden = params[:attachment][:hidden]
        # Need to be careful on this one... we can't let students turn in a
        # file and then edit it after the fact...
        attachment_params = strong_attachment_params
        attachment_params.delete(:uploaded_data) if @context.is_a?(User)

        if attachment_params[:uploaded_data].present?
          @attachment.user = @current_user
          @attachment.modified_at = Time.now.utc
        end

        @attachment.attributes = attachment_params
        if just_hide == '1'
          @attachment.locked = false
          @attachment.hidden = true
        elsif hidden && (hidden.empty? || hidden == "0")
          @attachment.hidden = false
        end
        @attachment.folder = @folder
        @folder_id_changed = @attachment.folder_id_changed?
        @attachment.set_publish_state_for_usage_rights
        if @attachment.save
          @attachment.move_to_bottom if @folder_id_changed
          flash[:notice] = t 'notices.updated', "File was successfully updated."
          format.html { redirect_to named_context_url(@context, :context_files_url) }
          format.json { render :json => @attachment.as_json(:methods => [:readable_size, :mime_class, :currently_locked], :permissions => {:user => @current_user, :session => session}), :status => :ok }
        else
          format.html { render :edit }
          format.json { render :json => @attachment.errors, :status => :bad_request }
        end
      end
    end
  end

  # @API Update file
  # Update some settings on the specified file
  #
  # @argument name [String]
  #   The new display name of the file
  #
  # @argument parent_folder_id [String]
  #   The id of the folder to move this file into.
  #   The new folder must be in the same context as the original parent folder.
  #   If the file is in a context without folders this does not apply.
  #
  # @argument on_duplicate [Optional, String, "overwrite"|"rename"]
  #   If the file is moved to a folder containing a file with the same name,
  #   or renamed to a name matching an existing file, the API call will fail
  #   unless this parameter is supplied.
  #
  #   "overwrite":: Replace the existing file with the same name
  #   "rename":: Add a qualifier to make the new filename unique
  #
  # @argument lock_at [DateTime]
  #   The datetime to lock the file at
  #
  # @argument unlock_at [DateTime]
  #   The datetime to unlock the file at
  #
  # @argument locked [Boolean]
  #   Flag the file as locked
  #
  # @argument hidden [Boolean]
  #   Flag the file as hidden
  #
  # @example_request
  #
  #   curl -X PUT 'https://<canvas>/api/v1/files/<file_id>' \
  #        -F 'name=<new_name>' \
  #        -F 'locked=true' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns File
  def api_update
    @attachment = Attachment.find(params[:id])
    if authorized_action(@attachment,@current_user,:update)
      @context = @attachment.context
      if @context && params[:parent_folder_id]
        folder = @context.folders.active.find(params[:parent_folder_id])
        if authorized_action(folder, @current_user, :update)
          @attachment.folder = folder
        else
          return
        end
      end

      @attachment.display_name = params[:name] if params.key?(:name)
      @attachment.lock_at = params[:lock_at] if params.key?(:lock_at)
      @attachment.unlock_at = params[:unlock_at] if params.key?(:unlock_at)
      @attachment.locked = value_to_boolean(params[:locked]) if params.key?(:locked)
      @attachment.hidden = value_to_boolean(params[:hidden]) if params.key?(:hidden)

      @attachment.set_publish_state_for_usage_rights if @attachment.context.is_a?(Group)
      if !@attachment.locked? && @attachment.locked_changed? && @attachment.usage_rights_id.nil? && @context.respond_to?(:feature_enabled?)  && @context.feature_enabled?(:usage_rights_required)
        return render :json => { :message => I18n.t('This file must have usage_rights set before it can be published.') }, :status => :bad_request
      end
      if (@attachment.folder_id_changed? || @attachment.display_name_changed?) && @attachment.folder.active_file_attachments.where(display_name: @attachment.display_name).where("id<>?", @attachment.id).exists?
        return render json: {message: "file already exists; use on_duplicate='overwrite' or 'rename'"}, status: :conflict unless %w(overwrite rename).include?(params[:on_duplicate])
        on_duplicate = params[:on_duplicate].to_sym
      end
      if @attachment.save
        @attachment.handle_duplicates(on_duplicate) if on_duplicate
        render :json => attachment_json(@attachment, @current_user, {}, { omit_verifier_in_app: true })
      else
        render :json => @attachment.errors, :status => :bad_request
      end
    end
  end

  def reorder
    @folder = @context.folders.active.find(params[:folder_id])
    if authorized_action(@context, @current_user, :manage_files)
      @folders = @folder.active_sub_folders.by_position
      @folders.first && @folders.first.update_order((params[:folder_order] || "").split(","))
      @folder.file_attachments.by_position_then_display_name.first && @folder.file_attachments.first.update_order((params[:order] || "").split(","))
      @folder.reload
      render :json => @folder.subcontent.map{ |f| f.as_json(methods: :readable_size, permissions: {user: @current_user, session: session}) }
    end
  end


  # @API Delete file
  # Remove the specified file
  #
  # @argument replace [boolean]
  #   This action is irreversible.
  #   If replace is set to true the file contents will be replaced with a
  #   generic "file has been removed" file. This also destroys any previews
  #   that have been generated for the file.
  #   Must have manage files and become other users permissions
  #
  # @example_request
  #
  #   curl -X DELETE 'https://<canvas>/api/v1/files/<file_id>' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns File
  def destroy
    @attachment = Attachment.find(params[:id])
    if value_to_boolean(params[:replace])
      @context = @attachment.context
      if can_replace_file?
        @attachment.destroy_content_and_replace(@current_user)
        return render json: attachment_json(@attachment, @current_user, {}, {omit_verifier_in_app: true})
      else
        return render_unauthorized_action
      end
    end
    if can_do(@attachment, @current_user, :delete)
      return render_unauthorized_action if master_courses? && editing_restricted?(@attachment)
      @attachment.destroy
      respond_to do |format|
        format.html {
          require_context
          redirect_to named_context_url(@context, :context_files_url)
        }
        if api_request?
          format.json { render :json => attachment_json(@attachment, @current_user, {}, { omit_verifier_in_app: true }) }
        else
          format.json { render :json => @attachment }
        end
      end
    elsif @attachment.associated_with_submission?
      render :json => { :message => I18n.t('Cannot delete a file that has been submitted as part of an assignment') }, :status => :forbidden
    else
      render :json => { :message => I18n.t('Unauthorized to delete this file') }, :status => :unauthorized
    end
  end

  def can_replace_file?
    if @context.is_a?(User)
      @context.can_masquerade?(@current_user, @domain_root_account)
    else
      @context.grants_right?(@current_user, nil, :manage_files) &&
        @domain_root_account.grants_right?(@current_user, nil, :become_user)
    end
  end

  def image_thumbnail
    cancel_cache_buster
    url = Rails.cache.fetch(['thumbnail_url', params[:uuid], params[:size]].cache_key, :expires_in => 30.minutes) do
      attachment = Attachment.active.where(id: params[:id], uuid: params[:uuid]).first if params[:id].present?
      thumb_opts = params.slice(:size)
      url = attachment.thumbnail_url(thumb_opts) rescue nil
      url ||= '/images/no_pic.gif'
      url
    end
    redirect_to url
  end

  # when using local storage, the image_thumbnail action redirects here rather
  # than to a s3 url
  def show_thumbnail
    if Attachment.local_storage?
      cancel_cache_buster
      thumbnail = Thumbnail.where(id: params[:id], uuid: params[:uuid]).first if params[:id].present?
      raise ActiveRecord::RecordNotFound unless thumbnail
      send_file thumbnail.full_filename, :content_type => thumbnail.content_type
    else
      image_thumbnail
    end
  end

  private

  def open_cors
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization, Accept-Encoding'
  end

  def render_attachment_json(attachment, deleted_attachments, folder = attachment.folder)
    json = {
      :attachment => attachment.as_json(
        allow: :uuid,
        methods: [:uuid,:readable_size,:mime_class,:currently_locked,:thumbnail_url],
        permissions: {user: @current_user, session: session},
        include_root: false
      ).merge(doc_preview_json(attachment, @current_user)),
      :deleted_attachment_ids => deleted_attachments.map(&:id)
    }
    if folder.name == 'profile pictures'
      json[:avatar] = avatar_json(@current_user, attachment, { :type => 'attachment' })
    end
    StringifyIds.recursively_stringify_ids(json)

    render :json => json, :as_text => true
  end

  def strong_attachment_params
    params.require(:attachment).permit(:display_name, :locked, :lock_at, :unlock_at, :uploaded_data, :hidden)
  end
end
