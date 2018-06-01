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

require "active_support/hash_with_indifferent_access"

module BroadcastPolicy
  module InstanceMethods

    def just_created
      saved_changes? && id_before_last_save.nil?
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
        # I'm pretty sure we can stop messing with @changed_attributes once
        # we're on Rails 5.2 (CANVAS_RAILS5_1)
        frd_changed_attributes = @changed_attributes
        @changed_attributes = ActiveSupport::HashWithIndifferentAccess.new
        other.attributes.each do |key, value|
          @changed_attributes[key] = value if value != attributes[key]
        end

        if defined?(ActiveRecord)
          frd_mutations_before_last_save = @mutations_before_last_save
          other_attributes = other.instance_variable_get(:@attributes).deep_dup
          namespace = CANVAS_RAILS5_1 ? ActiveRecord : ActiveModel
          @attributes.send(:attributes).each_key do |key|
            value = @attributes[key]
            # ignore newly added columns in the db that we don't really know
            # about yet
            if other_attributes[key].is_a?(namespace::Attribute.const_get(:Null))
              other_attributes.instance_variable_get(:@attributes).delete(key)
              next
            end
            if value.value != other_attributes[key].value
              other_attributes.write_from_user(key, value.value)
            else
              other_attributes.write_from_database(key, value.value)
            end
          end
          @mutations_before_last_save = namespace::AttributeMutationTracker.new(other_attributes)
        end
        yield
      ensure
        @changed_attributes = frd_changed_attributes
        @mutations_before_last_save = frd_mutations_before_last_save
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
      fields.any? { |field| saved_change_to_attribute?(field) } &&
        workflow_state == state.to_s &&
        workflow_state_before_last_save == state.to_s
    end

    def changed_state(new_state=nil, old_state=nil)
      if new_state && old_state
        workflow_state == new_state.to_s &&
          workflow_state_before_last_save == old_state.to_s
      elsif new_state
        workflow_state.to_s == new_state.to_s &&
          saved_change_to_workflow_state?
      else
        saved_change_to_workflow_state?
      end
    end
    alias :changed_state_to :changed_state

    def filter_asset_by_recipient(notification, recipient)
      policy = self.class.broadcast_policy_list.find_policy_for(notification.name)
      policy ? policy.recipient_filter.call(self, recipient) : self
    end

  end # InstanceMethods
end
