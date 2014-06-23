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
  
  # @API Get Kaltura config
  # Return the config information for the Kaltura plugin in json format.
  #
  # @response_field enabled Enabled state of the Kaltura plugin
  # @response_field domain Main domain of the Kaltura instance (This is the URL where the Kaltura API resides)
  # @response_field resources_domain Kaltura URL for grabbing thumbnails and other resources
  # @response_field rtmp_domain Hostname to be used for RTMP recording
  # @response_field partner_id Partner ID used for communicating with the Kaltura instance
  #
  # @example_response
  #     # For an enabled Kaltura plugin:
  #     {
  #       'domain': 'kaltura.example.com',
  #       'enabled': true,
  #       'partner_id': '123456',
  #       'resource_domain': 'cdn.kaltura.example.com',
  #       'rtmp_domain': 'rtmp.example.com'
  #     }
  #
  #     # For a disabled or unconfigured Kaltura plugin:
  #     {
  #       'enabled': false
  #     }
  def show_kaltura_config
    if @current_user
      @kal = CanvasKaltura::ClientV3.config
      response = { 'enabled' => !@kal.nil? }
      
      if @kal
        response['domain'] = @kal['domain']
        response['resource_domain'] = @kal['resource_domain']
        response['rtmp_domain'] = @kal['rtmp_domain']
        response['partner_id'] = @kal['partner_id']
      end
    
      render :json => response
    else
      render_unauthorized_action
    end
  end

  # @API Start Kaltura session
  # Start a new Kaltura session, so that new media can be recorded and uploaded
  # to this Canvas instance's Kaltura instance.
  #
  # @response_field ks The kaltura session id, for use in the kaltura v3 API.
  #     This can be used in the uploadtoken service, for instance, to upload a new
  #     media file into kaltura.
  #
  # @example_response
  #     {
  #       'ks': '1e39ad505f30c4fa1af5752b51bd69fe'
  #     }
  def start_kaltura_session
    @user = @current_user
    if !@current_user
      render :json => {:errors => {:base => t('must_be_logged_in', "You must be logged in to use Kaltura")}, :logged_in => false}
    end
    client = CanvasKaltura::ClientV3.new
    uid = "#{@user.id}_#{@domain_root_account.id}"
    res = client.startSession(CanvasKaltura::SessionType::USER, uid)
    raise "Kaltura session failed to generate" if res.match(/START_SESSION_ERROR/)
    render :json => {
      :ks => res,
      :subp_id => CanvasKaltura::ClientV3.config['subpartner_id'],
      :partner_id => CanvasKaltura::ClientV3.config['partner_id'],
      :uid => uid,
      :serverTime => Time.now.to_i
    }
  end
  
end
