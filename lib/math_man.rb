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
  class InvalidConfigurationError < StandardError; end

  def self.url_for(latex:, target:)
    uri = base_url.join(target.to_s)
    uri.query = "tex=#{latex}"
    uri.to_s
  end

  def self.cache_key_for(latex, target)
    ["mathman", dynamic_settings.fetch('version'), Digest::MD5.hexdigest(latex), target].compact.cache_key
  end

  def self.use_for_mml?
    Canvas::Plugin.value_to_boolean(plugin_settings[:use_for_mml])
  end

  def self.use_for_svg?
    Canvas::Plugin.value_to_boolean(plugin_settings[:use_for_svg])
  end

  class << self
    private

    def base_url
      url = dynamic_settings[:base_url]
      # if we get here, we should have already checked one of the booleans above
      raise InvalidConfigurationError unless url
      Addressable::URI.parse(url).tap do |uri|
        uri.path << '/' unless uri.path.end_with?('/')
      end
    end

    def plugin_settings
      Canvas::Plugin.find(:mathman).settings
    end

    def dynamic_settings
      Canvas::DynamicSettings.find('math-man')
    end
  end
end
