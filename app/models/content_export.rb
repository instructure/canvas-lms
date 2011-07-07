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

class ContentExport < ActiveRecord::Base
  include Workflow
  belongs_to :course
  belongs_to :user
  belongs_to :attachment
  has_many :attachments, :as => :context, :dependent => :destroy
  has_a_broadcast_policy
  serialize :settings
  attr_accessible
  
  workflow do
    state :created
    state :exporting
    state :exported
    state :failed
    state :deleted
  end

  set_broadcast_policy do |p|
    p.dispatch :content_export_finished
    p.to { [user] }
    p.whenever {|record|
      record.changed_state(:exported)
    }
    
    p.dispatch :content_export_failed
    p.to { [user] }
    p.whenever {|record|
      record.changed_state(:failed)
    }
  end
  
  def export_course
    self.workflow_state = 'exporting'
    self.save
    begin
      if CC::CCExporter.export(self)
        self.workflow_state = 'exported'
      else
        self.workflow_state = 'failed'
      end
    rescue
      add_error("Error running course export.", $!)
      self.workflow_state = 'failed'
    ensure
      self.save
    end
  end
  handle_asynchronously :export_course, :priority => Delayed::LOW_PRIORITY, :max_attempts => 1
  
  def error_message
    self.settings[:errors] ? self.settings[:errors].last : nil
  end
  
  def error_messages
    self.settings[:errors]
  end
  
  def add_error(user_message, exception_or_info)
    self.settings[:errors] ||= []
    if exception_or_info.is_a?(Exception)
      er = ErrorReport.log_exception(:course_export, exception_or_info)
      self.settings[:errors] << [user_message, "ErrorReport id: #{er.id}"]
    else
      self.settings[:errors] << [user_message, exception_or_info]
    end
  end
  
  def root_account
    self.course.root_account
  end
  
  def running?
    ['created', 'exporting'].member? self.workflow_state
  end
  
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.attachment.destroy! if self.attachment
    save!
  end

  def settings
    read_attribute(:settings) || write_attribute(:settings,{})
  end
  
  def fast_update_progress(val)
    self.progress = val
    ContentExport.update_all({:progress=>val}, "id=#{self.id}")
  end
  
  named_scope :active, {:conditions => ['workflow_state != ?', 'deleted']}
  named_scope :running, {:conditions => ['workflow_state IN (?)', ['created', 'exporting']]}
  
end
