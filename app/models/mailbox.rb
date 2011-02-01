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

class Mailbox < ActiveRecord::Base
  belongs_to :mailboxable_entity, :polymorphic => true
  
  before_create :generate_handle
  
  include Workflow
  
  workflow do
    state :active do
      event :deactivate, :transitions_to => :inactive
      event :terminate, :transitions_to => :terminated
    end
    
    state :inactive do
      event :activate, :transitions_to => :active
      event :terminate, :transitions_to => :terminated
    end
    
    state :terminated
        
  end
  
  # Something like broadcast-t5K8Re@instructure.com
  def path
    generate_handle unless self.handle
    self.handle + "@" + HostUrl.outgoing_email_domain
  end
  
  def generate_handle
    return self.handle if self.handle
    found = false
    until found do
      found_handle = "#{AutoHandle.generate(self.purpose, 10)}_#{(Account.root_account_id_for(mailboxable_entity) rescue "noaccount")}"
      found = true unless Mailbox.find_by_handle(found_handle)
    end
    new_record? ? self.handle = found_handle : update_attribute(:handle, found_handle)
  end
  protected :generate_handle
  end
