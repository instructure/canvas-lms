require "active_support/hash_with_indifferent_access"

#
# Copyright (C) 2011 - 2017 Instructure, Inc.
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
module BroadcastPolicy
  module InstanceMethods

    # either we're in an after_save of a new record, or we just
    # finished saving one
    def just_created
      changed? ? id_was.nil? : previous_changes.key?(:id) && previous_changes[:id].first.nil?
    end

    # Some flags for auditing policy matching
    def messages_sent
      @messages_sent ||= {}
    end

    def clear_broadcast_messages
      @messages_sent = {}
      @messages_failed = {}
    end

    # Whenever a requirement fails, this is stored here.
    def messages_failed
      @messages_failed ||= {}
    end

    def with_changed_attributes_from(other)
      return yield unless other
      begin
        frd_changed_attributes = @changed_attributes
        @changed_attributes = ActiveSupport::HashWithIndifferentAccess.new
        other.attributes.each do |key, value|
          @changed_attributes[key] = value if value != attributes[key]
        end
        yield
      ensure
        @changed_attributes = frd_changed_attributes
      end
    end

    # This is called after_save, but you can call it manually to trigger
    # notifications. If you pass in a prior_version of self, its
    # attributes will be used to fake out the various _was/_changed?
    # helpers
    def broadcast_notifications(prior_version = nil)
      raise ArgumentError, "Broadcast Policy block not supplied for #{self.class}" unless self.class.broadcast_policy_list
      if prior_version
        with_changed_attributes_from(prior_version) do
          self.class.broadcast_policy_list.broadcast(self)
        end
      else
        self.class.broadcast_policy_list.broadcast(self)
      end
    end

    attr_accessor :skip_broadcasts

    def save_without_broadcasting
      @skip_broadcasts = true
      self.save
    ensure
      @skip_broadcasts = false
    end

    def save_without_broadcasting!
      @skip_broadcasts = true
      self.save!
    ensure
      @skip_broadcasts = false
    end

    # The rest of the methods here should just be helper methods to make
    # writing a condition that much easier.
    def changed_in_state(state, fields: [])
      fields = Array(fields)
      fields.any? { |field| attribute_changed?(field) } &&
        workflow_state == state.to_s &&
        workflow_state_was == state.to_s
    end

    def changed_state(new_state=nil, old_state=nil)
      if new_state && old_state
        workflow_state == new_state.to_s &&
          workflow_state_was == old_state.to_s
      elsif new_state
        workflow_state.to_s == new_state.to_s &&
          workflow_state_changed?
      else
        workflow_state_changed?
      end
    end
    alias :changed_state_to :changed_state

    def filter_asset_by_recipient(notification, recipient)
      policy = self.class.broadcast_policy_list.find_policy_for(notification.name)
      policy ? policy.recipient_filter.call(self, recipient) : self
    end

  end # InstanceMethods
end
