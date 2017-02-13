#
# Copyright (C) 2016 Instructure, Inc.
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
require_dependency "lti/launch"

module Lti
  describe Launch do
  let(:launch) {Launch.new}

    describe 'initialize' do
      it 'correctly sets tool dimension default' do
        expect(subject.tool_dimensions).to eq({selection_height: '100%', selection_width: '100%'})
      end

      it 'uses specified tool dimensions if they are provided' do
        options = {
          tool_dimensions: {selection_height: '800', selection_width: '600'}
        }
        launch = Launch.new(options)
        expect(launch.tool_dimensions).to eq options[:tool_dimensions]
      end

      it 'returns "about:blank" if resource_url has an unsupported protocol' do
        launch.resource_url = 'javascript:x/x%250aalert(badstuff)'
        expect(launch.resource_url).to eq 'about:blank'
      end

      it 'returns "about:blank" if resource_url is an invalid url' do
        launch.resource_url = '"'
        expect(launch.resource_url).to eq 'about:blank'
      end
    end
  end
end
