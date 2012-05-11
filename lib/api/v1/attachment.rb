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

  def attachment_json(attachment, url_options = {}, options = {})
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
    }
  end

  # create an attachment in the context based on the AR request, and
  # render the attachment ajax_upload_params on success, or a relevant
  # error on failure.
  def api_attachment_preflight(context, request, opts = {})
    @attachment = Attachment.new
    @attachment.context = context
    @attachment.filename = request.params[:name]
    @attachment.file_state = 'deleted'
    @attachment.workflow_state = 'unattached'
    @attachment.content_type = request.params[:content_type].presence || Attachment.mimetype(@attachment.filename)
    if opts.key?(:folder)
      @attachment.folder = folder
    elsif context.respond_to?(:folders) && request.params[:folder].is_a?(String)
      @attachment.folder = Folder.assert_path(request.params[:folder], context)
    end
    duplicate_handling = check_duplicate_handling_option(request)
    duplicate_handling = nil if duplicate_handling == 'overwrite'
    @attachment.save!
    render :json => @attachment.ajax_upload_params(@current_pseudonym,
      api_v1_files_create_url(:on_duplicate => duplicate_handling),
      api_v1_files_create_success_url(@attachment, :uuid => @attachment.uuid, :on_duplicate => duplicate_handling),
      :ssl => request.ssl?).slice(:upload_url, :upload_params)
  end

  def check_duplicate_handling_option(request)
    duplicate_handling = request.params[:on_duplicate].presence || 'overwrite'
    unless %w(rename overwrite).include?(duplicate_handling)
      render(:json => { :message => 'invalid on_duplicate option' }, :status => :bad_request)
      return nil
    end
    duplicate_handling
  end
end
