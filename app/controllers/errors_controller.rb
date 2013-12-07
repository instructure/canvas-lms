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

    # XXX: temporary
    # will_paginate view helper doesn't currently handle having total_entries
    # nil. a fix via folio is in gerrit, but we need a stop gap. we can set
    # total_entries to the real count when we're on the last page, or
    # n*per_page+1 when on page n where n is less than the last page (so that a
    # next page link shows up). the check for a record at offset+per_page lets
    # us know whether the current page is the last page or not. we don't use
    # exists? because it blows up trying to instantiate something. we don't use
    # .limit(1).any? or .count > 0 because the count stays zero for some reason
    # even if there's a record. so... limit(1).pluck(:id), and see if it's
    # empty. :/
    scope = @reports
    @reports = scope.order('id DESC').paginate(:per_page => PER_PAGE, :page => params[:page], :total_entries => nil)
    @reports.total_entries = @reports.offset + @reports.size
    @reports.total_entries += 1 if scope.offset(@reports.offset + PER_PAGE).limit(1).pluck(:id).any?
  end

  def show
    @reports = [ErrorReport.find(params[:id])]
    render :action => 'index'
  end

  def error_search_enabled?
    Setting.get("error_search_enabled", "true") == "true"
  end
  helper_method :error_search_enabled?
end
