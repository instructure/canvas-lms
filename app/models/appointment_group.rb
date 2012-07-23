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
  has_many :appointment_group_contexts
  has_many :appointment_group_sub_contexts, :include => :sub_context

  def contexts
    appointment_group_contexts.map &:context
  end

  def sub_contexts
    appointment_group_sub_contexts.map &:sub_context
  end

  before_validation :default_values
  before_validation :update_contexts_and_sub_contexts
  before_save :update_cached_values
  after_save :update_appointments

  validates_length_of :title, :maximum => maximum_string_length
  validates_length_of :description, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validates_inclusion_of :participant_visibility, :in => ['private', 'protected'] # presumably we might add public if we decide to show appointments on the public calendar feed
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

  def validate
    if appointment_group_contexts.empty?
      errors.add :appointment_group_contexts,
                 t('errors.needs_contexts', 'Must have at least one context')
    end
  end

  attr_accessible :title, :description, :location_name, :location_address, :contexts, :sub_context_codes, :participants_per_appointment, :min_appointments_per_participant, :max_appointments_per_participant, :new_appointments, :participant_visibility, :cancel_reason

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
  attr_accessor :context

  def reload
    remove_instance_variable :@new_appointments if @new_appointments
    super
  end

  # TODO: someday this should become context_codes= for consistency
  def contexts=(new_contexts)
    @new_contexts ||= []
    @new_contexts  += new_contexts.compact
  end

  def sub_context_codes=(codes)
    @new_sub_context_codes ||= []
    @new_sub_context_codes   += codes.compact
  end

  def update_contexts_and_sub_contexts
    # TODO: validate the updating user has manage rights for all contexts /
    # sub_contexts
    #
    # sub contexts
    @new_sub_context_codes -= sub_context_codes if @new_sub_context_codes
    if @new_sub_context_codes.present?
      if new_record? &&
          @new_contexts.size == 1 &&
          @new_sub_context_codes.size == 1 &&
          @new_sub_context_codes.first =~ /\Agroup_category_(.*)/
        # a group category can only be assigned at creation time to
        # appointment groups with one course
        gc = GroupCategory.find_by_id($1)
        code = @new_sub_context_codes.first
        self.appointment_group_sub_contexts = [
          AppointmentGroupSubContext.new :appointment_group => self,
                                         :sub_context => gc,
                                         :sub_context_code => code
        ]
      else
        # right now we don't support changing the sub contexts for a context
        # on an appointment group after it has been saved
        disallowed_sub_context_codes = contexts.map(&:course_sections).
          flatten.map(&:asset_string)
        @new_sub_context_codes -= disallowed_sub_context_codes

        new_sub_contexts = @new_sub_context_codes.map { |code|
          next unless code =~ /\Acourse_section_(.*)/
          cs = CourseSection.find_by_id($1)
          AppointmentGroupSubContext.new :appointment_group => self,
                                         :sub_context => cs,
                                         :sub_context_code => code
        }
        self.appointment_group_sub_contexts += new_sub_contexts.compact
      end
    end

    # contexts
    @new_contexts -= contexts if @new_contexts
    if @new_contexts.present?
      unless appointment_group_sub_contexts.size == 1 &&
          appointment_group_sub_contexts.first.sub_context_type == 'GroupCategory' &&
          !new_record?
        self.appointment_group_contexts += @new_contexts.map { |c|
          AppointmentGroupContext.new :context => c, :appointment_group => self
        }
        @contexts_changed = true
      end
    end
  end

  def sub_context_codes
    appointment_group_sub_contexts.map &:sub_context_code
  end

  # complements :reserve permission
  named_scope :reservable_by, lambda { |user|
    codes = user.appointment_context_codes
    {
      :select => "DISTINCT appointment_groups.*",
      :joins => "JOIN appointment_group_contexts agc " \
                "ON appointment_groups.id = agc.appointment_group_id " \
                "LEFT JOIN appointment_group_sub_contexts sc " \
                "ON appointment_groups.id = sc.appointment_group_id",
      :conditions => [<<-COND, codes[:primary], codes[:secondary]]
        workflow_state = 'active'
        AND agc.context_code IN (?)
        AND (
          sc.sub_context_code IS NULL
          OR sc.sub_context_code IN (?)
        )
        COND
    }
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
    {
      :select => "DISTINCT appointment_groups.*",
      :joins => "JOIN appointment_group_contexts agc " \
                "ON appointment_groups.id = agc.appointment_group_id " \
                "LEFT JOIN appointment_group_sub_contexts sc " \
                "ON appointment_groups.id = sc.appointment_group_id",
      :conditions => [<<-COND, codes[:full] + codes[:limited], codes[:full], codes[:secondary]]
        workflow_state <> 'deleted'
        AND agc.context_code IN (?)
        AND (
          agc.context_code IN (?)
          OR sc.sub_context_code IN (?)
        )
        COND
    }
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
      next false unless contexts.all? { |c| c.grants_right? user, nil, :manage_calendar }
      if appointment_group_sub_contexts.present? && appointment_group_sub_contexts.first.sub_context_type == 'CourseSection'
        sub_context_ids = appointment_group_sub_contexts.map(&:sub_context_id)
        user_visible_sections = sub_context_ids & contexts.map { |c|
          c.section_visibilities_for(user).map { |v| v[:course_section_id] }
        }.flatten
        next true if user_visible_sections.length == sub_contexts.length
      end
      !contexts.all? { |c| c.visibility_limited_to_course_sections?(user) }
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
    whenever { contexts.any?(&:available?) && active? && workflow_state_changed? }

    dispatch :appointment_group_updated
    to       { possible_users }
    whenever { contexts.any?(&:available?) && active? && new_appointments && !workflow_state_changed? }

    dispatch :appointment_group_deleted
    to       { possible_users }
    whenever { contexts.any?(&:available?) && deleted? && workflow_state_changed? }
    data     { {:cancel_reason => @cancel_reason} }
  end

  def possible_users
    participant_type == 'User' ?
      possible_participants.uniq :
      possible_participants.flatten.map(&:participants).flatten.uniq
  end

  def instructors
    if sub_context_type == "CourseSection"
      contexts.map { |c| c.participating_instructors.restrict_to_sections(sub_context_id) }.flatten.uniq
    else
      contexts.map(&:participating_instructors).flatten.uniq
    end
  end

  def possible_participants(registration_status=nil)
    participants = if participant_type == 'User'
                     sub_contexts.empty? ?
                       contexts.map(&:participating_students).flatten :
                       sub_contexts.map(&:participating_students).flatten
                   else
                     # FIXME?
                     sub_contexts.map(&:groups).flatten
                   end
    participant_ids = self.participant_ids
    registered = participants.select { |p| participant_ids.include?(p.id) }

    participants = case registration_status
      when 'registered';     registered
      when 'unregistered';   participants - registered
      else                   participants
    end

    two_tier_cmp = lambda do |a, b, attr1, attr2|
      cmp = a.send(attr1) <=> b.send(attr1)
      cmp == 0 ? a.send(attr2) <=> b.send(attr2) : cmp
    end

    if participant_type == 'User'
      participants.sort { |a,b| two_tier_cmp.call(a, b, :sortable_name, :id) }
    else
      participants.sort { |a,b| two_tier_cmp.call(a, b, :name, :id) }
    end
  end

  def participant_ids
    appointments_participants.
      scoped(:select => 'context_id', :conditions => ["calendar_events.context_type = ?", participant_type]).
      map(&:context_id)
  end

  def participant_table
    Kernel.const_get(participant_type).table_name
  end

  def eligible_participant?(participant)
    return false unless participant && participant.class.base_ar_class.name == participant_type
    codes = participant.appointment_context_codes
    return false unless (codes[:primary] & appointment_group_contexts.map(&:context_code)).present?
    return false unless sub_context_codes.empty? || (codes[:secondary] & sub_context_codes).present?
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
    return false if participants_per_appointment && appointments_participants.count >= participants_per_appointment
    return reservations_for(participant).size < min_appointments_per_participant
  end

  def participant_for(user)
    participant = if participant_type == 'User'
      user
    else
      # can't have more than one group_category
      raise "inconsistent appointment group" if sub_contexts.size > 1
      sub_context_id = sub_contexts.first.id
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

    if @contexts_changed
      changed[:effective_context_code] = contexts.map(&:asset_string).join(",")
    end

    return unless changed.present?

    desc = changed.delete :description

    if changed.present?
      appointments.update_all changed
      changed.delete(:effective_context_code)
    end

    if changed.present?
      CalendarEvent.update_all changed, {:parent_calendar_event_id => appointments.map(&:id), :workflow_state => ['active', 'locked']}
    end

    if desc
      appointments.update_all({:description => desc}, :description => description_was)
      CalendarEvent.update_all({:description => desc}, :parent_calendar_event_id => appointments.map(&:id), :workflow_state => ['active', 'locked'], :description => description_was)
    end

    @new_appointments.each(&:reload) if @new_appointments.present?
  end

  def participant_type
    types = appointment_group_sub_contexts.map(&:participant_type).uniq
    raise "inconsistent participant types in appointment group" if types.size > 1
    types.first || 'User'
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

  def contexts_for_user(user)
    context_codes = context_codes_for_user(user)
    course_ids = appointment_group_contexts.all(:conditions => {:context_code => context_codes}).map(&:context_id)
    Course.all(:conditions => {:id => course_ids})
  end

  def context_codes_for_user(user)
    manageable_codes = user.manageable_appointment_context_codes
    user_codes = user.appointment_context_codes[:primary] |
                   manageable_codes[:full] | manageable_codes[:limited]
    context_codes & user_codes
  end

  def context_codes
    appointment_group_contexts.map(&:context_code)
  end
end
