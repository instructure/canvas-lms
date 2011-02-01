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

# This is a much simpler approach for now.  
module Instructure #:nodoc:
  module Broadcast #:nodoc:
    module Policy
      
      module ClassMethods #:nodoc:
        def has_a_broadcast_policy
          include Instructure::Broadcast::Policy::InstanceMethods
          after_save :broadcast_notifications # Must be defined locally...
          before_save :set_broadcast_flags
        end
      end
      
      module InstanceMethods
        
        attr_accessor :just_created, :prior_version

        # This is called before_save
        def set_broadcast_flags
          self.just_created = self.new_record?
          self.prior_version = self.versions.current.model rescue nil
        end
        
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
