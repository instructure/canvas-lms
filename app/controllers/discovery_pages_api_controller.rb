# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

# @API Discovery Pages
#
# @model DiscoveryPage
#     {
#       "id": "DiscoveryPage",
#       "description": "Configuration for the login discovery page",
#       "properties": {
#         "primary": {
#           "description": "Primary authentication provider buttons displayed prominently",
#           "type": "array",
#           "items": { "$ref": "DiscoveryPageEntry" }
#         },
#         "secondary": {
#           "description": "Secondary authentication provider buttons displayed less prominently",
#           "type": "array",
#           "items": { "$ref": "DiscoveryPageEntry" }
#         }
#       }
#     }
#
# @model DiscoveryPageEntry
#     {
#       "id": "DiscoveryPageEntry",
#       "description": "A single authentication provider entry on the discovery page",
#       "properties": {
#         "authentication_provider_id": {
#           "description": "The ID of the authentication provider",
#           "example": 1,
#           "type": "integer"
#         },
#         "label": {
#           "description": "The display label for this provider button",
#           "example": "Students",
#           "type": "string"
#         },
#         "icon_url": {
#           "description": "URL to an icon image for this provider button",
#           "example": "https://example.com/icons/students.svg",
#           "type": "string"
#         }
#       }
#     }

class DiscoveryPagesApiController < ApplicationController
  before_action :require_user, :load_context, :require_root_account_management

  # @API Get Discovery Page
  # Get the discovery page configuration for the domain root account.
  #
  # @returns DiscoveryPage
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/discovery_pages' \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "discovery_page": {
  #       "primary": [
  #         {
  #           "authentication_provider_id": 1,
  #           "label": "Students",
  #           "icon_url": "https://example.com/icons/students.svg"
  #         }
  #       ],
  #       "secondary": [
  #         {
  #           "authentication_provider_id": 3,
  #           "label": "Admins"
  #         }
  #       ]
  #     }
  #   }
  def show
    render json: { discovery_page: }
  end

  # @API Update Discovery Page
  # Update or create the discovery page configuration for the domain root account.
  #
  # @argument discovery_page[primary][][authentication_provider_id] [Required, Integer]
  #   The ID of an active authentication provider for this account.
  #
  # @argument discovery_page[primary][][label] [Required, String]
  #   The display label for this authentication provider button.
  #
  # @argument discovery_page[primary][][icon_url] [String]
  #   URL to an icon image for this authentication provider button.
  #
  # @argument discovery_page[secondary][][authentication_provider_id] [Required, Integer]
  #   The ID of an active authentication provider for this account.
  #
  # @argument discovery_page[secondary][][label] [Required, String]
  #   The display label for this authentication provider button.
  #
  # @argument discovery_page[secondary][][icon_url] [String]
  #   URL to an icon image for this authentication provider button.
  #
  # @returns DiscoveryPage
  #
  # @example_request
  #   curl -X PUT 'https://<canvas>/api/v1/discovery_pages' \
  #     -H 'Authorization: Bearer <token>' \
  #     -H 'Content-Type: application/json' \
  #     -d '{
  #       "discovery_page": {
  #         "primary": [
  #           {
  #             "authentication_provider_id": 1,
  #             "label": "Students",
  #             "icon_url": "https://example.com/icons/students.svg"
  #           },
  #           {
  #             "authentication_provider_id": 2,
  #             "label": "Faculty",
  #             "icon_url": "https://example.com/icons/faculty.svg"
  #           }
  #         ],
  #         "secondary": [
  #           {
  #             "authentication_provider_id": 3,
  #             "label": "Admins"
  #           }
  #         ]
  #       }
  #     }'
  #
  # @example_response
  #   {
  #     "discovery_page": {
  #       "primary": [
  #         {
  #           "authentication_provider_id": 1,
  #           "label": "Students",
  #           "icon_url": "https://example.com/icons/students.svg"
  #         },
  #         {
  #           "authentication_provider_id": 2,
  #           "label": "Faculty",
  #           "icon_url": "https://example.com/icons/faculty.svg"
  #         }
  #       ],
  #       "secondary": [
  #         {
  #           "authentication_provider_id": 3,
  #           "label": "Admins"
  #         }
  #       ]
  #     }
  #   }
  def upsert
    @domain_root_account.settings[:discovery_page] = upsert_params
    @domain_root_account.save!

    render json: { discovery_page: }
  end

  private

  def discovery_page
    context.settings[:discovery_page].presence || {}
  end

  def context
    @context ||= @domain_root_account
  end
  alias_method :load_context, :context

  def require_permission
    authorized_action(context, @current_user, :manage_account_settings)
  end

  def upsert_params
    permitted_keys = Validators::AccountSettingsValidator::DISCOVERY_PAGE_REQUIRED_KEYS +
                     Validators::AccountSettingsValidator::DISCOVERY_PAGE_OPTIONAL_KEYS

    params.expect(
      discovery_page: [primary: [permitted_keys],
                       secondary: [permitted_keys]]
    ).to_h.deep_symbolize_keys
  end
end
