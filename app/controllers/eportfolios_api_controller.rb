# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# @API ePortfolios
#
# @model ePortfolio
#     {
#       "id": "ePortfolio",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The database ID of the ePortfolio",
#           "example": 1,
#           "type": "integer"
#         },
#         "user_id": {
#           "description": "The user ID to which the ePortfolio belongs",
#           "example": 1,
#           "type": "integer"
#         },
#         "name": {
#           "description": "The name of the ePortfolio",
#           "example": "My Academic Journey",
#           "type": "string"
#         },
#         "public": {
#           "description": "Whether or not the ePortfolio is visible without authentication",
#           "example": true,
#           "type": "boolean"
#         },
#         "created_at": {
#           "description": "The creation timestamp for the ePortfolio",
#           "example": "2021-09-20T18:59:37Z",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "The timestamp of the last time any of the ePortfolio attributes changed",
#           "example": "2021-09-20T18:59:37Z",
#           "type": "datetime"
#         },
#         "workflow_state": {
#           "description": "The state of the ePortfolio. Either 'active' or 'deleted'",
#           "example": "active",
#           "type": "string"
#         },
#         "deleted_at": {
#           "description": "The timestamp when the ePortfolio was deleted, or else null",
#           "example": "2021-09-20T18:59:37Z",
#           "type": "datetime"
#         },
#         "spam_status": {
#           "description": "A flag indicating whether the ePortfolio has been
#           flagged or moderated as spam. One of 'flagged_as_possible_spam',
#           'marked_as_safe', 'marked_as_spam', or null",
#           "example": null,
#           "type": "string"
#         }
#       }
#     }
#
# @model ePortfolioPage
#     {
#       "id": "ePortfolioPage",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The database ID of the ePortfolio",
#           "example": 1,
#           "type": "integer"
#         },
#         "eportfolio_id": {
#           "description": "The ePortfolio ID to which the entry belongs",
#           "example": 1,
#           "type": "integer"
#         },
#         "position": {
#           "description": "The positional order of the entry in the list",
#           "example": 1,
#           "type": "integer"
#         },
#         "name": {
#           "description": "The name of the ePortfolio",
#           "example": "My Academic Journey",
#           "type": "string"
#         },
#         "content": {
#           "description": "The user entered content of the entry",
#           "example": "A long time ago...",
#           "type": "string"
#         },
#         "created_at": {
#           "description": "The creation timestamp for the ePortfolio",
#           "example": "2021-09-20T18:59:37Z",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "The timestamp of the last time any of the ePortfolio attributes changed",
#           "example": "2021-09-20T18:59:37Z",
#           "type": "datetime"
#         }
#       }
#     }
class EportfoliosApiController < ApplicationController
  before_action :require_user
  before_action :reject_student_view_student
  before_action :verified_user_check

  include Api::V1::Eportfolio

  # @API Get all ePortfolios for a User
  #
  # Get a list of all ePortfolios for the specified user.
  #
  # @argument include[] [String, "deleted"]
  #   deleted:: Include deleted ePortfolios. Only available to admins who can
  #   moderate_user_content.
  #
  # @returns [ePortfolio]
  def index
    user = api_find(User, params[:user_id])
    return unless user == @current_user || authorized_action(user, @current_user, :moderate_user_content)

    params[:include] ||= []
    scope = user.eportfolios
    if user == @current_user || params[:include].exclude?("deleted")
      scope = scope.active
    end

    portfolios = Api.paginate(scope.order(:updated_at), self, api_v1_eportfolios_url)
    render json: portfolios.map { |e| eportfolio_json(e, @current_user, session) }
  end

  # @API Get an ePortfolio
  #
  # Get details for a single ePortfolio.
  #
  # @returns ePortfolio
  def show
    portfolio = Eportfolio.find(params[:id])
    return unless authorized_action(portfolio, @current_user, :read)

    render json: eportfolio_json(portfolio, @current_user, session)
  end

  # @API Delete an ePortfolio
  #
  # Mark an ePortfolio as deleted.
  #
  # @returns ePortfolio
  def delete
    portfolio = Eportfolio.find(params[:id])
    return unless authorized_action(portfolio, @current_user, :delete)

    if portfolio.destroy
      render json: eportfolio_json(portfolio, @current_user, session)
    else
      render json: { error: "There was an error destroying the ePortfolio" }, status: :bad_request
    end
  end

  # @API Get ePortfolio Pages
  #
  # Get details for the pages of an ePortfolio
  #
  # @returns [ePortfolioPage]
  def pages
    portfolio = Eportfolio.find(params[:eportfolio_id])
    return unless authorized_action(portfolio, @current_user, :read)

    pages = Api.paginate(
      portfolio.eportfolio_entries.order(:position),
      self,
      api_v1_eportfolio_pages_url
    )

    render json: pages.map { |p| eportfolio_entry_json(p, @current_user, session) }
  end

  # @API Moderate an ePortfolio
  #
  # Update the spam_status of an eportfolio. Only available to admins who can
  # moderate_user_content.
  #
  # @argument spam_status [String, "marked_as_spam"|"marked_as_safe"]
  #   The spam status for the ePortfolio
  #
  # @returns ePortfolio
  def moderate
    portfolio = Eportfolio.find(params[:eportfolio_id])
    return unless authorized_action(portfolio, @current_user, :moderate)

    if Eportfolio::SPAM_MODERATIONS.exclude?(params[:spam_status])
      render json: { error: "spam_status must be one of #{Eportfolio::SPAM_MODERATIONS}" }, status: :bad_request
    elsif portfolio.update(spam_status: params[:spam_status])
      render json: eportfolio_json(portfolio, @current_user, session)
    else
      render json: portfolio.errors, status: :bad_request
    end
  end

  # @API Moderate all ePortfolios for a User
  #
  # Update the spam_status for all active eportfolios of a user. Only available to
  # admins who can moderate_user_content.
  #
  # @argument spam_status [String, "marked_as_spam"|"marked_as_safe"]
  #   The spam status for all the ePortfolios
  def moderate_all
    user = api_find(User, params[:user_id])
    return unless authorized_action(user, @current_user, :moderate_user_content)

    if Eportfolio::SPAM_MODERATIONS.exclude?(params[:spam_status])
      render json: { error: "spam_status must be one of #{Eportfolio::SPAM_MODERATIONS}" }, status: :bad_request
    elsif user.eportfolios.active.update_all(spam_status: params[:spam_status], updated_at: Time.now.utc)
      render json: :success
    else
      render json: { error: "There was an error bulk updating the spam status" }, status: :bad_request
    end
  end

  # @API Restore a deleted ePortfolio
  #
  # Restore an ePortfolio back to active that was previously deleted. Only
  # available to admins who can moderate_user_content.
  #
  # @returns ePortfolio
  def restore
    portfolio = Eportfolio.find(params[:eportfolio_id])
    return unless authorized_action(portfolio, @current_user, :restore)

    if portfolio.restore
      render json: eportfolio_json(portfolio, @current_user, session)
    else
      render json: { error: "There was an error restoring the ePortfolio" }, status: :bad_request
    end
  end
end
