# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module Lti
  # @API Accounts (LTI)
  #
  # API for accessing account data using an LTI dev key. Allows a tool to get account
  # information via LTI Advantage authorization scheme, which does not require a
  # user session like normal developer keys do. Requires the account lookup scope on
  # the LTI key.
  #
  # @model Account
  #     {
  #       "id": "Account",
  #       "description": "",
  #       "properties": {
  #         "id": {
  #           "description": "the ID of the Account object",
  #           "example": 2,
  #           "type": "integer"
  #         },
  #         "name": {
  #           "description": "The display name of the account",
  #           "example": "Canvas Account",
  #           "type": "string"
  #         },
  #         "uuid": {
  #           "description": "The UUID of the account",
  #           "example": "WvAHhY5FINzq5IyRIJybGeiXyFkG3SqHUPb7jZY5",
  #           "type": "string"
  #         },
  #         "parent_account_id": {
  #           "description": "The account's parent ID, or null if this is the root account",
  #           "example": 1,
  #           "type": "integer"
  #         },
  #         "root_account_id": {
  #           "description": "The ID of the root account, or null if this is the root account",
  #           "example": 1,
  #           "type": "integer"
  #         },
  #         "workflow_state": {
  #           "description": "The state of the account. Can be 'active' or 'deleted'.",
  #           "example": "active",
  #           "type": "string"
  #         }
  #       }
  #     }
  #
  class AccountLookupController < ApplicationController
    include Ims::Concerns::AdvantageServices
    include Api::V1::Account

    MIME_TYPE = 'application/vnd.canvas.accountlookup+json'.freeze

    # @API Get account
    # Retrieve information on an individual account, given by local or global ID.
    #
    # @returns Account
    def show
      # sending read_only=true; sending false would give more fields but passes the
      # nil session in to extensions' extend_account_json() which may not be safe
      render json: account_json(context, nil, nil, [], true), content_type: MIME_TYPE
    end

    private

    def scopes_matcher
      self.class.all_of(TokenScopes::LTI_ACCOUNT_LOOKUP_SCOPE)
    end

    def context
      # This can also find accounts in other shards if passed a global ID.
      # verify_active_in_account (via DeveloperKey#account_binding_for) prevents us from
      # accessing accounts we shouldn't, including in different shards from the dev key
      @context ||= Account.find(params[:account_id])
    end

    def verify_tool
      # no-op. not necessary to check for a tool associated with the account for this endpoint
    end
  end
end
