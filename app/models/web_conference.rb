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

class WebConference < ActiveRecord::Base
  include SendToStream
  include TextHelper
  attr_readonly :context_id, :context_type
  belongs_to :context, polymorphic: %i[course group account]
  has_one :calendar_event, -> { order("updated_at desc") }, inverse_of: :web_conference, dependent: :nullify
  has_many :web_conference_participants
  has_many :users, through: :web_conference_participants
  has_many :invitees, -> { where(web_conference_participants: { participation_type: "invitee" }) }, through: :web_conference_participants, source: :user
  has_many :attendees, -> { where(web_conference_participants: { participation_type: "attendee" }) }, through: :web_conference_participants, source: :user
  belongs_to :user

  validates :description, length: { maximum: maximum_text_length, allow_blank: true }
  validates :conference_type, :title, :context_id, :context_type, :user_id, presence: true
  validates :title, length: { within: 0..255 }
  validate :lti_tool_valid, if: -> { conference_type == "LtiConference" }

  MAX_DURATION = 99_999_999
  validates :duration, numericality: { less_than_or_equal_to: MAX_DURATION, allow_nil: true }

  before_validation :infer_conference_details

  before_create :assign_uuid
  before_create :set_root_account_id
  after_save :touch_context

  has_a_broadcast_policy

  scope :for_context_codes, ->(context_codes) { where(context_code: context_codes) }

  scope :with_config_for, ->(context:) { where(conference_type: WebConference.conference_types(context).pluck("conference_type")) }

  scope :live, -> { where("web_conferences.started_at BETWEEN (NOW() - interval '1 day') AND NOW() AND (web_conferences.ended_at IS NULL OR web_conferences.ended_at > NOW())") }

  serialize :settings
  def settings
    read_or_initialize_attribute(:settings, {})
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
    new_settings = new_settings.symbolize_keys
    if new_settings != user_settings
      settings_will_change!
      @user_settings = new_settings
    end
  end

  def user_settings
    @user_settings ||=
      self.class.user_setting_fields.keys.index_with do |key|
        settings[key]
      end
  end

  def lti?
    false
  end

  def lti_settings=(new_settings)
    settings[:lti_settings] = new_settings
  end

  def lti_settings
    settings&.[](:lti_settings)
  end

  def lti_tool_valid
    tool_id = settings.dig(:lti_settings, :tool_id)
    if tool_id.blank?
      errors.add(:settings, "settings[lti_settings][tool_id] must exist for LtiConference")
      return
    end
    tool = ContextExternalTool.find_external_tool_by_id(tool_id, context)
    if tool.blank?
      errors.add(:settings, "settings[lti_settings][tool_id] must be a ContextExternalTool instance visible in context")
      return
    end
    unless tool.has_placement?(:conference_selection)
      errors.add(:settings, "settings[lti_settings][tool_id] must be a ContextExternalTool instance with conference_selection placement")
    end
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
      %w[1 on true].include?(value.to_s)
    else value
    end
  end

  def friendly_setting(value)
    case value
    when true
      t("#web_conference.settings.boolean.true", "On")
    when false
      t("#web_conference.settings.boolean.false", "Off")
    else value.to_s
    end
  end

  def default_settings
    @default_settings ||=
      self.class.user_setting_fields.each_with_object({}) do |(name, data), hash|
        hash[name] = data[:default] if data[:default]
      end
  end

  def self.user_setting_field(name, options)
    user_setting_fields[name] = options
  end

  def self.user_setting_fields
    @user_setting_fields ||= {}
  end

  class << self
    attr_writer :user_setting_fields
  end

  def self.user_setting_field_name(key)
    user_setting_fields[key][:name].call
  end

  def self.user_setting_field_description(key)
    user_setting_fields[key][:description].call
  end

  def external_urls
    @external_urls ||= self.class.external_urls.dup.delete_if { |_key, info| info[:restricted_to] && !info[:restricted_to].call(self) }
  end

  # #{key}_external_url should return an array of hashes with url information (:name, :id, and :url).
  # if there is just one, we will redirect, otherwise we'll present links to all of them (possibly
  # redirecting through here again in case the url has a short-lived token and needs to be
  # regenerated)
  def external_url_for(key, user, url_id = nil)
    (external_urls[key.to_sym] &&
      respond_to?(:"#{key}_external_url") &&
      send(:"#{key}_external_url", user, url_id)) || []
  end

  def self.external_urls
    @external_urls ||= {}
  end

  class << self
    attr_writer :external_urls
  end

  def self.external_url(name, options)
    external_urls[name] = options
  end

  def assign_uuid
    self.uuid ||= CanvasSlug.generate_securish_uuid
  end
  protected :assign_uuid

  def course_broadcast_data
    context.broadcast_data if context.respond_to?(:broadcast_data)
  end

  set_broadcast_policy do |p|
    p.dispatch :web_conference_invitation
    p.to do
      notification_recipients = @new_participants.select do |participant|
        context.membership_for_user(participant).try(:active?)
      end
      @new_participants = []
      notification_recipients
    end
    p.whenever { context_is_available? && @new_participants && !@new_participants.empty? }
    p.data { course_broadcast_data }

    p.dispatch :web_conference_recording_ready
    p.to { user }
    p.whenever do
      recording_ready? && saved_change_to_recording_ready?
    end
    p.data { course_broadcast_data }
  end

  on_create_send_to_streams do
    [user_id] + web_conference_participants.map(&:user_id)
  end

  def context_is_available?
    case context
    when Course
      context.available?
    when Group
      context.context_available?
    when Account
      true
    end
  end

  def add_user(user, type)
    return unless user

    p = web_conference_participants.where(user_id: user).first
    p ||= web_conference_participants.build(user:)
    p.participation_type = type unless type == "attendee" && p.participation_type == "initiator"
    (@new_participants ||= []) << user if p.new_record?
    # Once anyone starts attending the conference, mark it as started.
    if type == "attendee"
      self.started_at ||= Time.now
      save
    end
    p.save
  end

  def invite_users_from_context(user_ids = context.user_ids)
    members = context.is_a?(Course) ? context.participating_users(user_ids) : context.participating_users_in_context(user_ids)
    new_invitees = members.to_a - invitees
    new_invitees.uniq.each do |u|
      add_invitee(u)
    end
    save
  end

  def recording_ready!
    self.recording_ready = true
    save!
  end

  def recording_ready?
    !!recording_ready
  end

  def added_users
    attendees
  end

  def add_initiator(user)
    add_user(user, "initiator")
  end

  def add_invitee(user)
    add_user(user, "invitee")
  end

  def add_attendee(user)
    add_user(user, "attendee")
  end

  def context_code
    read_attribute(:context_code) || "#{context_type.underscore}_#{context_id}" rescue nil
  end

  def infer_conference_settings; end

  def conference_type=(val)
    conf_type = if val == "LtiConference"
                  { conference_type: "LtiConference", class_name: "LtiConference" }
                else
                  WebConference.conference_types(context).detect { |t| t[:conference_type] == val }
                end
    if conf_type
      write_attribute(:conference_type, conf_type[:conference_type])
      write_attribute(:type, conf_type[:class_name])
      conf_type[:conference_type]
    else
      nil
    end
  end

  def infer_conference_details
    infer_conference_settings
    self.conference_type ||= config && config[:conference_type]
    self.context_code = "#{context_type.underscore}_#{context_id}" rescue nil
    self.added_user_ids ||= ""
    if title.blank?
      self.title = context.is_a?(Course) ? t("#web_conference.default_name_for_courses", "Course Web Conference") : t("#web_conference.default_name_for_groups", "Group Web Conference")
    end
    self.start_at ||= self.started_at
    self.end_at ||= ended_at
    self.end_at ||= self.start_at + duration.minutes if self.start_at && duration
    if self.started_at && ended_at && ended_at < self.started_at
      self.ended_at = self.started_at
    end
  end

  def initiator
    user
  end

  def available?
    !self.started_at
  end

  def finished?
    self.started_at && !active?
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
    self.end_at = duration && (self.start_at + duration_in_seconds)
    self.started_at ||= self.start_at
    self.ended_at = nil
    save
  end

  # Default implementation since most implementations don't support scheduling yet
  def scheduled?
    self.started_at.nil? && scheduled_date && scheduled_date > Time.now
  end

  # Default implementation since most implementations don't support scheduling yet
  def scheduled_date
    nil
  end

  def active?(force_check = false, allow_check = true)
    unless force_check
      return false if ended_at && Time.now > ended_at
      return true if self.start_at && (self.end_at.nil? || (self.end_at && Time.now > self.start_at && Time.now < self.end_at))
      return true if ended_at && Time.now < ended_at
      return @conference_active unless @conference_active.nil?
    end
    unless allow_check
      # we don't know if the conference is active and we can't afford an api call to check.
      # assume it's inactive
      return false
    end

    @conference_active = (conference_status == :active)
    # If somehow the end_at didn't get set, set the end date
    # based on the start time and duration
    if @conference_active && !self.end_at && !long_running?
      self.start_at ||= Time.now
      self.end_at = [self.start_at, Time.now].compact.min + duration_in_seconds
      save
    # If the conference is still active but it's been more than fifteen minutes
    # since it was supposed to end, just go ahead and end it
    elsif @conference_active && self.end_at && self.end_at < 15.minutes.ago && !ended_at
      self.ended_at = Time.now
      self.start_at ||= self.started_at
      self.end_at ||= ended_at
      @conference_active = false
      save
    # If the conference is no longer in use and its end_at has passed,
    # consider it ended
    elsif @conference_active == false && self.started_at && self.end_at && self.end_at < Time.now && !ended_at
      close
    end
    @conference_active
  rescue Errno::ECONNREFUSED
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
    @attendee_key ||= conference_key
  end

  # Default implementaiton since not every conference type requires initiation
  def initiate_conference
    true
  end

  # Default implementation since most implementations don't support recording yet
  def recordings
    []
  end

  def craft_url(user = nil, session = nil, return_to = "http://www.instructure.com")
    user ||= self.user
    (initiate_conference and touch) or return nil
    if user == self.user || grants_right?(user, session, :initiate)
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

  def has_calendar_event
    return 0 if calendar_event.nil?

    (calendar_event.workflow_state == "deleted") ? 0 : 1
  end

  scope :after, ->(date) { where("web_conferences.start_at IS NULL OR web_conferences.start_at>?", date) }

  set_policy do
    given { |user, session| users.include?(user) && context.grants_right?(user, session, :read) }
    can :read and can :join

    given { |user, session| users.include?(user) && context.grants_right?(user, session, :read) && long_running? && active? }
    can :resume

    given { |user, session| context.grants_right?(user, session, :create_conferences) }
    can :create

    given { |user, session| user && user.id == user_id && context.grants_right?(user, session, :create_conferences) }
    can :initiate and can :close

    #################### Begin legacy permission block #########################
    given do |user, session|
      user && !context.root_account.feature_enabled?(:granular_permissions_manage_course_content) &&
        context.grants_all_rights?(user, session, :manage_content, :create_conferences)
    end
    can :read and can :join and can :initiate and can :delete and can :close and can :manage_recordings

    given do |user, session|
      user && !context.root_account.feature_enabled?(:granular_permissions_manage_course_content) &&
        !finished? && context.grants_all_rights?(user, session, :manage_content, :create_conferences)
    end
    can :update
    ##################### End legacy permission block ##########################

    given do |user, session|
      user && context.root_account.feature_enabled?(:granular_permissions_manage_course_content) &&
        context.grants_all_rights?(user, session, :manage_course_content_add, :create_conferences)
    end
    can :read and can :join and can :initiate

    given do |user, session|
      user && context.root_account.feature_enabled?(:granular_permissions_manage_course_content) &&
        context.grants_all_rights?(user, session, :manage_course_content_delete, :create_conferences)
    end
    can :read and can :join and can :delete and can :close

    given do |user, session|
      user && context.root_account.feature_enabled?(:granular_permissions_manage_course_content) &&
        context.grants_all_rights?(user, session, :manage_course_content_edit, :create_conferences)
    end
    can :read and can :join and can :manage_recordings

    given do |user, session|
      user && context.root_account.feature_enabled?(:granular_permissions_manage_course_content) &&
        !finished? && context.grants_all_rights?(user, session, :manage_course_content_edit, :create_conferences)
    end
    can :update
  end

  def config
    @config ||= WebConference.config(context:, class_name: self.class.to_s)
  end

  def valid_config?
    if config
      config[:class_name] == self.class.to_s
    else
      false
    end
  end

  def conference_status
    :active
  end

  def self.active_conference_type_names
    WebConference.plugins.map { |p| p.id.classify }
  end

  scope :active, -> { where(conference_type: WebConference.active_conference_type_names) }

  def as_json(options = {})
    url = options.delete(:url)
    join_url = options.delete(:join_url)
    options.reverse_merge!(only: %w[id title description conference_type duration started_at ended_at user_ids context_id context_type context_code start_at end_at])
    result = super(options.merge(include_root: false, methods: %i[has_advanced_settings invitees_ids attendees_ids has_calendar_event long_running user_settings recordings]))
    result["url"] = url
    result["join_url"] = join_url
    result
  end

  def user_ids
    web_conference_participants.pluck(:user_id)
  end

  def invitees_ids
    invitees.pluck(:id)
  end

  def attendees_ids
    attendees.pluck(:id)
  end

  def self.conference_types(context)
    plugin_types + lti_types(context)
  end

  def self.lti_types(context)
    return [] unless Account.site_admin.feature_enabled?(:conference_selection_lti_placement)

    lti_tools(context).map do |tool|
      {
        name: tool.name,
        class_name: "LtiConference",
        conference_type: "LtiConference",
        user_setting_fields: {},
        lti_settings: tool.conference_selection.merge(tool_id: tool.id)
      }.with_indifferent_access
    end
  end

  def self.lti_tools(context)
    Lti::ContextToolFinder.new(context, placements: :conference_selection).all_tools_sorted_array
  end

  def self.plugins
    Canvas::Plugin.all_for_tag(:web_conferencing)
  end

  def self.enabled_plugin_conference_names
    WebConference.plugin_types.pluck("name")
  end

  def self.conference_tab_name
    if (names = WebConference.enabled_plugin_conference_names).any?
      t("%{conference_type_names}", conference_type_names: names.join(" "))
    else
      t("#tabs.conferences", "Conferences")
    end
  end

  def self.plugin_types
    plugins.filter_map do |plugin|
      next unless plugin.enabled? &&
                  (klass = (plugin.base || "#{plugin.id.classify}Conference").constantize rescue nil) &&
                  klass < base_class

      plugin.settings.merge(
        conference_type: plugin.id.classify,
        class_name: plugin.base || "#{plugin.id.classify}Conference",
        user_setting_fields: klass.user_setting_fields,
        name: plugin.name,
        plugin:
      ).with_indifferent_access
    end
  end

  def self.config(context: nil, class_name: nil)
    if class_name
      conference_types(context).detect { |c| c[:class_name] == class_name }
    else
      conference_types(context).first
    end
  end

  def self.serialization_excludes
    [:uuid]
  end

  def set_root_account_id
    case context
    when Course, Group
      self.root_account_id = context.root_account_id
    when Account
      self.root_account_id = context.resolved_root_account_id
    end
  end

  def self.max_invitees_sync_size
    Setting.get("max_invitees_sync_size", 100).to_i
  end
end
