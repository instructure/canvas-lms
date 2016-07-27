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
        preferred_renders: []
      }
      if @domain_root_account.settings[:canvadocs_prefer_office_online]
        opts[:preferred_renders].unshift Canvadocs::RENDER_O365
      end
      attachment.submit_to_canvadocs(1, opts) unless attachment.canvadoc_available?
      url = attachment.canvadoc.session_url(user: @current_user)

      # For the purposes of reporting student viewership, we only
      # care if the original attachment owner is looking
      attachment.touch(:viewed_at) if attachment.context == @current_user

      redirect_to url
    else
      render :text => "Not found", :status => :not_found
    end

  rescue HmacHelper::Error
    render :text => 'unauthorized', :status => :unauthorized
  rescue Timeout::Error
    render :text => "Service is currently unavailable. Try again later.",
           :status => :service_unavailable
  end
end
