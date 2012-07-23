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

require 'date'

class CalendarEvent < ActiveRecord::Base
  include CopyAuthorizedLinks
  include TextHelper
  attr_accessible :title, :description, :start_at, :end_at, :location_name,
      :location_address, :time_zone_edited, :cancel_reason,
      :participants_per_appointment, :child_event_data,
      :remove_child_events
  attr_accessor :cancel_reason
  sanitize_field :description, Instructure::SanitizeField::SANITIZE
  copy_authorized_links(:description) { [self.effective_context, nil] }

  include Workflow


  belongs_to :context, :polymorphic => true
  belongs_to :user
  belongs_to :cloned_item
  belongs_to :parent_event, :class_name => 'CalendarEvent', :foreign_key => :parent_calendar_event_id
  has_many :child_events, :class_name => 'CalendarEvent', :foreign_key => :parent_calendar_event_id, :conditions => "calendar_events.workflow_state <> 'deleted'"
  validates_presence_of :context
  validates_associated :context, :if => lambda { |record| record.validate_context }
  validates_length_of :description, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :title, :maximum => maximum_string_length, :allow_nil => true, :allow_blank => true
  before_save :default_values
  after_save :touch_context
  after_save :replace_child_events
  after_save :sync_parent_event
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
    next record.errors.add(attr, t('errors.no_updating_user', "Can't update child events unless an updating_user is set")) if events.present? && !record.updating_user
    context_codes = events.map{ |e| e[:context_code] }
    next record.errors.add(attr, t('errors.duplicate_child_event_contexts', "Duplicate child event contexts")) if context_codes != context_codes.uniq
    contexts = find_all_by_asset_string(context_codes).group_by(&:asset_string)
    context_codes.each do |code|
      context = contexts[code] && contexts[code][0]
      next if context && context.grants_right?(record.updating_user, :manage_calendar) && context.try(:parent_event_context) == record.context
      break record.errors.add(attr, t('errors.invalid_child_event_context', "Invalid child event context"))
    end
    record.child_event_contexts = contexts
    record.child_event_data = events
  end

  def replace_child_events
    return unless @child_event_data
    current_events = child_events.group_by{ |e| e[:context_code] }
    @child_event_data.each do |data|
      if event = current_events.delete(data[:context_code]) and event = event[0]
        event.updating_user = @updating_user
        event.update_attributes(:start_at => data[:start_at], :end_at => data[:end_at])
      else
        context = @child_event_contexts[data[:context_code]][0]
        event = child_events.build(:start_at => data[:start_at], :end_at => data[:end_at])
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
    !appointment_group && child_events.size > 0
  end

  def effective_context
    effective_context_code && ActiveRecord::Base.find_by_asset_string(effective_context_code) || context
  end

  named_scope :active, :conditions => ['calendar_events.workflow_state != ?', 'deleted']
  named_scope :locked, :conditions => ["calendar_events.workflow_state = 'locked'"]
  named_scope :unlocked, :conditions => ['calendar_events.workflow_state NOT IN (?)', ['deleted', 'locked']]

  # controllers/apis/etc. should generally use for_user_and_context_codes instead
  named_scope :for_context_codes, lambda { |codes|
    {:conditions => ['calendar_events.context_code IN (?)', codes] }
  }

  # appointments and appointment_participants have the appointment_group and
  # the user as the context, respectively. we are actually interested in
  # grouping them under the effective context (i.e. appointment_group.context).
  # it's the responsibility of the caller to ensure the user has rights to the
  # specified codes (e.g. using User#appointment_context_codes)
  named_scope :for_user_and_context_codes, lambda { |user, *args|
    codes = args.shift
    section_codes = args.shift || user.section_context_codes(codes)
    effectively_courses_codes = [user.asset_string] + section_codes
    # the all_codes check is redundant, but makes the query more efficient
    all_codes = codes | effectively_courses_codes
    group_codes = codes.grep(/\Aappointment_group_\d+\z/)
    codes -= group_codes

    codes_conditions = codes.map { |code|
      wildcard(quoted_table_name + '.effective_context_code', code, :delimiter => ',')
    }.join(" OR ")
    codes_conditions = self.connection.quote(false) if codes_conditions.blank?

    {:conditions => [<<-SQL, all_codes, codes, group_codes, effectively_courses_codes]}
      calendar_events.context_code IN (?)
      AND (
        ( -- explicit contexts (e.g. course_123)
          calendar_events.context_code IN (?)
          AND calendar_events.effective_context_code IS NULL
        )
        OR ( -- appointments (manageable or reservable)
          calendar_events.context_code IN (?)
        )
        OR ( -- own appointment_participants, or section events in the course
          calendar_events.context_code IN (?)
          AND (#{codes_conditions})
        )
      )
    SQL
  }

  named_scope :undated, :conditions => {:start_at => nil, :end_at => nil}

  named_scope :between, lambda { |start, ending|
    { :conditions => { :start_at => (start)..(ending) } }
  }
  named_scope :current, lambda {
    { :conditions => ['calendar_events.end_at >= ?', Time.zone.today.to_datetime.utc] }
  }
  named_scope :updated_after, lambda { |*args|
    if args.first
      { :conditions => [ "calendar_events.updated_at IS NULL OR calendar_events.updated_at > ?", args.first ] }
    end
  }

  def validate_context!
    @validate_context = true
    context.validation_event_override = self
  end
  attr_reader :validate_context

  def default_values
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}"
    self.title ||= (self.context_type.to_s + " Event") rescue "Event"
    self.end_at ||= self.start_at
    self.start_at ||= self.end_at
    if(self.start_at && self.end_at && self.end_at < self.start_at)
      self.end_at = self.start_at
    end
    zoned_start_at = self.start_at && ActiveSupport::TimeWithZone.new(self.start_at.utc, (ActiveSupport::TimeZone.new(self.time_zone_edited) rescue nil) || Time.zone)
    if self.start_at_changed?
      if self.start_at && self.start_at == self.end_at && zoned_start_at.strftime("%H:%M") == '00:00'
        self.all_day = true
      elsif self.start_at && self.start_at_was && self.start_at == self.end_at && self.all_day && self.start_at.strftime("%H:%M") == self.start_at_was.strftime("%H:%M")
        self.all_day = true
      else
        self.all_day = false
      end
    end

    self.all_day_date = (zoned_start_at.to_date rescue nil) if !self.all_day_date || self.start_at_changed? || self.all_day_date_changed?

    if parent_event
      self.effective_context_code = if appointment_group # appointment participant
                                      appointment_group.appointment_group_contexts.map(&:context_code).join(',') if appointment_group.participant_type == 'User' 
                                    else # e.g. section-level event
                                      parent_event.context_code
                                    end
      (locked? ? LOCKED_ATTRIBUTES : CASCADED_ATTRIBUTES).each{ |attr| send("#{attr}=", parent_event.send(attr)) }
    elsif context.is_a?(AppointmentGroup)
      self.effective_context_code = context.appointment_group_contexts.map(&:context_code).join(",")
      if new_record?
        AppointmentGroup::EVENT_ATTRIBUTES.each { |attr| send("#{attr}=", attr == :description ? context.description_html : context.send(attr)) }
        if locked?
          self.start_at = start_at_was if !new_record? && start_at_changed?
          self.end_at = end_at_was if !new_record? && end_at_changed?
        end
      else
        # we only allow changing the description
        (AppointmentGroup::EVENT_ATTRIBUTES - [:description]).each { |attr| send("#{attr}=", send("#{attr}_was")) if send("#{attr}_changed?") }
      end
    end
  end
  protected :default_values

  CASCADED_ATTRIBUTES = [
    :title,
    :description,
    :location_name,
    :location_address
  ]
  LOCKED_ATTRIBUTES = CASCADED_ATTRIBUTES + [
    :start_at,
    :end_at
  ]

  def sync_child_events
    locked_changes = LOCKED_ATTRIBUTES.select { |attr| send("#{attr}_changed?") }
    cascaded_changes = CASCADED_ATTRIBUTES.select { |attr| send("#{attr}_changed?") }
    child_events.locked.update_all Hash[locked_changes.map{ |attr| [attr, send(attr)] }] if locked_changes.present?
    child_events.unlocked.update_all Hash[cascaded_changes.map{ |attr| [attr, send(attr)] }] if cascaded_changes.present?
  end

  attr_writer :skip_sync_parent_event
  def sync_parent_event
    return unless parent_event
    return if appointment_group
    return unless start_at_changed? || end_at_changed? || workflow_state_changed?
    return if @skip_sync_parent_event
    parent_event.cache_child_event_ranges!
  end

  def cache_child_event_ranges!
    events = child_events(true)
    CalendarEvent.update_all({:start_at => events.map(&:start_at).min,
                              :end_at => events.map(&:end_at).max
                             }, ["id = ?", id])
    reload
  end

  workflow do
    state :active
    state :locked do # locked events may only be deleted, they cannot be edited directly
      event :unlock, :transitions_to => :active
    end
    state :deleted
  end

  alias_method :destroy!, :destroy
  def destroy(update_context_or_parent=true)
    transaction do
      self.workflow_state = 'deleted'
      self.deleted_at = Time.now.utc
      save!
      child_events.each do |e|
        e.cancel_reason = cancel_reason
        e.updating_user = updating_user
        e.destroy(false)
      end
      return true unless update_context_or_parent

      if appointment_group
        context.touch if context_type == 'AppointmentGroup' # ensures end_at/start_at get updated
        # when deleting an appointment or appointment_participant, make sure we reset the cache
        appointment_group.clear_cached_available_slots!
      end
      if parent_event && parent_event.locked? && parent_event.child_events.size == 0
        parent_event.workflow_state = 'active'
        parent_event.save!
      end
      true
    end
  end

  def time_zone_edited
    CGI::unescapeHTML(read_attribute(:time_zone_edited) || "")
  end

  has_a_broadcast_policy

  set_broadcast_policy do
    dispatch :new_event_created
    to { participants - [@updating_user] }
    whenever {
      !appointment_group && context.available? && just_created && !hidden?
    }

    dispatch :event_date_changed
    to { participants - [@updating_user] }
    whenever {
      !appointment_group &&
      context.available? && (
        changed_in_state(:active, :fields => :start_at) ||
        changed_in_state(:active, :fields => :end_at)
      ) && !hidden?
    }

    dispatch :appointment_reserved_by_user
    to { appointment_group.instructors }
    whenever {
      appointment_group && parent_event &&
      just_created &&
      context == appointment_group.participant_for(user)
    }
    data { {:updating_user => @updating_user} }

    dispatch :appointment_canceled_by_user
    to { appointment_group.instructors }
    whenever {
      appointment_group && parent_event &&
      deleted? &&
      workflow_state_changed? &&
      @updating_user &&
      context == appointment_group.participant_for(@updating_user)
    }
    data { {
      :updating_user => @updating_user,
      :cancel_reason => @cancel_reason
    } }

    dispatch :appointment_reserved_for_user
    to { participants - [@updating_user] }
    whenever {
      appointment_group && parent_event &&
      just_created
    }
    data { {:updating_user => @updating_user} }

    dispatch :appointment_deleted_for_user
    to { participants - [@updating_user] }
    whenever {
      appointment_group && parent_event &&
      deleted? &&
      workflow_state_changed?
    }
    data { {
      :updating_user => @updating_user,
      :cancel_reason => @cancel_reason
    } }
  end

  def participants
    # TODO: User#participants should probably be fixed to return [self],
    # then we can simplify this again
    context_type == 'User' ? [context] : context.participants
  end

  attr_reader :updating_user
  def updating_user=(user)
    self.user ||= user
    @updating_user = user
    content_being_saved_by(user)
  end

  def user
    read_attribute(:user) || (context_type == 'User' ? context : nil)
  end

  def appointment_group
    if parent_event.try(:context).is_a?(AppointmentGroup)
      parent_event.context
    elsif context_type == 'AppointmentGroup'
      context
    end
  end

  class ReservationError < StandardError; end
  def reserve_for(participant, user, options = {})
    raise ReservationError, "not an appointment" unless context_type == 'AppointmentGroup'
    raise ReservationError, "ineligible participant" unless context.eligible_participant?(participant)

    transaction do
      lock! # in case two people two participants try to grab the same slot
      participant.lock! # in case two people try to make a reservation for the same participant

      if options[:cancel_existing]
        context.reservations_for(participant).scoped(:lock => true).each do |reservation|
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
      event.save!
      if active?
        self.workflow_state = 'locked'
        save!
      end
      context.clear_cached_available_slots!
      event
    end
  end

  def child_events_for(participant)
    child_events.select{ |e| e.has_asset?(participant) }
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
    limit
  end

  def update_matching_days=(update)
    @update_matching_days = update == '1' || update == true || update == 'true'
  end

  def all_day
    read_attribute(:all_day) || (self.new_record? && self.start_at && self.start_at.strftime("%H:%M") == '00:00')
  end

  def to_atom(opts={})
    extend ApplicationHelper
    Atom::Entry.new do |entry|
      entry.title     = t(:feed_item_title, "Calendar Event: %{event_title}", :event_title => self.title) unless opts[:include_context]
      entry.title     = t(:feed_item_title_with_context, "Calendar Event, %{course_or_account_name}: %{event_title}", :course_or_account_name => self.context.name, :event_title => self.title) if opts[:include_context]
      entry.authors  << Atom::Person.new(:name => self.context.name)
      entry.updated   = self.updated_at.utc
      entry.published = self.created_at.utc
      entry.links    << Atom::Link.new(:rel => 'alternate',
                                    :href => "http://#{HostUrl.context_host(self.context)}/#{context_url_prefix}/calendar?month=#{self.start_at.strftime("%m") rescue ""}&year=#{self.start_at.strftime("%Y") rescue ""}#calendar_event_#{self.id}")
      entry.id        = "tag:#{HostUrl.default_host},#{self.created_at.strftime("%Y-%m-%d")}:/calendar_events/#{self.feed_code}_#{self.start_at.strftime("%Y-%m-%d-%H-%M") rescue "none"}_#{self.end_at.strftime("%Y-%m-%d-%H-%M") rescue "none"}"
      entry.content   = Atom::Content::Html.new("#{datetime_string(self.start_at, self.end_at)}<br/>#{self.description}")
    end
  end

  def to_ics(in_own_calendar=true)
    return CalendarEvent::IcalEvent.new(self).to_ics(in_own_calendar)
  end

  def self.search(query)
    find(:all, :conditions => wildcard('title', 'description', query))
  end

  attr_accessor :clone_updated
  def clone_for(context, dup=nil, options={})
    options[:migrate] = true if options[:migrate] == nil
    if !self.cloned_item && !self.new_record?
      self.cloned_item ||= ClonedItem.create(:original_item => self)
      self.save!
    end
    existing = context.calendar_events.active.find_by_id(self.id)
    existing ||= context.calendar_events.active.find_by_cloned_item_id(self.cloned_item_id || 0)
    return existing if existing && !options[:overwrite]
    dup ||= CalendarEvent.new
    dup = existing if existing && options[:overwrite]
    self.attributes.delete_if{|k,v| %w(id participants_per_appointment).include?(k) }.each do |key, val|
      dup.send("#{key}=", val)
    end
    dup.context = context
    dup.description = context.migrate_content_links(self.description, self.context) if options[:migrate]
    dup.write_attribute :participants_per_appointment, read_attribute(:participants_per_appointment)
    context.log_merge_result("Calendar Event \"#{self.title}\" created")
    context.may_have_links_to_migrate(dup)
    dup.updated_at = Time.now
    dup.clone_updated = true
    dup
  end

  def self.process_migration(data, migration)
    events = data['calendar_events'] ? data['calendar_events']: []
    events.each do |event|
      if migration.import_object?("events", event['migration_id'])
        begin
          import_from_migration(event, migration.context)
        rescue
          migration.add_warning("Couldn't import the event \"#{event[:title]}\"", $!)
        end
      end
    end
  end

  def self.import_from_migration(hash, context, item=nil)
    hash = hash.with_indifferent_access
    return nil if hash[:migration_id] && hash[:events_to_import] && !hash[:events_to_import][hash[:migration_id]]
    item ||= find_by_context_type_and_context_id_and_id(context.class.to_s, context.id, hash[:id])
    item ||= find_by_context_type_and_context_id_and_migration_id(context.class.to_s, context.id, hash[:migration_id]) if hash[:migration_id]
    item ||= context.calendar_events.new
    context.imported_migration_items << item if context.imported_migration_items && item.new_record?
    item.migration_id = hash[:migration_id]
    item.workflow_state = 'active' if item.deleted?
    item.title = hash[:title] || hash[:name]
    description = ImportedHtmlConverter.convert(hash[:description] || "", context)
    if hash[:attachment_type] == 'external_url'
      url = hash[:attachment_value]
      description += "<p><a href='#{url}'>" + ERB::Util.h(t(:see_related_link, "See Related Link")) + "</a></p>" if url
    elsif hash[:attachment_type] == 'assignment'
      assignment = context.assignments.find_by_migration_id(hash[:attachment_value]) rescue nil
      description += "<p><a href='/#{context.class.to_s.downcase.pluralize}/#{context.id}/assignments/#{assignment.id}'>" + ERB::Util.h(t(:see_assignment, "See %{assignment_name}", :assignment_name => assignment.title)) + "</a></p>" if assignment
    elsif hash[:attachment_type] == 'assessment'
      quiz = context.quizzes.find_by_migration_id(hash[:attachment_value]) rescue nil
      description += "<p><a href='/#{context.class.to_s.downcase.pluralize}/#{context.id}/quizzes/#{quiz.id}'>" + ERB::Util.h(t(:see_quiz, "See %{quiz_name}", :quiz_name => quiz.title)) + "</a></p>" if quiz
    elsif hash[:attachment_type] == 'file'
      file = context.attachments.find_by_migration_id(hash[:attachment_value]) rescue nil
      description += "<p><a href='/#{context.class.to_s.downcase.pluralize}/#{context.id}/files/#{file.id}/download'>" + ERB::Util.h(t(:see_file, "See %{file_name}", :file_name => file.display_name)) + "</a></p>" if file
    elsif hash[:attachment_type] == 'area'
     # ignored, no idea what this is
    elsif hash[:attachment_type] == 'web_link'
      link = context.external_url_hash[hash[:attachment_value]] rescue nil
      link ||= context.full_migration_hash['web_link_categories'].map{|c| c['links'] }.flatten.select{|l| l['link_id'] == hash[:attachment_value] } rescue nil
      description += "<p><a href='#{link['url']}'>#{link['name'] || ERB::Util.h(t(:see_related_link, "See Related Link"))}</a></p>" if link
    elsif hash[:attachment_type] == 'media_collection'
     # ignored, no idea what this is
    elsif hash[:attachment_type] == 'topic'
      topic = context.discussion_topic.find_by_migration_id(hash[:attachment_value]) rescue nil
      description += "<p><a href='/#{context.class.to_s.downcase.pluralize}/#{context.id}/discussion_topics/#{topic.id}'>" + ERB::Util.h(t(:see_discussion_topic, "See %{discussion_topic_name}", :discussion_topic_name => topic.title)) + "</a></p>" if topic
    end
    item.description = description

    hash[:start_at] ||= hash[:start_date]
    hash[:end_at] ||= hash[:end_date]
    item.start_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:start_at]) unless hash[:start_at].nil?
    item.end_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:end_at]) unless hash[:end_at].nil?

    item.save_without_broadcasting!
    context.imported_migration_items << item if context.imported_migration_items
    if hash[:all_day]
      item.all_day = hash[:all_day]
      item.save
    end
    item
  end

  def self.max_visible_calendars
    10
  end

  set_policy do
    given { |user, session| self.cached_context_grants_right?(user, session, :read) }#students.include?(user) }
    can :read

    given { |user, session| !appointment_group ^ cached_context_grants_right?(user, session, :read_appointment_participants) }
    can :read_child_events

    given { |user, session| parent_event && appointment_group && parent_event.grants_right?(user, session, :manage) }
    can :read and can :delete

    given { |user, session| appointment_group && cached_context_grants_right?(user, session, :manage) }
    can :manage

    given { |user, session|
      appointment_group && (
        grants_right?(user, session, :manage) ||
        cached_context_grants_right?(user, nil, :reserve) && context.participant_for(user).present?
      )
    }
    can :reserve

    given { |user, session| self.cached_context_grants_right?(user, session, :manage_calendar) }#admins.include?(user) }
    can :read and can :create

    given { |user, session| (!locked? || context.is_a?(AppointmentGroup)) && !deleted? && self.cached_context_grants_right?(user, session, :manage_calendar) }#admins.include?(user) }
    can :update and can :update_content

    given { |user, session| !deleted? && self.cached_context_grants_right?(user, session, :manage_calendar) }
    can :delete
  end

  class IcalEvent
    include Api
    include ActionController::UrlWriter
    include TextHelper

    def initialize(event)
      @event = event
    end

    def location
    end

    def to_ics(in_own_calendar)
      cal = Icalendar::Calendar.new
      # to appease Outlook
      cal.custom_property("METHOD","PUBLISH")

      event = Icalendar::Event.new
      event.klass = "PUBLIC"

      start_at = @event.is_a?(CalendarEvent) ? @event.start_at : @event.due_at
      end_at = @event.is_a?(CalendarEvent) ? @event.end_at : @event.due_at

      if start_at
        event.start = start_at.utc_datetime
        event.start.icalendar_tzid = 'UTC'
      end

      if end_at
        event.end = end_at.utc_datetime
        event.end.icalendar_tzid = 'UTC'
      end

      if @event.all_day
        event.start = Date.new(@event.all_day_date.year, @event.all_day_date.month, @event.all_day_date.day)
        event.start.ical_params = {"VALUE"=>["DATE"]}
        event.end = event.start
        event.end.ical_params = {"VALUE"=>["DATE"]}
      end
      event.summary = @event.title
      if @event.description
        html = api_user_content(@event.description, @event.context)
        event.description html_to_text(html)
        event.x_alt_desc(html, { 'FMTTYPE' => 'text/html' })
      end

      if @event.is_a?(CalendarEvent)
        loc_string = ""
        loc_string << @event.location_name + ", " if @event.location_name.present?
        loc_string << @event.location_address if @event.location_address.present?
      else
        loc_string = @event.location
      end

      event.location = loc_string
      event.dtstamp = @event.updated_at.utc_datetime if @event.updated_at
      event.dtstamp.icalendar_tzid = 'UTC' if event.dtstamp

      tag_name = @event.class.name.underscore

      # This will change when there are other things that have calendars...
      # can't call calendar_url or calendar_url_for here, have to do it manually
      event.url           "http://#{HostUrl.context_host(@event.context)}/calendar?include_contexts=#{@event.context.asset_string}&month=#{start_at.try(:strftime, "%m")}&year=#{start_at.try(:strftime, "%Y")}##{tag_name}_#{@event.id.to_s}"
      event.uid           "event-#{tag_name.gsub('_', '-')}-#{@event.id.to_s}"
      event.sequence      0
      event = nil unless start_at

      return event unless in_own_calendar

      cal.add_event(event) if event

      return cal.to_ical
    end
  end
end

