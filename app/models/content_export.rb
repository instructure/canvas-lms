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
  belongs_to :content_migration
  has_many :attachments, :as => :context, :dependent => :destroy
  has_a_broadcast_policy
  serialize :settings
  attr_accessible

  #export types
  COMMON_CARTRIDGE = 'common_cartridge'
  COURSE_COPY = 'course_copy'
  QTI = 'qti'
  
  workflow do
    state :created
    state :exporting
    state :exported
    state :exported_for_course_copy
    state :failed
    state :deleted
  end

  set_broadcast_policy do |p|
    p.dispatch :content_export_finished
    p.to { [user] }
    p.whenever {|record|
      record.changed_state(:exported) && self.content_migration.blank?
    }
    
    p.dispatch :content_export_failed
    p.to { [user] }
    p.whenever {|record|
      record.changed_state(:failed) && self.content_migration.blank?
    }
  end
  
  def export_course(opts={})
    self.workflow_state = 'exporting'
    self.save
    begin
      @cc_exporter = CC::CCExporter.new(self, opts.merge({:for_course_copy => for_course_copy?}))
      if @cc_exporter.export
        self.progress = 100
        if for_course_copy?
          self.workflow_state = 'exported_for_course_copy'
        else
          self.workflow_state = 'exported'
        end
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

  def referenced_files
    @cc_exporter ? @cc_exporter.referenced_files : {}
  end

  def for_course_copy?
    self.export_type == COURSE_COPY
  end

  def qti_export?
    self.export_type == QTI
  end
  
  def error_message
    self.settings[:errors] ? self.settings[:errors].last : nil
  end
  
  def error_messages
    self.settings[:errors] ||= []
  end

  def selected_content=(copy_settings)
    self.settings[:selected_content] = copy_settings
  end

  def selected_content
    self.settings[:selected_content] ||= {}
  end

  def export_object?(obj)
    return false unless obj
    return true if selected_content.empty?
    return true if is_set?(selected_content[:everything])

    asset_type = obj.class.table_name
    return true if is_set?(selected_content["all_#{asset_type}"])

    return false unless selected_content[asset_type]
    return true if is_set?(selected_content[asset_type][CC::CCHelper.create_key(obj)])

    false
  end

  def add_item_to_export(obj)
    return unless obj && obj.class.respond_to?(:table_name)
    return if selected_content.empty?
    return if is_set?(selected_content[:everything])

    asset_type = obj.class.table_name
    selected_content[asset_type] ||= {}
    selected_content[asset_type][CC::CCHelper.create_key(obj)] = true
  end
  
  def add_error(user_message, exception_or_info=nil)
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
    read_attribute(:settings) || write_attribute(:settings,{}.with_indifferent_access)
  end
  
  def fast_update_progress(val)
    self.progress = val
    ContentExport.update_all({:progress=>val}, "id=#{self.id}")
  end
  
  named_scope :active, {:conditions => ['workflow_state != ?', 'deleted']}
  named_scope :not_for_copy, {:conditions => ['workflow_state != ?', 'exported_for_course_copy']}
  named_scope :common_cartridge, {:conditions => ['export_type == ?', COMMON_CARTRIDGE]}
  named_scope :qti, {:conditions => ['export_type == ?', QTI]}
  named_scope :course_copy, {:conditions => ['export_type == ?', COURSE_COPY]}
  named_scope :running, {:conditions => ['workflow_state IN (?)', ['created', 'exporting']]}

  private

  def is_set?(option)
    Canvas::Plugin::value_to_boolean option
  end
  
end
