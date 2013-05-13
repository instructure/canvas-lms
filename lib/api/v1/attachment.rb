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

  def attachments_json(files, user, url_options = {}, options = {})
    files.map do |f|
      attachment_json(f, user, url_options, options)
    end
  end

  def attachment_json(attachment, user, url_options = {}, options = {})
    can_manage_files = options.has_key?(:can_manage_files) ? options[:can_manage_files] : attachment.grants_right?(user, nil, :update)
    url = if options[:thumbnail_url]
      # this thumbnail url is a route that redirects to local/s3 appropriately
      thumbnail_image_url(attachment.id, attachment.uuid)
    else
      file_download_url(attachment, { :verifier => attachment.uuid, :download => '1', :download_frd => '1' }.merge(url_options))
    end
    
    {
      'id' => attachment.id,
      'content-type' => attachment.content_type,
      'display_name' => attachment.display_name,
      'filename' => attachment.filename,
      'url' => url,
      'size' => attachment.size,
      'created_at' => attachment.created_at,
      'updated_at' => attachment.updated_at,
      'unlock_at' => attachment.unlock_at,
      'locked' => !!attachment.locked,
      'hidden' => !!attachment.hidden?,
      'lock_at' => attachment.lock_at,
      'locked_for_user' => can_manage_files ? false : !!attachment.currently_locked,
      'hidden_for_user' => can_manage_files ? false : !!attachment.hidden?,
      'thumbnail_url' => attachment.thumbnail_url
    }
  end

  # create an attachment in the context based on the AR request, and
  # render the attachment ajax_upload_params on success, or a relevant
  # error on failure.
  def api_attachment_preflight(context, request, opts = {})
    @attachment = Attachment.new
    @attachment.context = context
    @attachment.filename = request.params[:name]
    atts = process_attachment_params(params)
    atts.delete(:display_name)
    @attachment.attributes = atts
    @attachment.submission_attachment = true if opts[:submission_attachment]
    @attachment.file_state = 'deleted'
    @attachment.workflow_state = 'unattached'
    @attachment.content_type = request.params[:content_type].presence || Attachment.mimetype(@attachment.filename)
    # Handle deprecated folder path
    request.params[:parent_folder_path] ||= request.params[:folder]
    if opts.key?(:folder)
      @attachment.folder = folder
    elsif request.params[:parent_folder_path] && request.params[:parent_folder_id]
      render :json => {:message => I18n.t('lib.api.attachments.only_one_folder', "Can't set folder path and folder id")}, :status => 400
      return
    elsif request.params[:parent_folder_id]
      @attachment.folder = context.folders.find(request.params.delete(:parent_folder_id))
    elsif context.respond_to?(:folders) && request.params[:parent_folder_path].is_a?(String)
      @attachment.folder = Folder.assert_path(request.params[:parent_folder_path], context)
    end
    duplicate_handling = check_duplicate_handling_option(request)
    if opts[:check_quota]
      get_quota
      if request.params[:size] && @quota < @quota_used + request.params[:size].to_i
        render(:json => { :message => 'file size exceeds quota' }, :status => :bad_request)
        return
      end
    end
    @attachment.save!
    if request.params[:url]
      @attachment.send_later_enqueue_args(:clone_url, { :priority => Delayed::LOW_PRIORITY, :max_attempts => 1, :n_strand => 'file_download' }, request.params[:url], duplicate_handling, opts[:check_quota])
      render :json => { :id => @attachment.id, :upload_status => 'pending', :status_url => api_v1_file_status_url(@attachment, @attachment.uuid) }
    else
      duplicate_handling = nil if duplicate_handling == 'overwrite'
      quota_exemption = opts[:check_quota] ? nil : @attachment.quota_exemption_key
      render :json => @attachment.ajax_upload_params(@current_pseudonym,
                                                     api_v1_files_create_url(:on_duplicate => duplicate_handling, :quota_exemption => quota_exemption),
                                                     api_v1_files_create_success_url(@attachment, :uuid => @attachment.uuid, :on_duplicate => duplicate_handling, :quota_exemption => quota_exemption),
                                                     :ssl => request.ssl?).slice(:upload_url, :upload_params)
    end
  end
  
  def check_quota_after_attachment(request)
    exempt = request.params[:quota_exemption] == @attachment.quota_exemption_key
    if !exempt && Attachment.over_quota?(@attachment.context, @attachment.size)
      render(:json => {:message => 'file size exceeds quota limits'}, :status => :bad_request)
      return false
    end
    return true
  end

  def check_duplicate_handling_option(request)
    duplicate_handling = request.params[:on_duplicate].presence || 'overwrite'
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
end
