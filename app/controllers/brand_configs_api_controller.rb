#
# Copyright (C) 2016 - present Instructure, Inc.
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

# @API Brand Configs
class BrandConfigsApiController < ApplicationController

  # @API Get the brand config variables that should be used for this domain
  #
  # Will redirect to a static json file that has all of the brand
  # variables used by this account. Even though this is a redirect,
  # do not store the redirected url since if the account makes any changes
  # it will redirect to a new url. Needs no authentication.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/brand_variables'
  def show
    headers['Access-Control-Allow-Origin'] = '*'
    redirect_to active_brand_config_url('json')
  end
end
