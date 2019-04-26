#
# Copyright (C) 2019 - present Instructure, Inc.
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

# @API Image Search
# @beta

class InternetImageController < ApplicationController

  before_action :require_user
  before_action :unsplash_config

  def unsplash_config
    @settings ||= Canvas::Plugin.find(:unsplash).try(:settings)
    return render json: { message: 'Service not configured' }, status: :not_implemented unless @settings&.dig('access_key')&.present?
  end

  def service_url
    "https://api.unsplash.com"
  end

  # @API Find images
  # Find public domain images for use in courses and user content.
  #
  # @argument query [String]
  #   Search terms used for matching images (e.g. "cats").
  #
  # @example_response
  #   [{"id": "eOLpJytrbsQ", "user": "Jeff Sheldon", "user_url": "http://unsplash.com/@ugmonk", "url": "https://images.unsplash.com/photo-1416339306562-f3d12fefd36f?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max&s=92f3e02f63678acc8416d044e189f515"}]
  #
  # @response_field id The unique identifier for the image.
  #
  # @response_field description Accessible description of the image.
  #
  # @response_field user The name of the user who owns the image
  #
  # @response_field user_url The URL to view the user's profile on the image upload site
  #
  # @response_field large_url The URL of the image sized large
  #
  # @response_field regular_url The URL of the image
  #
  # @response_field small_url The URL of the image sized small

  def image_search
    search_url = "#{service_url}/search/photos"
    send_params = {per_page: 10, page: 1}.merge(params.permit(:query, :per_page, :page))
    search_results = HTTParty.get("#{search_url}?#{send_params.to_query}", {
      headers: {"Authorization" => "Client-ID #{@settings[:access_key]}"}
    })
    raise "Unsplash: #{search_results.dig('errors')&.join(', ') || search_results}" unless search_results.success?
    new_links = LinkHeader.parse(search_results.headers['Link']).links.map do |link|
      url = URI.parse(link.href)
      ["#{request.protocol}#{request.host_with_port}#{request.path}?#{url.query}", link.attr_pairs]
    end
    response.headers['Link'] = LinkHeader.new(new_links).to_s
    json = JSON.parse(search_results.body).dig('results').map do |sr|
      {
        id: sr['id'],
        description: sr['description'],
        user: sr.dig('user', 'name'),
        user_url: sr.dig('user', 'links', 'html'),
        large_url: sr.dig('urls', 'regular'),
        regular_url: sr.dig('urls', 'small'),
        small_url: sr.dig('urls', 'thumb')
      }
    end
    render json: json
  end
end
