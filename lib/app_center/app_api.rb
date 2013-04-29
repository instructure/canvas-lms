module AppCenter
  class AppApi
    attr_reader :app_center

    def initialize
      @app_center = Canvas::Plugin.find(:app_center)
    end

    def get_apps(offset = 0, per_page = 10)
      if @app_center && @app_center.enabled? && !@app_center.settings['base_url'].empty?

        base_url = @app_center.settings['base_url']
        endpoint = @app_center.settings['apps_endpoint']
        response = Rails.cache.fetch(['app_center', base_url, endpoint, offset, per_page].cache_key, :expires_in => 5.minutes) do
          path = "#{@app_center.settings['apps_endpoint']}?page=#{offset}&per_page=#{per_page}"
          response = Canvas::HTTP.get("#{@app_center.settings['base_url']}/#{path}").body
        end

        apps = JSON.parse(response)['objects']

        #Temporary hack until edu-apps pagination works correctly
        if apps.size > per_page
          apps = apps[offset, per_page]
        end

        return apps
      else
        return []
      end
    end
  end
end