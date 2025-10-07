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

class AccessToken < ActiveRecord::Base
  include Workflow

  extend RootAccountResolver

  workflow do
    state :pending do
      event :activate, transitions_to: :active
    end
    state :active
    state :deleted
  end

  attr_reader :full_token
  attr_reader :plaintext_refresh_token

  scope :user_generated, -> { where(developer_key_id: DeveloperKey.default.id) }

  belongs_to :developer_key
  belongs_to :user, inverse_of: :access_tokens
  belongs_to :real_user, inverse_of: :masquerade_tokens, class_name: "User"
  has_one :account, through: :developer_key

  serialize :scopes, type: Array

  validates :purpose, length: { minimum: 1, maximum: maximum_string_length }
  validate :must_only_include_valid_scopes, unless: :deleted?

  has_many :notification_endpoints, -> { where(workflow_state: "active") }, dependent: :destroy

  before_validation -> { self.developer_key ||= DeveloperKey.default }
  before_validation -> { self.purpose ||= self.developer_key&.name unless manually_created? }

  resolves_root_account through: :developer_key

  has_a_broadcast_policy

  set_broadcast_policy do |p|
    p.dispatch :manually_created_access_token_created
    p.to(&:user)
    p.whenever do |access_token|
      access_token.crypted_token_previously_changed? && access_token.manually_created? &&
        access_token.active?
    end
    p.dispatch :access_token_created_on_behalf_of_user
    p.to(&:user)
    p.whenever do |access_token|
      access_token.crypted_token_previously_changed? && access_token.manually_created? &&
        access_token.pending?
    end
    p.dispatch :access_token_deleted
    p.to(&:user)
    p.whenever do |access_token|
      access_token.manually_created? && access_token.deleted?
    end
  end

  # helper method to generate a "session" hash that can be passed into
  # permission checks
  def self.account_session_for_permissions(root_account)
    {
      permissions_key: root_account,
      root_account:
    }
  end

  set_policy do
    given do |user, session|
      # This block is only for checking if the user can manage their own tokens
      next false unless user.id == user_id

      # if the session wasn't set up correctly, just ignore the additional restrictions
      next true unless (root_account = session&.dig(:root_account))
      # additional restrictions gated by feature flags
      next true unless root_account.feature_enabled?(:admin_manage_access_tokens)

      # if personal access tokens are limited, then you can't create tokens for yourself
      # (from this block; if you're an admin, you'll still be able to from the block below)
      next false if root_account.limit_personal_access_tokens?
      # if students are restricted from creating personal access tokens,
      # then if you're _only_ a student, only an observer, or only both, you can't create tokens
      # (a teacher that is a student/observer will still be allowed to)
      next false if root_account.restrict_personal_access_tokens_from_students? &&
                    (roles = user.roles(root_account) - ["user"]) &&
                    (roles.empty? || (roles - ["student", "observer"]).empty?)

      true
    end
    can :create and can :update

    given { |user| user.id == user_id }
    can :read and can :delete

    given do |user|
      self.user.check_accounts_right?(user, :create_access_tokens)
    end
    can :create and can :update

    given { |user| self.user.check_accounts_right?(user, :delete_access_tokens) }
    can :delete

    given { |user| self.user.check_accounts_right?(user, :view_user_generated_access_tokens) && developer_key_id == DeveloperKey.default.id }
    can :read
  end

  # For user-generated tokens, purpose should always be set.
  # For app-generated tokens, this should be generated based
  # on the scope defined in the auth process (scope has not
  # yet been implemented)

  scope :active, -> { not_deleted.where("permanent_expires_at IS NULL OR permanent_expires_at>?", Time.now.utc) }
  scope :not_deleted, -> { where.not(workflow_state: "deleted") }

  TOKEN_SIZE = 64
  TOKEN_TYPES = [:crypted_token, :crypted_refresh_token].freeze
  HINT_LENGTH = 5

  before_create :generate_token
  before_create :generate_refresh_token
  after_create :queue_developer_key_token_count_increment

  alias_method :destroy_permanently!, :destroy
  def destroy
    return true if deleted?

    self.workflow_state = "deleted"
    run_callbacks(:destroy) { save! }
  end

  def self.authenticate(token_string, token_key = :crypted_token, access_token = nil, load_pseudonym_from_access_token: false)
    # hash the user supplied token with all of our known keys
    # attempt to find a token that matches one of the hashes
    hashed_tokens = all_hashed_tokens(token_string)
    token =
      if access_token.present?
        access_token
      else
        scope = load_pseudonym_from_access_token ? self : not_deleted
        scope.where(token_key => hashed_tokens).order(Arel.sql("workflow_state = 'active' DESC, workflow_state")).first
      end
    if token && token.send(token_key) != hashed_tokens.first
      # we found the token but, its hashed using an old key. save the updated hash
      token.send(:"#{token_key}=", hashed_tokens.first)
      token.save!
    end
    return token if load_pseudonym_from_access_token

    token = nil unless token&.usable?(token_key)
    token
  end

  def self.authenticate_refresh_token(token_string)
    authenticate(token_string, :crypted_refresh_token)
  end

  def self.hashed_token(token, key = Canvas::Security.encryption_key)
    # This use of hmac is a bit odd, since we aren't really signing a message
    # other than the random token string itself.
    # However, what we're essentially looking for is a hash of the token
    # "signed" or concatenated with the secret encryption key, so this is perfect.
    Canvas::Security.hmac_sha1(token, key)
  end

  # @return [String, false]
  #   the de-mangled token hint that should match the database if the id is a
  #   valid token hint, false otherwise
  def self.token_hint?(id)
    id.is_a?(String) && id.length == HINT_LENGTH && id
  end

  def self.all_hashed_tokens(token)
    Canvas::Security.encryption_keys.map { |key| hashed_token(token, key) }
  end

  def self.visible_tokens(tokens)
    tokens.uniq.reject { |token| token.developer_key&.internal_service }
  end

  # If the token exists, and belongs to site admin, return the token itself.
  # Otherwise return falsey (not specified if it's false or nil).
  #
  # This can be used to eliminate an additional call to {.authenticate} once
  # you know the token is relevant, while still being boolean.
  #
  # @return [AccessToken, false, nil]
  def self.site_admin?(token_string)
    (access_token = authenticate(token_string)) && access_token.site_admin? && access_token
  end

  def localized_workflow_state
    if expired?
      I18n.t("expired")
    elsif pending?
      I18n.t("pending")
    elsif active?
      I18n.t("active")
    else
      workflow_state
    end
  end

  def set_permanent_expiration
    expires_in = developer_key.tokens_expire_in
    self.permanent_expires_at = Time.now.utc + expires_in if expires_in
  end

  def usable?(token_key = :crypted_token)
    return false if expired? || pending?

    if !developer_key_id || developer_key&.usable?
      return false if token_key != :crypted_refresh_token && needs_refresh?
      return true if user_id
    end
    false
  end

  def app_name
    developer_key&.name || "No App"
  end

  def authorized_for_account?(target_account)
    return true unless developer_key

    developer_key.authorized_for_account?(target_account)
  end

  def site_admin?
    return false unless global_developer_key_id.present?

    Shard.shard_for(global_developer_key_id).default?
  end

  def used!(at: nil)
    return if last_used_at && last_used_at >= 10.minutes.ago

    at ||= Time.now.utc

    if Rails.env.production? && !shard.in_current_region? && !Delayed::Job.in_delayed_job?
      # just choose a random shard in the current region to ensure the job
      # is queued in the current region
      Shard.in_current_region.first&.activate do
        delay(singleton: "update_access_token_last_user/#{global_id}",
              on_conflict: :loose).used!(at:)
        return
      end
    end

    if changed?
      self.last_used_at = at
      save!
      return
    end

    # only update if nobody else has touched last_used_at, to avoid multiple
    # writes for the same interval
    prior_last_used_at = last_used_at
    self.last_used_at = at

    shard.activate do
      # not only use optimistic locking, but also don't update if someone else
      # is already in the process of updating it
      updated = AccessToken.where(id: AccessToken.where(id: self, last_used_at: prior_last_used_at)
                                                 .lock("FOR UPDATE SKIP LOCKED"))
                           .update_all(last_used_at: at, updated_at: at)
      changes_applied if updated == 1
    end
  end

  def expired?
    !!(permanent_expires_at && permanent_expires_at < Time.now.utc)
  end

  def needs_refresh?
    # expires_at is only used for refreshable tokens, and therefore is only set on tokens
    # from dev keys with auto_expire_tokens=true. We want to immediately respect
    # auto_expire_tokens being flipped off, so ignore the expires_at in the
    # db if the dev key no longer wants tokens to expire
    developer_key&.auto_expire_tokens && expires_at && expires_at < Time.now.utc
  end

  def token=(new_token)
    self.crypted_token = AccessToken.hashed_token(new_token)
    @full_token = new_token
    self.token_hint = new_token[0, HINT_LENGTH]
  end

  def clear_full_token!
    @full_token = nil
  end

  def generate_token(overwrite = false)
    if overwrite || !crypted_token
      self.token = CanvasSlug.generate(nil, TOKEN_SIZE)

      self.expires_at = Time.now.utc + 1.hour if developer_key&.auto_expire_tokens
    end
  end

  def refresh_token=(new_token)
    self.crypted_refresh_token = AccessToken.hashed_token(new_token)
    @plaintext_refresh_token = new_token
  end

  def generate_refresh_token(overwrite: false)
    if !crypted_refresh_token || overwrite
      self.refresh_token = CanvasSlug.generate(nil, TOKEN_SIZE)
    end
  end

  def clear_plaintext_refresh_token!
    @plaintext_refresh_token = nil
  end

  def regenerate_access_token
    generate_token(true)
    save
  end

  def can_manually_regenerate?
    manually_created? && !expired?
  end

  def visible_token
    if !manually_created?
      nil
    elsif full_token
      full_token
    else
      "#{token_hint}..."
    end
  end

  def self.always_allowed_scopes
    [
      "/login/oauth2/token"
    ].map { |path| Regexp.new("^#{path}$") }
  end

  def url_scopes_for_method(method)
    re = /^url:#{method}\|/
    scopes.grep(re).map do |scope|
      path = scope.split("|").last
      # build up the scope matching regexp from the route path
      path = path.gsub(%r{:[^/)]+}, "[^/]+") # handle dynamic segments /courses/:course_id -> /courses/[^/]+
      path = path.gsub(%r{\*[^/)]+}, ".+") # handle glob segments /files/*path -> /files/.+
      path = path.gsub("(", "(?:").gsub(")", "|)") # handle optional segments /files(/[^/]+) -> /files(?:/[^/]+|)
      path = "#{path}(?:\\.[^/]+|)" # handle format segments /files(.:format) -> /files(?:\.[^/]+|)
      Regexp.new("^#{path}$")
    end
  end

  # Scoped token convenience method
  def scoped_to?(req_scopes)
    self.class.scopes_match?(scopes, req_scopes)
  end

  def self.scopes_match?(scopes, req_scopes)
    return req_scopes.empty? if scopes.nil?

    scopes.size == req_scopes.size &&
      scopes.all? do |scope|
        req_scopes.any? { |req_scope| scope[%r{(^|/)#{req_scope}$}] }
      end
  end

  def must_only_include_valid_scopes
    return true if scopes.nil? || !developer_key.require_scopes?

    errors.add(:scopes, "requested scopes must match scopes on developer key") unless scopes.all? { |scope| developer_key.scopes.include?(scope) }
  end

  # It's encrypted, but end users still shouldn't see this.
  # The hint is only returned in visible_token, if protected_token is false.
  def self.serialization_excludes
    %i[crypted_token token_hint crypted_refresh_token]
  end

  def dev_key_account_id
    developer_key.account_id
  end

  # If you have a relation, please use the `user_generated` scope instead of this method.
  def manually_created?
    developer_key_id == DeveloperKey.default.id || developer_key&.name == DeveloperKey::DEFAULT_KEY_NAME
  end

  # if user is not provided, all user tokens in the account will be invalidated
  # if skip_admins is true, tokens for users with active admin roles in the account will not be invalidated
  def self.invalidate_mobile_tokens!(account, user: nil, skip_admins: true)
    return unless account.root_account?

    developer_key_ids = DeveloperKey.mobile_app_keys.map do |app_key|
      app_key.respond_to?(:global_id) ? app_key.global_id : app_key.id
    end
    user_scope = User.active.joins(:pseudonyms).where(pseudonyms: { account_id: account })
    user_scope = user_scope.where(id: user) if user
    user_scope = user_scope.where(<<~SQL.squish, account.id) if skip_admins
      NOT EXISTS (SELECT 1 FROM #{AccountUser.quoted_table_name}
                  WHERE account_users.user_id = users.id
                  AND account_users.account_id = ?
                  AND account_users.workflow_state = 'active')
    SQL
    tokens = active.where(developer_key_id: developer_key_ids, user_id: user_scope.select(:id))

    now = Time.zone.now
    tokens.in_batches(of: 10_000).update_all(updated_at: now, permanent_expires_at: now)
  end

  def queue_developer_key_token_count_increment
    return if developer_key.nil? || developer_key.shard == Shard.default

    developer_key.shard.activate do
      # Previously this enqueued a delayed job per token creation to increment
      # the developer key's access_token_count. High-volume token creation was
      # overwhelming the job shard(s) with many trivial increment jobs, especially
      # when multiple shards created tokens referencing the same developer key.
      #
      # Using ActiveRecord.increment_counter here performs a single, atomic
      # UPDATE statement (SET access_token_count = access_token_count + 1) on
      # the developer key's shard, avoiding the background job overhead while
      # still remaining contention-safe at the DB level.
      DeveloperKey.increment_counter(:access_token_count, developer_key.id)
    end
  end
end
