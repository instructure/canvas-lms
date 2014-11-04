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

    def fetch_app_center_response(endpoint, expires, page, per_page)
      return {} unless valid_app_center?

      base_url = @app_center.settings['base_url']
      page = page.to_i
      per_page = per_page.to_i
      offset = ( page - 1 ) * per_page
      access_token = @app_center.settings['token']

      begin
        cache_key = ['app_center', base_url, endpoint, offset, access_token].cache_key
        response = Rails.cache.fetch(cache_key, :expires_in => expires) do
          uri = URI.parse("#{base_url}#{endpoint}")
          uri.query = [uri.query, "offset=#{offset}"].compact.join('&')
          CanvasHttp.get(uri.to_s).body
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

      uri = URI.parse(@app_center.settings['apps_index_endpoint'])
      params = URI.decode_www_form(uri.query || '')
      params << ['access_token', @app_center.settings['token']]
      uri.query = URI.encode_www_form(params)

      json = fetch_app_center_response(uri.to_s, 5.minutes, page, per_page)
      if json['lti_apps']
        json['lti_apps'].each do |app|
          app.delete('tags').each do |tag|
            context = 'custom_tags'
            case tag['context']
              when "category"
                context = 'categories'
              when "extension"
                context = 'extensions'
              when "education_level"
                context = 'levels'
            end
            app[context] ||= []
            app[context] << tag['name']
          end
        end
      elsif json['objects']
        #mapping for backwards compatibility with edu-apps v1
        apps = json.delete('objects')
        apps.each do |app|
          app['short_description'] = app['description']
          app['short_name'] = app['id']
          app['banner_image_url'] = app['banner_url']
          app['logo_image_url'] = app['logo_url']
          app['icon_image_url'] = app['icon_url']
          app['config_xml_url'] = app['config_url']
          app['average_rating'] = app['avg_rating']
          app['total_ratings'] = app['ratings_count']
          app['requires_secret'] = !app['any_key']
          (app['config_options'] || []).each do |option|
            option['param_type'] = option['type']
            option['is_required'] = option['required']
          end
        end
        json['lti_apps'] = apps
      end
      json
    end
  end
end