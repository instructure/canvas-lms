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
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

class CrocodocSessionsController < ApplicationController
  before_filter :require_user
  include HmacHelper

  def show
    blob = extract_blob(params[:hmac], params[:blob],
                        "user_id" => @current_user.global_id,
                        "type" => "crocodoc")
    attachment = Attachment.find(blob["attachment_id"])

    if attachment.crocodoc_available?
      annotations = params[:annotations] ?
        value_to_boolean(params[:annotations]) :
        true

      crocodoc = attachment.crocodoc_document
      redirect_to crocodoc.session_url(:user => @current_user,
                                       :annotations => annotations)
    else
      render :text => "Not found", :status => :not_found
    end

  rescue HmacHelper::Error
    render :text => 'unauthorized', :status => :unauthorized
  end
end
