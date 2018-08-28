#
# Copyright (C) 2013 - present Instructure, Inc.
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

require 'net/http'
require 'net/https'
require 'uri'

module AppCenter
  class AppApi
    attr_reader :app_center

    def initialize(context)
      @app_center = Canvas::Plugin.find(:app_center)
      @context ||= context
    end

    def valid_app_center?
      @app_center&.enabled? && !@app_center.settings['base_url'].empty?
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

      json
    end

    def get_apps(page = 1, per_page = 72)
      return {} unless valid_app_center?

      uri = URI.parse(@app_center.settings['apps_index_endpoint'])
      params = URI.decode_www_form(uri.query || '')
      access_token = app_center_token_by_context
      params << ['access_token', access_token]
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

    def get_app_config_url(app_center_id, config_settings)
      access_token = app_center_token_by_context
      endpoint = "/api/v1/lti_apps/#{app_center_id}?access_token=#{access_token}"

      app_details = fetch_app_center_response(endpoint, 5.minutes, 1, 1)

      if app_details['config_xml_url']
        user_query_string = ''
        user_query_string = config_settings.map {|k, v| "#{k}=#{v}"}.join('&') if config_settings

        response_config_url = app_details['config_xml_url']

        uri = URI(response_config_url)
        response_config_url += (uri.query.present? ? '&' : '?') + user_query_string if user_query_string.present?

        config_url = response_config_url
      else
        config_url = nil
      end

      config_url
    end

    private

    def app_center_token_by_context
      context = @context.is_a?(Account) ? @context : @context.account

      context.settings[:app_center_access_token].presence ||
      context.calculate_inherited_setting(:app_center_access_token)[:value] ||
      @app_center.settings['token']
    end
  end
end
