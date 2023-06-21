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
#

module Diigo
  class Error < RuntimeError; end

  class TooManyRedirectsError < Diigo::Error; end

  class Connection
    def self.diigo_url(service)
      "https://www.diigo.com/api/v2/bookmarks?key=#{CGI.escape(key)}&user=#{CGI.escape(service.service_user_name)}"
    end

    def self.diigo_generate_request(url, method, user_name, password, form_data = nil)
      redirect_limit = 3
      loop do
        raise(TooManyRedirectsError) if redirect_limit <= 0

        url = URI.parse url
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        path = url.path
        path += "?" + url.query if url.query

        request = if method == "GET"
                    Net::HTTP::Get.new(path)
                  else
                    Net::HTTP::Post.new(path)
                  end
        request.set_form_data(form_data) if form_data
        request.basic_auth user_name, password
        response = http.request(request)

        case response
        when Net::HTTPSuccess
          return response
        when Net::HTTPRedirection
          url = response["Location"]
          redirect_limit -= 1
        else
          response.error!
        end
      end
    end

    def self.diigo_get_bookmarks(service)
      response = diigo_generate_request(diigo_url(service), "GET", service.service_user_name, service.decrypted_password)
      ActiveSupport::JSON.decode(response.body)
    end

    def self.diigo_post_bookmark(service, url, title, desc, tags)
      form_data = { title:, url:, tags: tags.join(","), desc: }
      response = diigo_generate_request(diigo_url(service), "POST", service.service_user_name, service.decrypted_password, form_data)
      ActiveSupport::JSON.decode(response.body)
    end

    def self.key
      config["api_key"]
    end

    def self.config_check(settings)
      key = settings[:api_key]
      key ? nil : "Configuration check failed, please check your settings"
    end

    def self.config=(config)
      unless config.is_a?(Proc)
        raise "Config must be a Proc"
      end

      @config = config
    end

    def self.config
      @config.call
    end
  end
end
