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
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Canvas::Crocodoc do
  describe '.enabled?' do
    it 'returns true when there crocodoc is configured' do
      expect(Canvas::Crocodoc.enabled?).to eq false

      PluginSetting.create! name: "crocodoc", settings: {api_key: "abc123"}
      expect(Canvas::Crocodoc.enabled?).to eq true

      ps = PluginSetting.where(name: "crocodoc").first
      ps.update_attribute :disabled, true
      expect(Canvas::Crocodoc.enabled?).to eq false
    end
  end
end
