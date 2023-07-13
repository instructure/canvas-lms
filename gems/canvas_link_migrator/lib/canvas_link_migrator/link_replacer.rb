# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module CanvasLinkMigrator
  class LinkReplacer
    # returns false if no substitutions were made
    def self.sub_placeholders!(html, links)
      subbed = false
      links.each do |link|
        new_value = link[:new_value] || link[:old_value]
        if html.gsub!(link[:placeholder], new_value)
          link[:replaced] = true
          subbed = true
        end
      end
      subbed
    end

    def self.recursively_sub_placeholders!(object, links)
      subbed = false
      case object
      when Hash
        object.each_value { |o| subbed = true if recursively_sub_placeholders!(o, links) }
      when Array
        object.each { |o| subbed = true if recursively_sub_placeholders!(o, links) }
      when String
        subbed = sub_placeholders!(object, links)
      end
      subbed
    end
  end
end
