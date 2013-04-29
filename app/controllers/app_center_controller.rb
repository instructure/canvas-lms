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

  def index
    collection = PaginatedCollection.build do |pager|
      current_page = pager.current_page ? pager.current_page.to_i - 1 : 0
      apps = AppCenter::AppApi.new.get_apps(current_page * pager.per_page, pager.per_page) || []
      pager.replace(apps)
      pager.next_page = current_page + 2 if apps.size > 0
      pager
    end

    endpoint_scope = (@context.is_a?(Account) ? 'account' : 'course')
    render :json => Api.paginate(collection, self,
                                 send("api_v1_#{endpoint_scope}_app_center_apps_url"))
  end
end