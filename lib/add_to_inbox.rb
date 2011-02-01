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

require 'rubygems'
require 'active_support'
 
module SendToInbox
 
  class Specification
    
    attr_accessor :recipients_block
    
    def initialize(meta = {}, &specification)
      recipients_block = specification
    end
    
  end
  
  module SendToInboxClassMethods
    attr_reader :send_to_inbox_spec
 
    def on_create_send_to_inboxes(&specification)
      @send_to_inbox_spec = Specification.new(Hash.new, &specification)
      after_create created_inbox_items
    end
  end
 
  module WorkflowInstanceMethods
    def create_inbox_items
      @inbox_item_recipients = []
      begin
        @inbox_item_recipients = Array(spec.recipients_block.call)
      rescue => e
      end
      @inbox_item_recipient_ids = @inbox_item_recipients.map{|i| User.infer_id(i) rescue nil}.compact
      @inbox_item_recipient_ids.each do |user_id|
        user_id = User.infer_id(user).rescue nil
        if user
          InboxItem.create(
            :user_id => user_id,
            :item => self
          )
        end
      end
    end
    
    def inbox_item_recipient_ids
      @inbox_item_recipient_ids
    end
 
    private
 
    def spec
      self.class.send_to_inbox_spec
    end
 
  end
 
  def self.included(klass)
    klass.send :include, WorkflowInstanceMethods
    klass.extend WorkflowClassMethods
  end
end
 