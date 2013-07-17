require 'net/http'
require 'net/https'
require 'uri'

module AppCenter
  class AppApi
    attr_reader :app_center

    def initialize
      @app_center = Canvas::Plugin.find(:app_center)
    end

    def valid_app_center?
      @app_center && @app_center.enabled? && !@app_center.settings['base_url'].empty?
    end

    def fetch_app_center_response(endpoint, expires, page, per_page, force_refresh=false)
      return {} unless valid_app_center?

      base_url = @app_center.settings['base_url']
      page = page.to_i
      per_page = per_page.to_i
      offset = ( page - 1 ) * per_page

      begin
        cache_key = ['app_center', base_url, endpoint, offset].cache_key
        Rails.cache.delete(cache_key) if force_refresh

        response = Rails.cache.fetch(cache_key, :expires_in => expires) do
          uri = URI.parse("#{base_url}#{endpoint}")
          uri.query = [uri.query, "offset=#{offset}"].compact.join('&')
          Canvas::HTTP.get(uri.to_s).body
        end

        json = JSON.parse(response)
        json['meta']['next_page'] = page + 1  if (json['meta'] && json['meta']['next']) || (json['objects'] && json['objects'].size > per_page)
        json['objects'] = json['objects'][0, per_page] if json['objects']
      rescue
        json = {}
        Rails.cache.delete cache_key
      end

      return json
    end

    def get_apps(page = 1, per_page = 72)
      return {} unless valid_app_center?

      fetch_app_center_response(@app_center.settings['apps_index_endpoint'], 5.minutes, page, per_page)
    end

    def get_app_reviews(id, page = 1, per_page = 15, force_refresh=false)
      return {} unless valid_app_center?

      fetch_app_center_response(@app_center.settings['app_reviews_endpoint'].gsub(':id', id.to_s), 60.minutes, page, per_page, force_refresh)
    end

    def get_app_user_review(id, user_id)
      return {} unless valid_app_center?
      
      begin
        base_url = @app_center.settings['base_url']
        app_reviews_endpoint = @app_center.settings['app_reviews_endpoint'].gsub(':id', id.to_s)
        token = @app_center.settings['token']
        uri = URI.parse("#{base_url}#{app_reviews_endpoint}/#{token}/#{user_id}")
        response = Canvas::HTTP.get(uri.to_s).body
        json = JSON.parse(response)
      rescue
        json = {}
      end
      return json
    end

    def add_app_review(id, user_id, user_name, rating, comments, avatar)
      return {} unless valid_app_center?

      base_url = @app_center.settings['base_url']
      app_reviews_endpoint = @app_center.settings['app_reviews_endpoint'].gsub(':id', id.to_s)
      token = @app_center.settings['token']
      uri = URI.parse("#{base_url}#{app_reviews_endpoint}")
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl=true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      begin
        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({
          :access_token    => token,
          :user_id         => user_id,
          :user_name       => user_name,
          :rating          => rating,
          :comments        => comments,
          :user_avatar_url => avatar
        })
        response = http.request(request)
        json = JSON.parse(response.body)
      rescue
        json = {}
      end
      return json
    end
  end
end