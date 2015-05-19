class BitlyHelper 
  def bitly_shorten(url) 
    access_token = BeyondZConfiguration.bitly_access_token 
    uri = URI.parse("https://api-ssl.bitly.com/v3/shorten?access_token=#{access_token}&longUrl=#{URI::escape(url)}&format=txt") 
    http = Net::HTTP.new(uri.host, uri.port) 
    http.use_ssl = true 
    request = Net::HTTP::Get.new(uri.request_uri) 
    response = http.request(request) 
    response.body 
  end 
end  
