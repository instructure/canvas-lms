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

  include Api::V1::PageView

  def update
    render :json => {:ok => true}
    # page view update happens in log_page_view after_filter
  end

  # @API List user page views
  # Return the user's page view history in json format, similar to the
  # available CSV download. Pagination is used as described in API basics
  # section. Page views are returned in descending order, newest to oldest.
  #
  # @argument start_time [Datetime] [optional] The beginning of the time range
  #   from which you want page views.
  # @argument end_time [Datetime] [optional] The end of the time range
  #   from which you want page views.
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
      date_options = {}
      url_options = {user_id: @user}
      if start_time = TimeHelper.try_parse(params[:start_time])
        date_options[:oldest] = start_time
        url_options[:start_time] = params[:start_time]
      end
      if end_time = TimeHelper.try_parse(params[:end_time])
        date_options[:newest] = end_time
        url_options[:end_time] = params[:end_time]
      end
      page_views = @user.page_views(date_options)
      url = api_v1_user_page_views_url(url_options)
      @page_views = Api.paginate(page_views, self, url, :order => 'created_at DESC', :without_count => :true)

      respond_to do |format|
        format.json do
          render :json => @page_views.map { |pv| page_view_json(pv, @current_user, session) }
        end
        format.csv do
          cancel_cache_buster
          data = @user.page_views.paginate(:page => 1, :per_page => Setting.get('page_views_csv_export_rows', '300').to_i)
          send_data(
            data.to_a.to_csv,
            :type => "text/csv",
            :filename => t(:download_filename, "Pageviews For %{user}", :user => @user.name.to_s.gsub(/ /, "_")) + '.csv',
            :disposition => "attachment"
          )
        end
      end
    end
  end
end
