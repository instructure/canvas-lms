#
# Copyright (C) 2014 - present Instructure, Inc.
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

class FilePreviewsController < ApplicationController
  include AttachmentHelper

  before_action :get_context

  # renders (or redirects to) appropriate content for the file, such as
  # canvadocs, crocodoc, inline image, etc.
  def show
    @file = @context.attachments.not_deleted.find_by_id(params[:file_id])
    css_bundle :react_files
    unless @file
      @headers = false
      @show_left_side = false
      return render template: 'shared/errors/404_message',
        status: :not_found,
        formats: [:html]
    end
    if authorized_action(@file, @current_user, :read)
      unless @file.grants_right?(@current_user, session, :download)
        @lock_info = @file.locked_for?(@current_user)
        return render template: 'file_previews/lock_explanation', layout: false
      end
      # mark item seen for module progression purposes
      @file.context_module_action(@current_user, :read) if @current_user
      log_asset_access(@file, "files", "files")
      # redirect to or render content for the file according to its type
      # crocodocs (if annotation requested)
      if Canvas::Plugin.value_to_boolean(params[:annotate]) && (url = @file.crocodoc_url(@current_user))
        redirect_to url and return
      # canvadocs
      elsif url = @file.canvadoc_url(@current_user)
        redirect_to url and return
      # google docs
      elsif GoogleDocsPreview.previewable?(@domain_root_account, @file)
        url = GoogleDocsPreview.url_for(@file)
        redirect_to('//docs.google.com/viewer?' + { embedded: true, url: url }.to_query) and return
      # images
      elsif @file.content_type =~ %r{\Aimage/}
        return render template: 'file_previews/img_preview', layout: false
      # media files
      elsif @file.content_type =~ %r{\A(audio|video)/}
        return render template: 'file_previews/media_preview', layout: false
      # html files
      elsif @file.content_type == 'text/html'
        return redirect_to context_url(@context, :context_file_preview_url, @file.id)
      # no preview available
      else
        @accessed_asset = nil # otherwise it will double-log when they download the file
        return render template: 'file_previews/no_preview', layout: false
      end
    end
  end
end
