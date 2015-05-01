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

class ErrorsController < ApplicationController
  PER_PAGE = 20

  before_filter :require_view_error_reports
  def require_view_error_reports
    require_site_admin_with_permission(:view_error_reports)
  end

  def index
    params[:page] = params[:page].to_i > 0 ? params[:page].to_i : 1
    @reports = ErrorReport.includes(:user)

    @message = params[:message]
    if error_search_enabled? && @message.present?
      @reports = @reports.where("message LIKE ?", '%' + @message + '%')
    elsif params[:category].blank?
      @reports = @reports.where("category<>'404'")
    end
    if params[:category].present?
      @reports = @reports.where(:category => params[:category])
    end

    @reports = @reports.order('created_at DESC').paginate(:per_page => PER_PAGE, :page => params[:page], :total_entries => nil)
  end

  def show
    @reports = [ErrorReport.find(params[:id])]
    render :index
  end

  def error_search_enabled?
    Setting.get("error_search_enabled", "true") == "true"
  end
  helper_method :error_search_enabled?
end
