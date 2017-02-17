#
# Copyright (C) 2012 - 2014 Instructure, Inc.
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

class GradebookCsvsController < ApplicationController
  before_action :require_context
  before_action :require_user

  def show
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      current_time = Time.zone.now.to_formatted_s(:short)
      name = t('grades_filename', "Grades") + "-" + @context.short_name.to_s
      filename = "#{current_time}_#{name}.csv".gsub(/ /, '_')

      csv_options = {
        include_sis_id: @context.grants_any_right?(@current_user, session, :read_sis, :manage_sis),
        grading_period_id: params[:grading_period_id]
      }

      attachment_progress = @context.gradebook_to_csv_in_background(filename, @current_user, csv_options)
      render json: attachment_progress, status: :ok
    end
  end
end
