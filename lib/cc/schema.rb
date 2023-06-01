# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

module CC
  class Schema
    XSD_DIRECTORY = "lib/cc/xsd"
    REGEX = /\.xsd$/

    def self.for_version(version)
      return nil unless whitelist.include?(version)

      Rails.root.join("#{XSD_DIRECTORY}/#{version}.xsd")
    end

    def self.whitelist
      @whitelist ||= Dir.entries(XSD_DIRECTORY).each_with_object([]) do |entry, memo|
        memo << entry.gsub(REGEX, "") if REGEX.match?(entry)
      end
    end
  end
end
