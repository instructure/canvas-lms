
# Copyright (C) 2011-2012 Instructure, Inc.
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

  attr_accessible :user, :title, :description
  attr_readonly   :collaboration_type

  belongs_to :context, :polymorphic => true
  belongs_to :user

  has_many :collaborators, :dependent => :destroy
  has_many :groups, :through => :collaborators
  has_many :users,  :through => :collaborators

  before_destroy { |record| Collaborator.where(:collaboration_id => record).destroy_all }

  before_save :generate_document
  before_save :assign_uuid
  before_save :set_context_code

  after_save :include_author_as_collaborator
  after_save :touch_context

  validates_length_of :description, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true

  serialize :data

  alias_method :destroy!, :destroy

  workflow do
    state :active
    state :deleted
  end

  on_create_send_to_streams do
    [self.user_id] + self.collaborators.map(&:user_id)
  end

  set_policy do
    given { |user, session|
      !self.new_record? &&
        (self.user_id == user.id ||
         self.users.include?(user) ||
         Collaborator.
             joins('INNER JOIN group_memberships ON collaborators.group_id = group_memberships.group_id').
             where('collaborators.group_id IS NOT NULL AND
                            group_memberships.user_id = ? AND
                            collaborators.collaboration_id = ?', user, self).exists?)
    }
    can :read

    given { |user, session| self.cached_context_grants_right?(user, session, :create_collaborations) }
    can :create

    given { |user, session| self.cached_context_grants_right?(user, session, :manage_content) }
    can :read and can :update and can :delete

    given { |user, session|
      user && self.user_id == user.id &&
        self.cached_context_grants_right?(user, session, :create_collaborations) }
    can :read and can :update and can :delete
  end

  scope :active, where("collaborations.workflow_state<>'deleted'")

  scope :after, lambda { |date| where("collaborations.updated_at>?", date) }

  scope :for_context_codes, lambda { |context_codes| where(:context_code => context_codes) }

  # These methods should be implemented in child classes.

  def service_name; 'Collaboration'; end

  def delete_document; end

  def initialize_document; end

  def user_can_access_document_type?(user); true; end

  def authorize_user(user); end

  def remove_users_from_document(users_to_remove); end

  def add_users_to_document(users_to_add); end

  def config; raise 'Not implemented'; end

  def parse_data; nil; end

  # Public: Find the class of for the given type.
  #
  # type - The string name of the collaboration type (e.g. 'GoogleDocs' or 'EtherPad').
  #
  # Returns a class or nil.
  def self.collaboration_class(type)
    config_exists = Collaboration.collaboration_types.map { |collaboration|
      collaboration['type'].titleize.gsub(/\s/, '')
    }.include?(type)

    if config_exists && klass = "#{type}Collaboration".constantize
      klass.ancestors.include?(Collaboration) && klass.config ? klass : nil
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
    class_config = Collaboration.collaboration_types.find { |c| c['name'] == name }
    klass        = collaboration_class(class_config['type'].titleize.gsub(/\s/, ''))

    if klass
      collaboration = klass.new
      collaboration.collaboration_type = class_config['name']
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
      HashWithIndifferentAccess.new({ 'name' => plugin.name, 'type' => plugin.id })
    end
  end

  # Public: Determine if any collaborations plugin is enabled.
  #
  # Returns true/false.
  def self.any_collaborations_configured?
    collaboration_types.any? do |type|
      collaboration_class(type['type'].titleize.gsub(/\s/, '')).present?
    end
  end

  # Public: Declare excluded serialization fields.
  #
  # Returns an array.
  def self.serialization_excludes; [:uuid]; end

  # Public: Soft-delete this collaboration.
  #
  # Returns true.
  def destroy
    self.workflow_state = 'deleted'
    self.deleted_at     = Time.now

    save!
  end

  # Public: Un-delete this collaboration.
  #
  # Returns a success boolean.
  def restore
    update_attribute(:workflow_state, 'active')
  end

  # Internal: Add the author of the collaboration to its collaborators.
  #
  # Returns nothing.
  def include_author_as_collaborator
    author = collaborators.where(:user_id => self.user_id).first

    unless author
      collaborator = Collaborator.new(:collaboration => self)
      collaborator.user_id = self.user_id
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
    self.collaborators.pluck(:user_id).join(',')
  end

  # Public: Return the title for this collaboration.
  #
  # Returns a title string.
  def title
    read_attribute(:title) || self.parse_data.title
  rescue NoMethodError
    t('#collaboration.default_title', 'Unnamed Collaboration')
  end

  # Internal: Create the collaboration document in the remote service.
  #
  # Returns nothing.
  def generate_document
    assign_uuid
    initialize_document
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
  # group_ids - An array of group ids to include as collaborators.
  #
  # Returns nothing.
  def update_members(users = [], group_ids = [])
    save if new_record?
    generate_document
    users << user if user.present? && !users.include?(user)
    update_user_collaborators(users)
    update_group_collaborators(group_ids)
    group_users_to_add = User.
        uniq.
        joins(:group_memberships).
        includes(:communication_channels).
        where('group_memberships.group_id' => group_ids).all
    add_users_to_document((users + group_users_to_add).uniq)
  end

  # Internal: Create a new UUID for this collaboration if one does not exist.
  #
  # Returns a UUID string.
  def assign_uuid
    self.uuid ||= AutoHandle.generate_securish_uuid
  end
  protected :assign_uuid

  # Internal: Set the context code for this collaboration.
  #
  # Returns a context code.
  def set_context_code
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}"
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
    users_to_remove = User.
        uniq.
        joins('LEFT JOIN group_memberships ON users.id = group_memberships.user_id
               RIGHT JOIN collaborators ON users.id = collaborators.user_id').
        where('collaborators.collaboration_id = ? OR
               group_memberships.group_id IN (?)', self, self.groups).all
    remove_users_from_document(users_to_remove)
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
    if group_ids.empty?
      Collaborator.where('group_id IS NOT NULL AND
                                 collaboration_id=?', self).destroy_all
    else
      Collaborator.where('group_id IS NOT NULL AND
                                 group_id NOT IN (?) AND
                                 collaboration_id=?',
                                 group_ids, self).destroy_all
    end
  end
  protected :remove_groups_from_collaborators

  # Internal: Delete users no longer being collaborated with.
  #
  # users - An array of users that will be used as collaborators.
  #
  # Returns nothing.
  def remove_users_from_collaborators(users)
    if users.empty?
      Collaborator.where('user_id IS NOT NULL AND
                                 collaboration_id = ?', self).destroy_all
    else
      Collaborator.where('user_id IS NOT NULL AND
                                 user_id NOT IN (?) AND
                                 collaboration_id = ?',
                                 users, self).destroy_all
    end
  end
  protected :remove_users_from_collaborators

  # Internal: Update collaborators with the given groups.
  #
  # group_ids - An array of group IDs to add as collaborators.
  #
  # Returns nothing.
  def add_groups_to_collaborators(group_ids)
    if group_ids.length > 0
      existing_groups = collaborators.where(:group_id => group_ids).pluck(:group_id)
      (group_ids - existing_groups).each do |g|
        collaborator = collaborators.build
        collaborator.group_id = g
        collaborator.save
      end
    end
  end
  protected :add_groups_to_collaborators

  # Internal: Update collaborators with the given groups.
  #
  # users - An array of users to add as collaborators.
  #
  # Returns nothing.
  def add_users_to_collaborators(users)
    if users.length > 0
      existing_users = collaborators.where(:user_id => users).pluck(:user_id)
      users.select { |u| !existing_users.include?(u.id) }.each do |u|
        collaborators.create(:user => u, :authorized_service_user_id => u.gmail)
      end
    end
  end
  protected :add_users_to_collaborators
end
