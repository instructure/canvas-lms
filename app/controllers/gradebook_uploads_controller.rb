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

  before_filter :require_context

  def new
    if authorized_action(@context, @current_user, :manage_grades)
      @gradebook_upload = @context.build_gradebook_upload
    end
  end

  def create
    if authorized_action(@context, @current_user, :manage_grades)
      if params[:gradebook_upload] &&
       (@attachment = params[:gradebook_upload][:uploaded_data]) &&
       (@attachment_contents = @attachment.read)

        @uploaded_gradebook = GradebookImporter.new(@context, @attachment_contents)
        errored_csv = false
        begin
          @uploaded_gradebook.parse!
        rescue => e
          logger.warn "Error importing gradebook: #{e.inspect}"
          errored_csv = true
        end
        respond_to do |format|
          if errored_csv
            flash[:error] = t('errors.invalid_file', "Invalid csv file, grades could not be updated")
            format.html { redirect_to polymorphic_url([@context, 'gradebook']) }
          else
            js_env uploaded_gradebook: @uploaded_gradebook,
              gradebook_path: course_gradebook_path(@context),
              bulk_update_path: "/api/v1/courses/#{@context.id}/submissions/update_grades",
              create_assignment_path: api_v1_course_assignments_path(@context)
            format.html { render :show }
          end
        end
      else
        respond_to do |format|
          flash[:error] = t('errors.upload_failed', 'File could not be uploaded.')
          format.html { redirect_to polymorphic_url([@context, 'gradebook']) }
        end
      end
    end
  end
end
