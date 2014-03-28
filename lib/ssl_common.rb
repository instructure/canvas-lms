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

require 'net/https'

class SSLCommon
  SSL_CA_PATH = "/etc/ssl/certs/"

  class << self
    def get_http_conn(host, port, ssl)
      http = Net::HTTP.new(host, port)
      http.use_ssl = true if ssl
      if File.directory? SSL_CA_PATH
        http.ca_path = SSL_CA_PATH
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      http
    end

    def raw_post(url, payload, headers = {}, form_data = nil)
      url = URI.parse(url)
      http = self.get_http_conn(url.host, url.port, url.scheme.downcase == 'https')
      req = Net::HTTP::Post.new(url.request_uri, headers)
      req.basic_auth URI.unescape(url.user || ""), URI.unescape(url.password || "") if url.user
      req.form_data = form_data if form_data
      http.start {|http| http.request(req, payload) }
    end

    def get(url, headers={})
      url = URI.parse(url)
      http = self.get_http_conn(url.host, url.port, url.scheme.downcase == 'https')
      http.get(url.request_uri, headers)
    end

    def post_form(url, form_data, headers={})
      self.raw_post(url, nil, headers, form_data)
    end

    def post_multipart_form(url, form_data, headers={}, field_priority=[])
      payload, mp_headers = Multipart::Post.new.prepare_query(form_data, field_priority)
      self.raw_post(url, payload, mp_headers.merge(headers))
    end

    def post_data(url, data, content_type, headers={})
      self.raw_post(url, data, {"Content-Type" => content_type}.merge(headers))
    end
  end
end
