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
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

# @API Document Previews
# This API can only be accessed when another endpoint provides a signed URL.
# It will simply redirect you to the 3rd party document preview..
#
class CanvadocSessionsController < ApplicationController
  include HmacHelper

  def show
    blob = extract_blob(params[:hmac], params[:blob],
                        "user_id" => @current_user.try(:global_id),
                        "type" => "canvadoc")
    attachment = Attachment.find(blob["attachment_id"])

    if attachment.canvadocable?
      opts = {
        preferred_plugins: [Canvadocs::RENDER_BOX, Canvadocs::RENDER_CROCODOC]
      }

      if attachment.context.try(:account)&.feature_enabled?(:new_annotations)
        opts[:preferred_plugins].unshift Canvadocs::RENDER_PDFJS
      end

      if @domain_root_account.settings[:canvadocs_prefer_office_online]
        opts[:preferred_plugins].unshift Canvadocs::RENDER_O365
      end

      attachment.submit_to_canvadocs(1, opts) unless attachment.canvadoc_available?
      url = attachment.canvadoc.session_url(opts.merge(user: @current_user))

      # For the purposes of reporting student viewership, we only
      # care if the original attachment owner is looking
      # Depending on how the attachment came to exist that might be
      # either the context of the attachment or the attachments' user
      if (attachment.context == @current_user) || (attachment.user == @current_user)
        attachment.touch(:viewed_at)
      end

      redirect_to url
    else
      render :plain => "Not found", :status => :not_found
    end

  rescue HmacHelper::Error
    render :plain => 'unauthorized', :status => :unauthorized
  rescue Timeout::Error
    render :plain => "Service is currently unavailable. Try again later.",
           :status => :service_unavailable
  end
end
