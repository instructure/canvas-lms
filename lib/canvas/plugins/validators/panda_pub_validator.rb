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

module Canvas::Plugins::Validators::PandaPubValidator
  def self.validate(settings, plugin_setting)
    if settings.map(&:last).all?(&:blank?)
      {}
    else
      if settings.map(&:last).any?(&:blank?)
        plugin_setting.errors.add(:base, I18n.t('canvas.plugins.errors.all_fields_required', 'All fields are required'))
        false
      else
        uri = URI.parse(settings[:base_url].strip) rescue nil
        if !uri
          plugin_setting.errors.add(:base, I18n.t('canvas.plugins.errors.invalid_url', 'Invalid URL'))
          false
        else
          settings.permit(:base_url, :application_id, :key_id, :key_secret).to_h.with_indifferent_access
        end
      end
    end
  end
end

