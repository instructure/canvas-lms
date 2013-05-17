#
# Copyright (C) 2012 Instructure, Inc.
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

module Api::V1::AccountAuthorizationConfig
  include Api::V1::Json

  def aacs_json(aacs)
    aacs.map do |aac|
      aac_json(aac)
    end
  end

  def aac_json(aac)
    AccountAuthorizationConfig.recognized_params(aac.auth_type).inject(api_json(aac, nil, nil, :only => [:id, :position])) do |h, key|
      h[key] = aac.send(key) unless key == :auth_password
      h
    end
  end
end
