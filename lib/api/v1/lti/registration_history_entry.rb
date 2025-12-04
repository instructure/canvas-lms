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
#

module Api::V1::Lti::RegistrationHistoryEntry
  include Api::V1::Json
  include Api::V1::User
  include Api::V1::Lti::ContextControl
  include Api::V1::Lti::Deployment

  JSON_ATTRS = %w[
    id
    root_account_id
    lti_registration_id
    created_at
    updated_at
    diff
    update_type
    comment
    old_configuration
    new_configuration
  ].freeze

  # Use #preload_context_controls_for_entries for preloaded_data.
  def lti_registration_history_entry_json(history_entry, user, session, context, preloaded_data:)
    api_json(history_entry, user, session, only: JSON_ATTRS).tap do |json|
      if history_entry.created_by.present?
        json["created_by"] = if Account.site_admin.grants_right?(history_entry.created_by, session, :read)
                               "Instructure"
                             else
                               user_json(history_entry.created_by, user, session, [], context, nil, ["pseudonym"])
                             end
      end

      # We can't just use the ol' database columns, as it only contains the bare
      # minimum info about the context control, which is basically useless for showing things
      # in the UI in a helpful/descriptive way.
      json["old_controls_by_deployment"] = serialize_context_controls(
        history_entry.old_context_controls,
        preloaded_data[:controls_by_deployment],
        preloaded_data[:calculated_attrs],
        user,
        session,
        context
      )
      json["new_controls_by_deployment"] = serialize_context_controls(
        history_entry.new_context_controls,
        preloaded_data[:controls_by_deployment],
        preloaded_data[:calculated_attrs],
        user,
        session,
        context
      )
    end
  end

  def lti_registration_history_entries_json(history_entries, user, session, context)
    preloaded_data = preload_context_controls_for_entries(history_entries)

    history_entries.map do |entry|
      lti_registration_history_entry_json(entry, user, session, context, preloaded_data:)
    end
  end

  private

  # Preload all context controls and their calculated attributes for the given history entries
  # @param history_entries [Array<Lti::RegistrationHistoryEntry>]
  # @return [Hash] Hash with:
  #   :controls_by_deployment - Hash mapping deployment_id => Array<Lti::ContextControl>
  #   :calculated_attrs - Hash mapping control_id => calculated attributes
  def preload_context_controls_for_entries(history_entries)
    control_ids = history_entries.map { [it.old_context_controls, it.new_context_controls].compact }
                                 .flatten
                                 .reduce(Set.new) { |set, controls| set.merge(controls.keys) }

    controls_by_deployment = Lti::ContextControl.where(id: control_ids.to_a)
                                                # Needed to figure out display paths and context names
                                                .preload(:account,
                                                         :course,
                                                         deployment: :context)
                                                .group_by(&:deployment)

    calculated_attrs = Lti::ContextControlService.preload_calculated_attrs(controls_by_deployment.values.flatten)

    {
      controls_by_deployment:,
      calculated_attrs:
    }
  end

  # Serialize context controls grouped by deployment using the lti_deployment_json serializer,
  # then override the controls within each deployment with historical snapshot values
  # @param historical_attrs [Hash] Hash of control_id => control_attributes (historical snapshot)
  # @param controls_by_deployment [Hash] Hash mapping deployment_id => Array of ContextControl
  # @param deployments [Hash] Hash mapping deployment_id => ContextExternalTool
  # @param calculated_attrs [Hash] Hash of control_id => calculated attributes
  # @param user [User] the user making the request
  # @param session [Session] the session of the user making the request
  # @param context [Context] the context in which the request is made
  # @return [Array] Array of deployment JSON objects with historical control data
  def serialize_context_controls(historical_attrs, controls_by_deployment, calculated_attrs, user, session, context)
    return [] unless historical_attrs.present?

    controls_by_deployment.filter_map do |deployment, context_controls|
      # ID is stringified cause JSON only allows string keys
      historical_controls = context_controls.select { historical_attrs.key?(it.id.to_s) }
      # Only include this if stuff related to it changed in the entry.
      next unless historical_controls.present?

      deployment_json = lti_deployment_json(deployment,
                                            user,
                                            session,
                                            context,
                                            context_controls: historical_controls,
                                            context_controls_calculated_attrs: calculated_attrs)
      deployment_json["context_controls"].map! do |control|
        control.merge(historical_attrs[control["id"].to_s])
      end
      deployment_json
    end
  end
end
