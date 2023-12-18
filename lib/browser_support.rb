# frozen_string_literal: true

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

require "browser/browser"

BrowserSupport = Struct.new(:browser, :version) do
  class << self
    def supported?(user_agent)
      browser = Browser.new(user_agent)
      return true if respondus? browser
      return true if chrome_os_lts? browser
      return false if minimum_browsers.any? { |min| browser.send(:"#{min.browser}?", "<#{min.version}") }

      true # if we don't recognize it (e.g. Android), be nice
    end

    def configuration
      @configuration ||= YAML.load_file(File.expand_path("../config/browsers.yml", __dir__))
    end

    def minimum_browsers
      @minimum_browsers ||= (configuration["minimums"] || [])
                            .map { |browser, version| new(browser, version.to_s) }
    end

    private

    def lts
      @lts = OpenStruct.new(configuration["chrome_os_lts"])
    end

    #
    # Respondus lockdown browser includes a telltale in the User-Agent string which
    # is platform-dependent. Hopefully this never needs to be modified.
    #
    def respondus?(browser)
      return true if browser.platform.mac? && browser.ua.match(/ CMAC \d[.\d]+;/)
      return true if browser.platform.windows? && browser.ua.match(/ CLDB \d[.\d]+;/)

      false
    end

    #
    # Chrome OS has a long-term support (LTS) channel which is updated every 6 months.
    # Unfortunately, the LTS distinction is not reflected in the User-Agent string.
    # This method checks if the browser is Chrome running on Chrome OS and compares it
    # to the specific major LTS version specified in the configuration file.
    #
    def chrome_os_lts?(browser)
      return false unless browser.platform.chrome_os?
      return false unless browser.chrome?(lts.chrome)
      return true if /X11; CrOS \w+ #{lts.platform}/.match?(browser.ua)

      false
    end
  end
end
