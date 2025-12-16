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

# Rate Limiting Settings
#
# Controller for managing rate limiting settings for external tools and integrations.
#
class RateLimitingSettingsController < ApplicationController
  before_action :get_context
  before_action :require_account_management
  before_action :require_feature_flag
  before_action :check_rate_limiting_permission
  before_action :set_oauth_client_config, only: %i[show update destroy]

  # List rate limit settings
  #
  # Returns a paginated list of rate limit settings for the account.
  # For HTML requests, displays the rate limiting settings page.
  # For JSON requests, returns paginated data.
  def index
    respond_to do |format|
      format.html do
        set_navigation
        js_env(
          ACCOUNT: {
            "id" => @context.id,
            "site_admin" => @context.site_admin?,
            "root_account" => @context.root_account?
          }
        )
        render :index
      end
      format.json do
        # Determine sorting parameters
        order_by = params[:order_by]&.to_sym || :created_at
        direction = (params[:direction]&.downcase == "asc") ? :asc : :desc

        # Map UI sort fields to database columns and build scope with ordering
        scope = @context.oauth_client_configs.active

        # List of allowed sort columns for validation
        allowed_sort_columns = %i[
          type
          identifier
          client_name
          throttle_high_water_mark
          throttle_outflow
          comment
          updated_at
        ].freeze

        if order_by == :updated_by
          scope = scope.joins(:updated_by).order("users.name #{direction.to_s.upcase}, oauth_client_configs.id #{direction.to_s.upcase}")
          primary_column = :updated_at # We can't bookmark on joined columns, so use updated_at
        else
          column = allowed_sort_columns.include?(order_by) ? order_by : :created_at
          scope = scope.order(column => direction, :id => direction)
          primary_column = column
        end

        # Only eager_load when needed for sorting
        scope = scope.eager_load(:updated_by) unless order_by == :updated_by

        bookmarker = BookmarkedCollection::SimpleBookmarker.new(OAuthClientConfig, primary_column, :id)
        bookmarked_collection = BookmarkedCollection.wrap(bookmarker, scope)
        @oauth_client_configs = Api.paginate(bookmarked_collection, self, polymorphic_url([@context, :rate_limiting_settings]))

        render json: @oauth_client_configs.map(&method(:serialize_oauth_client_config))
      end
    end
  end

  # Get rate limit setting
  #
  # Retrieve a single rate limit setting by ID.
  def show
    respond_to do |format|
      format.json { render json: serialize_oauth_client_config(@oauth_client_config) }
    end
  end

  # Create rate limit setting
  #
  # Create a new rate limit setting.
  def create
    create_params = oauth_client_config_params
    calculate_throttle_maximum_if_needed(create_params)

    @oauth_client_config = @context.oauth_client_configs.build(create_params)
    @oauth_client_config.updated_by = @current_user

    if @oauth_client_config.save
      respond_to do |format|
        format.json do
          render json: serialize_oauth_client_config(@oauth_client_config),
                 status: :created
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: { errors: @oauth_client_config.errors.full_messages },
                 status: :unprocessable_entity
        end
      end
    end
  end

  # Update rate limit setting
  #
  # Update an existing rate limit setting.
  def update
    update_params = oauth_client_config_params.except(:type, :identifier)
    calculate_throttle_maximum_if_needed(update_params)
    update_params[:updated_by] = @current_user

    if @oauth_client_config.update(update_params)
      respond_to do |format|
        format.json { render json: serialize_oauth_client_config(@oauth_client_config) }
      end
    else
      respond_to do |format|
        format.json do
          render json: { errors: @oauth_client_config.errors.full_messages },
                 status: :unprocessable_entity
        end
      end
    end
  end

  # Delete rate limit setting
  #
  # Delete a rate limit setting.
  def destroy
    @oauth_client_config.destroy

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  protected

  def set_navigation
    set_active_tab "rate_limiting"
    add_crumb t("#crumbs.rate_limiting", "Rate Limiting")
  end

  private

  def require_feature_flag
    unless @context.feature_enabled?(:api_rate_limits)
      respond_to do |format|
        format.html { redirect_to account_path(@context) }
        format.json { render json: { error: "Feature not enabled" }, status: :forbidden }
      end
      false
    end
  end

  def check_rate_limiting_permission
    unless @context.grants_right?(@current_user, session, :manage_rate_limiting)
      respond_to do |format|
        format.html { redirect_to account_path(@context) }
        format.json { render json: { error: "Permission denied" }, status: :forbidden }
      end
      false
    end
  end

  def set_oauth_client_config
    @oauth_client_config = @context.oauth_client_configs.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { error: "Rate limit setting not found" }, status: :not_found }
    end
  end

  def oauth_client_config_params
    params.expect(rate_limit_setting: %i[type identifier throttle_high_water_mark throttle_maximum throttle_outflow client_name comment])
  end

  def serialize_oauth_client_config(config)
    {
      id: config.id.to_s,
      identifier_type: config.type,
      identifier_value: config.identifier,
      masked_identifier: masked_identifier(config.identifier),
      rate_limit: config.throttle_high_water_mark,
      outflow_rate: config.throttle_outflow,
      client_name: config.client_name,
      comment: config.comment,
      created_at: config.created_at.iso8601,
      updated_at: config.updated_at.iso8601,
      updated_by: config.updated_by&.name
    }
  end

  def masked_identifier(identifier)
    return identifier if identifier.blank? || identifier.length <= 8

    start_chars = identifier[0..3]
    end_chars = identifier[-4..]
    "#{start_chars}...#{end_chars}"
  end

  # Calculate throttle_maximum automatically if not provided but throttle_high_water_mark is present
  # This allows manual API users to set both values explicitly, while UI users get automatic calculation
  def calculate_throttle_maximum_if_needed(params)
    high_water_mark = params[:throttle_high_water_mark]
    return unless high_water_mark.present? && !params.key?(:throttle_maximum)

    params[:throttle_maximum] = [high_water_mark.to_i + 200, 0].max
  end
end
