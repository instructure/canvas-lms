#
# Copyright (C) 2011 Instructure, Inc.
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

module Instructure #:nodoc:
  module Broadcast #:nodoc:
    # This should work like this:
    # 
    # class Account < ActiveRecord::Base
    #   has_a_broadcast_policy
    # 
    #   set_broadcast_policy do
    #     dispatch(:name)
    #     to { some_list }
    #     whenever { |obj| obj.something == condition }
    #   end
    # end
    # 
    # Some useful examples:
    # 
    # set_broadcast_policy do
    #   dispatch :new_assignment
    #   to { self.students }
    #   whenever { |record| record.just_created? } 
    # end
    # 
    # set_broadcast_policy do
    #   dispatch :assignment_change
    #   to { self.students }
    #   whenever { |record| 
    #     record.prior_version != self.version and true
    #     # ... some field-wise comparison
    #   }
    # end
    # 
    # u = User.find(:first)
    # a = Account.find(:first)
    # a.check_policy(u)
    module Policy
      
      class PolicyStorage
        
        attr_accessor :dispatch, :to, :whenever
        
        def initialize(dispatch)
          self.dispatch = dispatch
        end
        
        # This should be called for an instance.  It can only be sent out if the
        # condition is met, if there is a notification that we can find, and if
        # there is someone to send this to.  At this point, a Message record is
        # created, which will be delayed, consolidated, dispatched to the right
        # server, and then finally sent through that server. 
        # 
        # This now sets a series of temporary flags while working for audit
        # reasons. 
        def broadcast(record)
          if (record.skip_broadcasts rescue false)
            record.messages_failed[self.dispatch] = "Broadcasting explicitly skipped"
            return false
          end
          begin
            meets_condition = self.whenever.call(record)
          rescue
            meets_condition = false
            record.messages_failed[self.dispatch] = "Error thrown attempting to meet condition."
            return false
          end

          unless meets_condition
            record.messages_failed[self.dispatch] = "Did not meet condition."
            return false 
          end
          notification = record.notifications.find_by_name(self.dispatch) rescue nil
          notification ||= Notification.find_by_name(self.dispatch)
          # logger.warn "Could not find notification for #{record.inspect}" unless notification
          unless notification
            record.messages_failed[self.dispatch] = "Could not find notification: #{self.dispatch}."
            return false 
          end
          # self.consolidated_notifications[notification_name.to_s.titleize] rescue nil
      
          begin
            to_list = self.to.call(record)
          rescue
            to_list = nil
            record.messages_failed[self.dispatch] = "Error thrown attempting to generate a recipient list."
            return false
          end
          unless to_list
            record.messages_failed[self.dispatch] = "Could not generate a recipient list."
            return false 
          end
          to_list = Array[to_list].flatten
          n = DelayedNotification.send_later_if_production_enqueue_args(
            :process,
            { :priority => Delayed::LOW_PRIORITY },
            record, notification, (to_list || []).compact.map(&:asset_string))
          n ||= DelayedNotification.new(:asset => record, :notification => notification, :recipient_keys => (to_list || []).compact.map(&:asset_string))
          if Rails.env.test?
            record.messages_sent[self.dispatch] = n.is_a?(DelayedNotification) ? n.process : n
          end
          n
          # notification.create_message(record, to_list)
        end
        
      end # PolicyStorage
      
      module ClassMethods #:nodoc:       
        def has_a_broadcast_policy
          extend Instructure::Broadcast::Policy::SingletonMethods
          include Instructure::Broadcast::Policy::InstanceMethods
          after_save :broadcast_notifications # Must be defined locally...
          before_save :set_broadcast_flags
          has_many :mailboxes, :as => :mailboxable_entity
        end
        
        # Uses the 'context' relationship as the governing relationship.
        # Canonically, this probably will look something like: 
        # course -> professor -> section -> department -> account.  
        # So, this method recurses the list, keeping the nearer values.  So,
        # account can setup a series of default notifications, but a professor
        # can override these. 
        
        # Removing for now, until we memoize this
        # def consolidated_notifications
        #   instance_notifications = Notification.find_all_by_context_type_and_context_id(self.class.to_s, self.id)
        #   class_notifications = Notification.find_all_by_context_type_and_context_id(self.class.to_s, nil)
        #   context_notifications = context.consolidated_notifications if 
        #     defined?(context) and context.respond_to?(:consolidated_notifications)
        #   context_notifications ||= []
        #   
        #   cn = hashify(*instance_notifications)
        #   cn.reverse_merge!(*class_notifications)
        #   cn.reverse_merge!(*context_notifications)
        #   cn
        # end
        # 
        # def hashify(*list)
        #   list.inject({}) {|h, v| h[v.name] = v; h}
        # end
        # protected :hashify
        
      end
      
      # This is where the DSL is defined.
      module SingletonMethods
      
        def self.extended(klass)
          klass.send(:class_inheritable_accessor, :broadcast_policy_block)
        end
        
        # This stores the policy for broadcasting changes on a class.  It works like a
        # macro.  The policy block will be stored in @broadcast_policy_block.  Then, an
        # instance will use that to instantiate a Policy object. 
        def set_broadcast_policy(&block)
          self.broadcast_policy_block = block
        end
      
      end # SingletonMethods

      module InstanceMethods
        
        # Some generic flags for inside the policy
        attr_accessor :just_created, :prior_version
        
        # Some mailboxes for general communication
        def messaging_mailbox
          if self.respond_to?(:reply_from)
            @broadcast_mailbox ||= self.mailboxes.find_or_create_by_purpose_and_name(
              'notification', 
              ("#{self.asset_string} Notifications").strip
            )
          elsif (self.respond_to?(:context) && self.context rescue nil)
            @broadcast_mailbox ||= Mailbox.find_or_create_by_mailboxable_entity_type_and_mailboxable_entity_id_and_purpose_and_name(
              self.context.class.to_s,
              self.context.id,
              'general',
              "self.context.asset_string General Notifications"
            )
          end
        end
        
        # def incoming_mailbox
          # @incoming_mailbox ||= mailboxes.find_or_create_by_purpose_and_name(
            # :purpose => 'incoming', 
            # :name => ('' + " Communication").strip
          # )
          # # Set pseudonyms???  Could do this with incoming_list
        # end
        
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
          self.just_created = self.new_record?
          self.prior_version = generate_prior_version
        end
        
        def generate_prior_version
          obj = self.class.new
          self.attributes.each do |attr, value|
            obj.__send__("#{attr}=", value) rescue nil
          end
          self.changes.each do |attr, values|
            obj.__send__("#{attr}=", values[0]) rescue nil
          end
          obj.workflow_state = self.workflow_state_was if obj.respond_to?("workflow_state=") && self.respond_to?("workflow_state_was")
          obj
        end
        
        # This is called after_save
        def broadcast_notifications
          return if @broadcasted
          @broadcasted = true
          raise ArgumentError, "Block not supplied for #{self.class.to_s}" unless self.class.broadcast_policy_block
          self.instance_eval &self.class.broadcast_policy_block
          self.broadcast_policy_list.each {|p| p.broadcast(self) }
        end

        def broadcast_policy_list
          @broadcast_policy_list ||= []
        end

        # If this is nil, we don't worry about trying to implement anything.
        def dispatch(notification_name)
          found = self.broadcast_policy_list.find {|bp| bp.dispatch == titleized(notification_name)}
          return found if found
          self.broadcast_policy_list << PolicyStorage.new(titleized(notification_name))
        end
        
        def titleized(notification_name)
          notification_name.to_s.titleize.gsub(/sms/i, "SMS")
        end
        protected :titleized
        
        def implementing_policy
          if not self.broadcast_policy_list.last
            # This really shouldn't happen, if a policy is setup right, but it
            # should be logged and silently fail. 
            self.broadcast_policy_list << PolicyStorage.new("unknown")
          end
          self.broadcast_policy_list.last
        end
        
        def to(&block)
          self.implementing_policy.to = block
        end
        
        def whenever(&block)
          self.implementing_policy.whenever = block
        end
        
        attr_accessor :skip_broadcasts
        
        def save_without_broadcasting
          @skip_broadcasts = true
          self.save
          @skip_broadcasts = false
        end
        
        def save_without_broadcasting!
          @skip_broadcasts = true
          self.save!
          @skip_broadcasts = false
        end
        
        # The rest of the methods here should just be helper methods to make
        # writing a condition that much easier. 
        def changed_in_state(state, opts={})
          fields  = opts[:fields] || []
          fields = [fields] unless fields.is_a?(Array)

          # Come back to this to debug some of the notifications
          # if fields == [:due_at]
          #   require 'rubygems'
          #   require 'ruby-debug'
          #   debugger
          #   1 + 1
          # end
          
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
            logger.warn "Could not check if a record changed state: #{e.inspect}"
            false
          end
        end
        alias :changed_state_to :changed_state
        
        
      end # InstanceMethods
    end # Policy
  end # Adheres
end # Instructure
