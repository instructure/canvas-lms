# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
  # Update or create an LTI::ContextControl.
  #
  # @param control_params [Hash] Attributes to initialize or update on the Lti::ContextControl.
  # ```
  # {
  #   "account_id": 1,
  #   "course_id": 1,
  #   "deployment_id": 1,
  #   "registration_id": 1,
  #   "available": true
  #   "updated_by_id": 1,
  #   "workflow_state": "active",
  #   "created_by_id": 1,
  #   "path": "a1.c1.",
  #   "context_type": "Course",
  #   "root_account_id": 1
  # }
  # ```
  #
  # @return Lti::ContextControl the created or updated Lti::ContextControl.
  class ContextControlService
    def self.create_or_update(control_params)
      unique_checks = control_params.slice(*unique_check_attrs)

      control = Lti::ContextControl.find_or_initialize_by(unique_checks)
      if control.new_record?
        control.assign_attributes(control_params)
      else
        restore_deleted_control(control, control_params)
      end

      if control.save
        control
      else
        raise Lti::ContextControlErrors, control.errors
      end
    end

    def self.unique_check_attrs
      %i[
        account_id
        course_id
        deployment_id
        registration_id
      ]
    end

    def self.restore_deleted_control(control, control_params)
      restore_params = control_params.slice(:available, :updated_by, :updated_by_id, :workflow_state)
      control.assign_attributes(restore_params)
    end
  end

  class Lti::ContextControlErrors < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super("Error creating ContextControl: #{errors.full_messages.join(", ")}")
    end
  end
end
