#
# Copyright (C) 2011 Instructure, Inc.
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

# @API Services
class ServicesApiController < ApplicationController
  
  # @API
  # Return the config information for kaltura in json format.
  #
  # @response_field domain Main domain of the kaltura instance. This is the URL where the kaltura API resides.
  # @response_field resources_domain Kaltura URL for grabbing thumbnails and other resources.
  # @response_field partner_id Partner ID used for communicating with the kaltura instance
  #
  # Example response:
  #
  # {
  #   'domain': 'kaltura.example.com',
  #   'resource_domain': 'cdn.kaltura.example.com',
  #   'partner_id': '123456'
  # }
  def show_kaltura_config
    if @current_user
      @kal = Kaltura::ClientV3.config
      response = { 'enabled' => !@kal.nil? }
      
      if @kal
        response['domain'] = @kal['domain']
        response['resource_domain'] = @kal['resource_domain']
        response['partner_id'] = @kal['partner_id']
      end
    
      render :json => response.to_json
    else
      render_unauthorized_action
    end
  end
  
end