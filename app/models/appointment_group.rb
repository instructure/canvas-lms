# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

  # rubocop:disable Rails/InverseOf
  has_many :appointments,
           -> { order(:start_at).preload(:child_events).where("calendar_events.workflow_state <> 'deleted'") },
           **(opts = { class_name: "CalendarEvent", as: :context, inverse_of: :context })

  # has_many :through on the same table does not alias columns in condition
  # strings, just hashes. we create this helper association to ensure
  # appointments_participants conditions have the correct table alias
  has_many :_appointments, -> { order(:start_at).preload(:child_events).where("_appointments_appointments_participants.workflow_state <> 'deleted'") }, **opts
  # rubocop:enable Rails/InverseOf
  has_many :appointments_participants, -> { where("calendar_events.workflow_state <> 'deleted'").order(:start_at) }, through: :_appointments, source: :child_events
  has_many :appointment_group_contexts
  has_many :appointment_group_sub_contexts, -> { preload(:sub_context) }

  def context
    appointment_group_contexts.first&.context
  end

  def contexts
    appointment_group_contexts.map(&:context)
  end

  def active_contexts
    contexts.reject { |context| context.workflow_state == "deleted" }
  end

  def sub_contexts
    # I wonder how rails is adding multiples of the same sub_contexts
    appointment_group_sub_contexts.map(&:sub_context)
  end

  validates :workflow_state, presence: true
  before_validation :default_values
  before_validation :update_contexts_and_sub_contexts
  before_save :update_cached_values
  after_save :update_appointments

  validates :title, length: { maximum: maximum_string_length }
  validates :location_name, length: { maximum: maximum_string_length }
  validates :description, length: { maximum: maximum_long_text_length, allow_blank: true }
  validates :participant_visibility, inclusion: { in: ["private", "protected"] } # presumably we might add public if we decide to show appointments on the public calendar feed
  validates_each :appointments do |record, attr, value|
    next unless record.new_appointments.present? || record.validation_event_override

    appointments = value
    if record.validation_event_override
      appointments = appointments.select { |a| a.new_record? || a.id != record.validation_event_override.id } << record.validation_event_override
    end
    prev = nil
    appointments.sort_by(&:start_at).each do |appointment|
      record.errors.add(attr, t("errors.invalid_end_at", "Appointment end time precedes start time")) if appointment.end_at < appointment.start_at
      record.errors.add(attr, t("errors.overlapping_appointments", "Appointments overlap")) if prev && appointment.start_at < prev.end_at
      prev = appointment
    end
  end

  def validate
    if appointment_group_contexts.empty?
      errors.add :appointment_group_contexts,
                 t("errors.needs_contexts", "Must have at least one context")
    end
  end

  # when creating/updating an appointment, you can give it a list of (new)
  # appointment times. these will be added to the existing appointment times
  # format is [[start, end], [start, end], ...]
  attr_reader :new_appointments

  def new_appointments=(appointments)
    appointments = appointments.values if appointments.is_a?(Hash)
    @new_appointments = appointments.map do |start_at, end_at|
      next unless start_at && end_at

      a = self.appointments.build(start_at:, end_at:)
      a.context = self
      a
    end
  end
  attr_accessor :validation_event_override
  attr_accessor :cancel_reason

  def reload
    remove_instance_variable :@new_appointments if @new_appointments
    super
  end

  # TODO: someday this should become context_codes= for consistency (in
  # conjunction with checking permissions in update_contexts_and_sub_contexts)
  def contexts=(new_contexts)
    @new_contexts ||= []
    @new_contexts += new_contexts.compact
  end

  def sub_context_codes=(codes)
    @new_sub_context_codes ||= []
    @new_sub_context_codes += codes.compact
  end

  def update_contexts_and_sub_contexts
    # TODO: validate the updating user has manage rights for all contexts /
    # sub_contexts. currently this is done in the controller level, since
    # we validate contexts beforehand
    @new_sub_context_codes -= sub_context_codes if @new_sub_context_codes
    new_sub_contexts = []
    if @new_sub_context_codes.present?
      if new_record? &&
         @new_contexts.size == 1 &&
         @new_sub_context_codes.size == 1 &&
         @new_sub_context_codes.first =~ /\Agroup_category_(.*)/
        # a group category can only be assigned at creation time to
        # appointment groups with one course
        gc = GroupCategory.where(id: $1).first
        self.appointment_group_sub_contexts = [
          AppointmentGroupSubContext.new(appointment_group: self,
                                         sub_context: gc,
                                         sub_context_code: @new_sub_context_codes.first)
        ]
      else
        # if new record and we have a course without sections, add all the sections
        if new_record?
          @new_contexts.each do |context|
            context_subs = context.course_sections.map(&:asset_string)
            # if context has no selected subcontexts, add all subcontexts
            if (@new_sub_context_codes & context_subs).count == 0
              @new_sub_context_codes += context_subs
            end
          end
        end

        # right now we don't support changing the sub contexts for a context
        # on an appointment group after it has been saved
        disallowed_sub_context_codes = contexts.map(&:course_sections)
                                               .flatten.map(&:asset_string)
        @new_sub_context_codes -= disallowed_sub_context_codes

        new_sub_contexts = @new_sub_context_codes.filter_map do |code|
          next unless code =~ /\Acourse_section_(.*)/

          cs = CourseSection.where(id: $1).first
          AppointmentGroupSubContext.new(appointment_group: self,
                                         sub_context: cs,
                                         sub_context_code: code)
        end
      end
    end

    # contexts
    @new_contexts -= contexts if @new_contexts
    if @new_contexts.present? && !((appointment_group_sub_contexts + new_sub_contexts).size == 1 &&
             (appointment_group_sub_contexts + new_sub_contexts).first.sub_context_type == "GroupCategory" &&
             !new_record?)
      self.appointment_group_contexts += @new_contexts.map do |c|
        AppointmentGroupContext.new context: c, appointment_group: self
      end
      @contexts_changed = true
    end

    if new_sub_contexts.present?
      # the sub_contexts get validated as soon as we add them in Rails 3,
      # so we need to add them after we have updated the contexts
      self.appointment_group_sub_contexts += new_sub_contexts
    end
  end

  def sub_context_codes
    appointment_group_sub_contexts.map(&:sub_context_code)
  end

  # complements :reserve permission
  scope :reservable_by, lambda { |*options|
    user = options.shift
    restrict_to_codes = options.shift

    student_codes = user.appointment_context_codes.dup
    all_codes = user.appointment_context_codes(include_observers: true).dup
    if restrict_to_codes
      student_codes[:primary] &= restrict_to_codes
      all_codes[:primary] &= restrict_to_codes
    end
    scope = distinct
            .joins(<<~SQL.squish)
              JOIN #{AppointmentGroupContext.quoted_table_name} agc
                ON appointment_groups.id = agc.appointment_group_id
              LEFT JOIN #{AppointmentGroupSubContext.quoted_table_name} sc
                ON appointment_groups.id = sc.appointment_group_id
            SQL
    scope
      .where(<<~SQL.squish, student_codes[:primary], student_codes[:secondary])
        workflow_state = 'active'
        AND agc.context_code IN (?)
        AND (
          sc.sub_context_code IS NULL
          OR sc.sub_context_code IN (?)
        )
      SQL
      .union(scope.where(<<~SQL.squish, all_codes[:primary], all_codes[:secondary])
        workflow_state = 'active'
        AND allow_observer_signup = true
        AND agc.context_code IN (?)
        AND (
          sc.sub_context_code IS NULL
          OR sc.sub_context_code IN (?)
        )
      SQL
            )
  }
  # complements :manage permission
  scope :manageable_by, lambda { |*options|
    user = options.shift
    restrict_to_codes = options.shift

    codes = user.manageable_appointment_context_codes.dup
    if restrict_to_codes
      codes[:full] &= restrict_to_codes
      codes[:limited] &= restrict_to_codes
    end
    distinct
      .joins(<<~SQL.squish)
        JOIN #{AppointmentGroupContext.quoted_table_name} agc
          ON appointment_groups.id = agc.appointment_group_id
        LEFT JOIN #{AppointmentGroupSubContext.quoted_table_name} sc
          ON appointment_groups.id = sc.appointment_group_id
      SQL
      .where(<<~SQL.squish, codes[:full] + codes[:limited], codes[:full], codes[:secondary])
        workflow_state <> 'deleted'
        AND agc.context_code IN (?)
        AND (
          agc.context_code IN (?)
          OR sc.sub_context_code IN (?)
        )
      SQL
  }
  scope :current, -> { where("end_at>=?", Time.zone.now) }
  scope :current_or_undated, -> { where("end_at>=? OR end_at IS NULL", Time.zone.now) }
  scope :intersecting, ->(start_date, end_date) { where("start_at<? AND end_at>?", end_date, start_date) }

  set_policy do
    given do |user|
      active? && participant_for(user)
    end
    can :reserve and can :read

    given do |user|
      next false if deleted?
      next false unless active_contexts.any? { |c| c.grants_right? user, :manage_calendar }

      if appointment_group_sub_contexts.present? && appointment_group_sub_contexts.first.sub_context_type == "CourseSection"
        sub_context_ids = appointment_group_sub_contexts.map(&:sub_context_id)
        user_visible_section_ids = contexts.map do |c|
          c.section_visibilities_for(user).pluck(:course_section_id)
        end.flatten
        next true if (sub_context_ids - user_visible_section_ids).empty?
      end
      contexts.any? { |c| c.enrollment_visibility_level_for(user) == :full }
    end
    can :manage and can :manage_calendar and can :read and can :read_appointment_participants and
      can :create and can :update and can :delete

    given do |user|
      participant_visibility == "protected" && grants_right?(user, :reserve)
    end
    can :read_appointment_participants
  end

  def broadcast_data
    data = {}
    ids = appointment_group_contexts.where(context_type: "Course")
                                    .joins("INNER JOIN #{Course.quoted_table_name} ON courses.id = context_id").pluck(:context_id, :root_account_id)
    ids += appointment_group_contexts.where(context_type: "CourseSection")
                                     .joins("INNER JOIN #{CourseSection.quoted_table_name} ON course_sections.id = context_id").pluck(:course_id, :root_account_id)
    data[:root_account_id] = ids.map(&:last).first
    data[:course_ids] = ids.map(&:first).sort
    data
  end

  has_a_broadcast_policy

  set_broadcast_policy do
    dispatch :appointment_group_published
    to       { possible_users }
    whenever { contexts.any?(&:available?) && active? && saved_change_to_workflow_state? }
    data     { broadcast_data }

    dispatch :appointment_group_updated
    to       { possible_users }
    whenever { contexts.any?(&:available?) && active? && new_appointments && !saved_change_to_workflow_state? }
    data     { broadcast_data }

    dispatch :appointment_group_deleted
    to       { possible_users }
    whenever { contexts.any?(&:available?) && changed_state(:deleted, :active) }
    data     { broadcast_data.merge({ cancel_reason: @cancel_reason }) }
  end

  def possible_users
    if participant_type == "User"
      possible_participants(include_observers: true).uniq
    else
      possible_participants.flatten.map(&:participants).flatten.uniq
    end
  end

  def instructors
    if participant_type == "User" && sub_contexts.present?
      contexts.map { |c| c.participating_instructors.restrict_to_sections(sub_contexts) }.flatten.uniq
    else
      contexts.map(&:participating_instructors).flatten.uniq
    end
  end

  def possible_participants(registration_status: nil, include_observers: false)
    participants = if participant_type == "User"
                     participant_func = if include_observers
                                          ->(c) { c.participating_students_by_date + c.participating_observers_by_date }
                                        else
                                          ->(c) { c.participating_students_by_date }
                                        end
                     if sub_contexts.empty?
                       contexts.select(&:published?).map(&participant_func).flatten
                     else
                       sub_contexts.map(&participant_func).flatten
                     end
                   else
                     # FIXME?
                     sub_contexts.map(&:groups).flatten
                   end
    participant_ids = self.participant_ids
    registered = participants.select { |p| participant_ids.include?(p.id) }

    participants = case registration_status
                   when "registered"
                     registered
                   when "unregistered"
                     participants - registered
                   else
                     participants
                   end

    if participant_type == "User"
      participants.sort_by { |p| [Canvas::ICU.collation_key(p.sortable_name), p.id] }
    else
      participants.sort_by { |p| [Canvas::ICU.collation_key(p.name), p.id] }
    end
  end

  def participant_ids
    appointments_participants
      .except(:order)
      .where(context_type: participant_type)
      .pluck(:context_id)
  end

  def participant_table
    Kernel.const_get(participant_type).table_name
  end

  def eligible_participant?(participant)
    return false unless participant && participant.class.base_class.name == participant_type

    codes = (participant_type == "User") ? participant.appointment_context_codes(include_observers: allow_observer_signup) : participant.appointment_context_codes
    return false unless codes[:primary].intersect?(appointment_group_contexts.map(&:context_code))
    return false unless sub_context_codes.empty? || codes[:secondary].intersect?(sub_context_codes)

    true
  end

  # TODO: create a scope that does this
  # students would generally call this with the user as the argument
  # instructors would call it with the user or group (depending on participant_type)
  def requiring_action?(user_or_participant)
    participant = user_or_participant
    participant = participant_for(user_or_participant) if participant_type == "Group" && participant.is_a?(User)
    return false unless eligible_participant?(participant)
    return false unless min_appointments_per_participant
    return false if all_appointments_filled?

    reservations_for(participant).size < min_appointments_per_participant
  end

  def all_appointments_filled?
    return false unless participants_per_appointment

    appointments_participants.count >= appointments.sum(
      sanitize_sql(["COALESCE(participants_per_appointment, ?)", participants_per_appointment])
    )
  end

  def participant_for(user)
    @participant_for ||= {}
    return @participant_for[user.global_id] if @participant_for.key?(user.global_id)

    @participant_for[user.global_id] = begin
      participant = if participant_type == "User"
                      user
                    else
                      # can't have more than one group_category
                      group_categories = sub_contexts.find_all { |sc| sc.instance_of? GroupCategory }
                      raise "inconsistent appointment group: #{id} #{group_categories}" if group_categories.length > 1

                      group_category_id = group_categories.first.id
                      user.current_groups.detect { |g| g.group_category_id == group_category_id }
                    end
      participant if participant && eligible_participant?(participant)
    end
  end

  def reservations_for(participant)
    appointments_participants.for_context_codes(participant.asset_string)
  end

  def update_cached_values
    self.start_at = appointments.map(&:start_at).min
    self.end_at = appointments.map(&:end_at).max
    clear_cached_available_slots! if participants_per_appointment_changed?
    true
  end

  EVENT_ATTRIBUTES = %i[
    title
    description
    location_name
    location_address
  ].freeze

  def update_appointments
    changed =
      EVENT_ATTRIBUTES.select { |attr| saved_change_to_attribute?(attr) }
                      .index_with { |attr| send(attr) }

    if @contexts_changed
      changed[:root_account_id] = context&.root_account_id
      changed[:effective_context_code] = contexts.map(&:asset_string).join(",")
    end

    return if changed.blank?

    if changed.present?
      appointments.update_all(changed)
      changed.delete(:effective_context_code)
    end

    if changed.present?
      CalendarEvent.joins(:parent_event).where(
        workflow_state: ["active", "locked"],
        parent_events_calendar_events: { context_id: self, context_type: "AppointmentGroup" }
      ).update_all(changed)
    end

    @new_appointments.each(&:reload) if @new_appointments.present?
  end

  def participant_type
    types = appointment_group_sub_contexts.map(&:participant_type).uniq
    raise "inconsistent participant types in appointment group" if types.size > 1

    types.first || "User"
  end

  def available_slots(current_only: false)
    return nil unless participants_per_appointment

    Rails.cache.fetch([self, "available_slots"].cache_key) do
      filtered_appointments = current_only ? appointments.current : appointments
      # participants_per_appointment can change after the fact, so a given
      # could exceed it and we can't just say:
      #   appointments.size * participants_per_appointment
      CalendarEvent.from(
        filtered_appointments.left_joins(:child_events)
                             .group("calendar_events.id")
                             .select("GREATEST(0, #{participants_per_appointment} - COUNT(child_events_calendar_events.id)) AS count")
      ).sum(:count).to_i
    end
  end

  def clear_cached_available_slots!
    Rails.cache.delete([self, "available_slots"].cache_key)
  end

  def default_values
    self.participant_visibility ||= "private"
  end

  workflow do
    state :pending do
      event :publish, transitions_to: :active
    end
    state :active
    state :deleted
  end

  alias_method :destroy_permanently!, :destroy
  def destroy(updating_user)
    transaction do
      self.workflow_state = "deleted"
      save!
      appointments.map do |a|
        a.updating_user = updating_user
        a.destroy(false)
      end
    end
  end

  def contexts_for_user(user)
    @contexts_for_user ||= {}
    return @contexts_for_user[user.global_id] if @contexts_for_user.key?(user.global_id)

    @contexts_for_user[user.global_id] = begin
      context_codes = context_codes_for_user(user)
      course_ids = appointment_group_contexts.select { |agc| context_codes.include? agc.context_code }.map(&:context_id)
      Course.where(id: course_ids).to_a
    end
  end

  def context_codes_for_user(user)
    @context_codes_for_user ||= {}
    return @context_codes_for_user[user.global_id] if @context_codes_for_user.key?(user.global_id)

    @context_codes_for_user[user.global_id] = begin
      manageable_codes = user.manageable_appointment_context_codes
      user_codes = user.appointment_context_codes(include_observers: true)[:primary] |
                   manageable_codes[:full] | manageable_codes[:limited]
      context_codes & user_codes
    end
  end

  def context_codes
    appointment_group_contexts.map(&:context_code)
  end

  def users_with_reservations_through_group
    appointments_participants
      .joins(<<~SQL.squish)
        INNER JOIN #{GroupMembership.quoted_table_name}
          ON group_memberships.group_id = calendar_events.context_id
             AND calendar_events.context_type = 'Group'
      SQL
      .where("group_memberships.workflow_state <> 'deleted'")
      .pluck("group_memberships.user_id")
  end
end
