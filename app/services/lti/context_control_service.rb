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
    def self.create_or_update(control_params, comment: nil)
      unique_checks = control_params.slice(*unique_check_attrs)

      control = Lti::ContextControl.find_or_initialize_by(unique_checks)
      if control.new_record?
        control.assign_attributes(control_params)
      else
        restore_deleted_control(control, control_params)
      end

      anchor_control = build_anchor_control(
        control_params[:deployment_id],
        control_params[:account_id],
        control_params[:course_id]
      )

      control_params = [control, anchor_control].compact.map do |c|
        {
          deployment_id: c.deployment_id,
          account_id: c.account_id,
          course_id: c.course_id,
          available: c.available
        }
      end

      Lti::ContextControl.transaction do
        Lti::RegistrationHistoryEntry
          .track_bulk_control_changes(control_params:,
                                      lti_registration: control.registration,
                                      # We have to do this because the control might not be persisted yet,
                                      # so the root account might not be set yet.
                                      root_account: control.account&.root_account || control.course&.root_account,
                                      current_user: control.updated_by,
                                      comment:) do
          control.save!
          anchor_control&.save!
        end
      end

      control
    rescue ActiveRecord::RecordInvalid => e
      raise Lti::ContextControlErrors, control.errors || e
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

    # Given parameters which will be used to create an Lti::ContextControl,
    # determine if an "anchor" control is needed and return the parameters
    # needed to create it.
    #
    # An "anchor" control helps show the user where a deeply nested control lives in
    # the account hierarchy, and is one subaccount level below the account where
    # the deployment lives.
    #
    # A wrapper around build_anchor_controls that constructs the data needed
    # for only a single control.
    #
    # @param deployment_id [Integer] the ID of the deployment for which the anchor control is being created
    # @param account_id [Integer, nil] the ID of the account for which the control is being created
    # @param course_id [Integer, nil] the ID of the course for which the control is being created
    #
    # @return [Lti::ContextControl, nil] an Lti::ContextControl if an anchor control is needed, otherwise nil
    #
    # @raise [ArgumentError] if both account_id and course_id are nil
    #
    def self.build_anchor_control(deployment_id, account_id, course_id)
      if account_id.nil? && course_id.nil?
        # this will raise further down the line, ignore it here
        return nil
      end

      deployment_account_ids = {}
      deployment_course_ids = {}
      course_account_ids = {}
      account_chains = {}

      deployment = ContextExternalTool.find(deployment_id)
      if deployment.context_type == "Course"
        deployment_course_ids[deployment.id] = deployment.context_id
      elsif deployment.context_type == "Account"
        deployment_account_ids[deployment.id] = deployment.context_id
      end

      if course_id
        course_account_id = Course.find(course_id).account_id
        course_account_ids[course_id] = course_account_id
        account_chains[course_account_id] = Account.account_chain_ids(course_account_id)
      else
        account_chains[account_id] = Account.account_chain_ids(account_id)
      end

      anchor_controls = build_anchor_controls(
        controls: [{ account_id:, deployment_id:, course_id: }],
        account_chains:,
        course_account_ids:,
        deployments: [deployment_id],
        deployment_account_ids:,
        deployment_course_ids:
      )
      return nil if anchor_controls.blank?

      anchor_params = anchor_controls.first
      return nil if Lti::ContextControl.where(**anchor_params.slice(:account_id, :deployment_id, :course_id)).exists?

      Lti::ContextControl.new(**anchor_params)
    end

    # Given a list of parameters meant to build Lti::ContextControls,
    # find those that need an "anchor" control and build the parameters for each.
    #
    # An "anchor" control helps show the user where a deeply nested control lives in
    # the account hierarchy, and is one subaccount level below the account where
    # the deployment lives.
    #
    # This method takes preloaded data to avoid N+1 queries.
    # @param controls [Array<Hash>] list of JSON representations of Lti::ContextControls
    # @param account_chains [Hash] map from account ID to its account chain. example:
    #   { 1 => [1, 2, 3], 2 => [2, 3], 3 => [3] }
    # @param course_account_ids [Hash] map from course ID to its account ID. example:
    #   { 1 => 2, 2 => 3 }
    # @param deployments [Array<Integer>] list of all deployment IDs being used in `controls`
    # @param deployment_account_ids [Hash] map from deployment ID to its account ID. example:
    #   { 1 => 2, 2 => 3 }
    # @param deployment_course_ids [Hash] map from deployment ID to its course ID. example:
    #   { 1 => 2, 2 => 3 }
    # @param cached_paths [Hash] map from account or course ID to its path. example:
    #   { "a1" => "a1.", "a2" => "a1.a2.", "c1" => "a1.c1." }
    #
    # @return [Array<Hash>] list of anchor controls to be created. JSON representation of Lti::ContextControl.
    def self.build_anchor_controls(controls:, account_chains:, course_account_ids:, deployments:, deployment_account_ids:, deployment_course_ids:, cached_paths: {})
      deployment_availabilities = Lti::ContextControl.primary_controls_for(deployments:).pluck(:deployment_id, :available).to_h
      new_primary_controls = controls.select { |c| deployment_account_ids[c[:deployment_id]] == c[:account_id] }

      deployment_availabilities.merge!(new_primary_controls.to_h { |c| [c[:deployment_id], c[:available]] })

      # avoid creating anchor controls if they will be created already here
      possible_account_controls = controls.filter_map do |c|
        next nil if c[:account_id].nil?

        [[c[:account_id], c[:deployment_id]], true]
      end.to_h

      controls.filter_map do |c|
        if deployment_course_ids.key?(c[:deployment_id])
          # course-level deployments never need an anchor control
          next nil
        end

        deployment_account_id = deployment_account_ids[c[:deployment_id]]
        if deployment_account_id == c[:account_id]
          # primary controls never need an anchor control
          next nil
        end

        course_account_id = course_account_ids[c[:course_id]]
        if deployment_account_id == course_account_id
          # control is for course only one level below deployment context
          next nil
        end

        account_id = c[:account_id] || course_account_id
        account_chain = account_chains[account_id]
        deployment_index = account_chain.index(deployment_account_id)
        if deployment_index.nil?
          # control context is not a child of deployment context,
          # which will raise a validation error later
          next nil
        end

        anchor_account_id = account_chain[deployment_index - 1]
        if c[:account_id].present? && anchor_account_id == c[:account_id]
          # control is for account only one level below deployment context
          next nil
        end

        if possible_account_controls.key?([anchor_account_id, c[:deployment_id]])
          # anchor control will already be created here
          next nil
        end

        parent_availability = deployment_availabilities.key?(c[:deployment_id]) ? deployment_availabilities[c[:deployment_id]] : true
        path = cached_paths["a#{anchor_account_id}"] || Lti::ContextControl.calculate_path_for_account_ids(Account.account_chain_ids(anchor_account_id))

        {
          **c,
          course_id: nil,
          account_id: anchor_account_id,
          available: parent_availability,
          path:,
        }
      end.uniq { [it[:account_id], it[:deployment_id]] }
    end

    # Calculate attributes in bulk for a collection of Lti::ContextControls.
    # Avoids N+1 queries for API responses that include multiple context controls.
    # Make sure that you preload :account, :course, :created_by, :updated_by before calling
    # this method to avoid even more N+1s!
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
      child_paths_of_controls = group_by_deployment_id(
        base_query_for_paths(account_controls)
          .where("path LIKE ANY (?)", "{#{unique_paths.join(",")}}")
      )

      child_control_counts = account_controls.each_with_object({}) do |control, counts|
        deployment_paths = child_paths_of_controls[control.deployment_id] || []

        counts[control.id] = deployment_paths.count do |path|
          path.start_with?(control.path) && path != control.path
        end
      end

      all_possible_parent_paths = controls.map do |control|
        Lti::ContextControl.self_and_all_parent_paths(control.account || control.course)
      end.flatten.uniq

      parent_paths_of_controls = group_by_deployment_id(
        base_query_for_paths(controls)
          .where(path: all_possible_parent_paths)
      )
      control_depths = controls.each_with_object({}) do |control, depths|
        deployment_paths = parent_paths_of_controls[control.deployment_id] || []

        depths[control.id] = deployment_paths.count do |path|
          control.path.start_with?(path) && path != control.path
        end
      end

      course_account_ids = Course.where(id: course_controls.pluck(:course_id).compact).pluck(:account_id)
      account_ids = (course_account_ids + account_controls.pluck(:account_id).compact).uniq
      all_account_ids = Account.multi_account_chain_ids(account_ids)
      all_account_names = Account.where(id: all_account_ids).pluck(:id, :name).to_h

      display_paths = controls.each_with_object({}) do |control, paths|
        # exclude control's own context, only include parents
        # exclude root account as well
        account_names = control.path.split(".")[1...-1].filter_map do |segment|
          account_id = segment[1..].to_i
          all_account_names[account_id]
        end

        paths[control.id] = account_names
      end

      account_controls.each do |control|
        attrs[control.id] = {
          subaccount_count: subaccount_ids[control.account_id].size,
          course_count: course_counts[control.account_id],
          child_control_count: child_control_counts[control.id],
          display_path: display_paths[control.id],
          depth: control_depths[control.id]
        }
      end

      course_controls.each do |control|
        attrs[control.id] = {
          subaccount_count: 0,
          course_count: 0,
          child_control_count: 0,
          display_path: display_paths[control.id],
          depth: control_depths[control.id]
        }
      end

      attrs
    end

    def self.base_query_for_paths(controls)
      Lti::ContextControl
        .where(deployment_id: controls.map(&:deployment_id).uniq)
        .active
    end

    def self.group_by_deployment_id(results)
      results
        .pluck(:deployment_id, :path)
        .group_by(&:first) # deployment_id
        .transform_values { |ccs| ccs.map(&:last) } # path
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
