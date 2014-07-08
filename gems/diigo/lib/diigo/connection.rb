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

module Diigo
  class Connection
    def self.diigo_generate_request(url, method, user_name, password)
      url = URI.parse url
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = nil
      if method == 'GET'
        path = url.path
        path += "?" + url.query if url.query
        request = Net::HTTP::Get.new(path)
      else
        request = Net::HTTP::Post.new(url.path)
      end
      request.basic_auth user_name, password
      [http,request]
    end

    def self.diigo_get_bookmarks(service, cnt=10)
      http,request = diigo_generate_request("https://secure.diigo.com/api/v2/bookmarks?key=#{CGI.escape(self.key)}&user=#{CGI.escape(service.service_user_name)}",
                                            'GET', service.service_user_name, service.decrypted_password)
      response = http.request(request)
      case response
        when Net::HTTPSuccess
          return ActiveSupport::JSON.decode(response.body)
        else
          response.error!
      end
    end

    def self.diigo_post_bookmark(service, url, title, desc, tags)
      http,request = diigo_generate_request("https://secure.diigo.com/api/v2/bookmarks?key=#{CGI.escape(self.key)}&user=#{CGI.escape(service.service_user_name)}",
                                            'POST', service.service_user_name, service.decrypted_password)
      request.set_form_data({:title => title, :url => url, :tags => tags.join(","), :desc => desc})
      response = http.request(request)
      case response
        when Net::HTTPSuccess
          return ActiveSupport::JSON.decode(response.body)
        else
          response.error!
      end
    end

    def self.key(key=nil)
      self.config['api_key']
    end

    def self.config_check(settings)
      key = settings[:api_key]
      key ? nil : "Configuration check failed, please check your settings"
    end

    def self.config=(config)
      if !config.is_a?(Proc)
        raise "Config must be a Proc"
      end
      @config = config
    end

    def self.config
      @config.call()
    end
  end
end
