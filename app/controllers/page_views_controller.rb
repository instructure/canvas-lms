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

class PageViewsController < ApplicationController
  before_filter :require_user, :only => [:index]
  def update
    render :json => {:ok => true}
    # page view update happens in log_page_view after_filter
  end
  
  def index
    @user = User.find(params[:user_id])
    if authorized_action(@user, @current_user, :view_statistics)
      @page_views = @user.page_views.paginate :page => params[:page], :order => 'created_at DESC'
      respond_to do |format|
        format.html
        format.js { render :partial => @page_views }
        format.json { render :partial => @page_views }
        format.csv {
          cancel_cache_buster
          send_data(
            @user.page_views.scoped(:limit=>params[:report_count] || 300).to_a.to_csv, 
            :type => "text/csv", 
            :filename => "Pageviews For #{@user.name.to_s.gsub(/ /, "_")}.csv", 
            :disposition => "attachment"
          ) 
        }
        format.xml { render :xml => @user.page_views.scoped(:limit=>params[:report_count] || 300).to_xml } 
      end
    end
  end
end
