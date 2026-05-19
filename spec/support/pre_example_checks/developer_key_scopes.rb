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
module PreExampleChecks
  class DeveloperKeyScopes < Base
    run_during :before_example

    def self.run
      DeveloperKey.where.not(lti_registration_id: nil).find_each do |key|
        config_scopes = key.lti_registration.internal_lti_configuration(include_overlay: true)[:scopes] || []
        return false if key.scopes.sort != config_scopes.sort
      end
    end
  end
end
