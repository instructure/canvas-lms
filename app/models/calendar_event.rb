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
  attr_accessible :title, :description, :start_at, :end_at, :location_name, 
      :location_address, :time_zone_edited
  sanitize_field :description, Instructure::SanitizeField::SANITIZE 
  copy_authorized_links(:description) { [self.context, nil] }
  
  include Workflow
  
  adheres_to_policy
  
  belongs_to :context, :polymorphic => true
  belongs_to :user
  belongs_to :cloned_item
  validates_presence_of :context_id
  validates_presence_of :context_type
  validates_length_of :description, :maximum => maximum_long_text_length, :allow_nil => true, :allow_blank => true
  before_save :default_values
  after_save :touch_context
  
  named_scope :active, :conditions => ['calendar_events.workflow_state != ?', 'deleted']
  
  named_scope :for_context_codes, lambda {|codes|
    {:conditions => ['calendar_events.context_code IN (?)', codes] }
  }
  
  named_scope :undated, :conditions => {:start_at => nil, :end_at => nil}
  
  named_scope :between, lambda { |start, ending|
    { :conditions => { :start_at => (start)..(ending) } }
  }
  named_scope :updated_after, lambda { |*args|
    if args.first
      { :conditions => [ "calendar_events.updated_at IS NULL OR calendar_events.updated_at > ?", args.first ] }
    end
  }
  
  
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
  end
  protected :default_values
  
  workflow do
    state :active
    state :read_only
    state :cancelled
    state :deleted
  end
  
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now
    save!
  end
  
  def time_zone_edited
    CGI::unescapeHTML(read_attribute(:time_zone_edited) || "")
  end
  
  has_a_broadcast_policy
  
  set_broadcast_policy do |p|
    p.dispatch :new_event_created
    p.to { participants - [user] }
    p.whenever { |record| 
      record.context.state == :available and record.just_created
    }
    
    p.dispatch :event_date_changed
    p.to { participants - [user] }
    p.whenever { |record|
      record.context.state == :available and (
      record.changed_in_state(:active, :fields => :start_at) or
      record.changed_in_state(:active, :fields => :end_at))
    }
  end
  
  def participants
    self.context.participants
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
      entry.updated   = self.updated_at.utc
      entry.published = self.created_at.utc
      entry.links    << Atom::Link.new(:rel => 'alternate', 
                                    :href => "http://#{HostUrl.context_host(self.context)}/#{context_url_prefix}/calendar?month=#{self.start_at.strftime("%m") rescue ""}&year=#{self.start_at.strftime("%Y") rescue ""}#calendar_event_#{self.id}")
      entry.id        = "tag:#{HostUrl.default_host},#{self.created_at.strftime("%Y-%m-%d")}:/calendar_events/#{self.feed_code}_#{self.start_at.strftime("%Y-%m-%d-%H-%M") rescue "none"}_#{self.end_at.strftime("%Y-%m-%d-%H-%M") rescue "none"}"
      entry.content   = Atom::Content::Html.new("#{datetime_string(self.start_at, self.end_at)}<br/>#{self.description}")
    end
  end
  
  def to_ics(in_own_calendar=true)
    cal = Icalendar::Calendar.new
    # to appease Outlook
    cal.custom_property("METHOD","PUBLISH")

    loc_string = ""
    loc_string << self.location_name + ", " if !self.location_name.blank?
    loc_string << self.location_address if !self.location_address.blank?

    event = Icalendar::Event.new
    event.klass =       "PUBLIC"
    event.start =       DateTime.civil(
                          self.start_at.utc.strftime("%Y").to_i, 
                          self.start_at.utc.strftime("%m").to_i,
                          self.start_at.utc.strftime("%d").to_i,
                          self.start_at.utc.strftime("%H").to_i, 
                          self.start_at.utc.strftime("%M").to_i) rescue nil
    event.end =        DateTime.civil(
                          self.end_at.utc.strftime("%Y").to_i, 
                          self.end_at.utc.strftime("%m").to_i, 
                          self.end_at.utc.strftime("%d").to_i,
                          self.end_at.utc.strftime("%H").to_i, 
                          self.end_at.utc.strftime("%M").to_i) rescue nil
    event.start.icalendar_tzid = 'UTC' if event.start
    event.end.icalendar_tzid = 'UTC' if event.end
    if self.all_day
      event.start = Date.new(self.all_day_date.year, self.all_day_date.month, self.all_day_date.day)
      event.start.ical_params = {"VALUE"=>["DATE"]}
      event.end = event.start
      event.end.ical_params = {"VALUE"=>["DATE"]}
    end
    event.summary =     self.title
    event.description = self.description
    event.location =    loc_string
    event.dtstamp =     self.updated_at.to_datetime
    event.tzid =        'Europe/UTC'
    # This will change when there are other things that have calendars...
    # can't call calendar_url or calendar_url_for here, have to do it manually
    event.url           "http://#{HostUrl.context_host(self.context)}/calendar?include_contexts=#{self.context.asset_string}&month=#{self.start_at.strftime("%m") rescue ""}&year=#{self.start_at.strftime("%Y") rescue ""}#calendar_event_#{self.id.to_s}"
    event.uid           "event-calendar-event-#{self.id.to_s}"
    event.sequence      0
    event = nil unless self.start_at
    
    return event unless in_own_calendar

    cal.add_event(event) if event

    return cal.to_ical
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
    self.attributes.delete_if{|k,v| [:id].include?(k.to_sym) }.each do |key, val|
      dup.send("#{key}=", val)
    end
    dup.context = context
    dup.description = context.migrate_content_links(self.description, self.context) if options[:migrate]
    context.log_merge_result("Calendar Event \"#{self.title}\" created")
    context.may_have_links_to_migrate(dup)
    dup.updated_at = Time.now
    dup.clone_updated = true
    dup
  end

  def self.process_migration(data, migration)
    events = data['calendar_events'] ? data['calendar_events']: []
    to_import = migration.to_import 'events'
    events.each do |event|
      if event['migration_id'] && (!to_import || to_import[event['migration_id']])
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
    item.title = hash[:title] || hash[:name]
    description = ImportedHtmlConverter.convert(hash[:description] || "", context)
    if hash[:attachment_type] == 'external_url'
      url = hash[:attachment_value]
      description += "<p><a href='#{url}'>See Related Link</a></p>" if url
    elsif hash[:attachment_type] == 'assignment'
      assignment = context.assignments.find_by_migration_id(hash[:attachment_value]) rescue nil
      description += "<p><a href='/#{context.class.to_s.downcase.pluralize}/#{context.id}/assignments/#{assignment.id}'>See #{assignment.title}</a></p>" if assignment
    elsif hash[:attachment_type] == 'assessment'
      quiz = context.quizzes.find_by_migration_id(hash[:attachment_value]) rescue nil
      description += "<p><a href='/#{context.class.to_s.downcase.pluralize}/#{context.id}/quizzes/#{quiz.id}'>See #{quiz.title}</a></p>" if quiz
    elsif hash[:attachment_type] == 'file'
      file = context.attachments.find_by_migration_id(hash[:attachment_value]) rescue nil
      description += "<p><a href='/#{context.class.to_s.downcase.pluralize}/#{context.id}/files/#{file.id}/download'>See #{file.display_name}</a></p>" if file
    elsif hash[:attachment_type] == 'area'
     # ignored, no idea what this is
    elsif hash[:attachment_type] == 'web_link'
      link = context.external_url_hash[hash[:attachment_value]] rescue nil
      link ||= context.full_migration_hash['web_link_categories'].map{|c| c['links'] }.flatten.select{|l| l['link_id'] == hash[:attachment_value] } rescue nil
      description += "<p><a href='#{link['url']}'>#{link['name'] || 'See Related Link'}</a></p>" if link
    elsif hash[:attachment_type] == 'media_collection'
     # ignored, no idea what this is
    elsif hash[:attachment_type] == 'topic'
      topic = context.discussion_topic.find_by_migration_id(hash[:attachment_value]) rescue nil
      description += "<p><a href='/#{context.class.to_s.downcase.pluralize}/#{context.id}/discussion_topics/#{topic.id}'>See #{topic.title}</a></p>" if topic
    end
    item.description = description
    
    hash[:start_at] ||= hash[:start_date]
    hash[:end_at] ||= hash[:end_date]
    item.start_at = Canvas::MigratorHelper.get_utc_time_from_timestamp(hash[:start_at]) unless hash[:start_at].nil?
    item.end_at = Canvas::MigratorHelper.get_utc_time_from_timestamp(hash[:end_at]) unless hash[:end_at].nil?
    
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
    set { can :read }
    
    given { |user, session| self.cached_context_grants_right?(user, session, :manage_calendar) }#admins.include?(user) }
    set { can :read and can :create }
    
    given { |user, session| self.cached_context_grants_right?(user, session, :manage_calendar) }#admins.include?(user) }
    set { can :update and can :update_content and can :delete }
    
  end
end

