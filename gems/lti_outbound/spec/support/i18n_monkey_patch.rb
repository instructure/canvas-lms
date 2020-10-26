# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

#Any including Application will need to perform the override in order for this gem to function as expected.

module I18n
  class << self
    attr_accessor :localizer

    # Public: If a localizer has been set, use it to set the locale and then
    # delete it.
    #
    # Returns nothing.
    def set_locale_with_localizer
      if localizer
        self.locale = localizer.call
        self.localizer = nil
      end
    end
  end
end