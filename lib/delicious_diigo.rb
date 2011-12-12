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

module DeliciousDiigo
  require 'net/http'
  require 'net/https'
  require 'uri'
  
  def delicious_generate_request(url, method, user_name, password)
    rootCA = '/etc/ssl/certs'
    
    url = URI.parse url
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == 'https')
    if File.directory? rootCA
      http.ca_path = rootCA
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.verify_depth = 5
    else
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
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
  
  def bookmark_search(service, query)
    bookmarks = []
    if service.service == 'diigo'
      url = "http://api2.diigo.com/bookmarks?users=#{service.service_user_name}&tags=#{query}"
      http,request = diigo_generate_request(url, 'GET', service.service_user_name, service.decrypted_password)
      response = http.request(request)
      case response
      when Net::HTTPSuccess
        data = ActiveSupport::JSON.decode(response.body)
        data.each do |bookmark|
          bookmarks << {
            :title => bookmark['title'],
            :url => bookmark['url'],
            :description => bookmark['desc'],
            :tags => bookmark['tags'].split(/\s/).join(",")
          }
        end
      else
        response.error!
      end
    elsif service.service == 'delicious'
      url = "https://api.del.icio.us/v1/posts/all?tag=#{query}"
      http,request = delicious_generate_request(url, 'GET', service.service_user_name, service.decrypted_password)
      response = http.request(request)
      case response
      when Net::HTTPSuccess
        require 'libxml'
        document = LibXML::XML::Parser.string(response.body).parse
        document.find('/posts/post').each do |post|
          bookmarks << {
            :title => post['description'],
            :url => post['href'],
            :description => post['description'],
            :tags => post['tags']
          }
        end
      else
        response.error!
      end
    end
    bookmarks
  end
  
  def delicious_get_last_posted(service)
    http,request = delicious_generate_request('https://api.del.icio.us/v1/posts/update', 'GET', service.service_user_name, service.decrypted_password)
    response = http.request(request)
    case response
      when Net::HTTPSuccess
        require 'libxml'
        updated = LibXML::XML::Parser.string(response.body).parse.child["time"]
        return Time.parse(updated)
      else
        response.error!
    end
  end
  
  def delicious_post_bookmark(service, tag_url, title, desc, tags)
    http,request = delicious_generate_request('https://api.del.icio.us/v1/posts/add', 'POST', service.service_user_name, service.decrypted_password)
    request.set_form_data({:url => tag_url, :description => desc, :tags => tags.map{|t| t.to_s.gsub(/\s/, "_")}.join(" ")})
    response = http.request(request)
    case response
      when Net::HTTPSuccess
        require 'libxml'
        code = LibXML::XML::Parser.string(response.body).parse.child["code"]
        return code == 'done'
      else
        response.error!
    end
  end
  
  def diigo_generate_request(url, method, user_name, password)
    url = URI.parse url
    http = Net::HTTP.new(url.host, url.port)
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
  
  def diigo_get_bookmarks(service, cnt=10)
    http,request = diigo_generate_request('http://api2.diigo.com/bookmarks', 'GET', service.service_user_name, service.decrypted_password)
    response = http.request(request)
    case response
      when Net::HTTPSuccess
        return ActiveSupport::JSON.decode(response.body)
      else
        response.error!
    end
  end
  
  def diigo_post_bookmark(service, url, title, desc, tags)
    http,request = diigo_generate_request('http://api2.diigo.com/bookmarks', 'POST', service.service_user_name, service.decrypted_password)
    request.set_form_data({:title => title, :url => url, :tags => tags.join(","), :desc => desc})
    response = http.request(request)
    case response
      when Net::HTTPSuccess
        return ActiveSupport::JSON.decode(response.body)
      else
        response.error!
    end
  end
end
