#
# Copyright (C) 2013 Instructure, Inc.
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
  attr_accessible :feature, :state, :locking_account
  belongs_to :context, polymorphic: true
  belongs_to :locking_account, class_name: 'Account'

  validate :valid_state, :feature_applies, :locking_account_in_chain
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
    Account.find(context.feature_flag_account_ids.last).lookup_feature_flag(feature, true).hidden?
  end

  def enabled?
    state == 'on'
  end

  def allowed?
    state == 'allowed'
  end

  def locked?(query_context, current_user = nil)
    locking_account.present? && (current_user.blank? || !locking_account.grants_right?(current_user, :manage_feature_flags)) ||
        !allowed? && (context_id != query_context.id || context_type != query_context.class.name)
  end

  def clear_cache
    connection.after_transaction_commit { MultiCache.delete(self.context.feature_flag_cache_key(feature), copies: MultiCache.copies('feature_flags')) } if self.context
  end

private
  def valid_state
    errors.add(:state, "is not valid in context") unless %w(off on).include?(state) || context.is_a?(Account) && state == 'allowed'
  end

  def feature_applies
    errors.add(:feature, "is not valid in context") unless Feature.feature_applies_to_object(feature, context)
  end

  def locking_account_in_chain
    if locking_account_id.present?
      account = if context.respond_to?(:parent_account)
                  context.parent_account || Account.site_admin
                else
                  context.account
                end
      account_chain_ids = account.account_chain(include_site_admin: true).map(&:id)
      errors.add(:locking_account_id, "not in account chain") unless account_chain_ids.include?(locking_account_id)
    end
  end

  def check_cache
    clear_cache if self.changed?
  end
end
