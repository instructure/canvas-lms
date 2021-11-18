# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module Canvas::Plugins::Validators::InstFsValidator
  def self.validate(settings, plugin_setting)
    if settings[:migration_rate].blank?
      migration_rate = 0
    else
      migration_rate = settings[:migration_rate].to_f rescue nil
    end
    if migration_rate.nil? || migration_rate < 0 || migration_rate > 100
      plugin_setting.errors.add(:base, I18n.t('Please enter a number between 0 and 100 for the migration rate'))
      return false
    end
    settings[:migration] = migration_rate
    settings[:service_worker] = Canvas::Plugin.value_to_boolean(settings[:service_worker])
    settings.slice(:migration_rate, :service_worker).to_h.with_indifferent_access
  end
end
