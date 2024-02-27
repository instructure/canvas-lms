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

class CommunicationChannel < ActiveRecord::Base
  # You should start thinking about communication channels
  # as independent of pseudonyms
  include ManyRootAccounts
  include Workflow

  serialize :last_bounce_details
  serialize :last_transient_bounce_details

  belongs_to :pseudonym
  has_many :pseudonyms
  belongs_to :user, inverse_of: :communication_channels
  has_many :notification_policies, dependent: :destroy
  has_many :notification_policy_overrides, inverse_of: :communication_channel, dependent: :destroy
  has_many :delayed_messages, dependent: :destroy
  has_many :messages

  # IF ANY CALLBACKS ARE ADDED please check #bounce_for_path to see if it should
  # happen there too.
  before_save :set_root_account_ids
  before_save :assert_path_type, :set_confirmation_code
  before_save :consider_building_pseudonym
  validates :path, :path_type, :user, :workflow_state, presence: true
  validate :under_user_cc_limit, if: -> { new_record? }
  validate :uniqueness_of_path
  validate :validate_email, if: ->(cc) { cc.path_type == TYPE_EMAIL && cc.new_record? }
  validate :not_otp_communication_channel, if: ->(cc) { cc.path_type == TYPE_SMS && cc.retired? && !cc.new_record? }
  after_destroy :after_destroy_flag_old_microsoft_sync_user_mappings
  after_commit :check_if_bouncing_changed
  after_save :clear_user_email_cache, if: -> { workflow_state_before_last_save != workflow_state }
  after_save :after_save_flag_old_microsoft_sync_user_mappings
  after_save :consider_building_notification_policies, if: -> { workflow_state_before_last_save != "active" && workflow_state == "active" }

  acts_as_list scope: :user

  has_a_broadcast_policy

  attr_reader :request_password
  attr_reader :send_confirmation

  # Constants for the different supported communication channels
  TYPE_EMAIL          = "email"
  TYPE_PUSH           = "push"
  TYPE_SMS            = "sms"
  TYPE_SLACK          = "slack"
  TYPE_TWITTER        = "twitter"
  TYPE_PERSONAL_EMAIL = "personal_email"

  VALID_TYPES = [TYPE_EMAIL, TYPE_SMS, TYPE_TWITTER, TYPE_PUSH, TYPE_SLACK, TYPE_PERSONAL_EMAIL].freeze

  RETIRE_THRESHOLD = 1

  MAX_CCS_PER_USER = 100

  RESEND_PASSWORD_RESET_TIME = 30.minutes
  MAX_SHARDS_FOR_BOUNCES = 50
  MERGE_CANDIDATE_SEARCH_LIMIT = 10

  # Notification polcies are required for a user to start recieving notifications from an
  # active communication channel. This code will create these policies if they don't already exist.
  def consider_building_notification_policies
    if notification_policies.empty?
      NotificationPolicy.build_policies_for_channel(self)
    end
  end

  # Generally, "TYPE_PERSONAL_EMAIL" should be treated exactly the same
  # as TYPE_EMAIL.  It is just kept distinct for the purposes of customers
  # querying records in Canvas Data.
  def path_type
    raw_value = read_attribute(:path_type)
    return TYPE_EMAIL if raw_value == TYPE_PERSONAL_EMAIL

    raw_value
  end

  def under_user_cc_limit
    if user.communication_channels.limit(MAX_CCS_PER_USER + 1).count > MAX_CCS_PER_USER
      errors.add(:user_id, "user communication_channels limit exceeded")
    end
  end

  def clear_user_email_cache
    user.clear_email_cache! if path_type == TYPE_EMAIL
  end

  def self.country_codes
    # [country code, name, true if email should be used instead of Twilio]
    [
      ["93",   I18n.t("Afghanistan (+93)"),            false],
      ["54",   I18n.t("Argentina (+54)"),              false],
      ["61",   I18n.t("Australia (+61)"),              false],
      ["43",   I18n.t("Austria (+43)"),                false],
      ["32",   I18n.t("Belgium (+32)"),                false],
      ["591",  I18n.t("Bolivia (+591)"),               false],
      ["55",   I18n.t("Brazil (+55)"),                 false],
      ["1",    I18n.t("Canada (+1)"),                  false],
      ["56",   I18n.t("Chile (+56)"),                  false],
      ["86",   I18n.t("China (+86)"),                  false],
      ["57",   I18n.t("Colombia (+57)"),               false],
      ["506",  I18n.t("Costa Rica (+506)"),            false],
      ["45",   I18n.t("Denmark (+45)"),                false],
      ["1",    I18n.t("Dominican Republic (+1)"),      false],
      # ['593',  I18n.t('Ecuador (+593)'),               false],
      ["503",  I18n.t("El Salvador (+503)"),           false],
      ["358",  I18n.t("Finland (+358)"),               false],
      ["33",   I18n.t("France (+33)"),                 false],
      ["49",   I18n.t("Germany (+49)"),                false],
      ["502",  I18n.t("Guatemala (+502)"),             false],
      ["504",  I18n.t("Honduras (+504)"),              false],
      ["852",  I18n.t("Hong Kong (+852)"),             false],
      ["36",   I18n.t("Hungary (+36)"),                false],
      ["354",  I18n.t("Iceland (+354)"),               false],
      ["91",   I18n.t("India (+91)"),                  false],
      ["62",   I18n.t("Indonesia (+62)"),              false],
      ["353",  I18n.t("Ireland (+353)"),               false],
      ["972",  I18n.t("Israel (+972)"),                false],
      ["39",   I18n.t("Italy (+39)"),                  false],
      ["81",   I18n.t("Japan (+81)"),                  false],
      ["7",    I18n.t("Kazakhstan (+7)"),              false],
      ["254",  I18n.t("Kenya (+254)"),                 false],
      ["352",  I18n.t("Luxembourg (+352)"),            false],
      ["60",   I18n.t("Malaysia (+60)"),               false],
      ["52",   I18n.t("Mexico (+52)"),                 false],
      ["31",   I18n.t("Netherlands (+31)"),            false],
      ["64",   I18n.t("New Zealand (+64)"),            false],
      ["47",   I18n.t("Norway (+47)"),                 false],
      ["968",  I18n.t("Oman (+968)"),                  false],
      ["507",  I18n.t("Panama (+507)"),                false],
      ["92",   I18n.t("Pakistan (+92)"),               false],
      ["595",  I18n.t("Paraguay (+595)"),              false],
      # ['51',   I18n.t('Peru (+51)'),                   false],
      ["63",   I18n.t("Philippines (+63)"),            false],
      ["48",   I18n.t("Poland (+48)"),                 false],
      ["974",  I18n.t("Qatar (+974)"),                 false],
      ["7",    I18n.t("Russia (+7)"),                  false],
      ["250",  I18n.t("Rwanda (+250)"),                false],
      ["966",  I18n.t("Saudi Arabia (+966)"),          false],
      ["65",   I18n.t("Singapore (+65)"),              false],
      ["27",   I18n.t("South Africa (+27)"),           false],
      ["82",   I18n.t("South Korea (+82)"),            false],
      ["34",   I18n.t("Spain (+34)"),                  false],
      ["46",   I18n.t("Sweden (+46)"),                 false],
      ["41",   I18n.t("Switzerland (+41)"),            false],
      ["886",  I18n.t("Taiwan (+886)"),                false],
      ["66",   I18n.t("Thailand (+66)"),               false],
      ["1",    I18n.t("Trinidad and Tobago (+1)"),     false],
      ["971",  I18n.t("United Arab Emirates (+971)"),  false],
      ["44",   I18n.t("United Kingdom (+44)"),         false],
      ["1",    I18n.t("United States (+1)"),           true],
      ["598",  I18n.t("Uruguay (+598)"),               false],
      ["58",   I18n.t("Venezuela (+58)"),              false],
      ["84",   I18n.t("Vietnam (+84)"),                false]
    ].sort_by { |a| Canvas::ICU.collation_key(a[1]) }
  end

  DEFAULT_SMS_CARRIERS = {
    "txt.att.net" => { name: "AT&T", country_code: 1 }.with_indifferent_access.freeze,
    "message.alltel.com" => { name: "Alltel", country_code: 1 }.with_indifferent_access.freeze,
    "myboostmobile.com" => { name: "Boost", country_code: 1 }.with_indifferent_access.freeze,
    "cspire1.com" => { name: "C Spire", country_code: 1 }.with_indifferent_access.freeze,
    "cingularme.com" => { name: "Cingular", country_code: 1 }.with_indifferent_access.freeze,
    "mobile.celloneusa.com" => { name: "CellularOne", country_code: 1 }.with_indifferent_access.freeze,
    "mms.cricketwireless.net" => { name: "Cricket", country_code: 1 }.with_indifferent_access.freeze,
    "messaging.nextel.com" => { name: "Nextel", country_code: 1 }.with_indifferent_access.freeze,
    "messaging.sprintpcs.com" => { name: "Sprint PCS", country_code: 1 }.with_indifferent_access.freeze,
    "tmomail.net" => { name: "T-Mobile", country_code: 1 }.with_indifferent_access.freeze,
    "vtext.com" => { name: "Verizon", country_code: 1 }.with_indifferent_access.freeze,
    "vmobl.com" => { name: "Virgin Mobile", country_code: 1 }.with_indifferent_access.freeze,
  }.freeze

  def self.sms_carriers
    @sms_carriers ||= ConfigFile.load("sms", false) || DEFAULT_SMS_CARRIERS
  end

  def self.sms_carriers_by_name
    carriers = sms_carriers.map do |domain, carrier|
      [carrier["name"], domain]
    end
    Canvas::ICU.collate_by(carriers, &:first)
  end

  set_policy do
    given { |user| self.user.grants_right?(user, :manage_user_details) }
    can :force_confirm

    given { |user| Account.site_admin.grants_right?(user, :read_messages) }
    can :reset_bounce_count
    can :read_bounce_details
  end

  def pseudonym
    user.pseudonyms.where(unique_id: path).first if user
  end

  def broadcast_data
    return unless @root_account

    { root_account_id: @root_account.global_id, from_host: HostUrl.context_host(@root_account) }
  end

  set_broadcast_policy do |p|
    p.dispatch :forgot_password
    p.to { self }
    p.whenever { @request_password }
    p.data { broadcast_data }

    p.dispatch :confirm_registration
    p.to { self }
    p.whenever do |record|
      @send_confirmation and
        (record.workflow_state == "active" ||
          (record.workflow_state == "unconfirmed" and (user.pre_registered? || user.creation_pending?))) and
        path_type == TYPE_EMAIL
    end
    p.data { broadcast_data }

    p.dispatch :confirm_email_communication_channel
    p.to { self }
    p.whenever do |record|
      @send_confirmation and
        record.workflow_state == "unconfirmed" and user.registered? and
        path_type == TYPE_EMAIL
    end
    p.data { broadcast_data }

    p.dispatch :merge_email_communication_channel
    p.to { self }
    p.whenever { @send_merge_notification && path_type == TYPE_EMAIL }
    p.data { broadcast_data }

    p.dispatch :confirm_sms_communication_channel
    p.to { self }
    p.whenever do |record|
      @send_confirmation and
        record.workflow_state == "unconfirmed" and
        (path_type == TYPE_SMS or path_type == TYPE_SLACK) and
        !user.creation_pending?
    end
    p.data { broadcast_data }
  end

  def uniqueness_of_path
    return if path.nil?
    return if retired?
    return unless user_id

    shard.activate do
      # ^ if we create a new CC record while on another shard
      # and try to check the validity OUTSIDE the save path
      # (cc.valid?) this needs to switch to the shard where we'll
      # be writing to make sure we're checking uniqueness in the right place
      scope = self.class.by_path(path).where(user_id:, path_type:, workflow_state: ["unconfirmed", "active"])
      unless new_record?
        scope = scope.where("id<>?", id)
      end
      if scope.exists?
        errors.add(:path, :taken, value: path)
      end
    end
  end

  def validate_email
    # this is not perfect and will allow for invalid emails, but it mostly works.
    # This pretty much allows anything with an "@"
    errors.add(:email, :invalid, value: path) unless EmailAddressValidator.valid?(path)
  end

  def not_otp_communication_channel
    errors.add(:workflow_state, "Can't remove a user's SMS that is used for one time passwords") if id == user.otp_communication_channel_id
  end

  # Public: Build the url where this record can be confirmed.
  #
  #
  # Returns a string.
  def confirmation_url
    return "" unless path_type == TYPE_EMAIL

    "#{HostUrl.protocol}://#{HostUrl.context_host(context)}/register/#{confirmation_code}"
  end

  def context
    pseudonym&.account || user.pseudonym&.account
  end

  # Public: Determine if this channel is the product of an SIS import.
  #
  # Returns a boolean.
  def imported?
    id.present? &&
      Pseudonym.where(sis_communication_channel_id: self).shard(user).exists?
  end

  # Return the 'path' for simple communication channel types like email and sms.
  # For Twitter, return the user's configured user_name for the service.
  def path_description
    case path_type
    when TYPE_TWITTER
      res = user.user_services.for_service(TYPE_TWITTER).first.service_user_name rescue nil
      res ||= t :default_twitter_handle, "Twitter Handle"
      res
    when TYPE_PUSH
      t "For All Devices"
    else
      path
    end
  end

  def forgot_password!
    return if Rails.cache.read(["recent_password_reset", global_id].cache_key) == true

    @request_password = true
    Rails.cache.write(["recent_password_reset", global_id].cache_key, true, expires_in: RESEND_PASSWORD_RESET_TIME)
    set_confirmation_code(true, 2.hours.from_now)
    save!
    @request_password = false
  end

  def confirmation_limit_reached
    confirmation_sent_count > 2
  end

  def send_confirmation!(root_account)
    if confirmation_limit_reached || bouncing?
      return
    end

    self.confirmation_sent_count = confirmation_sent_count + 1
    @send_confirmation = true
    @root_account = root_account
    save!
    @root_account = nil
    @send_confirmation = false
  end

  def send_merge_notification!
    @send_merge_notification = true
    save!
    @send_merge_notification = false
  end

  def send_otp_via_sms_gateway!(message)
    m = messages.temp_record
    m.to = path
    m.body = message
    Mailer.deliver(Mailer.create_message(m))
  end

  def otp_impaired?
    return false unless path_type == TYPE_SMS

    # strip off the leading +
    raw_number = e164_path[1...]
    # Imperfect
    country = CommunicationChannel.country_codes.find do |code, _, _|
      raw_number.start_with?(code)
    end || ["unknown"]

    Setting.get("otp_impaired_country_codes", "").split(",").include?(country.first)
  end

  def send_otp!(code, account = nil)
    message = t :body, "Your Canvas verification code is %{verification_code}", verification_code: code

    case path_type
    when TYPE_SMS
      if Setting.get("mfa_via_sms", true) == "true" && e164_path && account&.feature_enabled?(:notification_service)
        InstStatsd::Statsd.increment("message.deliver.sms.one_time_password",
                                     short_stat: "message.deliver",
                                     tags: { path_type: "sms", notification_name: "one_time_password" })
        InstStatsd::Statsd.increment("message.deliver.sms.#{account.global_id}",
                                     short_stat: "message.deliver_per_account",
                                     tags: { path_type: "sms", root_account_id: account.global_id })
        Services::NotificationService.process(
          "otp:#{global_id}",
          message,
          "sms",
          e164_path,
          true
        )
      else
        delay_if_production(priority: Delayed::HIGH_PRIORITY).send_otp_via_sms_gateway!(message)
      end
    when TYPE_EMAIL
      m = messages.temp_record
      m.to = path
      m.context = account || Account.default
      m.user = user
      m.notification = Notification.new(name: "2fa", category: "Registration")
      m.data = { verification_code: code }
      m.parse!("email")
      m.subject = "Canvas Verification Code"
      Mailer.deliver(Mailer.create_message(m))
    else
      raise "OTP not supported for #{path_type}"
    end
  end

  # If you are creating a new communication_channel, do nothing, this just
  # works.  If you are resetting the confirmation_code, call @cc.
  # set_confirmation_code(true), or just save the record to leave the old
  # confirmation code in place.
  def set_confirmation_code(reset = false, expires_at = nil)
    self.confirmation_code = nil if reset
    self.confirmation_code ||= if path_type == TYPE_EMAIL || path_type.nil?
                                 CanvasSlug.generate(nil, 25)
                               else
                                 CanvasSlug.generate
                               end
    self.confirmation_code_expires_at = expires_at if reset
    true
  end

  def self.by_path_condition(path)
    Arel::Nodes::NamedFunction.new("lower", [Arel::Nodes.build_quoted(path)])
  end

  scope :by_path, ->(path) { where(by_path_condition(arel_table[:path]).eq(by_path_condition(path))) }
  scope :path_like, ->(path) { where(by_path_condition(arel_table[:path]).matches(by_path_condition(path))) }

  scope :email, -> { where(path_type: [TYPE_EMAIL, TYPE_PERSONAL_EMAIL]) }
  scope :sms, -> { where(path_type: TYPE_SMS) }

  scope :active, -> { where(workflow_state: "active") }
  scope :bouncing, -> { where(bounce_count: RETIRE_THRESHOLD..) }
  scope :unretired, -> { where.not(workflow_state: "retired") }
  scope :supported, -> { where.not(path_type: TYPE_SMS) }

  # Get the list of communication channels that overrides an association's default order clause.
  # This returns an unretired and properly ordered already fetch array of CommunicationChannel objects ready for usage.
  def self.all_ordered_for_display(user)
    # Add communication channel for users that already had Twitter
    # integrated before we started offering it as a cc
    twitter_service = user.user_services.for_service(CommunicationChannel::TYPE_TWITTER).first
    twitter_service&.assert_communication_channel

    rank_order = [TYPE_EMAIL, TYPE_SMS, TYPE_PUSH]
    # Add twitter and yo (in that order) if the user's account is setup for them.
    rank_order << TYPE_TWITTER if twitter_service
    rank_order << TYPE_SLACK if user.associated_root_accounts.any? { |a| a.settings[:encrypted_slack_key] }
    unretired.where(communication_channels: { path_type: rank_order })
             .order(Arel.sql("#{rank_sql(rank_order, "communication_channels.path_type")} ASC, communication_channels.position asc")).to_a
  end

  scope :in_state, ->(state) { where(workflow_state: state.to_s) }
  scope :of_type, ->(type) { where(path_type: type) }

  # the only way this is used is if a user adds a communication channel in their
  # profile from the default account. In this space, there is currently a
  # check_box that will allow you to login with the same email. This method is
  # only ever true for Account.default
  # see build_pseudonym_for_email in app/views/profile/_ways_to_contact.html.erb
  def consider_building_pseudonym
    if build_pseudonym_on_confirm && active?
      self.build_pseudonym_on_confirm = false
      pseudonym = Account.default.pseudonyms.build(unique_id: path, user:)
      existing_pseudonym = Account.default.pseudonyms.active.where(user_id: user).take
      if existing_pseudonym
        pseudonym.password_salt = existing_pseudonym.password_salt
        pseudonym.crypted_password = existing_pseudonym.crypted_password
      end
      pseudonym.save!
    end
    true
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "retired"
    save
  end

  workflow do
    state :unconfirmed do
      event :confirm, transitions_to: :active do
        set_confirmation_code
      end
      event :retire, transitions_to: :retired
    end

    state :active do
      event :retire, transitions_to: :retired
    end

    state :retired do
      event :re_activate, transitions_to: :active do
        # Reset bounce count when we're being reactivated
        reset_bounce_count!
      end
    end
  end

  def set_root_account_ids(persist_changes: false, log: false)
    # communication_channels always are on the same shard as the user object and
    # can be used for any root_account, so just set root_account_ids from user.
    self.root_account_ids = user.root_account_ids
    if root_account_ids_changed? && log
      InstStatsd::Statsd.increment("communication_channel.root_account_ids_set", short_stat: "communication_channel.root_account_ids_set")
    end
    save! if persist_changes && root_account_ids_changed?
  end

  # This is setup as a default in the database, but this overcomes misspellings.
  def assert_path_type
    self.path_type = TYPE_EMAIL unless VALID_TYPES.include?(path_type)
    true
  end
  protected :assert_path_type

  def self.serialization_excludes
    [:confirmation_code]
  end

  def self.associated_shards(_path)
    [Shard.default]
  end

  def merge_candidates(break_on_first_found = false)
    return [] if path_type == "push"

    shards = self.class.associated_shards(path) if Enrollment.cross_shard_invitations?
    shards ||= [shard]
    scope = CommunicationChannel.active.by_path(path).of_type(path_type)
    merge_candidates = {}
    Shard.with_each_shard(shards) do
      scope = scope.shard(Shard.current).where("user_id<>?", user_id)

      ccs = scope.preload(:user).limit(MERGE_CANDIDATE_SEARCH_LIMIT + 1).to_a
      return [] if ccs.count > MERGE_CANDIDATE_SEARCH_LIMIT # just bail if things are getting out of hand

      ccs.map(&:user).select do |u|
        result = merge_candidates.fetch(u.global_id) do
          merge_candidates[u.global_id] = !u.all_active_pseudonyms.empty?
        end
        return [u] if result && break_on_first_found

        result
      end
    end.uniq
  end

  def has_merge_candidates?
    !merge_candidates(true).empty?
  end

  def bouncing?
    bounce_count >= RETIRE_THRESHOLD
  end

  def was_bouncing?
    old_bounce_count = previous_changes[:bounce_count].try(:first)
    old_bounce_count ||= bounce_count
    old_bounce_count >= RETIRE_THRESHOLD
  end

  def reset_bounce_count!
    self.bounce_count = 0
    save!
  end

  def was_retired?
    old_workflow_state = previous_changes[:workflow_state].try(:first)
    old_workflow_state ||= workflow_state
    old_workflow_state.to_s == "retired"
  end

  def check_if_bouncing_changed
    if retired?
      user.update_bouncing_channel_message!(self) if !was_retired? && was_bouncing?
    elsif (was_retired? && bouncing?) || (was_bouncing? != bouncing?)
      user.update_bouncing_channel_message!(self)
    end
  end
  private :check_if_bouncing_changed

  def self.bounce_for_path(path:, timestamp:, details:, permanent_bounce:, suppression_bounce:)
    # if there is a bounce on a channel that is associated to more than a few
    # shards there is no reason to bother updating the channel with the bounce
    # information, because its not a real user.
    return if !permanent_bounce && CommunicationChannel.associated_shards(path).count > MAX_SHARDS_FOR_BOUNCES

    Shard.with_each_shard(CommunicationChannel.associated_shards(path)) do
      cc_scope = CommunicationChannel.unretired.email.by_path(path).where("bounce_count<?", RETIRE_THRESHOLD)
      # If alllowed to do this naively, trying to capture bounces on the same
      # email address over and over can lead to serious db churn.  Here we
      # try to capture only the newly created communication channels for this path,
      # or the ones that have NOT been bounced in the last hour, to make sure
      # we aren't doing un-helpful overwork.
      debounce_window = 1.hour
      bounce_field = if suppression_bounce
                       "last_suppression_bounce_at"
                     elsif permanent_bounce
                       "last_bounce_at"
                     else
                       "last_transient_bounce_at"
                     end
      bouncable_scope = cc_scope.where("#{bounce_field} IS NULL OR updated_at < ?", debounce_window.ago)
      bouncable_scope.find_in_batches do |batch|
        update = if suppression_bounce
                   { last_suppression_bounce_at: timestamp, updated_at: Time.zone.now }
                 elsif permanent_bounce
                   ["bounce_count = bounce_count + 1, updated_at=NOW(), last_bounce_at=?, last_bounce_details=?", timestamp, details.to_yaml]
                 else
                   { last_transient_bounce_at: timestamp, last_transient_bounce_details: details, updated_at: Time.zone.now }
                 end

        CommunicationChannel.where(id: batch).update_all(update)

        # replacement for check_if_bouncing_changed callback.
        # We know the channel is not and was not retired, we also know that the
        # "bouncing? state" changed.
        if permanent_bounce
          CommunicationChannel.where(id: batch).preload(:user).find_each do |channel|
            channel.user.update_bouncing_channel_message!(channel)
          end
        end
      end
    end
  end

  def last_bounce_summary
    last_bounce_details.try(:[], "bouncedRecipients").try(:[], 0).try(:[], "diagnosticCode")
  end

  def last_transient_bounce_summary
    last_transient_bounce_details.try(:[], "bouncedRecipients").try(:[], 0).try(:[], "diagnosticCode")
  end

  def self.find_by_confirmation_code(code)
    where(confirmation_code: code).first
  end

  def self.user_can_have_more_channels?(user, domain_root_account)
    max_allowed_channels = domain_root_account.settings[:max_communication_channels]
    return true unless max_allowed_channels

    number_channels = user.communication_channels.where(
      "workflow_state <> 'retired' OR (workflow_state = 'retired' AND created_at > ?)", 1.hour.ago
    ).count
    number_channels < max_allowed_channels
  end

  def e164_path
    return path if /^\+\d+$/.match?(path)
    return nil unless (match = path.match(/^(?<number>\d+)@(?<domain>.+)$/))
    return nil unless (carrier = CommunicationChannel.sms_carriers[match[:domain]])

    "+#{carrier["country_code"]}#{match[:number]}"
  end

  def after_save_flag_old_microsoft_sync_user_mappings
    # We might be able to refine this check to ignore irrelevant changes to
    # non-primary email addresses but the conditions are complicated (for
    # instance, if the comm chammenl with the lowest priority number is not in
    # an "active" state, changes to other comm channels may be relevant), so
    # it's safer just to do this.
    if %i[path path_type position workflow_state].any? { |attr| saved_change_to_attribute(attr) } &&
       (path_type == TYPE_EMAIL || path_type_before_last_save == TYPE_EMAIL)
      MicrosoftSync::UserMapping.delay_if_production.flag_as_needs_updating_if_using_email(user)
    end
  end

  def after_destroy_flag_old_microsoft_sync_user_mappings
    if path_type == TYPE_EMAIL
      MicrosoftSync::UserMapping.delay_if_production.flag_as_needs_updating_if_using_email(user)
    end
  end

  class << self
    def trusted_confirmation_redirect?(root_account, redirect_url)
      uri = begin
        URI.parse(redirect_url)
      rescue URI::InvalidURIError
        nil
      end
      return false unless uri && ["http", "https"].include?(uri.scheme)

      @redirect_trust_policies&.any? do |policy|
        policy.call(root_account, uri)
      end
    end

    def add_confirmation_redirect_trust_policy(&block)
      @redirect_trust_policies ||= []
      @redirect_trust_policies << block
    end
  end
end
