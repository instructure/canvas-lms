#
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
  attr_accessible :user, :title, :description
  attr_readonly :collaboration_type
  include Workflow
  include SendToStream
  belongs_to :user
  has_many :collaborators, :dependent => :destroy
  has_many :groups, :through => :collaborators
  has_many :users,  :through => :collaborators
  belongs_to :context, :polymorphic => true
  
  before_save :generate_document
  before_save :assign_uuid
  before_save :set_context_code
  after_save :include_author_as_collaborator
  after_save :touch_context
  validates_length_of :description, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  
  serialize :data
  
  before_destroy :destroy_collaborators
  

  workflow do
    state :active
    state :deleted
  end
  
  on_create_send_to_streams do
    [self.user_id] + self.collaborators.map(&:user_id)
  end
  
  def include_author_as_collaborator
    c = Collaborator.find_by_user_id_and_collaboration_id(self.user_id, self.id)
    unless c
      c = Collaborator.new(:collaboration => self)
      c.user_id = self.user_id
      c.save
    end
  end
  
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now
    save!
  end
  
  def restore
    self.workflow_state = 'active'
    self.save
  end
  
  def style_class
    nil
  end
  
  def self.collaboration_class(type)
    found_config = Collaboration.collaboration_types.find{|c| c['type'].titleize.gsub(/\s/, "") == type }
    klass = found_config && "#{type}Collaboration".constantize rescue nil
    klass = nil unless klass && klass.ancestors.include?(Collaboration) && klass.config
    klass
  end
  
  
  def self.typed_collaboration_instance(type)
    found_config = Collaboration.collaboration_types.find{|c| c['name'] == type }
    klass = found_config && collaboration_class(found_config['type'].titleize.gsub(/\s/, "")) rescue nil
    if klass && klass.ancestors.include?(Collaboration) && klass.config 
      res = klass.new
      res.collaboration_type = found_config['name']
      res
    else
      raise "Unrecognized collaboration type: #{type}"
    end
  end
  
  named_scope :for_context_codes, lambda { |context_codes| { 
    :conditions => {:context_code => context_codes} } 
  }
  
  named_scope :active, lambda{
    {:conditions => ['collaborations.workflow_state != ?', 'deleted']}
  }
  
  set_policy do
    given {|user, session| !self.new_record? && (self.user_id == user.id || self.users.include?(user)) }
    can :read
    
    given {|user, session| self.cached_context_grants_right?(user, session, :create_collaborations) }
    can :create
    
    given {|user, session| self.cached_context_grants_right?(user, session, :manage_content) }
    can :read and can :update and can :delete
    
    given {|user, session| user && self.user_id == user.id && self.cached_context_grants_right?(user, session, :create_collaborations) }
    can :read and can :update and can :delete
  end
  
  def assign_uuid
    self.uuid ||= AutoHandle.generate_securish_uuid
  end
  protected :assign_uuid
  
  def set_context_code
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
  end
  protected :set_context_code
  
  def destroy_collaborators
    self.collaborators.each do |c|
      c.destroy
    end
  end
  protected :destroy_collaborators
  
  def collaborator_ids
    self.collaborators.map(&:user_id).join(',')
  end
  
  def title
    read_attribute(:title) || (self.parse_data.title rescue nil) || t('#collaboration.default_title', "Unnamed Collaboration")
  end
  
  def service_name
    "Collaboration"
  end
  
  def delete_document
  end
  
  def initialize_document
  end
  
  def generate_document
    self.assign_uuid
    initialize_document
  end
  
  def user_can_access_document_type?(user)
    true
  end
  
  def valid_user?(user)
    return false unless self.grants_right?(user, nil, :read)
    user_can_access_document_type?(user)
  end
  
  def authorize_user(user)
  end
  
  def remove_users_from_document(users_to_remove)
  end
  
  def add_users_to_document(users_to_add)
  end

  def collaboration_users=(users)
    self.save
    generate_document
    users_to_remove = self.users - users
    remove_users_from_document(users_to_remove)
    self.collaborators.select{|c| !users.include?(c.user)}.each{|c|
      c.destroy 
    }
    new_users = users - self.users
    add_users_to_document(new_users)
    new_users.each do |u|
      self.collaborators.create(:user => u, :authorized_service_user_id => u.gmail)
    end

    self.save
    self.users
  end

  # Public: Update user and group collaborators for this collaboration.
  #   Any previous users and groups not included in this 
  #
  # users - An array of users to include as collaborators.
  # group_ids - An array of group ids to include as collaborators.
  #
  # Returns nothing.
  def update_members(users = [], group_ids = [])
    save if new_record?
    generate_document
    update_user_collaborators(users)
    update_group_collaborators(group_ids)
    group_users_to_add = User.all(:select => 'DISTINCT users.*',
      :joins => :group_memberships,
      :include => :communication_channels,
      :conditions => { 'group_memberships.group_id' => group_ids })
    add_users_to_document((users + group_users_to_add).uniq)
  end

  # Internal: Delete existing collaborating users and add new ones.
  #
  # users - The array of users to add. Any duplicates with current users
  #         will not be removed or re-added.
  #
  # Returns nothing.
  def update_user_collaborators(users)
    users_to_remove = User.all(:select => 'DISTINCT users.*',
      :joins => 'LEFT JOIN group_memberships ON users.id = group_memberships.user_id
                 RIGHT JOIN collaborators ON users.id = collaborators.user_id',
      :conditions => ['collaborators.collaboration_id = ? OR
                       group_memberships.group_id IN (?)', self.id, self.groups.map(&:id)])
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
      Collaborator.destroy_all(['group_id IS NOT NULL AND
                                 collaboration_id = ?', self.id])
    else
      Collaborator.destroy_all(['group_id IS NOT NULL AND
                                 group_id NOT IN (?) AND
                                 collaboration_id = ?',
                                 group_ids, self.id])
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
      Collaborator.destroy_all(['user_id IS NOT NULL AND
                                 collaboration_id = ?', self.id])
    else
      Collaborator.destroy_all(['user_id IS NOT NULL AND
                                 user_id NOT IN (?) AND
                                 collaboration_id = ?',
                                 users.map(&:id), self.id])
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
      existing_groups = collaborators.scoped(:select => 'group_id',
        :conditions => { :group_id => group_ids }).map(&:group_id)
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
      existing_users = collaborators.scoped(:select => 'user_id',
        :conditions => { :user_id => users.map(&:id) }).map(&:user_id)
      users.select { |u| !existing_users.include?(u) }.each do |u|
        collaborators.create(:user => u, :authorized_service_user_id => u.gmail)
      end
    end
  end
  protected :add_users_to_collaborators

  def parse_data
    nil
  end
  
  def self.collaboration_types
    Canvas::Plugin.all_for_tag(:collaborations).find_all(&:enabled?).map do |x|
      {'name' => x.name, 'type' => x.id}
    end
  end
  
  def self.any_collaborations_configured?
    collaboration_types.any? do |type|
      collaboration_class(type['type'].titleize.gsub(/\s/, "")) rescue false
    end
  end
  
  def config
    raise "not implemented"
  end
  
  named_scope :after, lambda{|date|
    {:conditions => ['collaborations.updated_at > ?', date]}
  }
  
  def self.serialization_excludes; [:uuid]; end
end
