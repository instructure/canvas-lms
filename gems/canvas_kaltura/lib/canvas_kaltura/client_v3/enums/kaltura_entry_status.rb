# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module CanvasKaltura
  class ClientV3
    module Enums
      # see: https://developer.kaltura.com/api-docs/General_Objects/Enums/KalturaEntryStatus
      module KalturaEntryStatus
        ERROR_IMPORTING = "-2"
        ERROR_CONVERTING = "-1"
        SCAN_FAILURE = "virusScan.ScanFailure"
        IMPORT = "0"
        INFECTED = "virusScan.Infected"
        PRECONVERT = "1"
        READY = "2"
        DELETED = "3"
        PENDING = "4"
        MODERATE = "5"
        BLOCKED = "6"
        NO_CONTENT = "7"

        class << self
          def [](value)
            value = value&.to_s
            @name_by_value ||= constants.index_by { |c| const_get(c) }
            @name_by_value[value]
          end
        end
      end
    end
  end
end
