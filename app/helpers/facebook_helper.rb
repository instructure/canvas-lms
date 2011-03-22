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

module FacebookHelper
  include Facebooker::Rails::Helpers
  
  def install_url
    @facebook_session.install_url(:next => "#{facebook_host}/facebook/authorize_user?oauth_request_id=#{@oauth_request && @oauth_request.id}&fb_key=#{params[:fb_key]}") #rescue "#"
  end
  
  def fb_key(pre="")
    params[:fb_key] ? "#{pre}fb_key=#{params[:fb_key]}" : ""
  end
  
  def authorize_url
    if @facebook_user_id
      nonce = Digest::MD5.hexdigest(@facebook_user_id.to_s + "_instructure_verified--for_facebook")
      "#{facebook_host}/facebook/authorize_user?user_id=#{@facebook_user_id}&nonce=#{nonce}#{fb_key("&")}"
    else
      "#"
    end
  end
  
  def facebook_host
    @original_host_with_port = @oauth_request.original_host_with_port if @oauth_request
    return "http://#{@original_host_with_port}" if @original_host_with_port
    "http://#{HostUrl.default_host}"
  end
end
