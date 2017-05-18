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

module MathMan
  def self.url_for(latex:, target:)
    "#{base_url}/#{target}?tex=#{latex}"
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

  private
  def self.base_url
    with_plugin_settings do |plugin_settings|
      plugin_settings[:base_url].sub(/\/$/, '')
    end
  end

  def self.with_plugin_settings
    plugin_settings = Canvas::Plugin.find(:mathman).settings
    yield plugin_settings
  end
end
