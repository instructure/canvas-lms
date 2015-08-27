#
# Copyright (C) 2011 Instructure, Inc.
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

class GradebookUploadsController < ApplicationController
  include GradebooksHelper
  include Api::V1::Progress

  before_filter :require_context

  def new
    if authorized_action(@context, @current_user, :manage_grades)
      # GradebookUpload is a singleton.  If there is
      # already an instance we'll redirect to it or kill it
      previous_upload = gradebook_upload
      if previous_upload
        if previous_upload.stale?
          previous_upload.destroy
        elsif previous_upload
          # let them continue on with their old upload
          redirect_to course_gradebook_upload_path(@context)
          return
        end
      end
    end
  end

  def show
    if authorized_action(@context, @current_user, :manage_grades)
      upload = gradebook_upload
      unless upload
        redirect_to new_course_gradebook_upload_path(@context)
        return
      end

      @progress = upload.progress
      js_env gradebook_env(@progress)
    end
  end

  def create
    if authorized_action(@context, @current_user, :manage_grades)
      if params[:gradebook_upload]
        attachment = params[:gradebook_upload][:uploaded_data]
        @progress = GradebookUpload.queue_from(@context, @current_user, attachment.read)
        js_env gradebook_env(@progress)
        render :show
      else
        flash[:error] = t(:no_file_attached, "We did not detect a CSV to "\
          "upload. Please select a CSV to upload and submit again.")
        redirect_to action: :new
      end
    end
  end

  def data
    if authorized_action(@context, @current_user, :manage_grades)
      upload = gradebook_upload
      raise ActiveRecord::RecordNotFound unless upload

      render json: upload.gradebook
      upload.destroy
    end
  end

  private
  def gradebook_env(progress)
    {
      progress: progress_json(progress, @current_user, session),
      uploaded_gradebook_data_path: "/courses/#{@context.id}/gradebook_upload/data",
      gradebook_path: course_gradebook_path(@context),
      bulk_update_path: "/api/v1/courses/#{@context.id}/submissions/update_grades",
      create_assignment_path: api_v1_course_assignments_path(@context),
      new_gradebook_upload_path: new_course_gradebook_upload_path(@context),
    }
  end

  def gradebook_upload
    GradebookUpload.where(
      course_id: @context,
      user_id: @current_user
    ).first
  end
end
