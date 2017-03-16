#
# Copyright (C) 2016 Instructure, Inc.
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

module Canvas::Plugins::Validators::AddressBookValidator
  def self.validate(settings, plugin_setting)
    strategy = settings[:strategy]
    if AddressBook::STRATEGIES.has_key?(strategy)
      settings.to_hash.with_indifferent_access
    else
      plugin_setting.errors.add(:base, I18n.t('Invalid address book strategy.'))
      false
    end
  end
end
