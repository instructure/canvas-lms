# frozen_string_literal: true

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

class CrocodocSessionsController < ApplicationController
  before_action :require_user
  include HmacHelper

  def show
    blob = extract_blob(params[:hmac],
                        params[:blob],
                        "user_id" => @current_user.global_id,
                        "type" => "crocodoc")
    attachment = Attachment.find(blob["attachment_id"])

    if attachment.crocodoc_available?
      annotations = if params[:annotations]
                      value_to_boolean(params[:annotations])
                    else
                      true
                    end

      crocodoc = attachment.crocodoc_document
      url = crocodoc.session_url(user: @current_user,
                                 annotations:,
                                 enable_annotations: blob["enable_annotations"],
                                 moderated_grading_allow_list: blob["moderated_grading_allow_list"])

      # For the purposes of reporting student viewership, we only
      # care if the original attachment owner is looking
      # Depending on how the attachment came to exist that might be
      # either the context of the attachment or the attachments' user
      if (attachment.context == @current_user) || (attachment.user == @current_user)
        attachment.touch(:viewed_at)
      end

      redirect_to url
    else
      render plain: "Not found", status: :not_found
    end
  rescue HmacHelper::Error
    render plain: "unauthorized", status: :unauthorized
  rescue Timeout::Error
    render plain: "Service is currently unavailable. Try again later.",
           status: :service_unavailable
  end
end
