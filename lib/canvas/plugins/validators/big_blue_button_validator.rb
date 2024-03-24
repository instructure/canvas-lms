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

module Canvas::Plugins::Validators::BigBlueButtonValidator
  def self.validate(settings, plugin_setting)
    if settings.map(&:last).all?(&:blank?)
      {}
    else
      secret = settings.delete(:secret)
      has_no_secret = secret.blank? && plugin_setting.settings.try(:[], :secret).blank?
      expected_settings = %i[domain recording_enabled replace_with_alternatives free_trial send_avatar use_fallback]
      has_nonsecret_blank = settings.map(&:last).any?(&:blank?)
      if settings.size != expected_settings.size || has_nonsecret_blank || has_no_secret
        plugin_setting.errors.add(:base, I18n.t("canvas.plugins.errors.all_fields_required", "All fields are required"))
        false
      else
        settings = settings.slice(*expected_settings).to_h.with_indifferent_access
        settings[:secret] = secret if secret.present?
        settings[:recording_enabled] = Canvas::Plugin.value_to_boolean(settings[:recording_enabled])
        settings[:replace_with_alternatives] = Canvas::Plugin.value_to_boolean(settings[:replace_with_alternatives])
        settings[:free_trial] = Canvas::Plugin.value_to_boolean(settings[:free_trial])
        settings[:send_avatar] = Canvas::Plugin.value_to_boolean(settings[:send_avatar])
        settings[:use_fallback] = Canvas::Plugin.value_to_boolean(settings[:use_fallback])
        settings
      end
    end
  end
end
