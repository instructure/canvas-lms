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
  class ContextControlService
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

    # Calculate attributes in bulk for a collection of Lti::ContextControls.
    # Avoids N+1 queries for API responses that include multiple context controls.
    #
    # @param controls [Array<Lti::ContextControl>] the context controls to preload attributes for
    # @return [Hash] a hash mapping control IDs to their calculated attributes
    def self.preload_calculated_attrs(controls)
      attrs = {}

      account_controls, course_controls = controls.partition { |c| c.account_id.present? }
      account_ids = account_controls.map(&:account_id).uniq
      subaccount_ids = Account.partitioned_sub_account_ids_recursive(account_ids)

      all_account_ids = (account_ids + subaccount_ids.values.flatten).uniq
      all_course_counts = Course.active.where(account_id: all_account_ids).group(:account_id).count
      course_counts = subaccount_ids.each_with_object({}) do |(id, sub_ids), c|
        c[id] = all_course_counts.slice(id, *sub_ids).values.sum
      end

      unique_paths = account_controls.map { |cc| "#{cc.path}%" }.uniq
      all_control_paths = Lti::ContextControl
                          .where("path LIKE ANY (?)", "{#{unique_paths.join(",")}}")
                          .where(deployment_id: account_controls.map(&:deployment_id).uniq)
                          .active.pluck(:deployment_id, :path)
                          .group_by(&:first) # deployment_id
                          .transform_values { |ccs| ccs.map(&:last) } # path
      child_control_counts = account_controls.each_with_object({}) do |control, counts|
        deployment_paths = all_control_paths[control.deployment_id] || []

        counts[control.id] = deployment_paths.count do |path|
          path.start_with?(control.path) && path != control.path
        end
      end

      account_controls.each do |control|
        attrs[control.id] = {
          subaccount_count: subaccount_ids[control.account_id].size,
          course_count: course_counts[control.account_id],
          child_control_count: child_control_counts[control.id]
        }
      end

      course_controls.each do |control|
        attrs[control.id] = {
          subaccount_count: 0,
          course_count: 0,
          child_control_count: 0
        }
      end

      attrs
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
