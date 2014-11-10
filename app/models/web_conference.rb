#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

class WebConference < ActiveRecord::Base
  include SendToStream
  include TextHelper
  attr_accessible :title, :duration, :description, :conference_type, :user, :user_settings, :context
  attr_readonly :context_id, :context_type
  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course', 'Group', 'Account']
  has_many :web_conference_participants
  has_many :users, :through => :web_conference_participants
  has_many :invitees, :through => :web_conference_participants, :source => :user, :conditions => ['web_conference_participants.participation_type = ?', 'invitee']
  has_many :attendees, :through => :web_conference_participants, :source => :user, :conditions => ['web_conference_participants.participation_type = ?', 'attendee']
  belongs_to :user

  EXPORTABLE_ATTRIBUTES = [
    :id, :title, :conference_type, :conference_key, :context_id, :context_type, :user_ids, :added_user_ids, :user_id, :started_at, :description, :duration, :created_at,
    :updated_at, :uuid, :invited_user_ids, :ended_at, :start_at, :end_at, :context_code, :type, :settings
  ]

  EXPORTABLE_ASSOCIATIONS = [:web_conference_participants, :users, :invitees, :attendees, :user]

  validates_length_of :description, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_presence_of :conference_type, :title, :context_id, :context_type, :user_id

  before_validation :infer_conference_details

  before_create :assign_uuid
  after_save :touch_context

  has_a_broadcast_policy

  scope :for_context_codes, lambda { |context_codes| where(:context_code => context_codes) }

  scope :with_config, -> { where(conference_type: WebConference.conference_types.map{|ct| ct['conference_type']}) }

  serialize :settings
  def settings
    read_attribute(:settings) || write_attribute(:settings, default_settings)
  end

  # whether they replace the whole hash or just update some values, make sure
  # we save those changes (after we sanitize it)
  before_save :merge_user_settings
  def merge_user_settings
    unless user_settings.empty?
      (type ? type.constantize : self).user_setting_fields.each do |name, field_data|
        next if field_data[:restricted_to] && !field_data[:restricted_to].call(self)
        settings[name] = cast_setting(user_settings[name], field_data[:type])
      end
      @user_settings = nil
    end
  end

  def user_settings=(new_settings)
    @user_settings = new_settings.symbolize_keys
  end

  def user_settings
    @user_settings ||=
      self.class.user_setting_fields.keys.inject({}){ |hash, key|
        hash[key] = settings[key]
        hash
      }
  end

  def external_urls_name(key)
    external_urls[key][:name].call
  end

  def external_urls_link_text(key)
    external_urls[key][:link_text].call
  end

  def cast_setting(value, type)
    case type
      when :boolean
        ['1', 'on', 'true'].include?(value.to_s)
      else value
    end
  end

  def friendly_setting(value)
    case value
      when true
        t('#web_conference.settings.boolean.true', "On")
      when false
        t('#web_conference.settings.boolean.false', "Off")
      else value.to_s
    end
  end

  def default_settings
    @default_settings ||=
    self.class.user_setting_fields.inject({}){ |hash, (name, data)|
      hash[name] = data[:default] if data[:default]
      hash
    }
  end

  def self.user_setting_field(name, options)
    user_setting_fields[name] = options
  end

  def self.user_setting_fields
    @user_setting_fields ||= {}
  end

  def self.user_setting_fields=(val)
    @user_setting_fields = val
  end

  def self.user_setting_field_name(key)
    user_setting_fields[key][:name].call
  end

  def self.user_setting_field_description(key)
    user_setting_fields[key][:description].call
  end

  def external_urls
    @external_urls ||= self.class.external_urls.dup.delete_if{ |key, info| info[:restricted_to] && !info[:restricted_to].call(self) }
  end

  # #{key}_external_url should return an array of hashes with url information (:name, :id, and :url).
  # if there is just one, we will redirect, otherwise we'll present links to all of them (possibly
  # redirecting through here again in case the url has a short-lived token and needs to be
  # regenerated)
  def external_url_for(key, user, url_id = nil)
    external_urls[key.to_sym] &&
    respond_to?("#{key}_external_url") &&
    send("#{key}_external_url", user, url_id) || []
  end

  def self.external_urls
    @external_urls ||= {}
  end
  def self.external_urls=(val)
    @external_urls = val
  end

  def self.external_url(name, options)
    external_urls[name] = options
  end

  def assign_uuid
    self.uuid ||= CanvasSlug.generate_securish_uuid
  end
  protected :assign_uuid

  set_broadcast_policy do |p|
    p.dispatch :web_conference_invitation
    p.to { @new_participants.select { |p| context.membership_for_user(p).active? } }
    p.whenever { |record|
      @new_participants && !@new_participants.empty?
    }
  end

  on_create_send_to_streams do
    [self.user_id] + self.web_conference_participants.map(&:user_id)
  end

  def add_user(user, type)
    return unless user
    p = self.web_conference_participants.where(user_id: user).first
    p ||= self.web_conference_participants.build(user: user)
    p.participation_type = type unless type == 'attendee' && p.participation_type == 'initiator'
    (@new_participants ||= []) << user if p.new_record?
    # Once anyone starts attending the conference, mark it as started.
    if type == 'attendee'
      self.started_at ||= Time.now
      self.save
    end
    p.save
  end

  def added_users
    attendees
  end

  def add_initiator(user)
    add_user(user, 'initiator')
  end
  def add_invitee(user)
    add_user(user, 'invitee')
  end
  def add_attendee(user)
    add_user(user, 'attendee')
  end

  def context_code
    read_attribute(:context_code) || "#{self.context_type.underscore}_#{self.context_id}" rescue nil
  end

  def infer_conference_settings
  end

  def conference_type=(val)
    conf_type = WebConference.conference_types.detect{|t| t[:conference_type] == val }
    if conf_type
      write_attribute(:conference_type, conf_type[:conference_type] )
      write_attribute(:type, conf_type[:class_name] )
      conf_type[:conference_type]
    else
      nil
    end
  end

  def infer_conference_details
    infer_conference_settings
    self.conference_type ||= config && config[:conference_type]
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
    self.user_ids ||= (self.user_id || "").to_s
    self.added_user_ids ||= ""
    self.title ||= self.context.is_a?(Course) ? t('#web_conference.default_name_for_courses', "Course Web Conference") : t('#web_conference.default_name_for_groups', "Group Web Conference")
    self.start_at ||= self.started_at
    self.end_at ||= self.ended_at
    self.end_at ||= self.start_at + self.duration.minutes if self.start_at && self.duration
    if self.started_at && self.ended_at && self.ended_at < self.started_at
      self.ended_at = self.started_at
    end
  end

  def initiator
    self.user
  end

  def available?
    !self.started_at
  end

  def finished?
    self.started_at && !self.active?
  end

  def restartable?
    end_at && Time.now <= end_at && !long_running?
  end

  def long_running?
    duration.nil?
  end
  def long_running
    long_running? ? 1 : 0
  end

  DEFAULT_DURATION = 60
  def duration_in_seconds
    duration ? duration * 60 : nil
  end

  def running_time
    if ended_at.present? && started_at.present?
      [ended_at - started_at, 60].max
    else
      0
    end
  end

  def restart
    self.start_at ||= Time.now
    self.end_at ||= self.start_at + self.duration_in_seconds if self.duration
    self.started_at ||= self.start_at
    self.ended_at = nil
    self.save
  end

  # Default implementation since most implementations don't support scheduling yet
  def scheduled?
    self.started_at.nil? && scheduled_date && scheduled_date > Time.now
  end

  # Default implementation since most implementations don't support scheduling yet
  def scheduled_date
    nil
  end

  def active?(force_check=false)
    if !force_check
      return true if self.start_at && (self.end_at.nil? || self.end_at && Time.now > self.start_at && Time.now < self.end_at)
      return true if self.ended_at && Time.now < self.ended_at
      return false if self.ended_at && Time.now > self.ended_at
      return @conference_active if @conference_active
    end
    @conference_active = (conference_status == :active)
    # If somehow the end_at didn't get set, set the end date
    # based on the start time and duration
    if @conference_active && !self.end_at && !long_running?
      self.start_at ||= Time.now
      self.end_at = [self.start_at, Time.now].compact.min + self.duration_in_seconds
      self.save
    # If the conference is still active but it's been more than fifteen minutes
    # since it was supposed to end, just go ahead and end it
    elsif @conference_active && self.end_at && self.end_at < 15.minutes.ago && !self.ended_at
      self.ended_at = Time.now
      self.start_at ||= self.started_at
      self.end_at ||= self.ended_at
      @conference_active = false
      self.save
    # If the conference is no longer in use and its end_at has passed,
    # consider it ended
    elsif @conference_active == false && self.started_at && self.end_at && self.end_at < Time.now && !self.ended_at
      close
    end
    @conference_active
  rescue Errno::ECONNREFUSED => ex
    # Account credentials changed, server unreachable/down, bad stuff happened.
    @conference_active = false
    @conference_active
  end

  def close
    self.ended_at = Time.now
    self.start_at ||= started_at
    self.end_at ||= ended_at
    save
  end

  def presenter_key
    @presenter_key ||= "instructure_" + Digest::MD5.hexdigest([user_id, self.uuid].join(","))
  end

  def attendee_key
    @attendee_key ||= self.conference_key
  end

  # Default implementaiton since not every conference type requires initiation
  def initiate_conference
    true
  end

  # Default implementation since most implementations don't support recording yet
  def recordings
    []
  end

  def craft_url(user=nil,session=nil,return_to="http://www.instructure.com")
    user ||= self.user
    initiate_conference and touch or return nil
    if user == self.user || self.grants_right?(user, session, :initiate)
      admin_join_url(user, return_to)
    else
      participant_join_url(user, return_to)
    end
  end

  def has_advanced_settings?
    respond_to?(:admin_settings_url)
  end
  def has_advanced_settings
    has_advanced_settings? ? 1 : 0
  end

  scope :after, lambda { |date| where("web_conferences.start_at IS NULL OR web_conferences.start_at>?", date) }

  set_policy do
    given { |user, session| self.users.include?(user) && self.context.grants_right?(user, session, :read) }
    can :read and can :join

    given { |user, session| self.users.include?(user) && self.context.grants_right?(user, session, :read) && long_running? && active? }
    can :resume

    given { |user| (self.respond_to?(:is_public) && self.is_public rescue false) }
    can :read and can :join

    given { |user, session| self.context.grants_right?(user, session, :create_conferences) }
    can :create

    given { |user, session| user && user.id == self.user_id && self.context.grants_right?(user, session, :create_conferences) }
    can :initiate

    given { |user, session| self.context.grants_right?(user, session, :manage_content) }
    can :read and can :join and can :initiate and can :create and can :delete

    given { |user, session| context.grants_right?(user, session, :manage_content) && !finished? }
    can :update

    given { |user, session| context.grants_right?(user, session, :manage_content) && long_running? && active? }
    can :close
  end

  def config
    @config ||= WebConference.config(self.class.to_s)
  end

  def valid_config?
    if !config
      false
    else
      config[:class_name] == self.class.to_s
    end
  end

  scope :active, -> { scoped }

  def as_json(options={})
    url = options.delete(:url)
    join_url = options.delete(:join_url)
    options.reverse_merge!(:only => %w(id title description conference_type duration started_at ended_at user_ids context_id context_type context_code))
    result = super(options.merge(:include_root => false, :methods => [:has_advanced_settings, :long_running, :user_settings, :recordings]))
    result['url'] = url
    result['join_url'] = join_url
    result
  end

  def self.plugins
    Canvas::Plugin.all_for_tag(:web_conferencing)
  end

  def self.conference_types
    plugins.map{ |plugin|
      next unless plugin.enabled? &&
          (klass = (plugin.base || "#{plugin.id.classify}Conference").constantize rescue nil) &&
          klass < self.base_class
      plugin.settings.merge(
        :conference_type => plugin.id.classify,
        :class_name => (plugin.base || "#{plugin.id.classify}Conference"),
        :user_setting_fields => klass.user_setting_fields,
        :plugin => plugin
      ).with_indifferent_access
    }.compact
  end

  def self.config(class_name=nil)
    if class_name
      conference_types.detect{ |c| c[:class_name] == class_name }
    else
      conference_types.first
    end
  end

  def self.serialization_excludes; [:uuid]; end
end
