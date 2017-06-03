#
# Copyright (C) 2013 - present Instructure, Inc.
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

require 'user_agent'

class Browser < Struct.new(:browser, :version)
  def self.supported?(user_agent)
    user_agent = UserAgent.parse(user_agent)
    return false if minimum_browsers.any?{ |browser| user_agent < browser }
    true # if we don't recognize it (e.g. Android), be nice
  end

  def self.configuration
    @configuration ||= YAML.load_file(File.expand_path('../../config/browsers.yml', __FILE__))
  end

  def self.minimum_browsers
    @minimum_browsers ||= (configuration['minimums'] || []).
      map{ |browser, version| new(browser, version.to_s) }
  end
end

