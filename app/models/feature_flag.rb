# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

class FeatureFlag < ActiveRecord::Base
  # this field is used for audit logging.
  # if a request is changing the state of a feature
  # flag, it should set this value before persisting
  # the change.
  attr_writer :current_user

  belongs_to :context, polymorphic: %i[account course user]

  validate :valid_state, :feature_applies
  before_save :check_cache
  after_create :audit_log_create # to make sure we have an ID, must be after
  before_update :audit_log_update
  before_destroy :audit_log_destroy
  before_destroy :clear_cache

  def default?
    false
  end

  def hidden?
    false
  end

  def unhides_feature?
    return false unless Feature.definitions[feature].hidden?
    return true if context.is_a?(Account) && context.site_admin?

    parent_setting = Account.find(context.feature_flag_account_ids.last).lookup_feature_flag(feature, override_hidden: true)
    parent_setting.nil? || parent_setting.hidden?
  end

  def enabled?
    state == Feature::STATE_ON || state == Feature::STATE_DEFAULT_ON
  end

  def can_override?
    state == Feature::STATE_DEFAULT_OFF || state == Feature::STATE_DEFAULT_ON
  end

  def locked?(query_context)
    !can_override? && (context_id != query_context.id || context_type != query_context.class.name)
  end

  def clear_cache
    if context
      self.class.connection.after_transaction_commit do
        context.feature_flag_cache.delete(context.feature_flag_cache_key(feature))
        context.touch if Feature.definitions[feature].try(:touch_context) || context.try(:root_account?)

        if context.is_a?(Account)
          if context.site_admin?
            Switchman::DatabaseServer.send_in_each_region(context, :clear_cache_key, {}, :feature_flags)
          else
            context.clear_cache_key(:feature_flags)
          end
        end

        if !::Rails.env.production? && context.is_a?(Account) && Account.all_special_accounts.include?(context)
          Account.clear_special_account_cache!(true)
        end
      end
    end
  end

  def audit_log_update(operation: :update)
    # User feature flags only get changed by the target user,
    # are much higher volume than higher level flags, and are generally
    # uninteresting from a forensics standpoint.  We can save a lot of writes
    # by not caring about them.
    unless context.is_a?(User)
      # this should catch a programatic/console user if one is acting
      # outside the request/response cycle
      acting_user = @current_user || Canvas.infer_user
      prior_state = prior_flag_state(operation)
      post_state = post_flag_state(operation)
      Auditors::FeatureFlag.record(self, acting_user, prior_state, post_state:)
    end
  end

  def audit_log_create
    audit_log_update(operation: :create)
  end

  def audit_log_destroy
    audit_log_update(operation: :destroy)
  end

  def prior_flag_state(operation)
    (operation == :create) ? default_for_flag : state_in_database
  end

  def post_flag_state(operation)
    (operation == :destroy) ? default_for_flag : state
  end

  def default_for_flag
    Feature.definitions[feature]&.state || "undefined"
  end

  private

  def valid_state
    unless [Feature::STATE_OFF, Feature::STATE_ON].include?(state) || (context.is_a?(Account) && [Feature::STATE_DEFAULT_OFF, Feature::STATE_DEFAULT_ON].include?(state))
      errors.add(:state, "is not valid in context")
    end
  end

  def feature_applies
    if !Feature.exists?(feature)
      errors.add(:feature, "does not exist")
    elsif !Feature.feature_applies_to_object(feature, context)
      errors.add(:feature, "does not apply to context")
    end
  end

  def check_cache
    clear_cache if changed?
  end
end
