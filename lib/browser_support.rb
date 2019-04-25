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

require 'browser/browser'

BrowserSupport = Struct.new(:browser, :version) do
  class << self
    def supported?(user_agent)
      browser = Browser.new(user_agent)
      return false if minimum_browsers.any?{ |min| browser.send("#{min.browser}?", "<#{min.version}") }
      true # if we don't recognize it (e.g. Android), be nice
    end

    def configuration
      @configuration ||= YAML.load_file(File.expand_path('../../config/browsers.yml', __FILE__))
    end

    def minimum_browsers
      @minimum_browsers ||= (configuration['minimums'] || []).
        map{ |browser, version| new(browser, version.to_s) }
    end
  end
end
