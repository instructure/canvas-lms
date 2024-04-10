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

# @API Files
# An API for managing files and folders
# See the File Upload Documentation for details on the file upload workflow.
#
# @model File
#     {
#       "id": "File",
#       "description": "",
#       "properties": {
#         "id": {
#           "example": 569,
#           "type": "integer"
#         },
#         "uuid": {
#           "example": "SUj23659sdfASF35h265kf352YTdnC4",
#           "type": "string"
#         },
#         "folder_id": {
#           "example": 4207,
#           "type": "integer"
#         },
#         "display_name": {
#           "example": "file.txt",
#           "type": "string"
#         },
#         "filename": {
#           "example": "file.txt",
#           "type": "string"
#         },
#         "content-type": {
#           "example": "text/plain",
#           "type": "string"
#         },
#         "url": {
#           "example": "http://www.example.com/files/569/download?download_frd=1&verifier=c6HdZmxOZa0Fiin2cbvZeI8I5ry7yqD7RChQzb6P",
#           "type": "string"
#         },
#         "size": {
#           "example": 43451,
#           "type": "integer",
#           "description": "file size in bytes"
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
#           "example": "2012-07-07T14:58:50Z",
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
#           "example": "2012-07-20T14:58:50Z",
#           "type": "datetime"
#         },
#         "hidden_for_user": {
#           "example": false,
#           "type": "boolean"
#         },
#         "visibility_level": {
#           "example": "course",
#           "type": "string",
#           "description": "Changes who can access the file. Valid options are 'inherit' (the default), 'course', 'institution', and 'public'. Only valid in course endpoints."
#         },
#         "thumbnail_url": {
#           "type": "string"
#         },
#         "modified_at": {
#           "example": "2012-07-06T14:58:50Z",
#           "type": "datetime"
#         },
#         "mime_class": {
#           "type": "string",
#           "example": "html",
#           "description": "simplified content-type mapping"
#         },
#         "media_entry_id": {
#           "type": "string",
#           "example": "m-3z31gfpPf129dD3sSDF85SwSDFnwe",
#           "description": "identifier for file in third-party transcoding service"
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
  protect_from_forgery except: [:api_capture, :show_relative], with: :exception

  before_action :require_user, only: :create_pending
  before_action :require_context, except: %i[
    assessment_question_show
    image_thumbnail
    show_thumbnail
    create_pending
    s3_success
    show
    api_create
    api_create_success
    api_create_success_cors
    api_show
    api_index
    destroy
    api_update
    api_file_status
    public_url
    api_capture
    icon_metadata
    reset_verifier
    show_relative
  ]

  before_action :open_limited_cors, only: [:show]
  before_action :open_cors, only: %i[
    api_create api_create_success api_create_success_cors show_thumbnail
  ]

  before_action :check_file_access_flags, only: [:show_relative, :show]

  skip_before_action :verify_authenticity_token, only: :api_create
  before_action :verify_api_id, only: %i[
    api_show api_create_success api_file_status api_update destroy icon_metadata reset_verifier
  ]

  include Api::V1::Attachment
  include Api::V1::Avatar
  include AttachmentHelper
  include FilesHelper
  include K5Mode

  before_action { |c| c.active_tab = "files" }

  def verify_api_id
    raise ActiveRecord::RecordNotFound unless Api::ID_REGEX.match?(params[:id])
  end

  def quota
    get_quota
    if authorized_action(@context.attachments.temp_record, @current_user, %i[create update delete])
      h = ActiveSupport::NumberHelper
      result = {
        quota: h.number_to_human_size(@quota),
        quota_used: h.number_to_human_size(@quota_used),
        quota_full: (@quota_used >= @quota)
      }
      render json: result
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
    # allow user quota info to be viewed by admins
    permitted = true if @context.is_a?(User) &&
                        @domain_root_account.grants_any_right?(
                          @current_user,
                          *RoleOverride::GRANULAR_FILE_PERMISSIONS
                        )
    if permitted || authorized_action(@context.attachments.build, @current_user, %i[create update delete])
      get_quota
      render json: { quota: @quota, quota_used: @quota_used }
    end
  end

  def check_file_access_flags
    access_verifier = {}
    begin
      access_verifier = validate_access_verifier
    rescue Canvas::Security::TokenExpired
      # maybe their browser is being stupid and came to the files domain directly with an old verifier - try to go back and get a new one
      return redirect_to_fallback_url if files_domain?
    rescue Users::AccessVerifier::InvalidVerifier
      nil
    end

    if access_verifier[:user]
      # attachment.rb checks for this session attribute when determining
      # permissions, but it should be ignored by the rest of the models'
      # permission checks
      session["file_access_user_id"] = access_verifier[:user].global_id
      session["file_access_real_user_id"] = access_verifier[:real_user]&.global_id
      session["file_access_developer_key_id"] = access_verifier[:developer_key]&.global_id
      session["file_access_root_account_id"] = access_verifier[:root_account]&.global_id
      session["file_access_oauth_host"] = access_verifier[:oauth_host]
      session["file_access_expiration"] = 1.hour.from_now.to_i
      session.file_access_user = access_verifier[:user]

      session[:permissions_key] = SecureRandom.uuid

      # if this was set we really just wanted to set the session on the files domain and return back to what we were doing before
      if access_verifier[:return_url]
        return redirect_to access_verifier[:return_url]
      end
    end
    # These sessions won't get deleted when the user logs out since this
    # is on a separate domain, so we've added our own (stricter) timeout.
    if session && session["file_access_user_id"] && session["file_access_expiration"].to_i > Time.now.to_i
      session["file_access_expiration"] = 1.hour.from_now.to_i
      session[:permissions_key] = SecureRandom.uuid
    end
    true
  end
  protected :check_file_access_flags

  def redirect_to_fallback_url
    fallback_url = params[:sf_verifier] && Canvas::Security.decode_jwt(params[:sf_verifier], ignore_expiration: true)[:fallback_url]
    if fallback_url
      redirect_to fallback_url
    else
      render_unauthorized_action # oh well we tried
    end
  end
  protected :redirect_to_fallback_url

  def index
    react_files
  end

  # @API List files
  # Returns the paginated list of files for the folder or course.
  #
  # @argument content_types[] [String]
  #   Filter results by content-type. You can specify type/subtype pairs (e.g.,
  #   'image/jpeg'), or simply types (e.g., 'image', which will match
  #   'image/gif', 'image/jpeg', etc.).
  #
  # @argument exclude_content_types[] [String]
  #   Exclude given content-types from your results. You can specify type/subtype pairs (e.g.,
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
    GuardRail.activate(:secondary) do
      get_context
      verify_api_id unless @context.present?
      @folder = Folder.from_context_or_id(@context, params[:id])

      if authorized_action(@folder, @current_user, :read_contents)
        params[:sort] ||= params[:sort_by] # :sort_by was undocumented; :sort is more consistent with other APIs such as wikis
        params[:include] = Array(params[:include])
        params[:include] << "user" if params[:sort] == "user"

        scope = Attachments::ScopedToUser.new(@context || @folder, @current_user).scope
        scope = scope.preload(:user) if params[:include].include?("user") && params[:sort] != "user"
        scope = scope.preload(:usage_rights) if params[:include].include?("usage_rights")
        scope = Attachment.search_by_attribute(scope, :display_name, params[:search_term], normalize_unicode: true)

        order_clause = case params[:sort]
                       when "position" # undocumented; kept for compatibility
                         "attachments.position, #{Attachment.display_name_order_by_clause("attachments")}"
                       when "size"
                         "attachments.size"
                       when "created_at"
                         "attachments.created_at"
                       when "updated_at"
                         "attachments.updated_at"
                       when "content_type"
                         "attachments.content_type"
                       when "user"
                         scope.primary_shard.activate do
                           scope = scope.joins("LEFT OUTER JOIN #{User.quoted_table_name} ON attachments.user_id=users.id")
                         end
                         "users.sortable_name IS NULL, #{User.sortable_name_order_by_clause("users")}"
                       else
                         Attachment.display_name_order_by_clause("attachments")
                       end
        order_clause = "#{order_clause} DESC" if params[:order] == "desc"
        scope = scope.order(Arel.sql(order_clause)).order(id: (params[:order] == "desc") ? :desc : :asc)

        if params[:content_types].present?
          scope = scope.by_content_types(Array(params[:content_types]))
        end

        if params[:exclude_content_types].present?
          scope = scope.by_exclude_content_types(Array(params[:exclude_content_types]))
        end

        if params[:category].present?
          scope = scope.for_category(params[:category])
        end

        url = @context ? context_files_url : api_v1_list_files_url(@folder)
        @files = Api.paginate(scope, self, url)

        log_asset_access(["files", @context], "files")

        render json: attachments_json(@files, @current_user, {}, {
                                        can_view_hidden_files: can_view_hidden_files?(@context || @folder, @current_user, session),
                                        context: @context || @folder.context,
                                        include: params[:include],
                                        only: params[:only],
                                        omit_verifier_in_app: !value_to_boolean(params[:use_verifiers])
                                      })
      end
    end
  end

  def images
    if authorized_action(@context.attachments.temp_record, @current_user, :read)
      @images = if Folder.root_folders(@context).first.grants_right?(@current_user, session, :read_contents)
                  if @context.grants_any_right?(@current_user, session, *RoleOverride::GRANULAR_FILE_PERMISSIONS)
                    @context.active_images.paginate page: params[:page]
                  else
                    @context.active_images.not_hidden.not_locked.where(folder_id: @context.active_folders.not_hidden.not_locked).paginate page: params[:page]
                  end
                else
                  [].paginate
                end
      headers["X-Total-Pages"] = @images.total_pages.to_s
      render partial: "shared/wiki_image", collection: @images
    end
  end

  def react_files
    unless request.format.html?
      return render body: "endpoint does not support #{request.format.symbol}", status: :bad_request
    end

    if authorized_action(@context, @current_user, [:read_files, *RoleOverride::GRANULAR_FILE_PERMISSIONS]) &&
       tab_enabled?(@context.class::TAB_FILES)
      @contexts = [@context]
      get_all_pertinent_contexts(include_groups: true, cross_shard: true) if @context == @current_user
      files_contexts = @contexts.map do |context|
        tool_context = case context
                       when Course
                         context
                       when User
                         @domain_root_account
                       when Group
                         context.context
                       end

        has_external_tools = !context.is_a?(Group) && tool_context

        file_menu_tools = (has_external_tools ? external_tools_display_hashes(:file_menu, tool_context, [:accept_media_types]) : [])
        file_index_menu_tools = if has_external_tools
                                  external_tools_display_hashes(:file_index_menu, tool_context)
                                else
                                  []
                                end

        {
          asset_string: context.asset_string,
          name: (context == @current_user) ? t("my_files", "My Files") : context.name,
          usage_rights_required: tool_context.respond_to?(:usage_rights_required?) && tool_context.usage_rights_required?,
          permissions: {
            manage_files_add: context.grants_right?(@current_user, session, :manage_files_add),
            manage_files_edit: context.grants_right?(@current_user, session, :manage_files_edit),
            manage_files_delete: context.grants_right?(@current_user, session, :manage_files_delete),
          },
          file_menu_tools:,
          file_index_menu_tools:
        }
      end

      @page_title = t("files_page_title", "Files")
      @body_classes << "full-width padless-content"
      js_bundle :files
      css_bundle :react_files
      js_env({
               FILES_CONTEXTS: files_contexts,
               COURSE_ID: context.id.to_s
             })
      log_asset_access(["files", @context], "files", "other")

      set_tutorial_js_env

      render html: "".html_safe, layout: true
    end
  end

  def assessment_question_show
    @context = AssessmentQuestion.find(params[:assessment_question_id])
    @attachment = @context.attachments.find(params[:id])
    @skip_crumb = true
    if @attachment.deleted?
      flash[:notice] = t "notices.deleted", "The file %{display_name} has been deleted", display_name: @attachment.display_name
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
    verifier_checker = Attachments::Verification.new(@attachment)

    # if the attachment is part of a submisison, its 'context' will be the student that submmited the assignment.  so if  @current_user is a
    # teacher authorized_action(@attachment, @current_user, :download) will be false, we need to actually check if they have perms to see the
    # submission.
    @submission = Submission.active.find(params[:submission_id]) if params[:submission_id]
    # verify that the requested attachment belongs to the submission
    return render_unauthorized_action if @submission && !@submission.includes_attachment?(@attachment)

    if (@submission && authorized_action(@submission, @current_user, :read)) ||
       ((params[:verifier] && verifier_checker.valid_verifier_for_permission?(params[:verifier], :download, session)) || authorized_action(@attachment, @current_user, :download))
      render json: { public_url: @attachment.public_url(secure: request.ssl?) }
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
  # @argument replacement_chain_context_type [Optional, String]
  #   When a user replaces a file during upload, Canvas keeps track of the "replacement chain."
  #
  #   Include this parameter if you wish Canvas to follow the replacement chain if the requested
  #   file was deleted and replaced by another.
  #
  #   Must be set to 'course' or 'account'. The "replacement_chain_context_id" parameter must
  #   also be included.
  #
  # @argument replacement_chain_context_id [Optional, Integer]
  #   When a user replaces a file during upload, Canvas keeps track of the "replacement chain."
  #
  #   Include this parameter if you wish Canvas to follow the replacement chain if the requested
  #   file was deleted and replaced by another.
  #
  #   Indicates the context ID Canvas should use when following the "replacement chain." The
  #   "replacement_chain_context_type" parameter must also be included.
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

    @attachment = @context ? @context.attachments.not_deleted.find_by(id: params[:id]) : Attachment.not_deleted.find_by(id: params[:id])

    if replacement_chain_context
      replacement = attachment_or_replacement(replacement_chain_context, params[:id])
      @attachment ||= replacement if replacement&.available?
    end

    unless @attachment
      render json: { errors: [{ message: "The specified resource does not exist." }] }, status: :not_found
      return
    end

    params[:include] = Array(params[:include])
    if access_allowed(@attachment, @current_user, :read)
      options = { include: params[:include], verifier: params[:verifier], omit_verifier_in_app: !value_to_boolean(params[:use_verifiers]) }
      if options[:include].include?("blueprint_course_status")
        options[:context] = @context || @folder&.context || @attachment.context
        options[:can_view_hidden_files] = can_view_hidden_files?(options[:context], @current_user, session)
      end
      json = attachment_json(@attachment, @current_user, {}, options)

      # Add canvadoc session URL if the file is unlocked
      json.merge!(
        doc_preview_json(@attachment, locked_for_user: json[:locked_for_user])
      )
      render json:
    end
  end

  # @API Translate file reference
  # Get information about a file from a course copy file reference
  #
  # @example_request
  #
  #   curl https://<canvas>/api/v1/courses/1/files/file_ref/i567b573b77fab13a1a39937c24ae88f2 \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns File
  def file_ref
    get_context

    @attachment = @context.attachments.not_deleted.find_by(migration_id: params[:migration_id])
    raise ActiveRecord::RecordNotFound unless @attachment
    return unless authorized_action(@attachment, @current_user, :read)

    render json: attachment_json(@attachment, @current_user, session, params)
  end

  def context_for_file_after_user_merge(search_context, file_id)
    # Users can create links that look like /users/:user_id/files/:file_id in the RCE. Then
    # after the user is merged, that old user context is no longer correct for the file attchment
    # and they'll get a 404 trying to access the file.
    # So we have two choices: fix all of the links in their html content or make their old file
    # links work. I hate both options, but making their old file links work was less complicated.
    # To do that, we find the context that the files have been moved to. This is normally the
    # active user they were merged to or the last user they were merged into before a cross-shard
    # merge (in which case we copy the files instead of moving them and the file ID we're looking
    # for is now associated to a past user), but the files don't get moved to the new user during
    # a merge if there's a duplicate, so it could be on any user in the chain on the current shard
    search_context.shard.activate do
      User.from(<<~SQL.squish).joins(<<~SQL2.squish).where(attachments: { id: file_id }).first || search_context
        (WITH RECURSIVE user_mergers AS (
          SELECT umd.from_user_id, umd.user_id
          FROM #{UserMergeData.quoted_table_name} umd
          WHERE umd.from_user_id=#{User.connection.quote(search_context.id)} AND umd.workflow_state = 'active'
          UNION
          SELECT umd.from_user_id, umd.user_id
          FROM #{UserMergeData.quoted_table_name} umd
          INNER JOIN user_mergers ON user_mergers.user_id=umd.from_user_id
          WHERE umd.workflow_state = 'active' AND umd.user_id < #{Shard::IDS_PER_SHARD}
        ) SELECT * FROM user_mergers) AS user_mergers
      SQL
        INNER JOIN #{User.quoted_table_name} ON users.id = user_mergers.user_id
        INNER JOIN #{Attachment.quoted_table_name} ON attachments.context_type = 'User' AND attachments.context_id = users.id
      SQL2
    end
  end

  def show
    GuardRail.activate(:secondary) do
      params[:id] ||= params[:file_id]

      get_context(user_scope: merged_user_scope)

      if @context.is_a?(User) && @context.deleted?
        @context = context_for_file_after_user_merge(@context, params[:id])
      end

      # NOTE: the /files/XXX URL implicitly uses the current user as the
      # context, even though it doesn't search for the file using
      # @current_user.attachments.find, since it might not actually be a user
      # attachment.
      # this implicit context magic happens in ApplicationController#get_context
      if @context.nil? || @current_user.nil? || @context == @current_user
        @attachment = Attachment.find(params[:id])

        # Check if a specific context for the relation replacement chain
        # was set. If so, use it to look up the attachment. This is needed
        # for some services (like Buttons & Icons) to avoid setting @context
        # and being redirected
        if replacement_chain_context && @attachment.deleted?
          @attachment = attachment_or_replacement(replacement_chain_context, params[:id])
        end

        @context = nil unless @context == @current_user || @context == @attachment.context
        @skip_crumb = true unless @context
      else
        @attachment ||= attachment_or_replacement(@context, params[:id])
      end

      if @attachment.inline_content? && params[:sf_verifier]
        return redirect_to url_for(params.to_unsafe_h.except(:sf_verifier))
      end

      params[:download] ||= params[:preview]
      add_crumb(t("#crumbs.files", "Files"), named_context_url(@context, :context_files_url)) unless @skip_crumb
      if @attachment.deleted?
        if @current_user.nil? || @attachment.user_id != @current_user.id
          @not_found_message = t("could_not_find_file", "This file has been deleted")
          render status: :not_found, template: "shared/errors/404_message", formats: [:html]
          return
        end
        flash[:notice] = t "notices.deleted", "The file %{display_name} has been deleted", display_name: @attachment.display_name
        if params[:preview] && @attachment.mime_class == "image"
          redirect_to "/images/blank.png"
        elsif request.format == :json
          render json: { deleted: true }
        else
          redirect_to named_context_url(@context, :context_files_url)
        end
        return
      end

      if access_allowed(@attachment, @current_user, :read)
        @attachment.ensure_media_object
        verifier_checker = Attachments::Verification.new(@attachment)

        if params[:download]
          if (params[:verifier] && verifier_checker.valid_verifier_for_permission?(params[:verifier], :download, session)) ||
             @attachment.grants_right?(@current_user, session, :download)
            disable_page_views if params[:preview]
            begin
              send_attachment(@attachment)
            rescue => e
              @headers = false if params[:ts] && params[:verifier]
              @not_found_message = t "errors.not_found", "It looks like something went wrong when this file was uploaded, and we can't find the actual file.  You may want to notify the owner of the file and have them re-upload it."
              Canvas::Errors.capture_exception(self.class.name, e)
              render "shared/errors/404_message",
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
          log_attachment_access(@attachment)
          render json: { ok: true }
        else
          # Module items count as an asset access
          log_attachment_access(@attachment) if params[:module_item_id]

          render_attachment(@attachment)
        end
      end
    end
  end

  def render_attachment(attachment)
    respond_to do |format|
      if params[:download] && attachment.mime_class == "image"
        format.html { redirect_to "/images/svg-icons/icon_lock.svg" }
      else
        if @files_domain
          @headers = false
          @show_left_side = false
        end
        if attachment.content_type&.match(%r{\Avideo/|audio/}) || (attachment.canvadocable? ||
          GoogleDocsPreview.previewable?(@domain_root_account, attachment))
          attachment.context_module_action(@current_user, :read)
        end
        format.html do
          if attachment.locked_for?(@current_user, check_policies: true)
            render :show, status: :forbidden
          elsif attachment.inline_content? && !attachment.canvadocable? && safer_domain_available? && !params[:fd_cookie_set]
            # redirect to the files domain and have the files domain redirect back with the param set
            # so we know the user session has been set there and relative files from the html will work
            query = URI.parse(request.url).query
            return_url = request.url + (query.present? ? "&" : "?") + "fd_cookie_set=1"
            redirect_to safe_domain_file_url(attachment, return_url:)
          else
            render :show
          end
        end
      end
      format.json do
        json = {
          attachment: {
            workflow_state: attachment.workflow_state,
            content_type: attachment.content_type
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
                           { include: %w[enhanced_preview_url] }
                         else
                           {}
                         end

          json[:attachment].merge!(
            attachment_json(attachment, @current_user, {}, json_include.merge(verifier: params[:verifier]))
          )

          # Add canvadoc session URL if the file is unlocked
          json[:attachment].merge!(
            doc_preview_json(
              attachment,
              locked_for_user: json.dig(:attachment, :locked_for_user)
            )
          )

          log_asset_access(attachment, "files", "files")
        end

        render json:
      end
    end
  end
  protected :render_attachment

  def show_relative
    require_context(user_scope: merged_user_scope)

    path = params[:file_path]
    file_id = params[:file_id]
    file_id = nil unless Api::ID_REGEX.match?(file_id.to_s)

    # Manually-invoke verify_authenticity_token for non-Account contexts
    # This is to allow Account-level file downloads to skip request forgery protection
    verify_authenticity_token unless @context.is_a?(Account)

    # if the relative path matches the given file id use that file
    if file_id && (@attachment = @context.attachments.where(id: file_id).first) &&
       !(@attachment.matches_full_display_path?(path) || @attachment.matches_full_path?(path))
      @attachment = nil
    end

    @attachment ||= Folder.find_attachment_in_context_with_path(@context, path)

    unless @attachment
      # if the file doesn't exist, don't leak its existence (and the context's name) to an unauthenticated user
      # (note that it is possible to have access to the file without :read on the context, e.g. with submissions)
      return unless authorized_action(@context, @current_user, :read)

      @include_js_env = true
      return render "shared/errors/file_not_found",
                    status: :bad_request,
                    formats: [:html]
    end

    params[:id] = @attachment.id

    params[:download] = "1"
    show
  end

  def attachment_content
    @attachment = @context.attachments.active.find(params[:file_id])
    if authorized_action(@attachment, @current_user, :update)
      # The files page lets you edit text content inline by firing off a json
      # request to get the data.
      # Protect ourselves against reading huge files into memory -- if the
      # attachment is too big, don't return it.
      if @attachment.size > 1.megabyte
        render json: { error: t("errors.too_large", "The file is too large to edit") }
        return
      end

      stream = @attachment.open
      json = { body: stream.read.force_encoding(Encoding::ASCII_8BIT) }
      render json:
    end
  end

  def send_attachment(attachment)
    # check for download_frd param and, if it's present, force the user to download the
    # file and don't display it inline. we use download_frd instead of looking to the
    # download param because the download param is used all over the place to mean stuff
    # other than actually download the file. Long term we probably ought to audit the files
    # controller, make download mean download, and remove download_frd.
    if params[:inline] && !params[:download_frd] && attachment.content_type && (attachment.content_type&.start_with?("text") || attachment.mime_class == "text" || attachment.mime_class == "html" || attachment.mime_class == "code" || attachment.mime_class == "image")
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

  def send_stored_file(attachment, inline = true)
    user = file_access_user
    attachment.context_module_action(user, :read) if user && !params[:preview]

    if params[:preview].blank?
      log_asset_access(@attachment, "files", "files")
      Canvas::LiveEvents.asset_access(@attachment, "files", nil, nil) if @current_user.blank?
    end

    render_or_redirect_to_stored_file(
      attachment:,
      verifier: params[:verifier],
      inline:
    )
  end
  protected :send_stored_file

  # Is the user permitted to upload a file to the context with the given intent
  # and related asset?
  def authorized_upload?(context, asset, intent)
    if asset.is_a?(Assignment) && intent == "comment"
      authorized_action(asset, @current_user, :attach_submission_comment_files)
    elsif asset.is_a?(Assignment) && intent == "submit"
      # despite name, this is really just asking if the assignment expects an
      # upload
      # The discussion_topic check is to allow attachments to graded discussions to not count against the user's quota.
      if asset.submission_types == "discussion_topic"
        any_entry = asset.discussion_topic.discussion_entries.temp_record
        authorized_action(any_entry, @current_user, :attach)
      elsif asset.allow_google_docs_submission?
        authorized_action(asset, @current_user, :submit)
      else
        authorized_action(asset, @current_user, :nothing)
      end
    elsif intent == "attach_discussion_file"
      any_topic = context.discussion_topics.temp_record
      authorized_action(any_topic, @current_user, :attach)
    elsif intent == "message"
      authorized_action(context, @current_user, :send_messages)
    else
      any_attachment = context.attachments.temp_record
      authorized_action(any_attachment, @current_user, :create)
    end
  end
  protected :authorized_upload?

  # Do we need to check quota for an upload to the context with the given
  # intent?
  def check_quota?(context, intent)
    if ["upload", "attach_discussion_file"].include?(intent) || !intent
      # uploads and discussion attachments count against quota if the context
      # has one. no explicit intent is assumed to be upload intent
      context.respond_to?(:is_a_context?)
    else
      # other intents (e.g. 'comment', 'submit', message') do not run up
      # against quota
      false
    end
  end
  protected :check_quota?

  # If no folder is specified, into what folder should uploads to the context
  # with the given intent and related asset be filed?
  def default_folder(context, asset, intent)
    if intent == "submit" && context.respond_to?(:submissions_folder) && asset
      context.submissions_folder(asset.context)
    else
      Folder.unfiled_folder(context)
    end
  end

  # For the given intent and related asset, should the uploaded file be treated
  # as temporary? (e.g. in cases like unzipping a file, extracting a QTI, etc.
  # we don't actually want the uploaded file to show up in the context's file
  # listings.)
  def temporary_file?(asset, intent)
    intent &&
      !%w[message attach_discussion_file upload].include?(intent) &&
      !(asset.is_a?(Assignment) && ["comment", "submit"].include?(intent))
  end
  protected :temporary_file?

  def create_pending
    # to what entity should the attachment "belong"?
    # regarding which entity is the attachment being created?
    # with what intent is the attachment being created?
    @context = Context.find_by_asset_string(params[:attachment][:context_code])
    @asset = Context.find_asset_by_asset_string(params[:attachment][:asset_string], @context) if params[:attachment][:asset_string]
    intent = params[:attachment][:intent]

    # Discussions Redesign is now using this endpoint and this is how we make it work for them.
    # We need to find the asset if it's a discussion topic and the asset_string is provided.
    # This only applies when the intent is "submit" and the asset.submission_types is a "discussion_topic".
    if params[:attachment][:asset_string] && @asset.nil? && intent == "submit"
      asset = Context.find_asset_by_asset_string(params[:attachment][:asset_string])

      if asset.is_a?(Assignment) && asset.submission_types == "discussion_topic"
        @asset = asset
      end
    end

    # correct context for assignment-related attachments
    if @asset.is_a?(Assignment) && intent == "comment"
      # attachments that are comments on an assignment "belong" to the
      # assignment, even if another context was nominally provided
      @context = @asset
    elsif @asset.is_a?(Assignment) && intent == "submit" && @asset.submission_types != "discussion_topic"
      # assignment submissions belong to either the group (if it's a group
      # assignment) or the user, even if another context was nominally provided
      group = @asset.group_category.group_for(@current_user) if @asset.has_group_category?
      @context = group || @current_user
    end
    if authorized_upload?(@context, @asset, intent)
      api_attachment_preflight(@context,
                               request,
                               check_quota: check_quota?(@context, intent),
                               folder: default_folder(@context, @asset, intent),
                               temporary: temporary_file?(@asset, intent),
                               params: {
                                 filename: params[:attachment][:filename],
                                 content_type: params[:attachment][:content_type],
                                 size: params[:attachment][:size],
                                 parent_folder_id: params[:attachment][:folder_id],
                                 on_duplicate: params[:attachment][:on_duplicate],
                                 no_redirect: params[:no_redirect],
                                 success_include: params[:success_include]
                               })
    end
  end

  # for local file uploads
  def api_create
    @policy, @attachment = Attachment.decode_policy(params[:Policy], params[:Signature])
    unless @policy
      return head :bad_request
    end

    @context = @attachment.context
    @attachment.workflow_state = nil
    @attachment.uploaded_data = params[:file] || (params[:attachment] && params[:attachment][:uploaded_data])
    if @attachment.save
      # for consistency with the s3 upload client flow, we redirect to the success url here to finish up
      includes = Array(params[:success_include])
      includes << "avatar" if @attachment.folder == @attachment.user&.profile_pics_folder
      redirect_to api_v1_files_create_success_url(@attachment,
                                                  uuid: @attachment.uuid,
                                                  on_duplicate: params[:on_duplicate],
                                                  quota_exemption: params[:quota_exemption],
                                                  include: includes)
    else
      head :bad_request
    end
  end

  def api_create_success_cors
    head :ok
  end

  # intentionally narrower than the list on `Attachment.belongs_to :context`
  VALID_ATTACHMENT_CONTEXTS = [
    "User",
    "Course",
    "Group",
    "Assignment",
    "ContentMigration",
    "Quizzes::QuizSubmission",
    "ContentMigration",
    "Quizzes::QuizSubmission"
  ].freeze

  def api_capture
    unless InstFS.enabled?
      head :not_found
      return
    end

    # check service authorization
    unless InstFS.validate_capture_jwt(params[:token])
      head :forbidden
      return
    end

    # validate params
    unless params[:user_id] && params[:context_type] && params[:context_id]
      head :bad_request
      return
    end

    unless VALID_ATTACHMENT_CONTEXTS.include?(params[:context_type])
      head :bad_request
      return
    end

    model = Object.const_get(params[:context_type])
    @context = model.where(id: params[:context_id]).first

    overwritten_instfs_uuid = nil
    @attachment = if params.key?(:precreated_attachment_id)
                    att = Attachment.where(id: params[:precreated_attachment_id]).take
                    if att.nil?
                      reject! "Requested to use precreated attachment, but attachment with id #{params[:precreated_attachment_id]} doesn't exist", 422
                    else
                      att.file_state = "available"
                      att
                    end
                  else
                    @context.shard.activate do
                      # avoid creating an identical Attachment
                      unless params[:on_duplicate] == "rename"
                        att = Attachment.active.find_by(context: @context,
                                                        folder_id: params[:folder_id],
                                                        display_name: params[:display_name] || params[:name],
                                                        size: params[:size],
                                                        md5: params[:sha512])
                        overwritten_instfs_uuid = att.instfs_uuid if att
                      end
                      att || Attachment.where(context: @context).build
                    end
                  end

    # service metadata
    #
    # NOTE: we're assigning the sha512 value from inst-fs to the md5 column.
    # this is gross; ideally we'd rename the column to "hash" or "digest"
    # instead of "md5", because that's how the column is acting now. but
    # renaming on such a huge table is expensive :(
    #
    # TODO we could at least alias the md5 _column_ into a digest _property_
    # and change code to refer to the digest instead of the md5. that won't
    # help people that are using the database dump directly, though. they'll
    # just need to be aware of the disconnect between name and use.
    #
    @attachment.filename = params[:name]
    @attachment.display_name = params[:display_name] || params[:name]
    @attachment.size = params[:size]
    @attachment.content_type = params[:content_type]
    @attachment.instfs_uuid = params[:instfs_uuid]
    @attachment.md5 = params[:sha512]
    @attachment.modified_at = Time.zone.now
    @attachment.workflow_state = "processed"

    # check non-exempt quota usage now that we have an actual size
    return unless value_to_boolean(params[:quota_exempt]) || check_quota_after_attachment

    # capture params
    @attachment.folder = Folder.where(id: params[:folder_id]).first
    @attachment.user = api_find(User, params[:user_id])
    @attachment.set_publish_state_for_usage_rights
    @attachment.category = params[:category] if params[:category].present?
    @attachment.save!

    # apply duplicate handling
    if overwritten_instfs_uuid
      # FIXME: this instfs uuid may be in use by other files;
      # add a check and reinstate when we know it's safe
      # InstFS.delay_if_production.delete_file(overwritten_instfs_uuid)
    else
      @attachment.handle_duplicates(params[:on_duplicate])
    end

    # trigger upload success callbacks
    if @context.respond_to?(:file_upload_success_callback)
      @context.file_upload_success_callback(@attachment)
    end

    if params[:progress_id]
      progress = Progress.find(params[:progress_id])
      submit_assignment = params.key?(:submit_assignment) ? value_to_boolean(params[:submit_assignment]) : true

      # If the attachment is for an Assignment's upload_via_url and the submit_assignment flag is set, submit it
      if progress.tag == "upload_via_url" && progress.context.is_a?(Assignment) && submit_assignment
        homework_service = Services::SubmitHomeworkService.new(@attachment, progress)

        begin
          homework_service.submit(params[:eula_agreement_timestamp], params[:comment])
          homework_service.success!
        rescue => e
          error_id = Canvas::Errors.capture_exception(self.class.name, e)[:error_report]
          message = "Unexpected error, ID: #{error_id || "unknown"}"
          logger.error "Error submitting a file: #{e} - #{e.backtrace}"
          homework_service.failed!(message)
        end
      elsif progress.running?
        progress.set_results("id" => @attachment.id)
        progress.complete!
      end
    end

    includes = []
    if Array(params[:include]).include?("preview_url")
      includes << "preview_url"
    # only use implicit enhanced_preview_url if there is no explicit preview_url
    elsif @context.is_a?(User) || @context.is_a?(Course) || @context.is_a?(Group)
      includes << "enhanced_preview_url"
    end

    render status: :created,
           json: attachment_json(@attachment, @attachment.user, {}, { include: includes, verifier: params[:verifier] }),
           location: api_v1_attachment_url(@attachment, include: includes)
  end

  def api_create_success
    @attachment = Attachment.where(id: params[:id], uuid: params[:uuid]).first
    return head :bad_request unless @attachment.try(:file_state) == "deleted"
    return unless validate_on_duplicate(params)
    return unless quota_exempt? || check_quota_after_attachment

    if Attachment.s3_storage?
      return head(:bad_request) unless @attachment.state == :unattached

      details = @attachment.s3object.data
      @attachment.process_s3_details!(details)
    else
      @attachment.file_state = "available"
      @attachment.save!
    end
    @attachment.handle_duplicates(infer_on_duplicate(params))

    if @attachment.context.respond_to?(:file_upload_success_callback)
      @attachment.context.file_upload_success_callback(@attachment)
    end

    json_params = {
      omit_verifier_in_app: true,
      include: []
    }

    includes = Array(params[:include])

    if includes.include?("avatar")
      json_params[:include] << "avatar"
    end

    if includes.include?("preview_url")
      json_params[:include] << "preview_url"
    # only use implicit enhanced_preview_url if there is no explicit preview_url
    elsif @attachment.context.is_a?(User) || @attachment.context.is_a?(Course) || @attachment.context.is_a?(Group)
      json_params[:include] << "enhanced_preview_url"
    end

    if @attachment.usage_rights_id.present?
      json_params[:include] << "usage_rights"
    end

    if @attachment.context.is_a?(Course)
      json_params[:master_course_status] = setup_master_course_restrictions([@attachment], @attachment.context)
    end

    json = attachment_json(@attachment, @current_user, {}, json_params)
    json.merge!(doc_preview_json(@attachment))

    # render as_text for IE, otherwise it'll prompt
    # to download the JSON response
    render json:, as_text: in_app?
  end

  def api_file_status
    @attachment = Attachment.where(id: params[:id], uuid: params[:uuid]).first!
    case @attachment.file_state
    when "available"
      render json: { upload_status: "ready", attachment: attachment_json(@attachment, @current_user) }
    when "deleted"
      render json: { upload_status: "pending" }
    else
      render json: { upload_status: "errored", message: @attachment.upload_error_message }
    end
  end

  def update
    @attachment = @context.attachments.find(params[:id])
    @folder = @context.folders.active.find(params[:attachment][:folder_id]) rescue nil
    return if @folder && !authorized_action(@folder, @current_user, :manage_contents)

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
        if just_hide == "1"
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
          flash[:notice] = t "notices.updated", "File was successfully updated."
          format.html { redirect_to named_context_url(@context, :context_files_url) }
          format.json { render json: @attachment.as_json(methods: %i[readable_size mime_class currently_locked], permissions: { user: @current_user, session: }), status: :ok }
        else
          format.html { render :edit }
          format.json { render json: @attachment.errors, status: :bad_request }
        end
      end
    end
  end

  # @API Update file
  # Update some settings on the specified file
  #
  # @argument name [String]
  #   The new display name of the file, with a limit of 255 characters.
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
  # @argument visibility_level [String]
  #   Configure which roles can access this file
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
    if authorized_action(@attachment, @current_user, :update)
      @context = @attachment.context
      if @context && params[:parent_folder_id]
        folder = @context.folders.active.find(params[:parent_folder_id])
        if authorized_action(folder, @current_user, :update)
          @attachment.folder = folder
        else
          return
        end
      end

      @attachment.display_name = params[:name].truncate(255) if params.key?(:name)
      @attachment.lock_at = params[:lock_at] if params.key?(:lock_at)
      @attachment.unlock_at = params[:unlock_at] if params.key?(:unlock_at)
      @attachment.locked = value_to_boolean(params[:locked]) if params.key?(:locked)
      @attachment.hidden = value_to_boolean(params[:hidden]) if params.key?(:hidden)
      @attachment.visibility_level = params[:visibility_level] if params.key?(:visibility_level)

      @attachment.set_publish_state_for_usage_rights if @attachment.context.is_a?(Group)
      if !@attachment.locked? && @attachment.locked_changed? && @attachment.usage_rights_id.nil? && @context.respond_to?(:usage_rights_required?) && @context.usage_rights_required?
        return render json: { message: I18n.t("This file must have usage_rights set before it can be published.") }, status: :bad_request
      end

      if (@attachment.folder_id_changed? || @attachment.display_name_changed?) && @attachment.folder.active_file_attachments.where(display_name: @attachment.display_name).where("id<>?", @attachment.id).exists?
        return render json: { message: "file already exists; use on_duplicate='overwrite' or 'rename'" }, status: :conflict unless %w[overwrite rename].include?(params[:on_duplicate])

        on_duplicate = params[:on_duplicate].to_sym
      end
      if @attachment.save
        @attachment.handle_duplicates(on_duplicate) if on_duplicate
        render json: attachment_json(@attachment, @current_user, {}, { omit_verifier_in_app: true, verifier: params[:verifier] })
      else
        render json: @attachment.errors, status: :bad_request
      end
    end
  end

  def reorder
    @folder = @context.folders.active.find(params[:folder_id])
    if authorized_action(@context, @current_user, :manage_files_edit)
      @folders = @folder.active_sub_folders.by_position
      @folders.first&.update_order((params[:folder_order] || "").split(","))
      @folder.file_attachments.by_position_then_display_name.first && @folder.file_attachments.first.update_order((params[:order] || "").split(","))
      @folder.reload
      render json: @folder.subcontent.map { |f| f.as_json(methods: :readable_size, permissions: { user: @current_user, session: }) }
    end
  end

  # @API Delete file
  # Remove the specified file. Unlike most other DELETE endpoints, using this
  # endpoint will result in comprehensive, irretrievable destruction of the file.
  # It should be used with the `replace` parameter set to true in cases where the
  # file preview also needs to be destroyed (such as to remove files that violate
  # privacy laws).
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
        return render json: attachment_json(@attachment, @current_user, {}, { omit_verifier_in_app: true })
      else
        return render_unauthorized_action
      end
    end
    if can_do(@attachment, @current_user, :delete)
      return render_unauthorized_action if editing_restricted?(@attachment)

      @attachment.destroy
      respond_to do |format|
        format.html do
          require_context
          redirect_to named_context_url(@context, :context_files_url)
        end
        if api_request?
          format.json { render json: attachment_json(@attachment, @current_user, {}, { omit_verifier_in_app: true }) }
        else
          format.json { render json: @attachment }
        end
      end
    elsif @attachment.associated_with_submission?
      render json: { message: I18n.t("Cannot delete a file that has been submitted as part of an assignment") }, status: :forbidden
    else
      render json: { message: I18n.t("Unauthorized to delete this file") }, status: :unauthorized
    end
  end

  # @API Get icon metadata
  # Returns the icon maker file attachment metadata
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/1/files/1/metadata' \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #
  #  {
  #    "type":"image/svg+xml-icon-maker-icons",
  #    "alt":"",
  #    "shape":"square",
  #    "size":"small",
  #    "color":"#FFFFFF",
  #    "outlineColor":"#65499D",
  #    "outlineSize":"large",
  #    "text":"Hello",
  #    "textSize":"x-large",
  #    "textColor":"#65499D",
  #    "textBackgroundColor":"#FFFFFF",
  #    "textPosition":"bottom-third",
  #    "encodedImage":"data:image/svg+xml;base64,PH==",
  #    "encodedImageType":"SingleColor",
  #    "encodedImageName":"Health Icon",
  #    "x":"50%",
  #    "y":"50%",
  #    "translateX":-54,
  #    "translateY":-54,
  #    "width":108,
  #    "height":108,
  #    "transform":"translate(-54,-54)"
  #  }
  #
  def icon_metadata
    @icon = Attachment.find(params[:id])
    @icon = attachment_or_replacement(@icon.context, params[:id]) if @icon.deleted? && @icon.replacement_attachment_id.present?
    return render json: { errors: [{ message: "The specified resource does not exist." }] }, status: :not_found if @icon.deleted?
    return unless access_allowed(@icon, @current_user, :download)

    unless @icon.category == Attachment::ICON_MAKER_ICONS
      return render json: { errors: [{ message: "The requested attachment does not support viewing metadata." }] }, status: :bad_request
    end

    sax_doc = MetadataSaxDoc.new
    parser = Nokogiri::XML::SAX::PushParser.new(sax_doc)
    @icon.open do |chunk|
      parser << chunk
      break if sax_doc.metadata_value.present?
    end
    sax_doc.metadata_value.present? ? render(json: { name: @icon.display_name }.merge(JSON.parse(sax_doc.metadata_value))) : head(:no_content)
  end

  class MetadataSaxDoc < Nokogiri::XML::SAX::Document
    attr_reader :current_value, :metadata_value, :retain_data

    def start_element(name, _attrs)
      return unless name == "metadata"

      @current_value = ""
      @retain_data = true
    end

    def end_element(name)
      return unless name == "metadata"

      @metadata_value = current_value
      @retain_data = false
    end

    def characters(chars)
      return unless retain_data

      @current_value ||= ""
      @current_value += chars
    end
  end
  private_constant :MetadataSaxDoc

  # @API Reset link verifier
  #
  # Resets the link verifier. Any existing links to the file using
  # the previous hard-coded "verifier" parameter will no longer
  # automatically grant access.
  #
  # Must have manage files and become other users permissions
  #
  # @example_request
  #
  #   curl -X POST 'https://<canvas>/api/v1/files/<file_id>/reset_verifier' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns File
  def reset_verifier
    @attachment = Attachment.find(params[:id])
    @context = @attachment.context
    if can_replace_file?
      @attachment.reset_uuid!
      render json: attachment_json(@attachment, @current_user, {}, { omit_verifier_in_app: true, verifier: params[:verifier] })
    else
      render_unauthorized_action
    end
  end

  def can_replace_file?
    if @context.is_a?(User)
      @context.can_masquerade?(@current_user, @domain_root_account)
    else
      permission_context =
        case @context
        when Course, Account, Group
          @context
        else
          @context.respond_to?(:context) ? @context.context : @context
        end
      permission_context.grants_any_right?(
        @current_user,
        nil,
        :manage_files_edit,
        :manage_files_delete
      ) && @domain_root_account.grants_right?(@current_user, nil, :become_user)
    end
  end

  def image_thumbnail
    cancel_cache_buster

    no_cache = !!Canvas::Plugin.value_to_boolean(params[:no_cache])

    # include authenticator fingerprint so we don't redirect to an
    # authenticated thumbnail url for the wrong user
    cache_key = ["thumbnail_url2", params[:uuid], params[:size], file_authenticator.fingerprint].cache_key
    url, instfs = Rails.cache.read(cache_key)
    if !url || no_cache
      attachment = Attachment.active.where(id: params[:id], uuid: params[:uuid]).first if params[:id].present?
      thumb_opts = params.slice(:size)
      url = authenticated_thumbnail_url(attachment, thumb_opts)
      if url
        instfs = attachment.instfs_hosted?
        # only cache for half the time because of use_consistent_iat
        Rails.cache.write(cache_key, [url, instfs], expires_in: (attachment.url_ttl / 2))
      end
    end

    if url && instfs && file_location_mode?
      render_file_location(url)
    else
      redirect_to(url || "/images/no_pic.gif")
    end
  end

  # when using local storage, the image_thumbnail action redirects here rather
  # than to a s3 url
  def show_thumbnail
    if Attachment.local_storage?
      cancel_cache_buster
      thumbnail = Thumbnail.where(id: params[:id], uuid: params[:uuid]).first if params[:id].present?
      raise ActiveRecord::RecordNotFound unless thumbnail

      send_file thumbnail.full_filename, content_type: thumbnail.content_type
    else
      image_thumbnail
    end
  end

  private

  def quota_exempt?
    @attachment.verify_quota_exemption_key(params[:quota_exemption]) ||
      !!@attachment.folder&.for_submissions?
  end

  def attachment_or_replacement(context, id)
    # NOTE: Attachment#find has special logic to find overwriting files; see FindInContextAssociation
    context.attachments.find(id)
  end

  def replacement_chain_context
    return unless params[:replacement_chain_context_type] == "course"
    return unless params[:replacement_chain_context_id].present?

    api_find(Course.active, params[:replacement_chain_context_id])
  end

  def merged_user_scope
    if params[:user_id].present?
      Shard.shard_for(params[:user_id]).activate do
        User.active.or(User.where.not(merged_into_user_id: nil))
      end
    end
  end

  def log_attachment_access(attachment)
    log_asset_access(attachment, "files", "files")
  end

  def open_cors
    headers["Access-Control-Allow-Origin"] = request.headers["origin"]
    headers["Access-Control-Allow-Credentials"] = "true"
    headers["Access-Control-Allow-Methods"] = "POST, PUT, DELETE, GET, OPTIONS"
    headers["Access-Control-Request-Method"] = "*"
    headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept, Authorization, Accept-Encoding"
  end

  def open_limited_cors
    headers["Access-Control-Allow-Origin"] = request.headers["origin"]
    headers["Access-Control-Allow-Credentials"] = "true"
    headers["Access-Control-Allow-Methods"] = "GET, HEAD"
  end

  def access_allowed(attachment, user, access_type)
    if params[:verifier]
      verifier_checker = Attachments::Verification.new(attachment)
      return true if verifier_checker.valid_verifier_for_permission?(params[:verifier], access_type, session)
    end

    submissions = attachment.attachment_associations.where(context_type: "Submission").preload(:context).filter_map(&:context)
    return true if submissions.any? { |submission| submission.grants_right?(user, session, access_type) }

    authorized_action(attachment, user, access_type)
  end

  def strong_attachment_params
    params.require(:attachment).permit(:display_name, :locked, :lock_at, :unlock_at, :uploaded_data, :hidden, :visibility_level)
  end
end
