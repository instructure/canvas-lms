# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class NotificationPolicyOverride < ActiveRecord::Base
  # NotificationPolicyOverride(id: integer,
  #                            context_id: integer,
  #                            context_type: string,
  #                            communication_channel_id: integer,
  #                            notification_id: integer,
  #                            workflow_state: boolean,
  #                            frequency: string,
  #                            created_at: datetime,
  #                            updated_at: datetime)

  include NotificationPreloader

  belongs_to :communication_channel, inverse_of: :notification_policy_overrides
  belongs_to :context, polymorphic: [:account, :course]
  belongs_to :notification, inverse_of: :notification_policy_overrides

  has_many :delayed_messages, inverse_of: :notification_policy_override, dependent: :destroy

  def self.enable_for_context(user, context, enable: true)
    user.shard.activate do
      workflow_state = enable ? "active" : "disabled"
      cc_ids = user.communication_channels.pluck(:id)
      connection = NotificationPolicyOverride.connection
      values = cc_ids.map! do |cc_id|
        vals = [
          connection.quote(context.id),
          connection.quote(context.class.name),
          connection.quote(cc_id),
          connection.quote(workflow_state),
          connection.quote(Time.zone.now),
          connection.quote(Time.zone.now)
        ]
        "(#{vals.join(",")})"
      end
      unless values.empty?
        # if the user has no communication channels, there really isn't anything
        # to do here for them.
        connection.execute(<<~SQL.squish)
          INSERT INTO #{NotificationPolicyOverride.quoted_table_name}
            (context_id, context_type, communication_channel_id, workflow_state, created_at, updated_at)
            VALUES #{sanitize_sql(values.join(","))}
            ON CONFLICT (context_id, context_type, communication_channel_id) WHERE notification_id IS NULL
            DO UPDATE SET
              workflow_state = excluded.workflow_state,
              updated_at = excluded.updated_at
            WHERE notification_policy_overrides.workflow_state<>excluded.workflow_state;
        SQL
      end
    end
  end

  def self.enabled_for(user, context, channel: nil)
    enabled_for_all_contexts(user, [context], channel:)
  end

  def self.enabled_for_all_contexts(user, contexts, channel: nil)
    !(find_all_for(user, contexts, channel:).find { |npo| npo.notification_id.nil? && npo.workflow_state == "disabled" })
  end

  def self.find_all_for(user, contexts, channel: nil)
    raise ArgumentError, "can only pass one type of context" if contexts.uniq(&:class).length > 1

    if channel&.notification_policy_overrides&.loaded?
      loaded_policies_for(contexts, channel)
    elsif channel
      channel.notification_policy_overrides.where(context_id: contexts.map(&:id), context_type: contexts.first.class.name)
    elsif user.notification_policy_overrides.loaded?
      loaded_policies_for(contexts, user)
    else
      user.notification_policy_overrides.where(context_id: contexts.map(&:id), context_type: contexts.first.class.name)
    end
  end

  def self.loaded_policies_for(contexts, object)
    contexts.map do |context|
      object.notification_policy_overrides.select { |npo| npo.in_context?(context) }
    end.flatten
  end

  def self.create_or_update_for(communication_channel, notification_category, frequency, context)
    notifications = Notification.all_cached.select { |n| n.category == notification_category }
    communication_channel.shard.activate do
      unique_constraint_retry do
        notifications.each do |notification|
          np = communication_channel.notification_policy_overrides.find { |npo| npo.notification_id == notification.id && npo.context_id == context.id && npo.context_type == context.class.name }
          np ||= communication_channel.notification_policy_overrides.build(notification:, context_id: context.id, context_type: context.class.name)
          np.frequency = frequency
          np.save!
        end
      end
    end
  end

  def in_context?(context)
    context_id == context.id && context_type == context.class.name
  end
end
