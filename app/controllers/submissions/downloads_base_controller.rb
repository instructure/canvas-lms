#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Submissions
  class DownloadsBaseController < ApplicationController
    include Submissions::ShowHelper

    before_action :require_context

    def show
      render_unauthorized_action and return unless @submission.grants_right?(@current_user, :read)
      @attachment = Submissions::AttachmentForSubmissionDownload.new(
        @submission, params.slice(:comment_id, :download)
      ).attachment
      respond_to do |format|
        format.html { redirect_to redirect_path }
        format.json { render json: @attachment.as_json(permissions: { user: @current_user }) }
      end
    end

    protected

    def download_params
      { verifier: @attachment.uuid, inline: params[:inline] }.tap do |h|
        h[:download_frd] = true unless params[:inline]
      end
    end

    def redirect_path
      if @attachment.context == @submission || @attachment.context == @submission.assignment
        file_download_url(@attachment, download_params)
      else
        named_context_url(@attachment.context, :context_file_download_url, @attachment, download_params)
      end
    end
  end
end

