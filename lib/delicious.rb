module Delicious
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
  
  def delicious_get_last_posted(service)
    http,request = delicious_generate_request('https://api.del.icio.us/v1/posts/update', 'GET', service.service_user_name, service.decrypted_password)
    response = http.request(request)
    case response
      when Net::HTTPSuccess
        updated = Nokogiri::XML(response.body).root["time"]
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
        code = Nokogiri::XML(response.body).root["code"]
        return code == 'done'
      else
        response.error!
    end
  end
end
