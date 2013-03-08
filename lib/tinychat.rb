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

class Tinychat
  require 'net/http'
  require 'net/https'
  require 'uri'
  
  def self.config_check(settings)
    auth = Digest::MD5.hexdigest("#{settings['secret_key']}:roomlist")
    res = Net::HTTP.get(URI.parse("http://tinychat.apigee.com/roomlist?result=json&key=#{settings['api_key']}&auth=#{auth}"))
    json = JSON.parse(res) rescue nil
    if json && json['error'] && json['error'] == "invalid request"
      "Configuration check failed, please check your settings"
    else
      nil
    end
  end
  
  def self.config
    Canvas::Plugin.find(:tinychat).try(:settings) ||
      (YAML.load_file(Rails.root+"config/tinychat.yml")[Rails.env] rescue nil)
  end
end
