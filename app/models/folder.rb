#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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
  def self.name_order_by_clause(table = nil)
    col = table ? "#{table}.name" : 'name'
    best_unicode_collation_key(col)
  end
  include Workflow
  attr_accessible :name, :full_name, :parent_folder, :workflow_state, :lock_at, :unlock_at, :locked, :hidden, :context, :position

  ROOT_FOLDER_NAME = "course files"
  PROFILE_PICS_FOLDER_NAME = "profile pictures"
  MY_FILES_FOLDER_NAME = "my files"
  CONVERSATION_ATTACHMENTS_FOLDER_NAME = "conversation attachments"

  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['User', 'Group', 'Account', 'Course']
  belongs_to :cloned_item
  belongs_to :parent_folder, :class_name => "Folder"
  has_many :file_attachments, :class_name => "Attachment"
  has_many :active_file_attachments, :class_name => 'Attachment', :conditions => ['attachments.file_state != ?', 'deleted']
  has_many :visible_file_attachments, :class_name => 'Attachment', :conditions => ['attachments.file_state in (?, ?)', 'available', 'public']
  has_many :sub_folders, :class_name => "Folder", :foreign_key => "parent_folder_id", :dependent => :destroy
  has_many :active_sub_folders, :class_name => "Folder", :conditions => ['folders.workflow_state != ?', 'deleted'], :foreign_key => "parent_folder_id", :dependent => :destroy

  EXPORTABLE_ATTRIBUTES = [
    :id, :name, :full_name, :context_id, :context_type, :parent_folder_id, :workflow_state, :created_at, :updated_at, :deleted_at, :locked,
    :lock_at, :unlock_at, :last_lock_at, :last_unlock_at, :cloned_item_id, :position
  ]

  EXPORTABLE_ASSOCIATIONS = [:context, :cloned_item, :parent_folder, :file_attachments, :sub_folders]

  acts_as_list :scope => :parent_folder

  before_save :infer_full_name
  before_save :default_values
  after_save :update_sub_folders
  after_destroy :clean_up_children
  after_save :touch_context
  before_save :infer_hidden_state
  validates_presence_of :context_id, :context_type
  validates_length_of :name, :maximum => maximum_string_length
  validate :protect_root_folder_name, :if => :name_changed?
  validate :reject_recursive_folder_structures, on: :update

  def protect_root_folder_name
    if self.parent_folder_id.blank? && self.name != Folder.root_folder_name_for_context(context)
      if self.new_record?
        root_folder = Folder.root_folders(context).first
        self.parent_folder_id = root_folder.id
        return true
      else
        errors.add(:name, t("errors.invalid_root_folder_name", "Root folder name cannot be changed"))
        return false
      end
    end
  end

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
    self.deleted_at = Time.now.utc
    self.save
  end

  scope :active, -> { where("folders.workflow_state<>'deleted'") }
  scope :not_hidden, -> { where("folders.workflow_state<>'hidden'") }
  scope :not_locked, -> { where("(folders.locked IS NULL OR folders.locked=?) AND ((folders.lock_at IS NULL) OR
    (folders.lock_at>? OR (folders.unlock_at IS NOT NULL AND folders.unlock_at<?)))", false, Time.now.utc, Time.now.utc) }
  scope :by_position, -> { order(:position) }
  scope :by_name, -> { order(name_order_by_clause('folders')) }

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
  end

  def infer_hidden_state
    self.workflow_state ||= self.parent_folder.workflow_state if self.parent_folder && !self.deleted?
  end
  protected :infer_hidden_state

  def infer_full_name
    # TODO i18n
    t :default_folder_name, 'folder'
    self.name = 'folder' if self.name.blank?
    self.name = self.name.gsub(/\//, "_")
    folder = self
    @update_sub_folders = false
    self.parent_folder_id = nil if !self.parent_folder || self.parent_folder.context != self.context || self.parent_folder_id == self.id
    self.context = self.parent_folder.context if self.parent_folder
    self.prevent_duplicate_name
    self.full_name = self.full_name(true)
    if self.parent_folder_id_changed? || !self.parent_folder_id || self.full_name_changed? || self.name_changed?
      @update_sub_folders = true
    end
    @folder_id = self.id
  end
  protected :infer_full_name

  def prevent_duplicate_name
    return unless self.parent_folder

    existing_folders = self.parent_folder.active_sub_folders.where('name ~* ? AND id <> ?', "^#{Regexp.quote(self.name)}(\\s\\d)?$", self.id.to_i).pluck(:name)

    return unless existing_folders.include?(self.name)

    iterations, usable_iterator, candidate = [], nil, 2

    existing_folders.each do |folder_name|
      iterator = folder_name.split.last.to_i
      iterations.push(iterator) if iterator > 1
    end

    iterations.sort.each do |i|
      if candidate < i
        usable_iterator = candidate
        break
      else
        candidate = i + 1
      end
    end

    usable_iterator ||= existing_folders.size + 1
    self.name = "#{self.name} #{usable_iterator}"
  end
  protected :prevent_duplicate_name

  def update_sub_folders
    return unless @update_sub_folders
    self.sub_folders.each{|f|
      f.reload
      f.full_name = f.full_name(true)
      f.save
    }
  end

  def clean_up_children
    Attachment.where(folder_id: @folder_id).each do |a|
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
    return @visible if defined?(@visible)
    @visible = (self.workflow_state == "visible") && (!self.parent_folder || self.parent_folder.visible?)
  end

  def hidden?
    return @hidden if defined?(@hidden)
    @hidden = self.workflow_state == 'hidden' || (self.parent_folder && self.parent_folder.hidden?)
  end

  def hidden
    hidden?
  end

  def hidden=(val)
    self.workflow_state = (val == true || val == '1' || val == 'true' ? 'hidden' : 'visible')
  end

  def just_hide
    self.workflow_state == 'hidden'
  end

  def protected?
    return @protected if defined?(@protected)
    @protected = (self.workflow_state == 'protected') || (self.parent_folder && self.parent_folder.protected?)
  end

  def public?
    return @public if defined?(@public)
    @public = self.workflow_state == 'public' || (self.parent_folder && self.parent_folder.public?)
  end

  def mime_class
    "folder"
  end

  # true if there are any active files or folders
  def has_contents?
    self.active_file_attachments.any? || self.active_sub_folders.any?
  end

  attr_accessor :clone_updated
  def clone_for(context, dup=nil, options={})
    if !self.cloned_item && !self.new_record?
      self.cloned_item ||= ClonedItem.create(:original_item => self)
      self.save!
    end
    existing = context.folders.active.where(id: self).first
    existing ||= context.folders.active.where(cloned_item_id: self.cloned_item_id || 0).first
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
            file.save_without_broadcasting!
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

  def self.root_folder_name_for_context(context)
    if context.is_a? Course
      ROOT_FOLDER_NAME
    elsif context.is_a? User
      MY_FILES_FOLDER_NAME
    else
      "files"
    end
  end

  def self.root_folders(context)
    name = root_folder_name_for_context(context)
    root_folders = []
    # something that doesn't have folders?!
    return root_folders unless context.respond_to?(:folders)

    context.shard.activate do
      Folder.unique_constraint_retry do
        root_folder = context.folders.active.where(parent_folder_id: nil, name: name).first
        root_folder ||= context.folders.create!(:name => name, :full_name => name, :workflow_state => "visible")
        root_folders = [root_folder]
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
    key = [context.global_asset_string, path].join('//')
    return @@path_lookups[key] if @@path_lookups[key]
    folders = path.split('/').select{|f| !f.empty? }
    @@root_folders ||= {}
    current_folder = (@@root_folders[context.global_asset_string] ||= Folder.root_folders(context).first)
    if folders[0] == current_folder.name
      folders.shift
    end
    folders.each do |name|
      sub_folder = @@path_lookups[[context.global_asset_string, current_folder.full_name + '/' + name].join('//')]
      sub_folder ||= current_folder.sub_folders.active.where(name: name).first_or_initialize
      current_folder = sub_folder
      if current_folder.new_record?
        current_folder.context = context
        yield current_folder if block_given?
        current_folder.save!
      end
      @@path_lookups[[context.global_asset_string, current_folder.full_name].join('//')] ||= current_folder
    end
    @@path_lookups[key] = current_folder
  end

  def self.reset_path_lookups!
    @@root_folders = {}
    @@path_lookups = {}
  end

  def self.unfiled_folder(context)
    folder = context.folders.where(parent_folder_id: Folder.root_folders(context).first, workflow_state: 'visible', name: 'unfiled').first
    unless folder
      folder = context.folders.build(:parent_folder => Folder.root_folders(context).first, :name => 'unfiled')
      folder.workflow_state = 'visible'
      folder.save!
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
        current_folder = context.folders.active.where(full_name: "course content").first
      elsif @context.is_a? User
        current_folder = context.folders.active.where(full_name: MY_FILES_FOLDER_NAME).first
      end
    end
  end

  def self.find_attachment_in_context_with_path(context, path)
    components = path.split('/')
    component = components.shift
    context.folders.active.where(parent_folder_id: nil).each do |folder|
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
      active_sub_folders.where(name: component).each do |folder|
        a = folder.find_attachment_with_components(components.dup)
        return a if a
      end
    end
    nil
  end

  def get_folders_by_component(components, include_hidden_and_locked)
    return [self] if components.empty?
    components = components.dup
    subfolder_name = components.shift
    # search all subfolders with the given name (yes, there can be duplicates)
    scope = active_sub_folders.where(name: subfolder_name)
    scope = scope.not_hidden.not_locked unless include_hidden_and_locked
    scope.each do |subfolder|
      sub_components = subfolder.get_folders_by_component(components, include_hidden_and_locked)
      return [self] + sub_components if sub_components
    end
    nil
  end

  def self.resolve_path(context, path, include_hidden_and_locked = true)
    path_components = path ? (path.is_a?(Array) ? path : path.split('/')) : []
    Folder.root_folders(context).each do |root_folder|
      folders = root_folder.get_folders_by_component(path_components, include_hidden_and_locked)
      return folders if folders
    end
    nil
  end

  def locked?
    return @locked if defined?(@locked)
    @locked = self.locked ||
      (self.lock_at && Time.now > self.lock_at) ||
      (self.unlock_at && Time.now < self.unlock_at) ||
      (self.parent_folder && self.parent_folder.locked?)
  end

  def currently_locked
    self.locked || (self.lock_at && Time.now > self.lock_at) || (self.unlock_at && Time.now < self.unlock_at) || self.workflow_state == 'hidden'
  end

  set_policy do
    given { |user, session| self.visible? && self.context.grants_right?(user, session, :read) }#students.include?(user) }
    can :read

    given { |user, session| self.visible? && !self.locked? && self.context.grants_right?(user, session, :read) && !(self.context.is_a?(Course) && self.context.tab_hidden?(Course::TAB_FILES)) }#students.include?(user) }
    can :read_contents

    given { |user, session| self.context.grants_right?(user, session, :manage_files) }#admins.include?(user) }
    can :update and can :delete and can :create and can :read and can :read_contents

    given {|user, session| self.protected? && !self.locked? && self.context.grants_right?(user, session, :read) && self.context.users.include?(user) }
    can :read and can :read_contents
  end
end
