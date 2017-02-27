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

class AuditorApiController < ApplicationController
  before_action :check_configured

  private

  def check_configured
    not_found unless Canvas::Cassandra::DatabaseBuilder.configured?('auditors')
  end

  def query_options
    start_time = CanvasTime.try_parse(params[:start_time])
    end_time = CanvasTime.try_parse(params[:end_time])

    options = {}
    options[:oldest] = start_time if start_time
    options[:newest] = end_time if end_time
    options
  end
end
