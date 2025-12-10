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

module AuthenticationMethods
  # Some authentication providers may provide federated pseudonym attributes.
  #
  # This class captures the expected set of those attributes to make them
  # available throughout the request lifecycle for features like
  # live events, etc.
  class FederatedPseudonymAttributes < ActiveSupport::CurrentAttributes
    attribute :sis_user_id, :unique_id

    def load_from(session)
      federated_pseudonym_attributes = session[:federated_pseudonym_attributes]
      return unless federated_pseudonym_attributes.present?

      self.sis_user_id = federated_pseudonym_attributes.dig("sis", "user_id")
      self.unique_id = federated_pseudonym_attributes["username"]

      attributes.compact_blank!

      if attributes.present?
        Rails.logger.info("[AUTH] Loaded federated pseudonym attributes: #{attributes.keys.join(", ")}")
      end
    end
  end
end
