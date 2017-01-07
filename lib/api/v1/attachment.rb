#
# Copyright (C) 2012 Instructure, Inc.
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
    context.grants_any_right?(user, session, :manage_files, :read_as_admin)
  end

  def attachments_json(files, user, url_options = {}, options = {})
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

    url = if options[:thumbnail_url] && downloadable
      # this thumbnail url is a route that redirects to local/s3 appropriately
      thumbnail_image_url(attachment.id, attachment.uuid)
    elsif !downloadable
      ''
    else
      h = { :download => '1', :download_frd => '1' }
      h.merge!(:verifier => attachment.uuid) unless options[:omit_verifier_in_app] && respond_to?(:in_app?, true) && in_app?
      file_download_url(attachment, h.merge(url_options))
    end

    thumbnail_download_url = if downloadable
      attachment.thumbnail_url
    else
      ''
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
      'thumbnail_url' => thumbnail_download_url,
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
      hash['preview_url'] = attachment.crocodoc_url(user, options[:crocodoc_ids]) ||
                            attachment.canvadoc_url(user)
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

    hash
  end

  # create an attachment in the context based on the AR request, and
  # render the attachment ajax_upload_params on success, or a relevant
  # error on failure.
  def api_attachment_preflight(context, request, opts = {})
    params = opts[:params] || request.params

    @attachment = Attachment.new
    @attachment.shard = context.shard
    @attachment.context = context
    @attachment.filename = params[:name]  || params[:filename]
    atts = process_attachment_params(params)
    atts.delete(:display_name)
    @attachment.attributes = atts
    @attachment.file_state = 'deleted'
    @attachment.workflow_state = 'unattached'
    @attachment.user = @current_user
    @attachment.modified_at = Time.now.utc
    @attachment.content_type = params[:content_type].presence || Attachment.mimetype(@attachment.filename)
    # Handle deprecated folder path
    params[:parent_folder_path] ||= params[:folder]
    if opts.key?(:folder)
      @attachment.folder = folder
    elsif params[:parent_folder_path] && params[:parent_folder_id]
      render :json => {:message => I18n.t('lib.api.attachments.only_one_folder', "Can't set folder path and folder id")}, :status => 400
      return
    elsif params[:parent_folder_id]
      @attachment.folder = context.folders.find(params.delete(:parent_folder_id))
    elsif context.respond_to?(:folders) && params[:parent_folder_path].is_a?(String)
      @attachment.folder = Folder.assert_path(params[:parent_folder_path], context)
    end
    if @attachment.folder
      return unless authorized_action(@attachment.folder, @current_user, :manage_contents)
    elsif opts[:submission_context] && opts[:submission_context].root_account.feature_enabled?(:submissions_folder)
      @attachment.folder = context.submissions_folder(opts[:submission_context]) if context.respond_to?(:submissions_folder)
    end
    duplicate_handling = check_duplicate_handling_option(params)
    if opts[:check_quota]
      get_quota
      if params[:size] && @quota < @quota_used + params[:size].to_i
        message = { :message => I18n.t('lib.api.over_quota', 'file size exceeds quota') }
        if opts[:return_json]
          message[:error] = true
          return message
        else
          render(:json => message, :status => :bad_request)
          return
        end
      end
    end
    @attachment.locked = true if @attachment.usage_rights_id.nil? && context.respond_to?(:feature_enabled?) && context.feature_enabled?(:usage_rights_required)
    @attachment.save!
    if params[:url]
      @attachment.send_later_enqueue_args(:clone_url, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1, :n_strand => 'file_download' }, params[:url], duplicate_handling, opts[:check_quota])
      json = { :id => @attachment.id, :upload_status => 'pending', :status_url => api_v1_file_status_url(@attachment, @attachment.uuid) }
    else
      duplicate_handling = nil if duplicate_handling == 'overwrite'
      quota_exemption = opts[:check_quota] ? nil : @attachment.quota_exemption_key
      json = @attachment.ajax_upload_params(@current_pseudonym,
                                                     api_v1_files_create_url(:on_duplicate => duplicate_handling, :quota_exemption => quota_exemption),
                                                     api_v1_files_create_success_url(@attachment, :uuid => @attachment.uuid, :on_duplicate => duplicate_handling, :quota_exemption => quota_exemption),
                                                     :ssl => request.ssl?, :file_param => opts[:file_param], no_redirect: params[:no_redirect]).
      slice(:upload_url,:upload_params,:file_param)
    end

    if opts[:return_json]
      json
    else
      render :json => json
    end
  end

  def api_attachment_preflight_json(context, request, opts={})
    opts[:return_json] = true
    {:attachments => [api_attachment_preflight(context, request, opts)]}
  end

  def check_quota_after_attachment(request)
    exempt = @attachment.verify_quota_exemption_key(request.params[:quota_exemption])
    if !exempt && Attachment.over_quota?(@attachment.context, @attachment.size)
      render(:json => {:message => 'file size exceeds quota limits'}, :status => :bad_request)
      return false
    end
    return true
  end

  def check_duplicate_handling_option(params)
    duplicate_handling = params[:on_duplicate].presence || 'overwrite'
    unless %w(rename overwrite).include?(duplicate_handling)
      render(:json => { :message => 'invalid on_duplicate option' }, :status => :bad_request)
      return nil
    end
    duplicate_handling
  end

  def process_attachment_params(params)
    new_atts = {}
    new_atts[:display_name] = params[:name] if params.has_key?(:name)
    new_atts[:lock_at] = params[:lock_at] if params.has_key?(:lock_at)
    new_atts[:unlock_at] = params[:unlock_at] if params.has_key?(:unlock_at)
    new_atts[:locked] = value_to_boolean(params[:locked]) if params.has_key?(:locked)
    new_atts[:hidden] = value_to_boolean(params[:hidden]) if params.has_key?(:hidden)
    new_atts
  end

  def context_files_url
    polymorphic_url([:api_v1, @context, :files])
  end
end
