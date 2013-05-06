module AppCenter
  class AppApi
    attr_reader :app_center

    def initialize
      @app_center = Canvas::Plugin.find(:app_center)
    end

    def valid_app_center?
      @app_center && @app_center.enabled? && !@app_center.settings['base_url'].empty?
    end

    def fetch_app_center_response(endpoint, expires, page, per_page)
      return {} unless valid_app_center?

      base_url = @app_center.settings['base_url']
      page = page.to_i
      per_page = per_page.to_i
      offset = ( page - 1 ) * per_page

      cache_key = ['app_center', base_url, endpoint, offset].cache_key
      response = Rails.cache.fetch(cache_key, :expires_in => expires) do
        uri = URI.parse("#{base_url}#{endpoint}")
        uri.query = [uri.query, "offset=#{offset}"].compact.join('&')
        Canvas::HTTP.get(uri.to_s).body
      end

      begin
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

    def get_app_reviews(id, page = 1, per_page = 15)
      return {} unless valid_app_center?

      fetch_app_center_response(@app_center.settings['app_reviews_endpoint'].gsub(':id', id.to_s), 60.minutes, page, per_page)
    end
  end
end