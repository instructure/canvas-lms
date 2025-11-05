# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class MicrofrontendsReleaseTagOverrideController < ApplicationController
  before_action :validate_environment

  SUPPORTED_APPS = %w[canvas_career_learner canvas_career_learning_provider].freeze
  ALLOWED_HOSTS = %w[assets.instructure.com].freeze

  def create
    validate_params!

    service = MicrofrontendsReleaseTagOverrideService.new(session)

    if params[:override].present?
      params[:override].each do |app, assets_url|
        next if assets_url.blank?

        service.set_override(app:, assets_url:)
      end
    end

    redirect_to root_url
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    service = MicrofrontendsReleaseTagOverrideService.new(session)
    service.clear_overrides

    redirect_to request.referer || root_url
  end

  private

  def validate_environment
    not_found unless Setting.get("allow_microfrontend_release_tag_override", "false") == "true"
  end

  def validate_params!
    override_params = params[:override]

    unless override_params.respond_to?(:each)
      raise ArgumentError, "override parameter must be a hash"
    end

    override_params.each do |app, assets_url|
      next if assets_url.blank?

      unless SUPPORTED_APPS.include?(app)
        raise ArgumentError, "app '#{app}' must be one of: #{SUPPORTED_APPS.join(", ")}"
      end

      begin
        uri = URI.parse(assets_url)
        unless ALLOWED_HOSTS.include?(uri.host)
          raise ArgumentError, "assets_url host for '#{app}' must be one of: #{ALLOWED_HOSTS.join(", ")}"
        end
      rescue URI::InvalidURIError
        raise ArgumentError, "assets_url for '#{app}' must be a valid URL"
      end
    end
  end
end
