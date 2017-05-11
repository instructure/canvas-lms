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

require 'sanitize'

module DataFixup
  module SanitizeEportfolios
    def self.run
      config = CanvasSanitize::SANITIZE
      EportfolioEntry.
        where("content LIKE '%rich\_text%' OR content LIKE '%html%'").
        find_each do |entry|
          next unless entry.content.is_a?(Array)
          entry.content.each do |obj|
            next unless obj.is_a?(Hash)
            next unless ['rich_text', 'html'].include?(obj[:section_type])
            obj[:content] = Sanitize.clean(obj[:content] || '', config).strip
          end
          entry.save!
      end
    end
  end
end
