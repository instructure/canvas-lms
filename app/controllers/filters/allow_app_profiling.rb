#
# Copyright (C) 2014 Instructure, Inc.
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

module Filters::AllowAppProfiling
  def self.before(controller)
    if allow?(controller.params, controller.session, controller.logged_in_user)
      Rack::MiniProfiler.authorize_request
    else
      Rack::MiniProfiler.deauthorize_request
    end
  end

  def self.allow?(params, session, user)
    if session[:enable_profiling]
      true
    elsif params[:pp] && Account.site_admin.grants_right?(user, :app_profiling)
      # the name of the param "pp" comes from rack-mini-profiler, typically you pass ?pp=enable or ?pp=profile-gc
      session[:enable_profiling] = true
      true
    else
      false
    end
  end
end

