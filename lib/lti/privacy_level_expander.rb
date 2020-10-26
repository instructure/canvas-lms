# frozen_string_literal: true

#
# Copyright (C) 2017 Instructure, Inc.
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

module Lti
  class PrivacyLevelExpander
    EMAIL_ONLY = %w(Person.email.primary).freeze
    INLCUDE_NAME = %w(Person.name.given Person.name.full Person.name.family).freeze
    PUBLIC = %w(Person.sourcedId CourseOffering.sourcedId).
      concat(EMAIL_ONLY).
      concat(INLCUDE_NAME).
      freeze
    ANONYMOUS = %w(com.instructure.contextLabel).freeze

    SUPPORTED_PARAMETERS_HASH = {
      public: PUBLIC,
      email_only: EMAIL_ONLY,
      name_only: INLCUDE_NAME,
      anonymous: ANONYMOUS
    }.freeze

    def initialize(placement, variable_expander)
      @placement = placement
      @variable_expander = variable_expander
    end

    def expanded_variables!(var_hash)
      @variable_expander.expand_variables!(var_hash).merge(parameter_hash)
    end

    def supported_parameters
      SUPPORTED_PARAMETERS_HASH[:anonymous] | SUPPORTED_PARAMETERS_HASH[@variable_expander.tool.workflow_state.to_sym]
    end

    private

    def parameter_hash
      @variable_expander.enabled_capability_params(supported_parameters)
    end
  end
end
