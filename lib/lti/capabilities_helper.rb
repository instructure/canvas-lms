#
# Copyright (C) 2017 - present Instructure, Inc.
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
  class CapabilitiesHelper
    SUPPORTED_CAPABILITIES = %w(ToolConsumerInstance.guid
                                CourseSection.sourcedId
                                Membership.role
                                Person.email.primary
                                Person.name.given
                                Person.name.family
                                Person.name.full
                                Person.sourcedId
                                User.id
                                User.image
                                Message.documentTarget
                                Message.locale
                                Context.id
                                vnd.Canvas.root_account.uuid).freeze

    def self.supported_capabilities
      SUPPORTED_CAPABILITIES
    end

    def self.filter_capabilities(enabled_capability)
      enabled_capability & SUPPORTED_CAPABILITIES
    end

    def self.capability_params_hash(enabled_capability, variable_expander)
      variable_expander.enabled_capability_params(filter_capabilities(enabled_capability))
    end
  end
end
