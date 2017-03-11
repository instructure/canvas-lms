#
# Copyright (C) 2015 Instructure, Inc.
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

class OauthProxyController < ApplicationController
  skip_before_action :require_user
  skip_before_action :load_user

  def redirect_proxy
    reject! t("The state parameter is required") and return unless params[:state]
    begin
      json = Canvas::Security.decode_jwt(params[:state])
      url = URI.parse(json['redirect_uri'])
      filtered_params = params.keep_if { |k, _| %w(state code).include?(k) }
      url.query = url.query.blank? ? filtered_params.to_query : "#{url.query}&#{filtered_params.to_query}"
      redirect_to url.to_s
    rescue JSON::JWT::InvalidFormat, Canvas::Security::InvalidToken
      reject! t("Invalid state parameter") and return
    end
  end

end
