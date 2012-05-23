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

require 'set'

class Folder < ActiveRecord::Base
  include Workflow
  attr_accessible :name, :full_name, :parent_folder, :workflow_state, :lock_at, :unlock_at, :locked, :hidden, :context

  ROOT_FOLDER_NAME = "course files"
  PROFILE_PICS_FOLDER_NAME = "profile pictures"
  MY_FILES_FOLDER_NAME = "my files"
  CONVERSATION_ATTACHMENTS_FOLDER_NAME = "conversation attachments"

  belongs_to :context, :polymorphic => true
  belongs_to :cloned_item
  belongs_to :parent_folder, :class_name => "Folder"
  has_many :file_attachments, :class_name => "Attachment", :order => 'position'
  has_many :active_file_attachments, :class_name => 'Attachment', :conditions => ['attachments.file_state != ?', 'deleted'], :order => 'position, display_name'
  has_many :visible_file_attachments, :class_name => 'Attachment', :conditions => ['attachments.file_state in (?, ?)', 'available', 'public'], :order => 'position, display_name'
  has_many :sub_folders, :class_name => "Folder", :foreign_key => "parent_folder_id", :dependent => :destroy, :order => 'position'
  has_many :active_sub_folders, :class_name => "Folder", :conditions => ['folders.workflow_state != ?', 'deleted'], :foreign_key => "parent_folder_id", :dependent => :destroy, :order => 'position'
  
  acts_as_list :scope => :parent_folder
  
  before_save :infer_full_name
  before_save :default_values
  after_save :update_sub_folders
  after_destroy :clean_up_children
  after_save :touch_context
  before_save :infer_hidden_state
  validates_presence_of :context_id, :context_type
  validate_on_update :reject_recursive_folder_structures

  def reject_recursive_folder_structures
    return true if !self.parent_folder_id_changed?
    seen_folders = Set.new([self])
    folder = self
    while folder.parent_folder
      folder = folder.parent_folder
      if seen_folders.include?(folder)
        errors.add(:parent_folder_id, t("errors.invalid_recursion", "A folder cannot be the parent of itself"))
        return false
      end
      seen_folders << folder
    end
    return true
  end

  workflow do
    # Anyone who has read access to the course can view
    state :visible
    # Anyone who is an enrolled member of the course can view
    state :protected
    # Only course admins can view
    state :private
    # Not sure what this was for...
    state :hidden
    state :deleted
  end
  
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.active_file_attachments.each{|a| a.destroy }
    self.active_sub_folders.each{|s| s.destroy }
    self.deleted_at = Time.now
    self.save
  end
  
  named_scope :active, :conditions => ['folders.workflow_state != ?', 'deleted']

  def display_name
    name
  end
  
  def full_name(reload=false)
    return read_attribute(:full_name) if !reload && read_attribute(:full_name)
    folder = self
    names = [self.name]
    while folder.parent_folder_id do
      folder = Folder.find(folder.parent_folder_id) #folder.parent_folder
      names << folder.name if folder
    end
    names.reverse.join("/")
  end
  
  def default_values
    self.last_unlock_at = self.unlock_at if self.unlock_at
    self.last_lock_at = self.lock_at if self.lock_at
    # You can't lock or hide root folders
    if !self.parent_folder_id && (self.locked? || self.hidden? || self.protected?)
      self.workflow_state = 'visible'
    end
  end
  
  def infer_hidden_state
    self.workflow_state ||= self.parent_folder.workflow_state if self.parent_folder && !self.deleted?
  end
  protected :infer_hidden_state
  
  def infer_full_name
    # TODO i18n
    t :default_folder_name, 'folder'
    self.name ||= "folder"
    self.name = self.name.gsub(/\//, "_")
    folder = self
    @update_sub_folders = false
    self.parent_folder_id = nil if !self.parent_folder || self.parent_folder.context != self.context || self.parent_folder_id == self.id
    self.context = self.parent_folder.context if self.parent_folder
    self.full_name = self.full_name(true)
    if self.parent_folder_id_changed? || !self.parent_folder_id || self.full_name_changed? || self.name_changed?
      @update_sub_folders = true
    end
    @folder_id = self.id
  end
  protected :infer_full_name
  
  def update_sub_folders
    return unless @update_sub_folders
    self.sub_folders.each{|f| 
      f.reload
      f.full_name = f.full_name(true)
      f.save
    }
  end
  
  def clean_up_children
    Attachment.find_all_by_folder_id(@folder_id).each do |a|
      a.destroy
    end
  end
  
  def subcontent(opts={})
    res = []
    res += self.active_sub_folders
    res += self.active_file_attachments unless opts[:exclude_files]
    res
  end
  
  def visible?
    # everything but private folders should be visible... for now...
    (self.workflow_state == "visible") && (!self.parent_folder || self.parent_folder.visible?)
  end
  memoize :visible?
  
  def hidden?
    self.workflow_state == 'hidden' || (self.parent_folder && self.parent_folder.hidden?)
  end
  memoize :hidden?
  
  def hidden
    hidden?
  end
  
  def hidden=(val)
    self.workflow_state = (val == true || val == '1' ? 'hidden' : 'visible')
  end
  
  def just_hide
    self.workflow_state == 'hidden'
  end
  
  def protected?
    (self.workflow_state == 'protected') || (self.parent_folder && self.parent_folder.protected?)
  end
  memoize :protected?
  
  def public?
    self.workflow_state == 'public' || (self.parent_folder && self.parent_folder.public?)
  end
  memoize :public?
  
  def mime_class
    "folder"
  end
  
  attr_accessor :clone_updated
  def clone_for(context, dup=nil, options={})
    if !self.cloned_item && !self.new_record?
      self.cloned_item ||= ClonedItem.create(:original_item => self)
      self.save!
    end
    existing = context.folders.active.find_by_id(self.id)
    existing ||= context.folders.active.find_by_cloned_item_id(self.cloned_item_id || 0)
    return existing if existing && !options[:overwrite] && !options[:force_copy]
    dup ||= Folder.new
    dup = existing if existing && options[:overwrite]
    self.attributes.delete_if{|k,v| [:id, :full_name, :parent_folder_id].include?(k.to_sym) }.each do |key, val|
      dup.send("#{key}=", val)
    end
    dup.context = context
    if options[:include_subcontent] != false
      dup.save_without_broadcasting!
      self.subcontent.each do |item|
        if options[:everything] || options[:all_files] || options[item.asset_string.to_sym]
          if item.is_a?(Attachment)
            file = item.clone_for(context)
            file.folder_id = dup.id
            file.save!
          elsif item.is_a?(Folder)
            sub = item.clone_for(context, nil, options)
            sub.parent_folder_id = dup.id
            sub.save!
          end
        end
      end
    end
    context.log_merge_result(t :folder_created, "Folder \"%{name}\" created", :name => dup.full_name)
    dup.updated_at = Time.now
    dup.clone_updated = true
    dup
  end
  
  def root_folder?
    !self.parent_folder_id
  end

  def self.root_folders(context)
    root_folders = []
    root_folders = context.folders.active.find_all_by_parent_folder_id(nil)
    if context.is_a? Course
      if root_folders.select{|f| f.name == ROOT_FOLDER_NAME }.empty?
        root_folders << context.folders.create(:name => ROOT_FOLDER_NAME, :full_name => ROOT_FOLDER_NAME, :workflow_state => "visible")
      end
    elsif context.is_a? User
      # TODO i18n 
      t :my_files_folder_name, 'my files'
      if root_folders.select{|f| f.name == MY_FILES_FOLDER_NAME }.empty?
        root_folders << context.folders.create(:name => MY_FILES_FOLDER_NAME, :full_name => MY_FILES_FOLDER_NAME, :workflow_state => "visible")
      end
    else
      # TODO i18n 
      t :files_folder_name, 'files'
      if root_folders.select{|f| f.name == "files" }.empty?
        root_folders << context.folders.create(:name => "files", :full_name => "files", :workflow_state => "visible")
      end
    end
    root_folders
  end
  
  def attachments
    file_attachments
  end
  
  # if a block is given, it'll be called with each new folder created by this
  # method before the folder is saved
  def self.assert_path(path, context)
    @@path_lookups ||= {}
    key = [context.asset_string, path].join('//')
    return @@path_lookups[key] if @@path_lookups[key]
    folders = path.split('/').select{|f| !f.empty? }
    @@root_folders ||= {}
    current_folder = (@@root_folders[context.asset_string] ||= Folder.root_folders(context).first)
    if folders[0] == current_folder.name
      folders.shift
    end
    folders.each do |name|
      sub_folder = @@path_lookups[[context.asset_string, current_folder.full_name + '/' + name].join('//')]
      sub_folder ||= current_folder.sub_folders.active.find_or_initialize_by_name(name)
      current_folder = sub_folder
      if current_folder.new_record?
        current_folder.context = context
        yield current_folder if block_given?
        current_folder.save!
      end
      @@path_lookups[[context.asset_string, current_folder.full_name].join('//')] ||= current_folder
    end
    @@path_lookups[key] = current_folder
  end
  
  def self.unfiled_folder(context)
    folder = context.folders.find_by_parent_folder_id_and_workflow_state_and_name(Folder.root_folders(context).first.id, 'visible', 'unfiled')
    unless folder
      folder = context.folders.new(:parent_folder => Folder.root_folders(context).first, :name => 'unfiled')
      folder.workflow_state = 'visible'
      folder.save
    end
    folder
  end
  
  def self.find_folder(context, folder_id)
    if folder_id
      current_folder = context.folders.active.find(folder_id)
    else
      # TODO i18n
      if context.is_a? Course
        t :course_content_folder_name, 'course content'
        current_folder = context.folders.active.find_by_full_name("course content")
      elsif @context.is_a? User
        current_folder = context.folders.active.find_by_full_name(MY_FILES_FOLDER_NAME)
      end
    end
  end

  def self.find_attachment_in_context_with_path(context, path)
    components = path.split('/')
    component = components.shift
    context.folders.active.find_all_by_parent_folder_id(nil).each do |folder|
      if folder.name == component
        attachment = folder.find_attachment_with_components(components.dup)
        return attachment if attachment
      end
    end
    nil
  end

  def find_attachment_with_components(components)
    component = components.shift
    if components.empty?
      # find the attachment
      return visible_file_attachments.to_a.find {|a| a.matches_filename?(component) }
    else
      # find a subfolder and recurse (yes, we can have multiple sub-folders w/ the same name)
      active_sub_folders.find_all_by_name(component).each do |folder|
        a = folder.find_attachment_with_components(components.dup)
        return a if a
      end
    end
    nil
  end

  def locked?
    self.locked ||
    (self.lock_at && Time.now > self.lock_at) ||
    (self.unlock_at && Time.now < self.unlock_at) ||
    (self.parent_folder && self.parent_folder.locked?)
  end
  memoize :locked?

  def currently_locked
    self.locked || (self.lock_at && Time.now > self.lock_at) || (self.unlock_at && Time.now < self.unlock_at) || self.workflow_state == 'hidden'
  end
  
  set_policy do
    given { |user, session| self.visible? && self.cached_context_grants_right?(user, session, :read) }#students.include?(user) }
    can :read

    given { |user, session| self.visible? && !self.locked? && self.cached_context_grants_right?(user, session, :read) }#students.include?(user) }
    can :read_contents

    given { |user, session| self.cached_context_grants_right?(user, session, :manage_files) }#admins.include?(user) }
    can :update and can :delete and can :create and can :read and can :read_contents

    given {|user, session| self.protected? && !self.locked? && self.cached_context_grants_right?(user, session, :read) && self.context.users.include?(user) }
    can :read and can :read_contents
  end
end
