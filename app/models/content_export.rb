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
  attr_accessible :course
  validates_presence_of :course_id, :workflow_state
  has_one :job_progress, :class_name => 'Progress', :as => :context

  alias_method :context, :course

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

  set_policy do
    given { |user, session| self.course.grants_right?(user, session, :manage_files) }
    can :manage_files and can :read
  end

  def export_course(opts={})
    self.workflow_state = 'exporting'
    self.save
    begin
      self.job_progress.try :start!
      @cc_exporter = CC::CCExporter.new(self, opts.merge({:for_course_copy => for_course_copy?}))
      if @cc_exporter.export
        self.progress = 100
        self.job_progress.try :complete!
        if for_course_copy?
          self.workflow_state = 'exported_for_course_copy'
        else
          self.workflow_state = 'exported'
        end
      else
        self.workflow_state = 'failed'
        self.job_progress.try :fail!
      end
    rescue
      add_error("Error running course export.", $!)
      self.workflow_state = 'failed'
      self.job_progress.try :fail!
    ensure
      self.save
    end
  end
  handle_asynchronously :export_course, :priority => Delayed::LOW_PRIORITY, :max_attempts => 1

  def queue_api_job(opts)
    if self.job_progress
      p = self.job_progress
    else
      p = Progress.new(:context => self, :tag => "content_export")
      self.job_progress = p
    end
    p.workflow_state = 'queued'
    p.completion = 0
    p.user = self.user
    p.save!

    export_course(opts)
  end

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

  # Method Summary
  #   Takes in an ActiveRecord object. Determines if the item being 
  #   checked should be exported or not. 
  #
  #   Returns: bool
  def export_object?(obj, asset_type=nil)
    return false unless obj
    return true if selected_content.empty?
    return true if is_set?(selected_content[:everything])

    asset_type ||= obj.class.table_name
    return true if is_set?(selected_content["all_#{asset_type}"])

    return false unless selected_content[asset_type]
    return true if is_set?(selected_content[asset_type][CC::CCHelper.create_key(obj)])

    false
  end

  # Method Summary
  #   Takes a symbol containing the items that were selected to export.
  #   is_set? will return true if the item is selected. Also handles
  #   a case where 'everything' is set and returns true
  #   
  # Returns: bool
  def export_symbol?(symbol)
    is_set?(selected_content[symbol]) || is_set?(selected_content[:everything])
  end

  def add_item_to_export(obj, type=nil)
    return unless obj && (type || obj.class.respond_to?(:table_name))
    return if selected_content.empty?
    return if is_set?(selected_content[:everything])

    asset_type = type || obj.class.table_name
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
    content_migration.update_conversion_progress(val) if content_migration
    self.progress = val
    ContentExport.where(:id => self).update_all(:progress=>val)
    self.job_progress.try(:update_completion!, val)
  end
  
  scope :active, -> { where("workflow_state<>'deleted'") }
  scope :not_for_copy, -> { where("export_type<>?", COURSE_COPY) }
  scope :common_cartridge, -> { where(:export_type => COMMON_CARTRIDGE) }
  scope :qti, -> { where(:export_type => QTI) }
  scope :course_copy, -> { where(:export_type => COURSE_COPY) }
  scope :running, -> { where(:workflow_state => ['created', 'exporting']) }

  private

  def is_set?(option)
    Canvas::Plugin::value_to_boolean option
  end
  
end
