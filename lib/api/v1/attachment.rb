#
# Copyright (C) 2012 - present Instructure, Inc.
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

module Api::V1::Attachment
  include Api::V1::Json
  include Api::V1::Locked
  include Api::V1::User
  include Api::V1::UsageRights

  def can_view_hidden_files?(context=@context, user=@current_user, session=nil)
    context.grants_any_right?(user, session, :manage_files, :read_as_admin, :manage_contents)
  end

  def attachments_json(files, user, url_options = {}, options = {})
    if options[:can_view_hidden_files] && options[:context] && master_courses?
      options[:master_course_status] = setup_master_course_restrictions(files, options[:context])
    end
    files.map do |f|
      attachment_json(f, user, url_options, options)
    end
  end

  def attachment_json(attachment, user, url_options = {}, options = {})
    hash = {
      'id' => attachment.id,
      'folder_id' => attachment.folder_id,
      'display_name' => attachment.display_name,
      'filename' => attachment.filename,
    }
    return hash if options[:only] && options[:only].include?('names')

    options.reverse_merge!(submission_attachment: false)
    includes = options[:include] || []

    # it takes loads of queries to figure out that a teacher doesn't have
    # :update permission on submission attachments.  we'll handle the
    # permissions ourselves instead of using the usual stuff to save thousands
    # of queries
    submission_attachment = options[:submission_attachment]

    # this seems like a stupid amount of branching but it avoids expensive
    # permission checks
    hidden_for_user = if submission_attachment
                        false
                      elsif !attachment.hidden?
                        false
                      elsif options.has_key?(:can_view_hidden_files)
                        options[:can_view_hidden_files]
                      else
                        !can_view_hidden_files?(attachment.context, user)
                      end

    downloadable = !attachment.locked_for?(user, check_policies: true)

    if downloadable
      thumbnail_url = attachment.thumbnail_url
      if options[:thumbnail_url]
        # not the same as thumbnail_url above because:
        # * that one's going to be a direct (and possibly signed) s3, inst-fs,
        #   etc. link for immediate use.
        # * this one's a more compact canvas link to be stored for later use;
        #   it will resolve to the former when accessed
        url = thumbnail_image_url(attachment)
      else
        h = { :download => '1', :download_frd => '1' }
        h.merge!(:verifier => attachment.uuid) unless options[:omit_verifier_in_app] && (respond_to?(:in_app?, true) && in_app? || @authenticated_with_jwt)
        url = file_download_url(attachment, h.merge(url_options))
      end
    else
      thumbnail_url = ''
      url = ''
    end

    hash.merge!(
      'content-type' => attachment.content_type,
      'url' => url,
      'size' => attachment.size,
      'created_at' => attachment.created_at,
      'updated_at' => attachment.updated_at,
      'unlock_at' => attachment.unlock_at,
      'locked' => !!attachment.locked,
      'hidden' => submission_attachment ? false : !!attachment.hidden?,
      'lock_at' => attachment.lock_at,
      'hidden_for_user' => hidden_for_user,
      'thumbnail_url' => thumbnail_url,
      'modified_at' => attachment.modified_at ? attachment.modified_at : attachment.updated_at,
      'mime_class' => attachment.mime_class,
      'media_entry_id' => attachment.media_entry_id
    )
    locked_json(hash, attachment, user, 'file')

    if includes.include? 'user'
      context = attachment.context
      context = :profile if context == user
      hash['user'] = user_display_json(attachment.user, context)
    end
    if includes.include? 'preview_url'

      url_opts = {
        moderated_grading_whitelist: options[:moderated_grading_whitelist],
        enable_annotations: options[:enable_annotations]
      }
      hash['preview_url'] = attachment.crocodoc_url(user, url_opts) ||
                            attachment.canvadoc_url(user, url_opts)
    end
    if includes.include?('canvadoc_document_id')
      hash['canvadoc_document_id'] = attachment&.canvadoc&.document_id
    end
    if includes.include? 'enhanced_preview_url'
      hash['preview_url'] = context_url(attachment.context, :context_file_file_preview_url, attachment, annotate: 0)
    end
    if includes.include? 'usage_rights'
      hash['usage_rights'] = usage_rights_json(attachment.usage_rights, user)
    end
    if includes.include? "context_asset_string"
      hash['context_asset_string'] = attachment.context.try(:asset_string)
    end
    if includes.include? 'avatar' && respond_to?(:avatar_json)
      hash['avatar'] = avatar_json(user, attachment, type: 'attachment')
    end

    if options[:master_course_status]
      hash.merge!(attachment.master_course_api_restriction_data(options[:master_course_status]))
    end

    hash
  end

  def infer_upload_filename(params)
    params[:name] || params[:filename]
  end

  def infer_upload_content_type(params)
    params[:content_type].presence || Attachment.mimetype(infer_upload_filename(params))
  end

  def infer_upload_folder(context, params)
    if !context.respond_to?(:folders)
      nil
    elsif params[:parent_folder_id]
      context.folders.find(params[:parent_folder_id])
    elsif params[:parent_folder_path].is_a?(String)
      Folder.assert_path(params[:parent_folder_path], context)
    end
  end

  def validate_on_duplicate(params)
    if params[:on_duplicate] && !%w(rename overwrite).include?(params[:on_duplicate])
      render status: :bad_request, json: {
        message: 'invalid on_duplicate option'
      }
      false
    else
      true
    end
  end

  def infer_on_duplicate(params)
    params[:on_duplicate].presence || 'overwrite'
  end

  # create an attachment in the context based on the AR request, and
  # render the attachment ajax_upload_params on success, or a relevant
  # error on failure.
  def api_attachment_preflight(context, request, opts = {})
    params = opts[:params] || request.params

    # Handle deprecated folder path
    params[:parent_folder_path] ||= params[:folder]
    if params[:parent_folder_path] && params[:parent_folder_id]
      render status: :bad_request, json: {
        message: I18n.t('lib.api.attachments.only_one_folder', "Can't set folder path and folder id")
      }
      return
    end

    return unless validate_on_duplicate(params)

    if opts[:check_quota]
      get_quota
      if params[:size] && @quota < @quota_used + params[:size].to_i
        over_quota = I18n.t('lib.api.over_quota', 'file size exceeds quota')
        if opts[:return_json]
          return { error: true, message: over_quota }
        else
          render status: :bad_request, json: {
            message: over_quota
          }
          return
        end
      end
    end

    # user must have permission on folder to user a custom folder other
    # than the "preferred" folder (that specified by the caller).
    folder = infer_upload_folder(context, params)
    return if folder && !authorized_action(folder, @current_user, :manage_contents)

    # no permission check required to use the preferred folder
    folder ||= opts[:folder]

    if InstFS.enabled?
      if params[:url]
        # TODO: CNVS-39171
        # * asynchronously tell inst-fs to fetch and store the file, then
        #   ping api_v1_files_capture_url on success or failure
        # * return a Progress from this method
        # * update client and docs to recognize the Progress
        # * augment api_capture to update the appropriate progress when it creates the file
        # * allow api_capture to receive an error and fail the appropriate
        #   Progress instead of creating a file
        raise NotImplementedError
      else
        json = InstFS.upload_preflight_json(
          context: context,
          user: @current_user,
          folder: folder,
          filename: infer_upload_filename(params),
          content_type: infer_upload_content_type(params),
          on_duplicate: infer_on_duplicate(params),
          quota_exempt: !opts[:check_quota],
          capture_url: api_v1_files_capture_url
        )
      end
    else
      @attachment = Attachment.new
      @attachment.shard = context.shard
      @attachment.context = context
      @attachment.user = @current_user
      @attachment.filename = infer_upload_filename(params)
      @attachment.content_type = infer_upload_content_type(params)
      @attachment.folder = folder
      @attachment.set_publish_state_for_usage_rights
      @attachment.file_state = 'deleted'
      @attachment.workflow_state = 'unattached'
      @attachment.modified_at = Time.now.utc
      @attachment.save!

      on_duplicate = infer_on_duplicate(params)
      if params[:url]
        @attachment.send_later_enqueue_args(:clone_url,
          {
            priority: Delayed::LOW_PRIORITY,
            max_attempts: 1,
            n_strand: 'file_download'
          },
          params[:url], on_duplicate, opts[:check_quota])
        json = {
          id: @attachment.id,
          upload_status: 'pending',
          status_url: api_v1_file_status_url(@attachment, @attachment.uuid)
        }
      else
        on_duplicate = nil if on_duplicate == 'overwrite'
        quota_exemption = @attachment.quota_exemption_key if !opts[:check_quota]
        json = @attachment.ajax_upload_params(
          @current_pseudonym,
          api_v1_files_create_url(
            on_duplicate: on_duplicate,
            quota_exemption: quota_exemption),
          api_v1_files_create_success_url(
            @attachment,
            uuid: @attachment.uuid,
            on_duplicate: on_duplicate,
            quota_exemption: quota_exemption),
          ssl: request.ssl?,
          file_param: opts[:file_param],
          no_redirect: params[:no_redirect])
        json = json.slice(:upload_url, :upload_params, :file_param)
      end
    end

    if opts[:return_json]
      json
    else
      render json: json
    end
  end

  def api_attachment_preflight_json(context, request, opts={})
    opts[:return_json] = true
    {:attachments => [api_attachment_preflight(context, request, opts)]}
  end

  def check_quota_after_attachment
    if Attachment.over_quota?(@attachment.context, @attachment.size)
      render status: :bad_request, json: {
        message: 'file size exceeds quota limits'
      }
      false
    else
      true
    end
  end

  def context_files_url
    polymorphic_url([:api_v1, @context, :files])
  end
end
