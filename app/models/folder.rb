# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class Folder < ActiveRecord::Base
  def self.name_order_by_clause(table = nil)
    col = table ? "#{table}.name" : "name"
    best_unicode_collation_key(col)
  end
  include Workflow

  ICON_MAKER_UNIQUE_TYPE = "icon maker icons"
  ROOT_FOLDER_NAME = "course files"
  PROFILE_PICS_FOLDER_NAME = "profile pictures"
  MY_FILES_FOLDER_NAME = "my files"
  CONVERSATION_ATTACHMENTS_FOLDER_NAME = "conversation attachments"
  STUDENT_ANNOTATION_DOCUMENTS_UNIQUE_TYPE = "student annotation documents"

  belongs_to :context, polymorphic: %i[user group account course], optional: false
  belongs_to :cloned_item
  belongs_to :parent_folder, class_name: "Folder"
  has_many :file_attachments, class_name: "Attachment"
  has_many :active_file_attachments, -> { where("attachments.file_state<>'deleted'") }, class_name: "Attachment"
  has_many :visible_file_attachments, -> { where(file_state: ["available", "public"]) }, class_name: "Attachment"
  has_many :sub_folders, class_name: "Folder", foreign_key: "parent_folder_id", dependent: :destroy
  has_many :active_sub_folders, -> { where("folders.workflow_state<>'deleted'") }, class_name: "Folder", foreign_key: "parent_folder_id", dependent: :destroy

  acts_as_list scope: :parent_folder

  before_create :populate_root_account_id
  before_save :infer_full_name
  after_save :update_sub_folders
  after_save :touch_context
  before_save :infer_hidden_state
  validates :context_id, :context_type, presence: true
  validates :name, length: { maximum: maximum_string_length }
  validate :protect_root_folder_name, if: :name_changed?
  validate :reject_recursive_folder_structures, on: :update
  validate :restrict_submission_folder_context
  after_commit :clear_permissions_cache, if: -> { %i[workflow_state parent_folder_id locked lock_at unlock_at].any? { |k| saved_changes.key?(k) } }

  def file_attachments_visible_to(user)
    if context.grants_any_right?(user, *RoleOverride::GRANULAR_FILE_PERMISSIONS) ||
       grants_right?(user, :read_as_admin)
      active_file_attachments
    else
      visible_file_attachments.not_locked
    end
  end

  def populate_root_account_id
    self.root_account_id = if context_type == "User"
                             0
                           elsif context_type == "Account" && context.root_account?
                             context_id
                           else
                             context.root_account_id
                           end
  end

  def protect_root_folder_name
    if parent_folder_id.blank? && name != Folder.root_folder_name_for_context(context)
      if new_record?
        root_folder = Folder.root_folders(context).first
        self.parent_folder_id = root_folder.id
        true
      else
        errors.add(:name, t("errors.invalid_root_folder_name", "Root folder name cannot be changed"))
        false
      end
    end
  end

  def reject_recursive_folder_structures
    return true unless parent_folder_id_changed?

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
    true
  end

  def restrict_submission_folder_context
    if for_submissions? && %w[User Group].exclude?(context_type)
      errors.add(:submission_context_code, t("submissions folders must be created in User or Group context"))
      return false
    end
    true
  end

  workflow do
    state :visible
    state :hidden
    state :deleted
  end

  alias_method :destroy_permanently!, :destroy

  def destroy
    shard.activate do
      loop do
        folder_count = 1000
        Folder.transaction do
          associated_folders = Folder.find_by_sql(<<~SQL.squish)
            WITH RECURSIVE associated_folders AS (
              SELECT * FROM #{Folder.quoted_table_name} WHERE id=#{id}
              UNION
              SELECT folders.* FROM #{Folder.quoted_table_name} INNER JOIN associated_folders ON folders.parent_folder_id=associated_folders.id
            )
            SELECT id FROM associated_folders WHERE associated_folders.workflow_state <> 'deleted' ORDER BY id LIMIT 1000 FOR UPDATE
          SQL
          Attachment.batch_destroy(Attachment.active.where(folder_id: associated_folders).order(:id))
          delete_time = Time.now.utc
          Folder.where(id: associated_folders).update_all(workflow_state: "deleted", deleted_at: delete_time, updated_at: delete_time)
          folder_count = associated_folders.length
        end
        break if folder_count < 1000
      end
      touch_context
    end
    reload
  end

  scope :active, -> { where("folders.workflow_state<>'deleted'") }
  scope :not_hidden, -> { where("folders.workflow_state<>'hidden'") }
  scope :not_locked, lambda {
    where("(folders.locked IS NULL OR folders.locked=?) AND ((folders.lock_at IS NULL) OR
    (folders.lock_at>? OR (folders.unlock_at IS NOT NULL AND folders.unlock_at<?)))",
          false,
          Time.now.utc,
          Time.now.utc)
  }
  scope :by_position, -> { ordered }
  scope :by_name, -> { order(name_order_by_clause("folders"), :id) }

  def display_name
    name
  end

  def full_name(reload = false)
    return read_attribute(:full_name) if !reload && read_attribute(:full_name)

    folder = self
    names = [name]
    while folder.parent_folder_id
      folder = Folder.find(folder.parent_folder_id) # folder.parent_folder
      names << folder.name if folder
    end
    names.reverse.join("/")
  end

  def infer_hidden_state
    self.workflow_state ||= parent_folder.workflow_state if parent_folder && !deleted?
  end

  protected :infer_hidden_state

  def infer_full_name
    # TODO: i18n
    t :default_folder_name, "New Folder"
    self.name = "New Folder" if name.blank?
    self.name = name.strip.tr("/", "_")
    @update_sub_folders = false
    self.parent_folder_id = nil if !parent_folder || parent_folder.context != context || parent_folder_id == id
    self.context = parent_folder.context if parent_folder
    prevent_duplicate_name
    self.full_name = full_name(true)
    if parent_folder_id_changed? || !parent_folder_id || full_name_changed? || name_changed?
      @update_sub_folders = true
    end
    @folder_id = id
  end

  protected :infer_full_name

  def prevent_duplicate_name
    return unless parent_folder

    existing_folders = parent_folder.active_sub_folders.where("name ~* ? AND id <> ?", "^#{Regexp.quote(name)}(\\s\\d+)?$", id.to_i).pluck(:name)

    return unless existing_folders.include?(name)

    iterations, usable_iterator, candidate = [], nil, 2

    existing_folders.each do |folder_name|
      iterator = folder_name.split.last.to_i
      iterations << iterator if iterator > 1
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
    self.name = "#{name} #{usable_iterator}"
  end

  protected :prevent_duplicate_name

  def update_sub_folders
    return unless @update_sub_folders

    sub_folders.each do |f|
      f.reload
      f.full_name = f.full_name(true)
      f.save
    end
  end

  def subcontent(opts = {})
    res = []
    res += active_sub_folders
    res += active_file_attachments unless opts[:exclude_files]
    res
  end

  def visible?
    return @visible if defined?(@visible)

    @visible = (self.workflow_state == "visible") && (!parent_folder || parent_folder.visible?)
  end

  def hidden?
    return @hidden if defined?(@hidden)

    @hidden = self.workflow_state == "hidden" || parent_folder&.hidden?
  end

  def hidden
    hidden?
  end

  def hidden=(val)
    self.workflow_state = ((val == true || val == "1" || val == "true") ? "hidden" : "visible")
  end

  def just_hide
    self.workflow_state == "hidden"
  end

  def public?
    return @public if defined?(@public)

    @public = self.workflow_state == "public" || parent_folder&.public?
  end

  def mime_class
    "folder"
  end

  # true if there are any active files or folders
  def has_contents?
    active_file_attachments.any? || active_sub_folders.any?
  end

  attr_accessor :clone_updated

  def clone_for(context, dup = nil, options = {})
    if !cloned_item && !new_record?
      self.cloned_item ||= ClonedItem.create(original_item: self)
      save!
    end
    existing = context.folders.active.where(id: self).first
    existing ||= context.folders.active.where(cloned_item_id: cloned_item_id || 0).first
    return existing if existing && !options[:overwrite] && !options[:force_copy]

    dup ||= Folder.new
    dup = existing if existing && options[:overwrite]
    attributes.except("id", "full_name", "parent_folder_id").each do |key, val|
      dup.send(:"#{key}=", val)
    end
    if unique_type && context.folders.active.where(unique_type:).exists?
      dup.unique_type = nil # we'll just copy the folder as a normal one and leave the existing unique_type'd one alone
    end
    dup.context = context
    if options[:include_subcontent] != false
      dup.save!
      subcontent.each do |item|
        next unless options[:everything] || options[:all_files] || options[item.asset_string.to_sym]

        case item
        when Attachment
          file = item.clone_for(context, nil, options.slice(:overwrite, :force_copy))
          file.folder_id = dup.id
          file.save_without_broadcasting!
        when Folder
          sub = item.clone_for(context, nil, options)
          sub.parent_folder_id = dup.id
          sub.save!
        end
      end
    end
    dup.updated_at = Time.now
    dup.clone_updated = true
    dup
  end

  def root_folder?
    !parent_folder_id
  end

  def self.root_folder_name_for_context(context)
    case context
    when Course
      ROOT_FOLDER_NAME
    when User
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
        root_folder = context.folders.active.where(parent_folder_id: nil, name:).first
        root_folder ||= GuardRail.activate(:primary) { context.folders.create!(name:, full_name: name, workflow_state: "visible") }
        root_folders = [root_folder]
      end
    end

    root_folders
  end

  def self.unique_folder(context, unique_type, default_name_proc)
    folder = nil
    context.shard.activate do
      Folder.unique_constraint_retry do
        folder = context.folders.active.where(unique_type:).take
        folder ||= context.folders.create!(unique_type:,
                                           name: default_name_proc.call,
                                           parent_folder_id: Folder.root_folders(context).first,
                                           workflow_state: "hidden")
      end
    end
    folder
  end

  def self.icon_maker_folder(context)
    unique_folder(context, ICON_MAKER_UNIQUE_TYPE, -> { t("Icon Maker Icons") })
  end

  MEDIA_TYPE = "media"
  def self.media_folder(context)
    unique_folder(context, MEDIA_TYPE, -> { t("Uploaded Media") })
  end

  def self.is_locked?(folder_id)
    RequestCache.cache("folder_is_locked", folder_id) do
      folder = Folder.where(id: folder_id).first
      folder&.locked?
    end
  end

  def attachments
    file_attachments
  end

  # if a block is given, it'll be called with each new folder created by this
  # method before the folder is saved
  def self.assert_path(path, context, conditions: {})
    @@path_lookups ||= {}
    key = [context.global_asset_string, path].join("//")
    return @@path_lookups[key] if @@path_lookups[key]

    folders = path.split("/").reject(&:empty?)
    @@root_folders ||= {}
    current_folder = (@@root_folders[context.global_asset_string] ||= Folder.root_folders(context).first)
    if folders[0] == current_folder.name
      folders.shift
    end
    folders.each do |name|
      sub_folder = @@path_lookups[[context.global_asset_string, current_folder.full_name + "/" + name].join("//")]
      sub_folder ||= current_folder.sub_folders.active.where({ name: }.merge(conditions)).first_or_initialize
      current_folder = sub_folder
      if current_folder.new_record?
        current_folder.context = context
        yield current_folder if block_given?
        current_folder.save!
      end
      @@path_lookups[[context.global_asset_string, current_folder.full_name].join("//")] ||= current_folder
    end
    @@path_lookups[key] = current_folder
  end

  def self.reset_path_lookups!
    @@root_folders = {}
    @@path_lookups = {}
  end

  def self.unfiled_folder(context)
    folder = context.folders.where(parent_folder_id: Folder.root_folders(context).first, workflow_state: "visible", name: "unfiled").first
    unless folder
      folder = context.folders.build(parent_folder: Folder.root_folders(context).first, name: "unfiled")
      folder.workflow_state = "visible"
      folder.save!
    end
    folder
  end

  def self.find_attachment_in_context_with_path(context, path)
    components = path.split("/")
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
      atts = visible_file_attachments.to_a
      return atts.detect { |a| Attachment.matches_name?(a.display_name, component) } || atts.detect { |a| Attachment.matches_name?(a.filename, component) }
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
    path_components = case path
                      when Array
                        path
                      when String
                        path.split("/")
                      else
                        []
                      end

    Folder.root_folders(context).each do |root_folder|
      folders = root_folder.get_folders_by_component(path_components, include_hidden_and_locked)
      return folders if folders
    end
    nil
  end

  def locked?
    return @locked if defined?(@locked)

    @locked = locked ||
              (lock_at && Time.zone.now > lock_at) ||
              (unlock_at && Time.zone.now < unlock_at) ||
              parent_folder&.locked?
  end

  def for_student_annotation_documents?
    unique_type == Folder::STUDENT_ANNOTATION_DOCUMENTS_UNIQUE_TYPE
  end

  def for_submissions?
    !submission_context_code.nil?
  end

  def currently_locked
    locked || (lock_at && Time.zone.now > lock_at) || (unlock_at && Time.zone.now < unlock_at) || self.workflow_state == "hidden"
  end

  alias_method :currently_locked?, :currently_locked

  set_policy do
    given { |user, session| visible? && context.grants_right?(user, session, :read_files) }
    can :read

    given { |user, session| context.grants_right?(user, session, :read_as_admin) }
    can :read_as_admin, :read_contents, :read_contents_for_export

    given do |user, session|
      visible? && !locked? && context.grants_right?(user, session, :read_files) &&
        !(context.is_a?(Course) && context.tab_hidden?(Course::TAB_FILES))
    end
    can :read_contents

    given do |user, session|
      !locked? && context.grants_right?(user, session, :read_files)
    end
    can :read_contents_for_export

    given do |user, session|
      context.grants_any_right?(user, session, :manage_files_add, :manage_files_delete, :manage_files_edit)
    end
    can :read and can :read_contents

    given do |user, session|
      !for_submissions? && context.grants_right?(user, session, :manage_files_add)
    end
    can :create and can :manage_contents

    given do |user, session|
      !for_submissions? && context.grants_right?(user, session, :manage_files_edit)
    end
    can :update and can :manage_contents

    given do |user, session|
      !for_submissions? && context.grants_right?(user, session, :manage_files_delete)
    end
    can :delete and can :manage_contents
  end

  # find all unlocked/visible folders that can be reached by following unlocked/visible folders from the root
  def self.all_visible_folder_ids(context)
    folder_tree = context.active_folders.not_hidden.not_locked.pluck(:id, :parent_folder_id).each_with_object({}) do |row, folders|
      id, parent_folder_id = row
      folders[parent_folder_id] ||= []
      folders[parent_folder_id] << id
    end
    visible_ids = []
    dir_contents = Folder.root_folders(context).map(&:id)
    find_visible_folders(visible_ids, folder_tree, dir_contents)
    visible_ids
  end

  def self.from_context_or_id(context, id)
    root_folders(context).first || where(id:).first || (raise ActiveRecord::RecordNotFound)
  end

  def self.find_visible_folders(visible_ids, folder_tree, dir_contents)
    visible_ids.concat dir_contents
    dir_contents.each do |child_folder_id|
      next unless folder_tree[child_folder_id].present?

      find_visible_folders(visible_ids, folder_tree, folder_tree[child_folder_id])
    end
    nil
  end
  private_class_method :find_visible_folders

  def clear_permissions_cache
    GuardRail.activate(:primary) do
      delay_if_production(singleton: "clear_downstream_permissions_#{global_id}").clear_downstream_permissions
      next_clear_cache = next_lock_change
      if next_clear_cache.present? && next_clear_cache < (Time.zone.now + AdheresToPolicy::Cache::CACHE_EXPIRES_IN)
        delay(run_at: next_clear_cache, singleton: "clear_permissions_cache_#{global_id}").clear_permissions_cache
      end
    end
  end

  def clear_downstream_permissions
    active_file_attachments.touch_all
    active_sub_folders.each(&:clear_permissions_cache)
  end

  def next_lock_change
    [lock_at, unlock_at].compact.select { |t| t > Time.zone.now }.min
  end

  def restore
    return unless self.workflow_state == "deleted"

    self.workflow_state = "visible"
    if save
      parent_folder&.restore
    end
  end
end
