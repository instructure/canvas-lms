#
# Copyright (C) 2018 - present Instructure, Inc.
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

require 'httparty'
require 'byebug'
class ApiClientBase
  include HTTParty

  AUTH_HEADER = 'Auth-User-Id'.freeze

  def initialize
    # default to user 1, optionally override later
    authenticate_as_user(1)
  end

  def authenticate_as_user(user_id)
    self.class.headers AUTH_HEADER => user_id.to_s
  end

end
