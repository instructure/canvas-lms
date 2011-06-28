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

  before_filter :require_user, :require_site_admin
  def index
    params[:page] = params[:page].to_i > 0 ? params[:page].to_i : 1
    @reports = ErrorReport

    @message = params[:message]
    if @message.present?
      @reports = @reports.scoped(:conditions => ["message LIKE ?", '%' + @message + '%'])
    elsif params[:category].blank?
      @reports = @reports.scoped(:conditions => ["message NOT LIKE ?", 'No route matches %'])
    end
    if params[:category].present?
      @reports = @reports.scoped(:conditions => { :category => params[:category] })
    end

    @reports = @reports.all(:limit => PER_PAGE, :offset => ((params[:page]-1)*PER_PAGE), :order => 'id DESC')
  end
  def show
    @reports = WillPaginate::Collection.new(1, 1, 1)
    @reports.replace([ErrorReport.find(params[:id])])
    render :action => 'index'
  end
end
