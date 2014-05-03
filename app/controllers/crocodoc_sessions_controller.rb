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

  def create
    attachment = Attachment.find(params[:attachment_id])
    submission = Submission.find(params[:submission_id]) if params[:submission_id]

    if submission
      if params[:version]
        submission = submission.submission_history[params[:version].to_i]
      end

      # make sure the attachment is tied to this submission
      attachment_ids = (submission.attachment_ids || "").split(',')
      unless attachment_ids.include? attachment.id.to_s
        raise ActiveRecord::RecordNotFound
      end

      unless submission.grants_right? @current_user, session, :read
        render :text => 'unauthorized', :status => :unauthorized
        return
      end
    else
      unless attachment.grants_right? @current_user, session, :download
        render :text => 'unauthorized', :status => :unauthorized
        return
      end
    end

    if attachment.crocodoc_available?
      annotations = params[:annotations] ?
        value_to_boolean(params[:annotations]) :
        true

      crocodoc = attachment.crocodoc_document
      session_url = crocodoc.session_url :user => @current_user,
                                         :annotations => annotations
      render :json => { :session_url => session_url }
    else
      raise ActiveRecord::RecordNotFound
    end
  end
end
