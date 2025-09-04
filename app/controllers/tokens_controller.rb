# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

# @API Access Tokens
# @model Token
#     {
#       "id": "Token",
#       "type": "object",
#       "properties": {
#         "id": { "type": "integer", "description": "The internal database ID of the token." },
#         "created_at": { "type": "string", "format": "date-time", "description": "The time the token was created." },
#         "expires_at": { "type": ["string", "null"], "format": "date-time", "description": "The time the token will permanently expire, or null if it does not permanently expire." },
#         "workflow_state": { "type": "string", "description": "The current state of the token. One of 'active', 'pending', 'disabled', or 'deleted'." },
#         "remember_access": { "type": "boolean", "description": "Whether the token should be remembered across sessions. Only applicable for OAuth tokens." },
#         "scopes": { "type": "array", "items": { "type": "string" }, "description": "The scopes associated with the token. If empty, there are no scope limitations." },
#         "real_user_id": { "type": ["integer", "null"], "description": "If the token was created while masquerading, this is the ID of the real user. Otherwise, null." },
#         "token": { "type": "string", "description": "The actual access token. Only included when the token is first created." },
#         "token_hint": { "type": "string", "description": "A short, unique string that can be used to look up the token." },
#         "user_id": { "type": "integer", "description": "The ID of the user the token belongs to." },
#         "purpose": { "type": "string", "description": "The purpose of the token." },
#         "app_name": { "type": ["string", "null"], "description": "If the token was created by an OAuth application, this is the name of that application. Otherwise, null." },
#         "can_manually_regenerate": { "type": "boolean", "description": "Whether the current user can manually regenerate this token." }
#       }
#     }
class TokensController < ApplicationController
  include Api::V1::Token
  include StudentEnrollmentHelper

  MAXIMUM_EXPIRATION_DURATION = 120.days

  before_action :require_registered_user
  before_action :get_context
  before_action :find_token, except: [:create, :user_generated_tokens]
  before_action { |c| c.active_tab = "profile" }
  before_action :require_password_session

  # @API List access tokens for a user
  #
  # Returns a list of manually generated access tokens for the specified user.
  # Note that the actual token values are only returned when the token is first created.
  #
  # @argument per_page [Integer]
  #  The number of results to return per page. Defaults to 10. Maximum of 100.
  #
  # @returns [Token]
  def user_generated_tokens
    unless @context.grants_right?(@current_user, session, :view_user_generated_access_tokens)
      return render_unauthorized_action
    end

    bookmarker = BookmarkedCollection::SimpleBookmarker.new(AccessToken, :created_at, :id)

    paginated_tokens = ShardedBookmarkedCollection.build(bookmarker, @context.access_tokens) do |scope|
      scope = scope.user_generated.preload(:developer_key)
      scope.order(:created_at, :id)
    end

    pagination_args = {
      per_page: params[:per_page]&.to_i || 10,
    }

    tokens = Api.paginate(paginated_tokens, self, api_v1_user_generated_tokens_path, pagination_args)

    render json: tokens.map { |token| token_json(token, @current_user, session) }
  end

  # @API Show an access token
  #
  # The ID can be the actual database ID of the token, or the 'token_hint' value.
  #
  def show
    unless @token.grants_right?(@current_user, session, :read)
      return render_unauthorized_action
    end

    render json: token_json(@token, @current_user, session)
  end

  #
  # @API Create an access token
  #
  # Create a new access token for the specified user.
  # If the user is not the current user, the token will be created as "pending",
  # and must be activated by the user before it can be used.
  #
  # @argument token[purpose] [Required, String] The purpose of the token.
  # @argument token[expires_at] [DateTime] The time at which the token will expire.
  # @argument token[scopes][] [Array] The scopes to associate with the token.
  #   Ignored if the default developer key does not have the "enable scopes" option enabled.
  #   In such cases, the token will inherit the user's permissions instead.
  #
  def create
    token_params = access_token_params

    return render_error("token[purpose] is missing") unless token_params.key?(:purpose)

    # Force an expiration date for students
    if Account.site_admin.feature_enabled?(:student_access_token_management) &&
       user_has_only_student_enrollments?(@current_user)

      return render_error("Expiration date is required") unless token_params[:permanent_expires_at]

      begin
        expiration_date = Time.zone.parse(token_params[:permanent_expires_at])
        if expiration_date > MAXIMUM_EXPIRATION_DURATION.from_now
          return render_error("Expiration date cannot be more than 120 days in the future")
        end
      rescue ArgumentError
        return render_error("Invalid expiration date format")
      end
    end

    token_params[:developer_key] = DeveloperKey.default
    @token = @context.access_tokens.build(token_params)

    return render_unauthorized_action unless @token.grants_right?(logged_in_user, AccessToken.account_session_for_permissions(@domain_root_account), :create)

    # unless we're creating it for ourselves (and not masquerading), set it to pending
    @token.workflow_state = "pending" unless @context == logged_in_user

    if @token.save
      render json: token_json(@token, @current_user, session)
    else
      render json: @token.errors, status: :bad_request
    end
  end

  #
  # @API Update an access token
  #
  # Update an existing access token.
  #
  # The ID can be the actual database ID of the token, or the 'token_hint' value.
  #
  # Regenerating an expired token requires a new expiration date.
  #
  # @argument token[purpose] [String] The purpose of the token.
  # @argument token[expires_at] [DateTime] The time at which the token will expire.
  # @argument token[scopes][] [Array] The scopes to associate with the token.
  # @argument token[regenerate] [Boolean] Regenerate the actual token.
  #
  def update
    unless @token.grants_right?(logged_in_user, AccessToken.account_session_for_permissions(@domain_root_account), :update)
      if @current_user.id == @token.user_id
        return render_unauthorized_action
      else
        raise ActiveRecord::RecordNotFound
      end
    end

    token_params = access_token_params
    if Canvas::Plugin.value_to_boolean(token_params.delete(:regenerate)) && @token.manually_created?
      if @token.expired? && !token_params.key?(:permanent_expires_at)
        return render json: { errors: { message: "cannot regenerate an expired token without a new expiration date" } }, status: :bad_request
      end

      @token.generate_token(true)
      # if it's regenerated while masquerading, set it back to pending
      @token.workflow_state = "pending" unless @context == logged_in_user
    end

    if @token.update(token_params)
      render json: token_json(@token, @current_user, session)
    else
      render json: @token.errors, status: :bad_request
    end
  end

  #
  # @API Delete an access token
  #
  # The ID can be the actual database ID of the token, or the 'token_hint' value.
  #
  def destroy
    unless @token.grants_right?(logged_in_user, session, :delete)
      if @current_user.id == @token.user_id
        return render_unauthorized_action
      else
        raise ActiveRecord::RecordNotFound
      end
    end

    @token.destroy
    render json: token_json(@token, @current_user, session)
  end

  def activate
    render_unauthorized_action unless @current_user == @token.user
    return render json: { errors: { token: ["is already active"] } }, status: :bad_request unless @token.pending?

    @token.activate!
    render json: token_json(@token, @current_user, session)
  end

  private

  def find_token
    if (hint = AccessToken.token_hint?(params[:id]))
      @token = @context.access_tokens.find_by(token_hint: hint)
    end
    @token ||= @context.access_tokens.find(params[:id])
    true
  end

  def access_token_params
    result = params.require(:token).permit(:purpose, :expires_at, :regenerate, scopes: [])
    # rename for API
    result[:permanent_expires_at] = result.delete(:expires_at) if result.key?(:expires_at)
    result
  end

  def render_error(message, status = :bad_request)
    render(json: [{
             message:,
           }],
           status:)
  end
end
