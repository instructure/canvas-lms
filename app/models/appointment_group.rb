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

class AppointmentGroup < ActiveRecord::Base
  include Workflow
  include TextHelper

  has_many :appointments, opts = {:class_name => 'CalendarEvent', :as => :context, :order => :start_at, :include => :child_events, :conditions => "calendar_events.workflow_state <> 'deleted'"}
  # has_many :through on the same table does not alias columns in condition
  # strings, just hashes. we create this helper association to ensure
  # appointments_participants conditions have the correct table alias
  has_many :_appointments, opts.merge(:conditions => opts[:conditions].gsub(/calendar_events\./, 'calendar_events_join.'))
  has_many :appointments_participants, :through => :_appointments, :source => :child_events, :conditions => "calendar_events.workflow_state <> 'deleted'", :order => :start_at
  belongs_to :context, :polymorphic => true
  alias_method :effective_context, :context
  belongs_to :sub_context, :polymorphic => true

  before_validation :default_values
  before_save :update_cached_values
  after_save :update_appointments

  validates_length_of :title, :maximum => maximum_string_length
  validates_length_of :description, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validates_presence_of :context
  validates_inclusion_of :participant_visibility, :in => ['private', 'protected'] # presumably we might add public if we decide to show appointments on the public calendar feed
  validates_each :sub_context do |record, attr, value|
    if record.participant_type == 'User'
      record.errors.add(attr, t('errors.invalid_course_section', 'Invalid course section')) unless value.blank? || value.is_a?(CourseSection) && value.course == record.context
    else
      record.errors.add(attr, t('errors.missing_group_category', 'Group appointments must have a group category')) unless value.present? && value.is_a?(GroupCategory)
      record.errors.add(attr, t('errors.invalid_group_category', 'Invalid group category')) unless value && value.context == record.context
    end
  end
  validates_each :appointments do |record, attr, value|
    next unless record.new_appointments.present? || record.validation_event_override
    appointments = value
    if record.validation_event_override
      appointments = appointments.select{ |a| a.new_record? || a.id != record.validation_event_override.id} << record.validation_event_override
    end
    appointments.sort_by(&:start_at).inject(nil) do |prev, appointment|
      record.errors.add(attr, t('errors.invalid_end_at', "Appointment end time precedes start time")) if appointment.end_at < appointment.start_at
      record.errors.add(attr, t('errors.overlapping_appointments', "Appointments overlap")) if prev && appointment.start_at < prev.end_at
      appointment
    end
  end

  attr_accessible :title, :description, :location_name, :location_address, :context, :sub_context_code, :participants_per_appointment, :min_appointments_per_participant, :max_appointments_per_participant, :new_appointments, :participant_visibility, :cancel_reason
  attr_readonly :context_id, :context_type, :context_code, :sub_context_id, :sub_context_type, :sub_context_code

  # when creating/updating an appointment, you can give it a list of (new)
  # appointment times. these will be added to the existing appointment times
  # format is [[start, end], [start, end], ...]
  attr_reader :new_appointments
  def new_appointments=(appointments)
    appointments = appointments.values if appointments.is_a?(Hash)
    @new_appointments = appointments.map { |start_at, end_at|
      next unless start_at && end_at
      a = self.appointments.build(:start_at => start_at, :end_at => end_at)
      a.context = self
      a
    }
  end
  attr_accessor :validation_event_override
  attr_accessor :cancel_reason

  def reload
    remove_instance_variable :@new_appointments if @new_appointments
    super
  end

  def sub_context_code=(code)
    if new_record?
      self.sub_context = case code
        when /\Acourse_section_(.*)/; CourseSection.find_by_id($1)
        when /\Agroup_category_(.*)/; GroupCategory.find_by_id($1)
      end
      write_attribute(:sub_context_code, sub_context ? code : nil)
    end
  end

  # complements :reserve permission
  named_scope :reservable_by, lambda { |user|
    codes = user.appointment_context_codes
    {:conditions => [<<-COND, codes[:primary], codes[:secondary]]}
      workflow_state = 'active'
      AND context_code IN (?)
      AND (
        sub_context_code IS NULL
        OR sub_context_code IN (?)
      )
      COND
  }
  # complements :manage permission
  named_scope :manageable_by, lambda { |*options|
    user = options.shift
    restrict_to_codes = options.shift

    codes = user.manageable_appointment_context_codes.dup
    if restrict_to_codes
      codes[:full] &= restrict_to_codes
      codes[:limited] &= restrict_to_codes
    end
    {:conditions => [<<-COND, codes[:full] + codes[:limited], codes[:full], codes[:secondary]]}
      workflow_state <> 'deleted'
      AND context_code IN (?)
      AND (
        context_code IN (?)
        OR sub_context_code IN (?)
      )
      COND
  }
  named_scope :current, lambda {
    {:conditions => ["end_at >= ?", Time.zone.today.to_datetime.utc]}
  }
  named_scope :current_or_undated, lambda {
    {:conditions => ["end_at >= ? OR end_at IS NULL", Time.zone.today.to_datetime.utc]}
  }
  named_scope :intersecting, lambda { |start_date, end_date|
    {:conditions => ["start_at < ? AND end_at > ?", end_date, start_date]}
  }

  set_policy do
    given { |user, session|
      next false if deleted?
      next false unless cached_context_grants_right?(user, nil, :manage_calendar)
      next true if sub_context_type == 'CourseSection' && context.section_visibilities_for(user).any?{ |v| sub_context_id == v[:course_section_id] }
      !context.visibility_limited_to_course_sections?(user)
    }
    can :manage and can :manage_calendar and can :read and can :read_appointment_participants and
    can :create and can :update and can :delete

    given { |user, session|
      active? &&
      participant_for(user)
    }
    can :reserve and can :read

    given { |user, session|
      participant_visibility == 'protected' && grants_right?(user, session, :reserve)
    }
    can :read_appointment_participants
  end

  has_a_broadcast_policy

  set_broadcast_policy do
    dispatch :appointment_group_published
    to       { possible_users }
    whenever { context.available? && active? && workflow_state_changed? }

    dispatch :appointment_group_updated
    to       { possible_users }
    whenever { context.available? && active? && new_appointments && !workflow_state_changed? }

    dispatch :appointment_group_deleted
    to       { possible_users }
    whenever { context.available? && deleted? && workflow_state_changed? }
  end

  def possible_users
    participant_type == 'User' ?
      possible_participants.uniq :
      possible_participants.map(&:participants).flatten.uniq
  end

  def instructors
    sub_context_type == 'CourseSection' ?
      context.participating_instructors.restrict_to_sections(sub_context_id).uniq :
      context.participating_instructors.uniq
  end

  def possible_participants(registration_status=nil)
    participants = AppointmentGroup.possible_participants(participant_type, context)
    participants = case registration_status
      when 'registered';   participants.scoped(:conditions => ["#{participant_table}.id IN (?)", participant_ids + [0]])
      when 'unregistered'; participants.scoped(:conditions => ["#{participant_table}.id NOT IN (?)", participant_ids + [0]])
      else                 participants
    end
    participants.order((participant_type == 'User' ? User.sortable_name_order_by_clause("users") : Group.case_insensitive("groups.name")) + ", #{participant_table}.id")
  end

  def participant_ids
    appointments_participants.
      scoped(:select => 'context_id', :conditions => ["calendar_events.context_type = ?", participant_type]).
      map(&:context_id)
  end

  def participant_table
    Kernel.const_get(participant_type).table_name
  end

  def self.possible_participants(participant_type, context)
    if participant_type == 'User'
      context.participating_students
    else
      context.active_groups
    end
  end

  def eligible_participant?(participant)
    return false unless participant && participant.class.base_ar_class.name == participant_type
    codes = participant.appointment_context_codes
    return false unless codes[:primary].include?(context_code)
    return false unless sub_context_code.nil? || codes[:secondary].include?(sub_context_code)
    true
  end

  # TODO: create a scope that does this
  # students would generally call this with the user as the argument
  # instructors would call it with the user or group (depending on participant_type)
  def requiring_action?(user_or_participant)
    participant = user_or_participant
    participant = participant_for(user_or_participant) if participant_type == 'Group' && participant.is_a?(User)
    return false unless eligible_participant?(participant)
    return false unless min_appointments_per_participant
    return reservations_for(participant).size < min_appointments_per_participant
  end

  def participant_for(user)
    participant = if participant_type == 'User'
      user
    else
      user.groups.detect{ |g| g.group_category_id == sub_context_id }
    end
    participant if participant && eligible_participant?(participant)
  end

  def reservations_for(participant)
    appointments_participants.for_context_codes(participant.asset_string)
  end

  def update_cached_values
    self.start_at = appointments.map(&:start_at).min
    self.end_at = appointments.map(&:end_at).max
    clear_cached_available_slots! if participants_per_appointment_changed?
  end

  EVENT_ATTRIBUTES = [
    :title,
    :description,
    :location_name,
    :location_address
  ]

  def description_html
    format_message(description).first if description
  end

  def update_appointments
    changed = Hash[
      EVENT_ATTRIBUTES.select{ |attr| send("#{attr}_changed?") }.
      map{ |attr| [attr, attr == :description ? description_html : send(attr)] }
    ]

    return unless changed.present?

    desc = changed.delete :description

    if changed.present?
      appointments.update_all changed
      CalendarEvent.update_all changed, {:parent_calendar_event_id => appointments.map(&:id), :workflow_state => ['active', 'locked']}
    end

    if desc
      appointments.update_all({:description => desc}, :description => description_was)
      CalendarEvent.update_all({:description => desc}, :parent_calendar_event_id => appointments.map(&:id), :workflow_state => ['active', 'locked'], :description => description_was)
    end

    @new_appointments.each(&:reload) if @new_appointments.present?
  end

  def participant_type
    sub_context_type == 'GroupCategory' ? 'Group' : 'User'
  end

  def available_slots
    return nil unless participants_per_appointment
    Rails.cache.fetch([self, 'available_slots'].cache_key) do
      # participants_per_appointment can change after the fact, so a given
      # could exceed it and we can't just say:
      #   appointments.size * participants_per_appointment
      appointments.inject(0){ |total, appointment|
        total + [participants_per_appointment - appointment.child_events.size, 0].max
      }
    end
  end

  def clear_cached_available_slots!
    Rails.cache.delete([self, 'available_slots'].cache_key)
  end

  def default_values
    self.context_code ||= context_string
    self.participant_visibility ||= 'private'
  end

  workflow do
    state :pending do
      event :publish, :transitions_to => :active
    end
    state :active
    state :deleted
  end

  alias_method :destroy!, :destroy
  def destroy
    transaction do
      self.workflow_state = 'deleted'
      save!
      self.appointments.map{ |a| a.destroy(false) }
    end
  end
end
