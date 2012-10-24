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

# @API Users
class PageViewsController < ApplicationController
  before_filter :require_user, :only => [:index]

  def update
    render :json => {:ok => true}
    # page view update happens in log_page_view after_filter
  end

  # @API List user page views
  # Return the user's page view history in json format, similar to the
  # available CSV download. Pagination is used as described in API basics
  # section. Page views are returned in descending order, newest to oldest.
  #
  # @response_field interaction_seconds The number of seconds the user actively interacted with the page. This is a best guess, using heuristics such as browser input events.
  # @response_field url The full canvas URL of the page view.
  # @response_field user_agent The browser identifier or other user agent that was used to make the request.
  # @response_field controller The Rails controller that processed the request.
  # @response_field action The action in the Rails controller that processed the request.
  # @response_field context_type The type of "context" of the request, e.g. Account or Course.
  def index
    @user = api_find(User, params[:user_id])
    if authorized_action(@user, @current_user, :view_statistics)
      @page_views = Api.paginate(@user.page_views, self, api_v1_user_page_views_url(:user_id => @user), :order => 'created_at DESC', :without_count => :true)
      respond_to do |format|
        format.html do
          if params[:html_xhr]
            render :partial => @page_views
          end
        end
        format.js { render :partial => @page_views }
        format.json do
          if api_request?
            stream_json_array(@page_views,
                              :include_root => false,
                              :only => (PageView.content_columns.map(&:name) + ['request_id']))
          else
            render :partial => @page_views
          end
        end
        format.csv {
          cancel_cache_buster
          send_data(
            @user.page_views.by_created_at.scoped(:limit=>params[:report_count] || 300).to_a.to_csv,
            :type => "text/csv", 
            :filename => t(:download_filename, "Pageviews For %{user}", :user => @user.name.to_s.gsub(/ /, "_")) + '.csv', 
            :disposition => "attachment"
          ) 
        }
      end
    end
  end
end
