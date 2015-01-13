#
# Copyright (C) 2012 - 2013 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Fr
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

class Role < ActiveRecord::Base
  NULL_ROLE_TYPE = "NoPermissions"

  ENROLLMENT_TYPES = ["StudentEnrollment", "TeacherEnrollment", "TaEnrollment", "DesignerEnrollment", "ObserverEnrollment"]

  DEFAULT_ACCOUNT_TYPE = 'AccountMembership'
  ACCOUNT_TYPES = ['AccountAdmin', 'AccountMembership']

  BASE_TYPES = (ACCOUNT_TYPES + ENROLLMENT_TYPES + [NULL_ROLE_TYPE]).freeze
  KNOWN_TYPES = (BASE_TYPES +
    ['StudentViewEnrollment',
     'TeacherlessStudentEnrollment',
     'NilEnrollment',
     'teacher', 'ta', 'designer', 'student', 'observer'
    ]).freeze

  module AssociationHelper
    # this is an override to take advantage of built-in role caching since those are by far the most common
    def role
      self.association(:role).target ||= self.shard.activate do
        Role.get_role_by_id(read_attribute(:role_id)) || (self.respond_to?(:default_role) && self.default_role)
      end
      super
    end
  end

  belongs_to :account
  belongs_to :root_account, :class_name => 'Account'
  attr_accessible :name

  EXPORTABLE_ATTRIBUTES = [:id, :name, :base_role_type, :account_id, :workflow_state, :created_at, :updated_at, :deleted_at, :root_account_id]
  EXPORTABLE_ASSOCIATIONS = [:account, :root_account]

  before_validation :infer_root_account_id, :if => :belongs_to_account?

  validate :ensure_unique_name_for_account, :if => :belongs_to_account?
  validates_presence_of :name, :workflow_state
  validates_presence_of :account_id, :if => :belongs_to_account?

  validates_inclusion_of :base_role_type, :in => BASE_TYPES, :message => 'is invalid'
  validates_exclusion_of :name, :in => KNOWN_TYPES, :unless => :built_in?, :message => 'is reserved'
  validate :ensure_non_built_in_name

  def id
    if self.built_in? && self.shard != Shard.current && role = Role.get_built_in_role(self.name, Shard.current)
      role.read_attribute(:id)
    else
      super
    end
  end

  def ensure_unique_name_for_account
    if self.active?
      scope = Role.where("name = ? AND account_id = ? AND workflow_state = ?", self.name, self.account_id, 'active')
      if self.new_record? ? scope.exists? : scope.where("id <> ?", self.id).exists?
        self.errors.add(:label, t(:duplicate_role, 'A role with this name already exists'))
        return false
      end
    end
  end

  def ensure_non_built_in_name
    if !self.built_in? && Role.built_in_roles.map(&:label).include?(self.name)
      self.errors.add(:label, t(:duplicate_role, 'A role with this name already exists'))
      return false
    end
  end

  def infer_root_account_id
    unless self.account
      self.errors.add(:account_id)
      return false
    end
    self.root_account_id = self.account.root_account_id || self.account.id
  end

  include Workflow
  workflow do
    state :active do
      event :deactivate, :transitions_to => :inactive
    end
    state :inactive do
      event :activate, :transitions_to => :active
    end
    state :built_in # for previously built-in roles
    state :deleted
  end

  def belongs_to_account?
    !built_in? && !deleted?
  end

  def self.ensure_built_in_roles!
    unless built_in_roles(true).count == BASE_TYPES.count
      BASE_TYPES.each do |base_type|
        role = Role.new
        role.name = base_type
        role.base_role_type = base_type
        role.workflow_state = :built_in
        role.save!
      end
      built_in_roles(true)
    end
  end

  def self.built_in_roles(reload=false, shard=Shard.current)
    @built_in_roles ||= {}
    if @built_in_roles[shard.id].blank? || reload
      @built_in_roles[shard.id] = shard.activate { Role.where(:workflow_state => 'built_in').to_a }
    end
    @built_in_roles[shard.id]
  end

  def self.built_in_roles_by_id(reload=false, shard=Shard.current)
    @built_in_roles_by_id ||= {}
    @built_in_roles_by_id[shard.id] ||= built_in_roles(reload, shard).index_by(&:id)
  end

  def self.built_in_course_roles
    built_in_roles.select{|role| role.course_role?}
  end

  def self.built_in_account_roles
    built_in_roles.select{|role| role.account_role?}
  end

  def self.visible_built_in_roles
    built_in_roles.select{|role| role.visible?}
  end

  def self.get_role_by_id(id)
    return nil unless id
    return nil if id.is_a?(String) && id !~ Api::ID_REGEX
    # most roles are going to be built in, so don't do a db search every time
    local_id, shard = Shard.local_id_for(id)
    shard ||= Shard.current
    role = built_in_roles_by_id(false, shard)[local_id] || Role.shard(shard).where(:id => local_id).first
    role
  end

  def self.get_built_in_role(name, shard=Shard.current)
    built_in_roles(false, shard).detect{|role| role.name == name}
  end

  def ==(other_role)
    if other_role.is_a?(Role) && self.built_in? && other_role.built_in?
      return self.name == other_role.name # be equivalent even if they're on different shards
    else
      super
    end
  end

  def visible?
    self.active? || (self.built_in? && !["AccountMembership", "NoPermissions"].include?(self.name))
  end

  def account_role?
    ACCOUNT_TYPES.include?(base_role_type)
  end

  def course_role?
    ENROLLMENT_TYPES.include?(base_role_type)
  end

  def label
    if self.built_in?
      if self.course_role?
        RoleOverride.enrollment_type_labels.detect{|label| label[:name] == self.name}[:label].call
      elsif self.name == 'AccountAdmin'
        RoleOverride::ACCOUNT_ADMIN_LABEL.call
      else
        self.name
      end
    else
      self.name
    end
  end

  # Should order course roles so we get "StudentEnrollment", custom student roles, "Teacher Enrollment", custom teacher roles, etc
  def display_sort_index
    if self.course_role?
      ENROLLMENT_TYPES.index(self.base_role_type) * 2 + (self.built_in? ? 0 : 1)
    else
      self.built_in? ? 0 : 1
    end
  end

  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now.utc
    save!
  end

  scope :not_deleted, -> { where("roles.workflow_state IN ('active', 'inactive')") }
  scope :deleted, -> { where(:workflow_state => 'deleted') }
  scope :active, -> { where(:workflow_state => 'active') }
  scope :inactive, -> { where(:workflow_state => 'inactive') }
  scope :for_courses, -> { where(:base_role_type => ENROLLMENT_TYPES) }
  scope :for_accounts, -> { where(:base_role_type => ACCOUNT_TYPES) }

  # Returns a list of hashes for each base enrollment type, and each will have a
  # custom_roles key, each will look like:
  # [{:base_role_name => "StudentEnrollment",
  #   :name => "StudentEnrollment",
  #   :label => "Student",
  #   :plural_label => "Students",
  #   :custom_roles =>
  #           [{:base_role_name => "StudentEnrollment",
  #             :name => "weirdstudent",
  #             :asset_string => "role_4"
  #             :label => "weirdstudent"}]},
  # ]
  def self.all_enrollment_roles_for_account(account, include_inactive=false)
    custom_roles = account.available_custom_course_roles(include_inactive)
    RoleOverride.enrollment_type_labels.map do |br|
      new = br.clone
      new[:id] = Role.get_built_in_role(br[:name]).id
      new[:label] = br[:label].call
      new[:plural_label] = br[:plural_label].call
      new[:custom_roles] = custom_roles.select{|cr|cr.base_role_type == new[:base_role_name]}.map do |cr|
        {:id => cr.id, :base_role_name => cr.base_role_type, :name => cr.name, :label => cr.name, :asset_string => cr.asset_string, :workflow_state => cr.workflow_state}
      end
      new
    end
  end

  # returns same hash as all_enrollment_roles_for_account but adds enrollment
  # counts for the given course to each item
  def self.custom_roles_and_counts_for_course(course, user, include_inactive=false)
    users_scope = course.users_visible_to(user)
    base_counts = users_scope.where('enrollments.role_id IS NULL OR enrollments.role_id IN (?)',
                                    Role.built_in_course_roles.map(&:id)).group('enrollments.type').select('users.id').uniq.count
    role_counts = users_scope.where('enrollments.role_id IS NOT NULL AND enrollments.role_id NOT IN (?)',
                                    Role.built_in_course_roles.map(&:id)).group('enrollments.role_id').select('users.id').uniq.count

    @enrollment_types = Role.all_enrollment_roles_for_account(course.account, include_inactive)
    @enrollment_types.each do |base_type|
      base_type[:count] = base_counts[base_type[:name]] || 0
      base_type[:custom_roles].each do |custom_role|
        custom_role[:count] = role_counts[custom_role[:id].to_s] || 0
      end
    end

    @enrollment_types
  end

  def self.manageable_roles_by_user(user, course)
    manageable = ['ObserverEnrollment', 'DesignerEnrollment']
    if course.grants_right?(user, :manage_students)
      manageable << 'StudentEnrollment'
    end
    if course.grants_right?(user, :manage_admin_users)
      manageable << 'TeacherEnrollment'
      manageable << 'TaEnrollment'
    elsif course.teacherless?
      manageable << 'TeacherEnrollment'
    end
    manageable.sort
  end

  def self.role_data(course, user, include_inactive=false)
    manageable = Role.manageable_roles_by_user(user, course)
    self.custom_roles_and_counts_for_course(course, user, include_inactive).inject([]) { |roles, role|
      is_manageable = manageable.include?(role[:base_role_name])
      role[:manageable_by_user] = is_manageable
      roles << role
      role[:custom_roles].each do |custom_role|
        custom_role[:manageable_by_user] = is_manageable
        roles << custom_role
      end
      roles
    }
  end
end
