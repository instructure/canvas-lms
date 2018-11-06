#
# Copyright (C) 2016 - present Instructure, Inc.
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

require "addressable/uri"

module MathMan
  def self.url_for(latex:, target:)
    uri = base_url.join(target.to_s)
    uri.query = "tex=#{latex}"
    uri.to_s
  end

  def self.use_for_mml?
    with_plugin_settings do |plugin_settings|
      Canvas::Plugin.value_to_boolean(
        plugin_settings[:use_for_mml]
      )
    end
  end

  def self.use_for_svg?
    with_plugin_settings do |plugin_settings|
      Canvas::Plugin.value_to_boolean(
        plugin_settings[:use_for_svg]
      )
    end
  end

  class << self
    private

    def base_url
      with_plugin_settings do |plugin_settings|
        Addressable::URI.parse(plugin_settings[:base_url]).tap do |uri|
          uri.path << '/' unless uri.path.end_with?('/')
        end
      end
    end

    def with_plugin_settings
      plugin_settings = Canvas::Plugin.find(:mathman).settings
      settings = {
        base_url: ENV['MATHMAN_BASE_URL'],
        use_for_mml: plugin_settings[:use_for_mml],
        use_for_svg: plugin_settings[:use_for_svg]
      }
      yield settings
    end
  end
end
