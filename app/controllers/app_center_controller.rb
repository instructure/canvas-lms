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

  def generate_app_api_collection(base_url)
    PaginatedCollection.build do |pager|
      page = (params['page'] || 1).to_i
      response = yield AppCenter::AppApi.new, page
      response ||= {}
      pager.replace(response['objects'] || [])
      pager.next_page = response['meta']['next_page'] if response['meta']
      pager
    end
  end

  def index
    per_page = params['per_page'] || 72
    endpoint_scope = (@context.is_a?(Account) ? 'account' : 'course')
    base_url = send("api_v1_#{endpoint_scope}_app_center_apps_url")
    collection = generate_app_api_collection(base_url) {|app_api, page| app_api.get_apps(page, per_page)}
    render :json => Api.paginate(collection, self, base_url, :per_page => per_page.to_i)
  end

  def reviews
    per_page = params['per_page'] || 15
    endpoint_scope = (@context.is_a?(Account) ? 'account' : 'course')
    base_url = send("api_v1_#{endpoint_scope}_app_center_app_reviews_url")
    collection = generate_app_api_collection(base_url) {|app_api, page| app_api.get_app_reviews(params[:app_id], page, per_page)}
    render :json => Api.paginate(collection, self, base_url, :per_page => per_page.to_i)
  end
end