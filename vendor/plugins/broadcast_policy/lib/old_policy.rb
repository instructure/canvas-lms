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

# Commenting out the parts I'm now avoiding.
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
      
      # class PolicyStorage
      #   
      #   attr_accessor :dispatch, :to, :whenever
      #   
      #   def initialize(dispatch)
      #     self.dispatch = dispatch
      #   end
      #   
      #   # This should be called for an instance.  It can only be sent out if the
      #   # condition is met, if there is a notification that we can find, and if
      #   # there is someone to send this to.  At this point, a Message record is
      #   # created, which will be delayed, consolidated, dispatched to the right
      #   # server, and then finally sent through that server. 
      #   
      #   def broadcast(record)
      #     begin
      #       meets_condition = self.whenever.call(record)
      #     rescue
      #       return false
      #     end
      #     return false unless meets_condition
      # 
      #     notification = Notification.find_by_name(self.dispatch)
      #     return false unless notification
      #     # self.consolidated_notifications[notification_name.to_s.titleize] rescue nil
      # 
      #     begin
      #       to_list = self.to.call(record)
      #     rescue
      #       return false
      #     end
      #     return false unless to_list
      # 
      #     notification.create_message(record, to_list)
      #   end
      #   
      # end
      
      module ClassMethods #:nodoc:
        def has_a_broadcast_policy
          # extend Instructure::Broadcast::Policy::SingletonMethods
          include Instructure::Broadcast::Policy::InstanceMethods
          after_save :broadcast_notifications # Must be defined locally...
          before_save :set_broadcast_flags
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
      # module SingletonMethods
      # 
      #   attr_accessor :broadcast_policy_block
      #   
      #   # This stores the policy for broadcasting changes on a class.  It works like a
      #   # macro.  The policy block will be stored in @broadcast_policy_block.  Then, an
      #   # instance will use that to instantiate a Policy object. 
      #   def set_broadcast_policy(&block)
      #     self.broadcast_policy_block = block
      #   end
      # 
      # end

      module InstanceMethods
        
        attr_accessor :just_created, :prior_version

        # This is called before_save
        def set_broadcast_flags
          self.just_created = self.new_record?
          self.prior_version = self.versions.current.model rescue nil
        end
        
        # This is called after_save
        # def broadcast_notifications
        #   self.instance_eval &self.class.broadcast_policy_block
        #   self.broadcast_policy_list.each {|p| p.broadcast(self) }
        # end

        # def broadcast_policy_list
        #   @broadcast_policy_list ||= []
        # end

        # If this is nil, we don't worry about trying to implement anything.
        # def dispatch(notification_name)
        #   self.broadcast_policy_list << PolicyStorage.new(notification_name.to_s.titleize)
        # end
        
        # def implementing_policy
        #   if not self.broadcast_policy_list.last
        #     # This really shouldn't happen, if a policy is setup right, but it
        #     # should be logged and silently fail. 
        #     self.broadcast_policy_list << PolicyStorage.new("unknown")
        #   end
        #   self.broadcast_policy_list.last
        # end
        # 
        # def to(&block)
        #   self.implementing_policy.to = block
        # end
        # 
        # def whenever(&block)
        #   self.implementing_policy.whenever = block
        # end
        
        # The rest of the methods here should just be helper methods to make
        # writing a condition that much easier. 
        def changed_in_state(state, opts={})
          fields  = opts[:fields] || []
          fields = [fields] unless fields.is_a?(Array)
          
          begin
            fields.each {|field| self.prior_version.send(field) != self.send(field) }.compact == [true] and
            self.workflow_state == state.to_s and
            self.prior_version.workflow_state == state.to_s 
          rescue Exception => e
            logger.warn "Could not check if a change was made: #{e.inspect}"
            false
          end
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
              self.workflow_state == new_state.to_s and
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
