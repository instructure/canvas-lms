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

class AiExperiences::Jobs::AiExperienceProvisionJob
  class << self
    def provision_account_for_ai_experiences(account)
      unless account.feature_enabled?(:ai_experiences_v2_auth)
        raise AiExperiences::AiExperienceProvisionError, "Account #{account.uuid} attempted to provision while AI Experiences V2 Auth Feature Flag was disabled"
      end

      provision_account(account)
    end

    private

    def provision_account(account)
      AiExperiences::ProvisionService.new.provision(account)
    rescue LlmConversation::Errors::ConflictError => e
      # 409 means already provisioned — not an error worth retrying
      Rails.logger.info("AiExperienceProvisionJob: account #{account.uuid} already provisioned: #{e.message}")
    end
  end
end
