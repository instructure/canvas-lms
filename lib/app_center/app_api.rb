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
      access_token = @app_center.settings['token']

      begin
        cache_key = ['app_center', base_url, endpoint, offset, access_token].cache_key
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

      uri = URI.parse(@app_center.settings['apps_index_endpoint'])
      params = URI.decode_www_form(uri.query || [])
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

    def get_app_reviews(id, page = 1, per_page = 15, force_refresh=false)
      return {} unless valid_app_center?

      json = fetch_app_center_response(@app_center.settings['app_reviews_endpoint'].gsub(':id', id.to_s), 60.minutes, page, per_page, force_refresh)
      #mapping for backwards compatibility with edu-apps v1
      if !json['reviews'] && json['objects']
        reviews = json.delete('objects')
        reviews.each do |review|
          review['user'] = {
              'name' => review['user_name'],
              'url' => review['user_url'],
              'avatar_url' => review['user_avatar_url'],
          }
          review['created_at'] = review['created']
        end
        json['reviews'] = reviews
      end
      json
    end

    def get_app_user_review(id, user_id)
      return {} unless valid_app_center?
      
      begin
        base_url = @app_center.settings['base_url']
        app_reviews_endpoint = @app_center.settings['app_reviews_endpoint'].gsub(':id', id.to_s)
        token = @app_center.settings['token']
        #uri = URI.parse("#{base_url}#{app_reviews_endpoint}/#{token}/#{user_id}")

        uri = URI.parse("#{base_url}#{app_reviews_endpoint}")
        params = URI.decode_www_form(uri.query || [])
        params << ['organization[access_token]', @app_center.settings['token']]
        params << ['membership[remote_uid]', user_id]
        uri.query = URI.encode_www_form(params)
        uri.to_s

        response = Canvas::HTTP.get(uri.to_s).body
        json = JSON.parse(response)
        json = json['reviews'].first if json['reviews']
      rescue
        json = {}
      end
      return json
    end

    def add_app_review(id, user, rating, comments)
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
        #review = app_api.add_app_review(params[:app_id], @current_user.try(:uuid), @current_user.try(:name), params[:rating], params[:comments], @current_user.try(:avatar_url))
        request = Net::HTTP::Post.new(uri.request_uri)
        form_data = {
            :access_token    => token,
            :rating          => rating,
            :comments        => comments,
            :user_id         => user.uuid,
            :user_name       => user.name,
            :user_avatar_url => user.avatar_url
        }
        form_data[:user_email] = user.email if user.email && user.email[/.+@.+\..+/]
        request.set_form_data(form_data)
        response = http.request(request)

        json = JSON.parse(response.body)
      rescue
        json = {}
      end
      return json
    end
  end
end