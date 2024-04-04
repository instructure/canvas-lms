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

require "icalendar"

Icalendar::Event.optional_property :x_alt_desc

class CalendarEvent < ActiveRecord::Base
  include CopyAuthorizedLinks
  include TextHelper
  include HtmlTextHelper
  include Plannable

  include MasterCourses::Restrictor

  restrict_columns :content, [:title, :description]
  restrict_columns :settings, %i[location_name location_address start_at end_at all_day all_day_date series_uuid rrule]

  attr_accessor :cancel_reason, :imported

  sanitize_field :description, CanvasSanitize::SANITIZE
  copy_authorized_links(:description) { [effective_context, nil] }

  include Workflow

  PERMITTED_ATTRIBUTES = %i[title
                            description
                            start_at
                            end_at
                            location_name
                            location_address
                            time_zone_edited
                            cancel_reason
                            participants_per_appointment
                            remove_child_events
                            all_day
                            comments
                            context_code
                            important_dates
                            series_uuid
                            rrule
                            blackout_date].freeze
  def self.permitted_attributes
    PERMITTED_ATTRIBUTES
  end

  belongs_to :context,
             polymorphic: %i[course user group appointment_group course_section account],
             polymorphic_prefix: true
  belongs_to :user
  belongs_to :parent_event, class_name: "CalendarEvent", foreign_key: :parent_calendar_event_id, inverse_of: :child_events
  has_many :child_events, -> { where.not(workflow_state: "deleted") }, class_name: "CalendarEvent", foreign_key: :parent_calendar_event_id, inverse_of: :parent_event
  belongs_to :web_conference, autosave: true
  belongs_to :root_account, class_name: "Account"

  validates :context, :workflow_state, presence: true
  validates_associated :context, if: ->(record) { record.validate_context }
  validates :description, length: { maximum: maximum_long_text_length, allow_blank: true }
  validates :title, length: { maximum: maximum_string_length, allow_blank: true }
  validates :comments, length: { maximum: 255, allow_blank: true }
  validate :validate_conference_visibility
  before_create :set_root_account
  before_save :default_values
  after_save :touch_context
  after_save :replace_child_events
  after_save :sync_parent_event
  after_save :sync_conference
  after_update :sync_child_events

  # when creating/updating a calendar_event, you can give it a list of child
  # events. these will update/replace any existing child events. the format is:
  # [{:start_at => start_at, :end_at => end_at, :context_code => context_code},
  #  {:start_at => start_at, :end_at => end_at, :context_code => context_code},
  #  ...]
  # the context for each child event must have this event's context as its
  # parent_event_context, and there can only be one event per context.
  # remove_child_events can be set to remove all existing events (since rails
  # form handling mechanism doesn't let you specify an empty array)
  attr_accessor :child_event_data, :remove_child_events, :child_event_contexts

  validates_each :child_event_data do |record, attr, events|
    next unless events || Canvas::Plugin.value_to_boolean(record.remove_child_events)

    events ||= []
    events = events.values if events.is_a?(Hash)
    next record.errors.add(attr, t("errors.no_updating_user", "Can't update child events unless an updating_user is set")) if events.present? && !record.updating_user

    context_codes = events.pluck(:context_code)
    next record.errors.add(attr, t("errors.duplicate_child_event_contexts", "Duplicate child event contexts")) if context_codes != context_codes.uniq

    contexts = find_all_by_asset_string(context_codes).group_by(&:asset_string)
    context_codes.each do |code|
      context = contexts[code] && contexts[code][0]
      new_event = events.detect { |e| e[:context_code] == context&.asset_string }
      existing_event = record.child_events.where(context:).first
      event_unchanged = new_event && existing_event && DateTime.parse(new_event[:start_at]) == existing_event.start_at && DateTime.parse(new_event[:end_at]) == existing_event.end_at
      next if (context&.grants_right?(record.updating_user, :manage_calendar) || event_unchanged) && context.try(:parent_event_context) == record.context

      break record.errors.add(attr, t("errors.invalid_child_event_context", "Invalid child event context"))
    end
    record.child_event_contexts = contexts
    record.child_event_data = events
  end

  def replace_child_events
    return unless @child_event_data

    current_events = child_events.group_by { |e| e[:context_code] }
    @child_event_data.each do |data|
      if (event = current_events.delete(data[:context_code])&.first)
        event.updating_user = @updating_user
        event.update(start_at: data[:start_at], end_at: data[:end_at])
      else
        context = @child_event_contexts[data[:context_code]][0]
        event = child_events.build(start_at: data[:start_at], end_at: data[:end_at])
        event.updating_user = @updating_user
        event.context = context
        event.skip_sync_parent_event = true
        event.save
      end
    end

    current_events.values.flatten.each(&:destroy)
    cache_child_event_ranges!
    @child_event_data = nil
  end

  def hidden?
    !appointment_group? && !child_events.empty?
  end

  def in_a_series?
    !!series_uuid
  end

  def series_tail?
    in_a_series? && !series_head
  end

  def effective_context
    (effective_context_code && ActiveRecord::Base.find_all_by_asset_string(effective_context_code).first) || context
  end

  scope :active, -> { where("calendar_events.workflow_state<>'deleted'") }
  scope :are_locked, -> { where(workflow_state: "locked") }
  scope :are_unlocked, -> { where("calendar_events.workflow_state NOT IN ('deleted', 'locked')") }

  # controllers/apis/etc. should generally use for_user_and_context_codes instead
  scope :for_context_codes, ->(codes) { where(context_code: codes) }

  # appointments and appointment_participants have the appointment_group and
  # the user as the context, respectively. we are actually interested in
  # grouping them under the effective context (i.e. appointment_group.context).
  # it's the responsibility of the caller to ensure the user has rights to the
  # specified codes (e.g. using User#appointment_context_codes)
  scope :for_user_and_context_codes, lambda { |user, codes, section_codes = nil|
    section_codes ||= user.section_context_codes(codes)
    effectively_courses_codes = [user.asset_string] + section_codes
    # the all_codes check is redundant, but makes the query more efficient
    all_codes = codes | effectively_courses_codes

    group_codes = codes.grep(/\Aappointment_group_\d+\z/)
    codes -= group_codes

    or_clauses = []
    unscoped do
      # explicit contexts (e.g. course_123)
      or_clauses << where(context_code: codes, effective_context_code: nil) unless codes.empty?

      # appointments (manageable or reservable)
      or_clauses << where(context_code: group_codes) unless group_codes.empty?

      # own appointment_participants, or section events in the course
      unless codes.empty?
        this_scope = where(context_code: effectively_courses_codes)

        codes_conditions = codes.map do |code|
          wildcard(quoted_table_name + ".effective_context_code", code, delimiter: ",")
        end.join(" OR ")

        this_scope = this_scope.where(codes_conditions)
        or_clauses << this_scope
      end
    end

    next none if or_clauses.empty?
    next merge(or_clauses.first) if or_clauses.length == 1

    # basically we're forming "context_code IN (<all_codes>) AND (... OR ... OR ...)"
    result = where(context_code: all_codes)
    or_clauses_merged = or_clauses.first
    or_clauses[1..].each do |clause|
      or_clauses_merged = or_clauses_merged.or(clause)
    end

    result = result.merge(or_clauses_merged)
    result
  }

  scope :not_hidden, lambda {
    where("NOT EXISTS (
      SELECT id
      FROM #{CalendarEvent.quoted_table_name} sub_events
      WHERE sub_events.parent_calendar_event_id=calendar_events.id
        AND sub_events.workflow_state <> 'deleted'
    )")
  }

  scope :undated, -> { where(start_at: nil, end_at: nil) }

  scope :between, ->(start, ending) { where(start_at: ..ending, end_at: start..) }
  scope :current, -> { where("calendar_events.end_at>=?", Time.zone.now) }
  scope :updated_after, lambda { |*args|
    if args.first
      where("calendar_events.updated_at IS NULL OR calendar_events.updated_at>?", args.first)
    else
      all
    end
  }

  scope :events_without_child_events, -> { where("NOT EXISTS (SELECT 1 FROM #{CalendarEvent.quoted_table_name} children WHERE children.parent_calendar_event_id = calendar_events.id AND children.workflow_state<>'deleted')") }
  scope :events_with_child_events, -> { where("EXISTS (SELECT 1 FROM #{CalendarEvent.quoted_table_name} children WHERE children.parent_calendar_event_id = calendar_events.id AND children.workflow_state<>'deleted')") }

  scope :user_created, -> { where(timetable_code: nil) }
  scope :for_timetable, -> { where.not(timetable_code: nil) }

  scope :with_important_dates, -> { where(important_dates: true) }
  scope :with_blackout_date, -> { where(blackout_date: true) }

  def validate_context!
    @validate_context = true
    context.validation_event_override = self
  end
  attr_reader :validate_context

  def default_values
    self.context_code = "#{context_type.underscore}_#{context_id}"
    self.title ||= (context_type.to_s + " Event") rescue "Event"

    populate_missing_dates
    populate_all_day_flag unless imported

    if parent_event
      populate_with_parent_event
    elsif context.is_a?(AppointmentGroup)
      populate_appointment_group_defaults
    end
  end
  protected :default_values

  def set_root_account(ctx = context)
    if ctx.respond_to?(:root_account)
      self.root_account = ctx.root_account # course, section, group
    else
      case ctx
      when User
        if effective_context.is_a?(User)
          self.root_account_id = 0
        else
          set_root_account(effective_context)
        end
      when AppointmentGroup
        self.root_account = context.context&.root_account
      end
    end
  end

  def child_event_participants_scope
    shard.activate do
      # user is set directly, or context is user
      User.where("id IN
        (#{child_events.where.not(user_id: nil).select(:user_id).to_sql}
        UNION
         #{child_events.where(user_id: nil, context_type: "User").select(:context_id).to_sql})")
    end
  end

  def populate_appointment_group_defaults
    self.effective_context_code = context.appointment_group_contexts.map(&:context_code).join(",")
    if new_record?
      AppointmentGroup::EVENT_ATTRIBUTES.each { |attr| send(:"#{attr}=", context.send(attr)) }
      if locked?
        self.start_at = start_at_was if !new_record? && start_at_changed?
        self.end_at   = end_at_was   if !new_record? && end_at_changed?
      end
    else
      # we only allow changing the description
      (AppointmentGroup::EVENT_ATTRIBUTES - [:description]).each { |attr| send(:"#{attr}=", send(:"#{attr}_was")) if send(:"#{attr}_changed?") }
    end
  end
  protected :populate_appointment_group_defaults

  def populate_with_parent_event
    self.effective_context_code = if appointment_group # appointment participant
                                    appointment_group.appointment_group_contexts.map(&:context_code).join(",") if appointment_group.participant_type == "User"
                                  else # e.g. section-level event
                                    parent_event.context_code
                                  end
    (locked? ? LOCKED_ATTRIBUTES : CASCADED_ATTRIBUTES).each { |attr| send(:"#{attr}=", parent_event.send(attr)) }
  end
  protected :populate_with_parent_event

  # Populate the start and end dates if they are not set, or if they are invalid
  def populate_missing_dates
    self.end_at ||= start_at
    self.start_at ||= self.end_at
    if self.start_at && self.end_at && self.end_at < self.start_at
      self.end_at = self.start_at
    end
  end
  protected :populate_missing_dates

  def populate_all_day_flag
    # If the all day flag has been changed to all day, set the times to 00:00
    if all_day_changed? && all_day?
      self.start_at = zoned_start_at.beginning_of_day rescue nil
      self.end_at = zoned_end_at.beginning_of_day rescue nil
    elsif start_at_changed? || end_at_changed? || Canvas::Plugin.value_to_boolean(remove_child_events)
      self.all_day = self.start_at && self.start_at == self.end_at && zoned_start_at.strftime("%H:%M") == "00:00"
    end

    if all_day && (!all_day_date || start_at_changed? || all_day_date_changed?)
      self.start_at = zoned_start_at.beginning_of_day rescue nil
      self.end_at = zoned_end_at.beginning_of_day rescue nil
      self.all_day_date = (zoned_start_at.to_date rescue nil)
    end
  end
  protected :populate_all_day_flag

  # Localized start_at
  def zoned_start_at
    self.start_at && ActiveSupport::TimeWithZone.new(self.start_at.utc,
                                                     ((ActiveSupport::TimeZone.new(time_zone_edited) rescue nil) || Time.zone))
  end

  def zoned_end_at
    self.end_at && ActiveSupport::TimeWithZone.new(self.end_at.utc,
                                                   ((ActiveSupport::TimeZone.new(time_zone_edited) rescue nil) || Time.zone))
  end

  CASCADED_ATTRIBUTES = %i[
    title
    description
    location_name
    location_address
    web_conference
  ].freeze
  LOCKED_ATTRIBUTES = CASCADED_ATTRIBUTES + [
    :start_at,
    :end_at
  ].freeze

  def sync_child_events
    locked_changes = LOCKED_ATTRIBUTES.select { |attr| saved_change_to_attribute?(attr) }
    cascaded_changes = CASCADED_ATTRIBUTES.select { |attr| saved_change_to_attribute?(attr) }
    child_events.are_locked.update_all(locked_changes.index_with { |attr| send(attr) }) if locked_changes.present?
    child_events.are_unlocked.update_all(cascaded_changes.index_with { |attr| send(attr) }) if cascaded_changes.present?
  end

  def sync_conference
    return if web_conference_id.blank?

    if saved_change_to_title?
      web_conference.title = title
    end
    if saved_change_to_start_at? && web_conference.user_settings.key?(:scheduled_date)
      web_conference.user_settings[:scheduled_date] = start_at
    end
    unless web_conference.lti?
      web_conference.invite_users_from_context
    end

    web_conference.save!
  end

  attr_writer :skip_sync_parent_event

  def sync_parent_event
    return unless parent_event
    return if appointment_group
    return unless saved_change_to_start_at? || saved_change_to_end_at? || saved_change_to_workflow_state?
    return if @skip_sync_parent_event

    parent_event.cache_child_event_ranges! unless workflow_state == "deleted"
  end

  def cache_child_event_ranges!
    events = child_events.reload

    if events.present?
      CalendarEvent.where(id: self)
                   .update_all(start_at: events.filter_map(&:start_at).min,
                               end_at: events.filter_map(&:end_at).max)
      reload
    end
  end

  workflow do
    state :active
    state :locked do # locked events may only be deleted, they cannot be edited directly
      event :unlock, transitions_to: :active
    end
    state :deleted
  end

  alias_method :destroy_permanently!, :destroy
  def destroy(update_context_or_parent = true)
    transaction do
      self.workflow_state = "deleted"
      self.deleted_at = Time.now.utc
      self.web_conference = nil
      save!
      child_events.find_each do |e|
        e.cancel_reason = cancel_reason
        e.updating_user = updating_user
        e.destroy(false)
      end
      next unless update_context_or_parent

      if appointment_group
        context.touch if context_type == "AppointmentGroup" # ensures end_at/start_at get updated
        # when deleting an appointment or appointment_participant, make sure we reset the cache
        appointment_group.clear_cached_available_slots!
        appointment_group.save!
      end
      if parent_event && parent_event.child_events.empty?
        parent_event.workflow_state = parent_event.locked? ? "active" : "deleted"
        parent_event.save!
      end
    end
    true
  end

  def time_zone_edited
    CGI.unescapeHTML(read_attribute(:time_zone_edited) || "")
  end

  has_a_broadcast_policy

  def course_broadcast_data
    return appointment_group.broadcast_data if appointment_group

    if context.respond_to?(:broadcast_data)
      context.broadcast_data
    else
      {}
    end
  end

  set_broadcast_policy do
    dispatch :new_event_created
    to { participants(include_observers: true) - [@updating_user] }
    whenever do
      !appointment_group && !account && context.available? && just_created && !hidden? && !series_tail?
    end
    data { course_broadcast_data }

    dispatch :event_date_changed
    to { participants(include_observers: true) - [@updating_user] }
    whenever do
      !appointment_group &&
        !account &&
        context.available? && (
        changed_in_state(:active, fields: :start_at) ||
        changed_in_state(:active, fields: :end_at)
      ) && !hidden?
    end
    data { course_broadcast_data }

    dispatch :appointment_reserved_by_user
    to do
      appointment_group.instructors +
        User.observing_students_in_course(@updating_user.id, appointment_group.active_contexts.select { |c| c.is_a?(Course) })
    end
    whenever do
      @updating_user && appointment_group && parent_event &&
        just_created &&
        context == appointment_group.participant_for(@updating_user)
    end
    data { { updating_user_name: @updating_user.name }.merge(course_broadcast_data) }

    dispatch :appointment_canceled_by_user
    to do
      appointment_group.instructors +
        User.observing_students_in_course(@updating_user.id, appointment_group.active_contexts.select { |c| c.is_a?(Course) })
    end
    whenever do
      appointment_group && parent_event &&
        deleted? &&
        saved_change_to_workflow_state? &&
        @updating_user &&
        context == appointment_group.participant_for(@updating_user)
    end
    data { { updating_user_name: @updating_user.name, cancel_reason: @cancel_reason }.merge(course_broadcast_data) }

    dispatch :appointment_reserved_for_user
    to { participants(include_observers: true) - [@updating_user] }
    whenever do
      appointment_group && parent_event &&
        just_created
    end
    data { { updating_user_name: @updating_user.name }.merge(course_broadcast_data) }

    dispatch :appointment_deleted_for_user
    to { participants(include_observers: true) - [@updating_user] }
    whenever do
      appointment_group && parent_event &&
        deleted? &&
        saved_change_to_workflow_state?
    end
    data { { updating_user_name: @updating_user.name, cancel_reason: @cancel_reason }.merge(course_broadcast_data) }
  end

  def participants(include_observers: false)
    if context_type == "User"
      if appointment_group? && include_observers
        course_ids = appointment_group.appointment_group_contexts.where(context_type: "Course").pluck(:context_id)
        [context] + User.observing_students_in_course(context, course_ids)
      else
        [context]
      end
    elsif context.respond_to?(:participants)
      context.participants(include_observers:, by_date: true)
    else
      []
    end
  end

  attr_reader :updating_user

  def updating_user=(user)
    self.user ||= user
    @updating_user = user
    content_being_saved_by(user)
  end

  def user
    read_attribute(:user) || ((context_type == "User") ? context : nil)
  end

  def appointment_group?
    context_type == "AppointmentGroup" || parent_event.try(:context_type) == "AppointmentGroup"
  end

  def appointment_group
    if parent_event.try(:context).is_a?(AppointmentGroup)
      parent_event.context
    elsif context_type == "AppointmentGroup"
      context
    end
  end

  def account
    (context_type == "Account") ? context : nil
  end

  class ReservationError < StandardError; end

  def reserve_for(participant, user, options = {})
    raise ReservationError, "not an appointment" unless context_type == "AppointmentGroup"
    raise ReservationError, "ineligible participant" unless context.eligible_participant?(participant)

    transaction do
      lock! # in case two people two participants try to grab the same slot
      participant.lock! # in case two people try to make a reservation for the same participant

      if options[:cancel_existing]
        context.reservations_for(participant).lock.each do |reservation|
          raise ReservationError, "cannot cancel past reservation" if reservation.end_at < Time.now.utc

          reservation.updating_user = user
          reservation.destroy
        end
      end

      raise ReservationError, "participant has met per-participant limit" if context.max_appointments_per_participant && context.reservations_for(participant).size >= context.max_appointments_per_participant
      raise ReservationError, "all slots filled" if participants_per_appointment && child_events.size >= participants_per_appointment
      raise ReservationError, "participant has already reserved this appointment" if child_events_for(participant).present?

      event = child_events.build
      event.updating_user = user
      event.context = participant
      event.workflow_state = :locked
      event.comments = options[:comments]
      event.save!
      if active?
        self.workflow_state = "locked"
        save!
      end
      context.clear_cached_available_slots!
      event
    end
  end

  def child_events_for(participant)
    if child_events.loaded?
      child_events.select { |e| e.has_asset?(participant) }
    else
      child_events.where(context_type: participant.class.name, context_id: participant)
    end
  end

  def participants_per_appointment
    if override_participants_per_appointment?
      read_attribute(:participants_per_appointment)
    else
      context.is_a?(AppointmentGroup) ? context.participants_per_appointment : nil
    end
  end

  def participants_per_appointment=(limit)
    # if the given limit is the same as the context's limit, we should not override
    if limit == context.participants_per_appointment && override_participants_per_appointment?
      self.override_participants_per_appointment = false
      write_attribute(:participants_per_appointment, nil)
    else
      write_attribute(:participants_per_appointment, limit)
      self.override_participants_per_appointment = true
    end
  end

  def update_matching_days=(update)
    @update_matching_days = update == "1" || update == true || update == "true"
  end

  def all_day
    read_attribute(:all_day) || (new_record? && self.start_at && self.start_at == self.end_at && self.start_at.strftime("%H:%M") == "00:00")
  end

  def to_atom(opts = {})
    extend ApplicationHelper

    title = t(:feed_item_title, "Calendar Event: %{event_title}", event_title: self.title) unless opts[:include_context]
    title = t(:feed_item_title_with_context, "Calendar Event, %{course_or_account_name}: %{event_title}", course_or_account_name: context.name, event_title: self.title) if opts[:include_context]

    {
      title:,
      author: context.name,
      updated: updated_at.utc,
      published: created_at.utc,
      link: "http://#{HostUrl.context_host(context)}/#{context_url_prefix}/calendar?month=#{self.start_at.strftime("%m") rescue ""}&year=#{self.start_at.strftime("%Y") rescue ""}#calendar_event_#{id}",
      id: "tag:#{HostUrl.default_host},#{created_at.strftime("%Y-%m-%d")}:/calendar_events/#{feed_code}_#{self.start_at.strftime("%Y-%m-%d-%H-%M") rescue "none"}_#{self.end_at.strftime("%Y-%m-%d-%H-%M") rescue "none"}",
      content: "#{datetime_string(self.start_at, self.end_at)}<br/>#{description}"
    }
  end

  def to_ics(in_own_calendar: true, preloaded_attachments: {}, user: nil, user_events: [])
    CalendarEvent::IcalEvent.new(self).to_ics(in_own_calendar:,
                                              preloaded_attachments:,
                                              include_description: true,
                                              user_events:)
  end

  def self.max_visible_calendars
    10
  end

  set_policy do
    given { |user, session| context.grants_right?(user, session, :read) } # students.include?(user) }
    can :read

    given do |user, session|
      if appointment_group?
        context.grants_right?(user, session, :read_appointment_participants)
      else
        !hidden? || context.grants_right?(user, session, :manage_calendar)
      end
    end
    can :read_child_events

    given { |user, session| parent_event && appointment_group? && parent_event.grants_right?(user, session, :manage) }
    can :read and can :delete

    given { |user, session| appointment_group? && context.grants_right?(user, session, :manage) }
    can :manage

    given do |user, session|
      appointment_group? && (
        grants_right?(user, session, :manage) ||
        (context.grants_right?(user, :reserve) && context.participant_for(user).present?)
      )
    end
    can :reserve

    given do |user, session|
      if account
        context.grants_right?(user, session, :manage_account_calendar_events)
      else
        context.grants_right?(user, session, :manage_calendar)
      end
    end
    can :read and can :create

    given do |user, session|
      (!locked? || context.is_a?(AppointmentGroup)) && !deleted? && (
      if account
        context.grants_right?(user, session, :manage_account_calendar_events)
      else
        context.grants_right?(user, session, :manage_calendar)
      end
    )
    end
    can :update and can :update_content

    given do |user, session|
      !deleted? && (
      if account
        context.grants_right?(user, session, :manage_account_calendar_events)
      else
        context.grants_right?(user, session, :manage_calendar)
      end
    )
    end
    can :delete
  end

  class IcalEvent
    include Api
    include Rails.application.routes.url_helpers
    include HtmlTextHelper

    def initialize(event)
      @event = event
    end

    def location; end

    def to_ics(in_own_calendar:, preloaded_attachments: {}, include_description: false, user_events: [])
      cal = Icalendar::Calendar.new
      # to appease Outlook
      cal.append_custom_property("METHOD", "PUBLISH")

      event = Icalendar::Event.new
      event.ip_class = "PUBLIC"

      start_at = @event.is_a?(CalendarEvent) ? @event.start_at : @event.due_at
      end_at = @event.is_a?(CalendarEvent) ? @event.end_at : @event.due_at

      event.dtstart = Icalendar::Values::DateTime.new(start_at.utc_datetime, "tzid" => "UTC") if start_at
      event.dtend = Icalendar::Values::DateTime.new(end_at.utc_datetime, "tzid" => "UTC") if end_at

      if @event.all_day && @event.all_day_date
        event.dtstart = Icalendar::Values::Date.new(@event.all_day_date)
        event.dtstart.ical_params = { "VALUE" => ["DATE"] }
        # per rfc5545 3.6.12, DTEND for all day events can omit DTEND
        event.dtend = nil
      end

      event.summary = @event.title

      if @event.description && include_description
        html = api_user_content(@event.description, @event.context, nil, preloaded_attachments)
        event.description = html_to_text(html)
        event.x_alt_desc = Icalendar::Values::Text.new(html, { "FMTTYPE" => "text/html" })
      end

      loc_string = if @event.is_a?(CalendarEvent)
                     [@event.location_name, @event.location_address].compact_blank.join(", ")
                   else
                     nil
                   end

      if @event.context_type.eql?("AppointmentGroup")
        # We should only enter this block if a user has made an appointment, so
        # there is always at least one element in current_apts
        current_appts = user_events.select { |appointment| @event.id == appointment[:parent_id] }
        if current_appts.any?
          if event.description.nil?
            event.description = current_appts[0][:course_name] + "\n\n"
          else
            event.description.concat("\n\n" + current_appts[0][:course_name] + "\n\n")
          end

          event.description.concat("Participants: ")
          current_appts.each { |appt| event.description.concat("\n" + appt[:user]) }
          comments = current_appts.pluck(:comments).join(",\n")
          event.description.concat("\n\n" + comments)
        end
      end

      event.location = loc_string
      event.dtstamp = Icalendar::Values::DateTime.new(@event.updated_at.utc_datetime, "tzid" => "UTC") if @event.updated_at

      tag_name = @event.class.name.underscore

      # Covers the case for when personal calendar event is created so that HostUrl finds the correct UR:
      url_context = @event.context
      if url_context.is_a? User
        url_context = url_context.account
      end

      # This will change when there are other things that have calendars...
      # can't call calendar_url or calendar_url_for here, have to do it manually
      event.url =         "https://#{HostUrl.context_host(url_context)}/calendar?include_contexts=#{@event.context.asset_string}&month=#{start_at.try(:strftime, "%m")}&year=#{start_at.try(:strftime, "%Y")}##{tag_name}_#{@event.id}"
      event.uid =         "event-#{tag_name.tr("_", "-")}-#{@event.id}"
      event.sequence =    0

      if @event.respond_to?(:applied_overrides)
        @event.applied_overrides.try(:each) do |override|
          next unless override.due_at_overridden

          tag_name = override.class.name.underscore
          event.uid       = "event-#{tag_name.tr("_", "-")}-#{override.id}"
          event.summary   = "#{@event.title} (#{override.title})"
          # TODO: event.url
        end
      end

      # make an effort to find an associated course without diving too deep down the rabbit hole
      associated_course = nil
      if @event.is_a?(CalendarEvent)
        if @event.effective_context.is_a?(Course)
          associated_course = @event.effective_context
        elsif @event.effective_context.respond_to?(:context) && @event.effective_context.context.is_a?(Course)
          associated_course = @event.effective_context.context
        end
      elsif @event.respond_to?(:context) && @event.context_type == "Course"
        associated_course = @event.context
      end

      event.summary += " [#{associated_course.course_code}]" if associated_course

      event = nil unless start_at
      return event unless in_own_calendar

      cal.add_event(event) if event

      cal.to_ical
    end
  end

  def validate_conference_visibility
    return unless web_conference_id_changed?
    return if web_conference_id.nil?

    unless user.blank? || web_conference.grants_right?(user, :read)
      errors.add(:web_conference_id, "cannot add web conference without read access for user")
      return
    end
    conference_context = case context
                         when Course, Group
                           context
                         when CourseSection
                           context.course
                         end
    if conference_context != web_conference.context
      errors.add(:web_conference_id, "cannot add web conference from different context")
    end
  end
end
