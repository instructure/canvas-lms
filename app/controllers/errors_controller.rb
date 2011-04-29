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
  before_filter :require_user, :require_site_admin
  def index
    conditions = ["message NOT LIKE ?", 'No route matches %']
    @message = params[:message]
    conditions = ["message LIKE ?", '%' + @message + '%'] if @message.present?
    @reports = ErrorReport.paginate(:page => params[:page], :per_page => 25, :order => 'id DESC',
      :conditions => conditions)
  end
  def show
    @reports = WillPaginate::Collection.new(1, 1, 1)
    @reports.replace([ErrorReport.find(params[:id])])
    render :action => 'index'
  end
end
