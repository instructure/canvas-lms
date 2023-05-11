# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "active_support/core_ext/object/blank"

module LtiOutbound
  class LTIUser < LTIContext
    ACTIVE_STATE = "active"
    INACTIVE_STATE = "inactive"

    proc_accessor :avatar_url,
                  :concluded_roles,
                  :currently_active_in_course,
                  :current_roles,
                  :first_name,
                  :email,
                  :last_name,
                  :login_id,
                  :name,
                  :timezone,
                  :current_observee_ids

    def current_role_types
      roles = current_roles.join(",") if current_roles.present?
      roles || LtiOutbound::LTIRoles::System::NONE
    end

    def concluded_role_types
      roles = concluded_roles.join(",") if concluded_roles.present?
      roles || LtiOutbound::LTIRoles::System::NONE
    end

    def enrollment_state
      {
        true => LtiOutbound::LTIUser::ACTIVE_STATE,
        false => LtiOutbound::LTIUser::INACTIVE_STATE,
        nil => nil
      }[currently_active_in_course]
    end

    def learner?
      current_roles.any? { |e| e == LtiOutbound::LTIRoles::ContextNotNamespaced::LEARNER || e == LtiOutbound::LTIRoles::Context::LEARNER }
    end

    def observer?
      return false unless current_roles

      current_roles.any? do |e|
        LtiOutbound::LTIRoles::ContextNotNamespaced::OBSERVER.split(",").include?(e) ||
          LtiOutbound::LTIRoles::Context::OBSERVER.split(",").include?(e)
      end
    end
  end
end
