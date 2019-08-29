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
      Account.root_accounts.find_each do |context|
        figure_setting_from_override(context, feature_flag_name, setting_name, inherited: false)
      end
    when "AccountAndCourseInherited"
      Account.root_accounts.find_each do |root_account|
        migrate_ff_overrides_to_inherited_recurse(root_account, feature_flag_name, setting_name)
      end
    else
      raise "invalid setting level"
    end
  end

  def self.migrate_ff_overrides_to_inherited_recurse(account, feature_flag_name, setting_name)
    figure_setting_from_override(account, feature_flag_name, setting_name, inherited: true)
    return if account.settings.dig(setting_name, :locked)

    account.sub_accounts.find_each do |sub_account|
      migrate_ff_overrides_to_inherited_recurse(sub_account, feature_flag_name, setting_name)
    end
    account.courses.find_each do |course|
      figure_setting_from_override(course, feature_flag_name, setting_name, inherited: false)
    end
  end
  private_class_method :migrate_ff_overrides_to_inherited_recurse

  def self.figure_setting_from_override(context, feature_flag_name, setting_name, inherited:)
    override = context.feature_flags.where(:feature => feature_flag_name.to_s).take
    override_value = nil
    if override
      case override.state
      when "allowed"
        # no op
      when "on"
        override_value = true
      when "off"
        override_value = false
      else
        Rails.logger.warn("DataFixup::MoveFeatureFlagsToSettings => unable to handle override state for context "\
                            "#{context.asset_string} of feature #{override.id} with state #{override.state}")
      end
    end

    unless override_value.nil?
      if context.is_a?(Account)
        context.settings[setting_name] = inherited ? {:locked => true, :value => override_value} : override_value
      else
        context.settings_frd[setting_name] = override_value
      end
      context.save!
    end
  end
  private_class_method :figure_setting_from_override
end
