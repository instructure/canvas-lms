# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

class RequestError < RuntimeError
  attr_accessor :response_status

  def initialize(message, status = :bad_request)
    self.response_status = Rack::Utils.status_code(status)
    super(message)
  end

  def error_json
    {
      status: (Rack::Utils::SYMBOL_TO_STATUS_CODE.key(response_status) || :internal_server_error).to_s,
      message:
    }
  end
end
