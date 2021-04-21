# frozen_string_literal: true

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
#
# This API requires a compatible image search service to be configured

class InternetImageController < ApplicationController

  before_action :require_user
  before_action :require_config

  def unsplash_config
    @settings ||= Canvas::Plugin.find(:unsplash).try(:settings)
  end

  def require_config
    unsplash_config
    return render json: { message: 'Service not found' }, status: :not_found unless @settings&.dig('access_key')&.present?
  end

  def service_url
    "https://api.unsplash.com"
  end

  def add_referral_params(url)
    query = {
      utm_source: unsplash_config[:application_name],
      utm_medium: 'referral' # hardcoded from Unsplash's API docs
    }.to_query

    "#{url}#{url.include?('?') ? '&' : '?'}#{query}"
  end

  # @API Find images
  # Find public domain images for use in courses and user content.  If you select an image using this API, please use the {api:InternetImageController#image_selection Confirm image selection API} to indicate photo usage to the server.
  #
  # @argument query [Required, String]
  #   Search terms used for matching images (e.g. "cats").
  #
  # @example_response
  #   [{
  #      "id": "eOLpJytrbsQ",
  #      "description": "description",
  #      "alt": "accessible description of image",
  #      "user": "Jeff Sheldon",
  #      "user_url": "http://unsplash.com/@ugmonk",
  #      "large_url": "https://images.unsplash.com/photo-1416339306562-f3d12fefd36f?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max&s=92f3e02f63678acc8416d044e189f515",
  #      "regular_url": "https://images.unsplash.com/photo-1416339306562-f3d12fefd36f?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max&s=92f3e02f63678acc8416d044e189f515",
  #      "small_url": "https://images.unsplash.com/photo-1416339306562-f3d12fefd36f?ixlib=rb-0.3.5&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=200&fit=max&s=8aae34cf35df31a592f0bef16e6342ef"
  #   }]
  #
  # @response_field id The unique identifier for the image.
  #
  # @response_field description Description of the image.
  #
  # @response_field alt Accessible alternative text for the image.
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
  #
  # @response_field raw_url The raw URL of the photo

  def image_search
    return render json: { error: 'query param is required'}, status: :bad_request unless params[:query]
    search_url = "#{service_url}/search/photos"
    send_params = {per_page: 10, page: 1, content_filter: 'high'}.with_indifferent_access.merge(
      params.permit(:query, :per_page, :page, :orientation, :content_filter)
    )
    search_results = HTTParty.get("#{search_url}?#{send_params.to_query}", {
      headers: {"Authorization" => "Client-ID #{unsplash_config[:access_key]}"}
    })
    raise "Unsplash: #{search_results.try(:dig, 'errors')&.join(', ') || search_results}" unless search_results.success?
    new_links = LinkHeader.parse(search_results.headers['Link']).links.map do |link|
      url = URI.parse(link.href)
      ["#{request.protocol}#{request.host_with_port}#{request.path}?#{url.query}", link.attr_pairs]
    end
    response.headers['Link'] = LinkHeader.new(new_links).to_s
    json = search_results.dig('results').map do |sr|
      {
        id: Canvas::Security.url_key_encrypt_data(sr.dig('links', 'download_location')),
        description: sr['description'],
        alt: sr['alt_description'],
        user: sr.dig('user', 'name'),
        user_url: add_referral_params(sr.dig('user', 'links', 'html')),
        large_url: add_referral_params(sr.dig('urls', 'regular')),
        regular_url: add_referral_params(sr.dig('urls', 'small')),
        small_url: add_referral_params(sr.dig('urls', 'thumb')),
        raw_url: add_referral_params(sr.dig('urls', 'raw'))
      }
    end
    render json: json
  end

  # @API Confirm image selection
  # After you have used the search API, you should hit this API to indicate photo usage to the server.
  #
  # @argument id [Required, String]
  #   The ID from the image_search result.
  #
  # @response_field message Confirmation success message or error

  def image_selection
    return render json: { message: 'id param is required'}, status: :bad_request unless params[:id]
    url = ''
    begin
      url = Canvas::Security.url_key_decrypt_data(params[:id])
    rescue
      return render json: {message: 'Could not find image.  Please check the id and try again'}, status: :bad_request
    end
    confirm_download = HTTParty.head(url, {headers: {"Authorization" => "Client-ID #{unsplash_config[:access_key]}"}})
    if confirm_download.code == 404 && confirm_download.dig('errors').present?
      return render json: {message: confirm_download.dig('errors')&.join(', ')}, status: :not_found
    end
    return render json: {message: 'Confirmation success. Thank you.'} if confirm_download.success?
    raise "Unsplash: #{confirm_download.try(:dig, 'errors')&.join(', ') || confirm_download}"
  end
end
