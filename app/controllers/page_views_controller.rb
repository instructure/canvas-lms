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
#
#
# @model PageView
#     {
#       "id": "PageView",
#       "description": "The record of a user page view access in Canvas",
#       "required": ["id"],
#       "properties": {
#         "id": {
#           "description": "A UUID representing the page view.  This is also the unique request id",
#           "example": "3e246700-e305-0130-51de-02e33aa501ef",
#           "type": "string",
#           "format": "uuid"
#         },
#         "url": {
#           "description": "The URL requested",
#           "example": "https://canvas.instructure.com/conversations",
#           "type": "string"
#         },
#         "context_type": {
#           "description": "The type of context for the request",
#           "example": "Course",
#           "type": "string"
#         },
#         "asset_type": {
#           "description": "The type of asset in the context for the request, if any",
#           "example": "Discussion",
#           "type": "string"
#         },
#         "controller": {
#           "description": "The rails controller that handled the request",
#           "example": "discussions",
#           "type": "string"
#         },
#         "action": {
#           "description": "The rails action that handled the request",
#           "example": "index",
#           "type": "string"
#         },
#         "contributed": {
#           "description": "This field is deprecated, and will always be false",
#           "example": "false",
#           "type": "boolean"
#         },
#         "interaction_seconds": {
#           "description": "An approximation of how long the user spent on the page, in seconds",
#           "example": "7.21",
#           "type": "float"
#         },
#         "created_at": {
#           "description": "When the request was made",
#           "example": "2013-10-01T19:49:47Z",
#           "type": "datetime",
#           "format": "iso8601"
#         },
#         "user_request": {
#           "description": "A flag indicating whether the request was user-initiated, or automatic (such as an AJAX call)",
#           "example": "true",
#           "type": "boolean"
#         },
#         "render_time": {
#           "description": "How long the response took to render, in seconds",
#           "example": "0.369",
#           "type": "float"
#         },
#         "user_agent": {
#           "description": "The user-agent of the browser or program that made the request",
#           "example": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/536.30.1 (KHTML, like Gecko) Version/6.0.5 Safari/536.30.1",
#           "type": "string"
#         },
#         "participated": {
#           "description": "True if the request counted as participating, such as submitting homework",
#           "example": "false",
#           "type": "boolean"
#         },
#         "http_method": {
#           "description": "The HTTP method such as GET or POST",
#           "example": "GET",
#           "type": "string"
#         },
#         "remote_ip": {
#           "description": "The origin IP address of the request",
#           "example": "173.194.46.71",
#           "type": "string"
#         },
#         "links": {
#           "description": "The page view links to define the relationships",
#           "type": "PageViewLinks",
#           "example": "{}"
#         }
#       }
#     }
#
# @model PageViewLinks
#   {
#     "id": "PageViewLinks",
#     "description": "The links of a page view access in Canvas",
#     "properties": {
#        "user": {
#          "description": "The ID of the user for this page view",
#          "example": "1234",
#          "type": "integer",
#          "format": "int64"
#        },
#        "context": {
#          "description": "The ID of the context for the request (course id if context_type is Course, etc)",
#          "example": "1234",
#          "type": "integer",
#          "format": "int64"
#        },
#        "asset": {
#          "description": "The ID of the asset for the request, if any",
#          "example": "1234",
#          "type": "integer",
#          "format": "int64"
#        },
#        "real_user": {
#          "description": "The ID of the actual user who made this request, if the request was made by a user who was masquerading",
#          "example": "1234",
#          "type": "integer",
#          "format": "int64"
#        },
#         "account": {
#           "description": "The ID of the account context for this page view",
#           "example": "1234",
#           "type": "integer",
#           "format": "int64"
#        }
#     }
#   }

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
  # @argument start_time [DateTime]
  #   The beginning of the time range from which you want page views.
  #
  # @argument end_time [DateTime]
  #   The end of the time range from which you want page views.
  #
  # @returns [PageView]
  def index
    @user = api_find(User, params[:user_id])

    return unless authorized_action(@user, @current_user, :view_statistics)

    date_options = {}
    url_options = {user_id: @user}
    if start_time = CanvasTime.try_parse(params[:start_time])
      date_options[:oldest] = start_time
      url_options[:start_time] = params[:start_time]
    end
    if end_time = CanvasTime.try_parse(params[:end_time])
      date_options[:newest] = end_time
      url_options[:end_time] = params[:end_time]
    end
    page_views = @user.page_views(date_options)
    url = api_v1_user_page_views_url(url_options)

    respond_to do |format|
      format.json do
        @page_views = Api.paginate(page_views, self, url, :total_entries => nil)
        render :json => page_views_json(@page_views, @current_user, session)
      end
      format.csv do
        cancel_cache_buster
        per_page = Setting.get('page_views_csv_export_rows', '300').to_i
        page_views = @user.page_views.paginate(:page => 1, :per_page => per_page)
        options = {
          type: 'text/csv',
          filename: t(:download_filename, 'Pageviews For %{user}',
          user: @user.name.to_s.gsub(/ /, '_')) + '.csv', disposition: 'attachment'
        }

        header = Array(page_views.first.export_columns.to_csv)
        rows   = Array(page_views.map { |view| view.to_row.to_csv })
        csv    = (header + rows).join

        send_data(csv, options)
      end
    end
  end
end
