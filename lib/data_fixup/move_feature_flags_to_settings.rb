# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module DataFixup::MoveFeatureFlagsToSettings
  def self.run(feature_flag_name, context_going_to, setting_name)
    case context_going_to
    when "RootAccount"
      Account.root_accounts.non_shadow.find_each do |context|
        figure_setting_from_override(context, feature_flag_name, setting_name, inherited: false)
      end
    when "AccountAndCourseInherited"
      Account.root_accounts.non_shadow.find_each do |root_account|
        Account.suspend_callbacks(:invalidate_caches_if_changed) do
          migrate_ff_overrides_to_inherited_recurse(root_account, feature_flag_name, setting_name)
        end
        Rails.cache.delete([feature_flag_name, root_account.global_id].cache_key)
        # queue one job on the root account to clear all the caches recursively
        Account.delay_if_production.invalidate_inherited_caches(root_account, [feature_flag_name])
      end
    else
      raise "invalid setting level"
    end
  end

  def self.migrate_ff_overrides_to_inherited_recurse(account, feature_flag_name, setting_name)
    figure_setting_from_override(account, feature_flag_name, setting_name, inherited: true)
    return if account.settings.dig(setting_name, :locked)

    account.sub_accounts.find_in_batches do |sub_accounts|
      ActiveRecord::Associations.preload(sub_accounts, :feature_flags, FeatureFlag.where(feature: feature_flag_name))
      sub_accounts.each do |sub_account|
        migrate_ff_overrides_to_inherited_recurse(sub_account, feature_flag_name, setting_name)
      end
    end
    account.courses.find_in_batches do |courses|
      ActiveRecord::Associations.preload(courses, :feature_flags, FeatureFlag.where(feature: feature_flag_name))
      courses.each do |course|
        figure_setting_from_override(course, feature_flag_name, setting_name, inherited: false)
      end
    end
  end
  private_class_method :migrate_ff_overrides_to_inherited_recurse

  def self.figure_setting_from_override(context, feature_flag_name, setting_name, inherited:)
    override = if context.feature_flags.loaded?
                 context.feature_flags.detect { |ff| ff.feature == feature_flag_name.to_s }
               else
                 context.feature_flags.where(feature: feature_flag_name.to_s).take
               end
    override_value = nil
    locked = true
    if override
      case override.state
      when "allowed"
        # no op
      when "allowed_on"
        override_value = true
        locked = false
      when "on"
        override_value = true
      when "off"
        override_value = false
      else
        Rails.logger.warn("DataFixup::MoveFeatureFlagsToSettings => unable to handle override state for context " \
                          "#{context.asset_string} of feature #{override.id} with state #{override.state}")
      end
    end

    unless override_value.nil?
      if context.is_a?(Account)
        context.settings[setting_name] = inherited ? { locked:, value: override_value } : override_value
      else
        context.settings_frd[setting_name] = override_value
      end
      context.save!
    end
  end
  private_class_method :figure_setting_from_override
end
