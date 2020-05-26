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
  belongs_to :context, polymorphic: [:account, :course, :user]

  validate :valid_state, :feature_applies
  before_save :check_cache
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
    state == 'on'
  end

  def allowed?
    state == 'allowed'
  end

  def locked?(query_context)
    !allowed? && (context_id != query_context.id || context_type != query_context.class.name)
  end

  def clear_cache
    if self.context
      self.class.connection.after_transaction_commit { self.context.feature_flag_cache.delete(self.context.feature_flag_cache_key(feature)) }
      self.context.touch if Feature.definitions[feature].try(:touch_context)
      self.context.clear_cache_key(:feature_flags) if self.context.is_a?(Account)
      if ::Rails.env.development? && self.context.is_a?(Account) && Account.all_special_accounts.include?(self.context)
        Account.clear_special_account_cache!(true)
      end
    end
  end

  private

  def valid_state
    errors.add(:state, "is not valid in context") unless %w(off on).include?(state) || context.is_a?(Account) && state == 'allowed'
  end

  def feature_applies
    if !Feature.exists?(feature)
      errors.add(:feature, "does not exist")
    elsif !Feature.feature_applies_to_object(feature, context)
      errors.add(:feature, "does not apply to context")
    end
  end

  def check_cache
    clear_cache if self.changed?
  end
end
