#
# Copyright (C) 2014 Instructure, Inc.
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

  before_filter :get_context

  GOOGLE_PREVIEWABLE_TYPES = %w{
   application/vnd.openxmlformats-officedocument.wordprocessingml.template
   application/vnd.oasis.opendocument.spreadsheet
   application/vnd.sun.xml.writer
   application/excel
   application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
   text/rtf
   text/plain
   application/vnd.openxmlformats-officedocument.spreadsheetml.template
   application/vnd.sun.xml.impress
   application/vnd.sun.xml.calc
   application/vnd.ms-excel
   application/msword
   application/mspowerpoint
   application/rtf
   application/vnd.oasis.opendocument.presentation
   application/vnd.oasis.opendocument.text
   application/vnd.openxmlformats-officedocument.presentationml.template
   application/vnd.openxmlformats-officedocument.presentationml.slideshow
   application/vnd.openxmlformats-officedocument.presentationml.presentation
   application/vnd.openxmlformats-officedocument.wordprocessingml.document
   application/postscript
   application/pdf
   application/vnd.ms-powerpoint
}

  # renders (or redirects to) appropriate content for the file, such as
  # canvadocs, crocodoc, inline image, etc.
  def show
    @file = @context.attachments.not_deleted.find_by_id(params[:file_id])
    unless @file
      @headers = false
      @show_left_side = false
      return render template: 'shared/errors/404_message', status: :not_found
    end
    if authorized_action(@file, @current_user, :read)
      unless @file.grants_right?(@current_user, :download)
        @lock_info = @file.locked_for?(@current_user)
        return render template: 'file_previews/lock_explanation', layout: false
      end
      # mark item seen for module progression purposes
      @file.context_module_action(@current_user, :read) if @current_user
      @file.record_inline_view
      # redirect to or render content for the file according to its type
      # crocodocs (if annotation requested)
      if Canvas::Plugin.value_to_boolean(params[:annotate]) && (url = @file.crocodoc_url(@current_user))
        redirect_to url and return
      # canvadocs
      elsif url = @file.canvadoc_url(@current_user)
        redirect_to url and return
      # google docs
      elsif service_enabled?(:google_docs_previews) && GOOGLE_PREVIEWABLE_TYPES.include?(@file.content_type)
        redirect_to('//docs.google.com/viewer?' + { embedded: true, url: @file.authenticated_s3_url }.to_query) and return
      # images
      elsif @file.content_type =~ %r{\Aimage/}
        return render template: 'file_previews/img_preview', layout: false
      # media files
      elsif @file.content_type =~ %r{\A(audio|video)/}
        return render template: 'file_previews/media_preview', layout: false
      # no preview available
      else
        return render template: 'file_previews/no_preview', layout: false
      end
    end
  end
end
