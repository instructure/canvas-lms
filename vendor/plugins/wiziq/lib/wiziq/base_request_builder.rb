require 'net/http'
require 'uri'

module Wiziq

  class BaseRequestBuilder
    attr_reader :api_method, :api_url

    def initialize(api_method)
      @api_method = api_method
      @plugin = Canvas::Plugin.find(:wiziq)
      @api_url = @plugin.setting(:api_url) + %{?method=#{@api_method}}
      get_auth_params
    end

    def get_auth_params
      access_key = @plugin.setting :access_key
      secret_key = @plugin.setting :secret_key
      time_stamp = get_unix_timestamp
      signature_base = "#{ApiConstants::ParamsAuth::ACCESS_KEY}=#{access_key}&#{ApiConstants::ParamsAuth::TIMESTAMP}=#{time_stamp}&#{ApiConstants::ParamsAuth::METHOD}=#{@api_method}"
      auth_base = AuthBase.new(secret_key, signature_base)
      signature = auth_base.generate_hmac_digest
      @post_params = {
         ApiConstants::ParamsAuth::ACCESS_KEY => access_key,
         ApiConstants::ParamsAuth::TIMESTAMP  => time_stamp,
         ApiConstants::ParamsAuth::SIGNATURE  => signature
      }
    end

    def add_params(params={})
      @post_params.merge! params
    end

    def add_param(key,value)
      add_params(key => value)
    end

    def send_api_request
      uri = URI(@api_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      req = Net::HTTP::Post.new(uri.request_uri)
      req.set_form_data(@post_params)
      res = http.request(req)
      r = res.body
      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
       r
      else
        res.error!
      end
    end

    def get_unix_timestamp
      Time.now.to_i
    end

    private :get_auth_params, :get_unix_timestamp
  end
end
