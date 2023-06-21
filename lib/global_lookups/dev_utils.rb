# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module GlobalLookups
  class DevUtils
    # this is a bit convoluted, but it makes it simpler
    # to have a module-level interface like this that
    # can be overidden easily in plugins by having
    # modules prepend themselves to override what "DevUtils" does.
    def initialize_ddb_for_development!(recreate: false)
      puts("Nothing to do for global lookups stub")
    end

    def self.initialize_ddb_for_development!(recreate: false)
      GlobalLookups::DevUtils.new.initialize_ddb_for_development!(recreate:)
    end
  end
end
