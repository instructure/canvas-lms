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

class Collaboration < ActiveRecord::Base
  include Workflow
  include SendToStream

  DEEP_LINKING_EXTENSION = "https://canvas.instructure.com/lti/collaboration"

  attr_readonly :collaboration_type

  belongs_to :context, polymorphic: [:course, :group]
  belongs_to :user
  has_many :collaborators, dependent: :destroy
  has_many :users, through: :collaborators

  before_destroy { |record| Collaborator.where(collaboration_id: record).destroy_all }

  before_save :assign_uuid
  before_save :set_context_code

  after_save :include_author_as_collaborator
  after_save :touch_context
  after_commit :generate_document, on: :create

  TITLE_MAX_LENGTH = 255
  validates :title, :workflow_state, :context_id, :context_type, presence: true
  validates :title, length: { maximum: TITLE_MAX_LENGTH }
  validates :description, length: { maximum: maximum_text_length, allow_blank: true }

  serialize :data

  alias_method :destroy_permanently!, :destroy

  workflow do
    state :active
    state :deleted
  end

  on_create_send_to_streams do
    [user_id] + collaborators.map(&:user_id)
  end

  set_policy do
    given do |user|
      user &&
        !new_record? &&
        (user_id == user.id ||
         users.include?(user) ||
         Collaborator
             .joins("INNER JOIN #{GroupMembership.quoted_table_name} ON collaborators.group_id = group_memberships.group_id AND group_memberships.workflow_state <> 'deleted'")
             .where('collaborators.group_id IS NOT NULL AND
                            group_memberships.user_id = ? AND
                            collaborators.collaboration_id = ?',
                    user,
                    self).exists?)
    end
    can :read

    given { |user, session| context.grants_right?(user, session, :create_collaborations) }
    can :create

    #################### Begin legacy permission block #########################
    given do |user, session|
      user && !context.root_account.feature_enabled?(:granular_permissions_manage_course_content) &&
        context.grants_right?(user, session, :manage_content)
    end
    can :read and can :update and can :delete
    ##################### End legacy permission block ##########################

    given do |user, session|
      user && context.root_account.feature_enabled?(:granular_permissions_manage_course_content) &&
        context.grants_right?(user, session, :manage_course_content_edit)
    end
    can :read and can :update

    given do |user, session|
      user && context.root_account.feature_enabled?(:granular_permissions_manage_course_content) &&
        context.grants_right?(user, session, :manage_course_content_delete)
    end
    can :read and can :delete

    given do |user, session|
      user && user_id == user.id &&
        context.grants_right?(user, session, :create_collaborations)
    end
    can :read and can :update and can :delete
  end

  scope :active, -> { where("collaborations.workflow_state<>'deleted'") }

  scope :after, ->(date) { where("collaborations.updated_at>?", date) }

  scope :for_context_codes, ->(context_codes) { where(context_code: context_codes) }
  scope :for_context, ->(context) { where(context_type: context.class.reflection_type_name, context_id: context) }

  # These methods should be implemented in child classes.

  def service_name
    "Collaboration"
  end

  def delete_document; end

  def initialize_document; end

  def user_can_access_document_type?(_user)
    true
  end

  def authorize_user(user); end

  # def remove_users_from_document(users_to_remove); end

  # def add_users_to_document(users_to_add); end

  def config
    raise NotImplementedError
  end

  def parse_data
    nil
  end

  # Public: Find the class of for the given type.
  #
  # type - The string name of the collaboration type (e.g. 'GoogleDocs' or 'EtherPad').
  #
  # Returns a class or nil.
  def self.collaboration_class(type)
    if (klass = "#{type}Collaboration".constantize)
      (klass.ancestors.include?(Collaboration) && klass.config) ? klass : nil
    end
  rescue NameError
    nil
  end

  # Public: Create a new collaboration of the given type.
  #
  # name - The string name of the collaboration type.
  #
  # Returns a collaboration instance or raises an exception if type unknown.
  def self.typed_collaboration_instance(name)
    class_config = Collaboration.collaboration_types.find { |c| c["name"] == name }
    raise InvalidCollaborationType unless class_config

    klass = collaboration_class(class_config["type"].titleize.gsub(/\s/, ""))

    if klass
      collaboration = klass.new
      collaboration.collaboration_type = class_config["name"]
    else
      raise "Unrecognized collaboration type #{type}."
    end

    collaboration
  end

  # Public: Find the available collaboration types.
  #
  # Returns an array of type hashes w/ 'name' and 'type' keys.
  def self.collaboration_types
    Canvas::Plugin.all_for_tag(:collaborations).select(&:enabled?).map do |plugin|
      # google_drive is really a google_docs_collaboration
      # eventually this will go away. baby steps...
      if plugin.id == "google_drive"
        type = "google_docs"
        name = "Google Docs"
      else
        type = plugin.id
        name = plugin.name
      end

      ActiveSupport::HashWithIndifferentAccess.new({ "name" => name, "type" => type })
    end
  end

  # Public: Determine if any collaborations plugin is enabled.
  #
  # Returns true/false.
  def self.any_collaborations_configured?(context)
    plugin_collabs = collaboration_types.any? do |type|
      collaboration_class(type["type"].titleize.gsub(/\s/, "")).present?
    end
    external_tool_collabs =
      Lti::ContextToolFinder.all_tools_scope_union(context, placements: :collaboration).exists?
    plugin_collabs || external_tool_collabs
  end

  # Public: Declare excluded serialization fields.
  #
  # Returns an array.
  def self.serialization_excludes
    [:uuid]
  end

  # Public: Soft-delete this collaboration.
  #
  # Returns true.
  def destroy
    self.workflow_state = "deleted"
    self.deleted_at     = Time.now

    save!
  end

  # Public: Un-delete this collaboration.
  #
  # Returns a success boolean.
  def restore
    update_attribute(:workflow_state, "active")
  end

  # Internal: Add the author of the collaboration to its collaborators.
  #
  # Returns nothing.
  def include_author_as_collaborator
    return unless user.present?

    author = collaborators.where(user_id:).first

    unless author
      collaborator = Collaborator.new(collaboration: self)
      collaborator.user_id = user_id
      collaborator.authorized_service_user_id = authorized_service_user_id_for(user)
      collaborator.save
    end
  end

  # Public: Create a CSS style string.
  #
  # NOTE: I assume this is for compatibility w/ something in Canvas' bowels,
  # but it may not be needed anymore.
  #
  # Returns nil.
  def style_class
    nil
  end

  # Public: Create a list of collaborator IDs.
  #
  # Returns a comma-seperated list of collaborator user IDs.
  def collaborator_ids
    collaborators.pluck(:user_id).join(",")
  end

  # Internal: Create the collaboration document in the remote service.
  #
  # Returns nothing.
  def generate_document
    return if @generated

    @generated = true
    assign_uuid
    initialize_document
    save!
  end

  # Public: Determine if a given user can access this collaboration.
  #
  # user - The user to test.
  #
  # Returns a boolean.
  def valid_user?(user)
    if grants_right?(user, nil, :read)
      user_can_access_document_type?(user)
    else
      false
    end
  end

  # Public: Update user and group collaborators for this collaboration.
  #
  # Any current collaborators not passed to this method will be destroyed.
  #
  # users     - An array of users to include as collaborators.
  # groups    - An array of groups or group ids to include as collaborators.
  #
  # Returns nothing.
  def update_members(users = [], groups = [])
    group_ids = groups.map { |g| g.try(:id) || g }
    save! if new_record?
    generate_document
    users << user if user.present? && !users.include?(user)
    update_user_collaborators(users)
    update_group_collaborators(group_ids)
    if respond_to?(:add_users_to_document)
      group_users_to_add = User
                           .distinct
                           .joins(:group_memberships)
                           .where("group_memberships.group_id" => group_ids).to_a
      add_users_to_document((users + group_users_to_add).uniq)
    end
  end

  # Internal: Create a new UUID for this collaboration if one does not exist.
  #
  # Returns a UUID string.
  def assign_uuid
    self.uuid ||= CanvasSlug.generate_securish_uuid
  end
  protected :assign_uuid

  # Internal: Set the context code for this collaboration.
  #
  # Returns a context code.
  def set_context_code
    self.context_code = "#{context_type.underscore}_#{context_id}"
  rescue NoMethodError
    nil
  end
  protected :set_context_code

  # Internal: Delete existing collaborating users and add new ones.
  #
  # users - The array of users to add. Any duplicates with current users
  #         will not be removed or re-added.
  #
  # Returns nothing.
  def update_user_collaborators(users)
    if respond_to?(:remove_users_from_document)
      # need to get everyone added to the document, cause we're going to re-add them all
      users_to_remove = collaborators.where.not(user_id: nil).pluck(:user_id)
      group_ids = collaborators.where.not(group_id: nil).pluck(:group_id)
      unless group_ids.empty?
        users_to_remove += GroupMembership.where(group_id: group_ids).distinct.pluck(:user_id)
        users_to_remove.uniq!
      end
      # make real user objects, instead of just ids, cause that's what this code expects
      users_to_remove.reject! { |id| id == user.id }
      users_to_remove = users_to_remove.map { |id| User.send(:instantiate, "id" => id) }
      remove_users_from_document(users_to_remove)
    end
    remove_users_from_collaborators(users)
    add_users_to_collaborators(users)
  end
  protected :update_user_collaborators

  # Internal: Remove old group collaborators and add new ones.
  #
  # group_ids - An array of IDs for groups to be added. Any duplicates w/
  #            existing groups will not be deleted/added.
  def update_group_collaborators(group_ids)
    remove_groups_from_collaborators(group_ids)
    add_groups_to_collaborators(group_ids)
  end
  protected :update_group_collaborators

  # Internal: Delete groups no longer being collaborated with.
  #
  # group_ids - An array of group IDs that will be used as collaborators.
  #
  # Returns nothing.
  def remove_groups_from_collaborators(group_ids)
    collaborators.where.not(group_id: group_ids.presence).delete_all
  end
  protected :remove_groups_from_collaborators

  # Internal: Delete users no longer being collaborated with.
  #
  # users - An array of users that will be used as collaborators.
  #
  # Returns nothing.
  def remove_users_from_collaborators(users)
    collaborators.where.not(user_id: users.presence).delete_all
  end
  protected :remove_users_from_collaborators

  # Internal: Update collaborators with the given groups.
  #
  # group_ids - An array of group IDs to add as collaborators.
  #
  # Returns nothing.
  def add_groups_to_collaborators(group_ids)
    return unless context.respond_to?(:groups)

    unless group_ids.empty?
      existing_groups = collaborators.where(group_id: group_ids).select(:group_id)
      context.groups.where(id: group_ids).where.not(id: existing_groups).each do |g|
        collaborator = collaborators.build
        collaborator.group_id = g
        collaborator.save
      end
    end
  end
  private :add_groups_to_collaborators

  # Internal: Update collaborators with the given groups.
  #
  # users - An array of users to add as collaborators.
  #
  # Returns nothing.
  def add_users_to_collaborators(users)
    unless users.empty?
      existing_users = collaborators.where(user_id: users).select(:user_id)
      context.potential_collaborators.where(id: users).where.not(id: existing_users).each do |u|
        collaborators.create(user: u, authorized_service_user_id: authorized_service_user_id_for(u))
      end
    end
  end
  private :add_users_to_collaborators

  class InvalidCollaborationType < StandardError; end
  protected

  # Internal: Get the authorized_service_user_id for a user.
  # May be overridden by other collaboration types.
  def authorized_service_user_id_for(user)
    user.gmail
  end
end
