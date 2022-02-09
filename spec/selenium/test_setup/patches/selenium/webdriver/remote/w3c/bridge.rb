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

require "selenium-webdriver"

module Selenium
  module WebDriver
    module Remote
      class Bridge
        def log(type)
          command(:get_log, "session/:session_id/log", :post)
          data = execute :get_log, {}, { type: type.to_s }

          Array(data).map do |l|
            LogEntry.new l.fetch("level", "UNKNOWN"), l.fetch("timestamp"), l.fetch("message")
          rescue KeyError
            next
          end
        end
      end
    end
  end
end
