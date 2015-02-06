#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

    # Some generic flags for inside the policy
    attr_accessor :just_created, :prior_version

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

    # This is called before_save
    def set_broadcast_flags
      @broadcasted = false
      unless @skip_broadcasts
        self.just_created = self.new_record?
        self.prior_version = generate_prior_version
      end
    end

    def generate_prior_version
      obj = self.class.new
      self.attributes.each do |attr, value|
        value = changed_attributes[attr] if changed_attributes.key?(attr)
        obj.write_attribute(attr, value)
      end
      obj
    end

    # This is called after_save
    def broadcast_notifications
      return if @broadcasted
      @broadcasted = true
      raise ArgumentError, "Broadcast Policy block not supplied for #{self.class.to_s}" unless self.class.broadcast_policy_list
      self.class.broadcast_policy_list.broadcast(self)
    end

    attr_accessor :skip_broadcasts

    def save_without_broadcasting
      begin
        @skip_broadcasts = true
        self.save
      ensure
        @skip_broadcasts = false
      end
    end

    def save_without_broadcasting!
      begin
        @skip_broadcasts = true
        self.save!
      ensure
        @skip_broadcasts = false
      end
    end

    # The rest of the methods here should just be helper methods to make
    # writing a condition that much easier.
    def changed_in_state(state, opts={})
      fields  = opts[:fields] || []
      fields = [fields] unless fields.is_a?(Array)

      begin
        fields.map {|field| self.prior_version.send(field) != self.send(field) }.include?(true) and
        self.workflow_state == state.to_s and
        self.prior_version.workflow_state == state.to_s
      rescue Exception => e
        logger.warn "Could not check if a change was made: #{e.inspect}"
        false
      end
    end

    def changed_in_states(states, opts={})
      !states.select{|s| changed_in_state(s, opts)}.empty?
    end

    def remained_in_state(state)
      begin
        self.workflow_state == state.to_s and
        self.prior_version.workflow_state == state.to_s
      rescue Exception => e
        logger.warn "Could not check if a record remained in the same state: #{e.inspect}"
        false
      end
    end

    def changed_state(new_state=nil, old_state=nil)
      begin
        if new_state and old_state
          self.workflow_state == new_state.to_s and
          self.prior_version.workflow_state == old_state.to_s
        elsif new_state
          self.workflow_state.to_s == new_state.to_s and
          self.prior_version.workflow_state != self.workflow_state
        else
          self.workflow_state != self.prior_version.workflow_state
        end
      rescue Exception => e
        ErrorReport.log_exception(:broadcast_policy, e, message: "Could not check if a record changed state")
        logger.warn "Could not check if a record changed state: #{e.inspect}"
        false
      end
    end
    alias :changed_state_to :changed_state

    def filter_asset_by_recipient(notification, recipient)
      policy = self.class.broadcast_policy_list.find_policy_for(notification.name)
      policy ? policy.recipient_filter.call(self, recipient) : self
    end

  end # InstanceMethods
end
