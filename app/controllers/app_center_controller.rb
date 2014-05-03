#
# Copyright (C) 2013 Instructure, Inc.
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

class AppCenterController < ApplicationController
  before_filter :require_context

  def map_tools_to_apps!(context, apps)
    return unless apps
    ContextExternalTool.all_tools_for(context).each do |tool|
      app = nil
      app = apps.find{|a| tool.tool_id == a['short_name'] } if tool.tool_id
      app['is_installed'] = true if app
    end
  end

  def app_api
    @app_api ||= AppCenter::AppApi.new
  end

  def page
    (params['page'] || 1).to_i
  end

  def index
    per_page = Api.per_page_for(self, default: 72, max: 72)
    endpoint_scope = (@context.is_a?(Account) ? 'account' : 'course')
    base_url = send("api_v1_#{endpoint_scope}_app_center_apps_url")
    response = app_api.get_apps(page, per_page) || {}
    if response['lti_apps']
      collection = PaginatedCollection.build do |pager|
        map_tools_to_apps!(@context, response['lti_apps'])
        pager.replace(response['lti_apps'])
        pager.next_page = response['meta']['next_page'] if response['meta']
        pager
      end
      render :json => Api.paginate(collection, self, base_url, :per_page => per_page.to_i)
    else
      render :json => response
    end
  end

  def reviews
    per_page = Api.per_page_for(self, default: 15)
    endpoint_scope = (@context.is_a?(Account) ? 'account' : 'course')
    base_url = send("api_v1_#{endpoint_scope}_app_center_app_reviews_url")
    force_refresh = params['force_refresh'] == '1'
    collection = PaginatedCollection.build do |pager|
      json = app_api.get_app_reviews(params[:app_id], page, per_page, force_refresh) || {}
      pager.replace(json['reviews'])
      pager.next_page = json['meta']['next_page'] if json['meta']
      pager
    end
    render :json => Api.paginate(collection, self, base_url, :per_page => per_page.to_i)
  end

  def review
    app_api = AppCenter::AppApi.new
    review = app_api.get_app_user_review(params[:app_id], @current_user.try(:uuid))
    render :json => review
  end

  def add_review
    app_api = AppCenter::AppApi.new
    review = app_api.add_app_review(params[:app_id], @current_user, params[:rating], params[:comments])
    render :json => review
  end
end
