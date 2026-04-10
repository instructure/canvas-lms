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

module AiExperiences
  class ProvisionService
    def initialize
      @client = LlmConversation::HttpClient.new(use_initial_token: true)
    end

    def provision(account)
      result = call_provision_api(account)

      # TODO: We will wait and poll here when we get to PINE Provisioning
      # If that times out then we throw an error and must restart the entire provision

      save_to_account_settings(account, result)
    end

    private

    def call_provision_api(account)
      payload = {
        account_id: account.uuid,
        root_account_id: account.root_account.uuid
      }
      response = @client.post("/provision", payload:)
      response["data"] || response
    end

    def save_to_account_settings(account, provision_result)
      account.settings[:llm_conversation_service] = {
        api_jwt_token: provision_result["api_token"],
        refresh_jwt_token: provision_result["refresh_token"]
      }
      account.save!
    end
  end
end
