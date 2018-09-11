#
# Copyright (C) 2011 - present Instructure, Inc.
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

    describe '#iframe_allowances' do
      subject{ Launch.iframe_allowances(user_agent) }

      context 'when Chrome is used' do
        let(:user_agent) do
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.81 Safari/537.36"
        end

        it 'sets allowed origin to "*"' do
          expect(subject).to match_array [
            'geolocation *',
            'microphone *',
            'camera *',
            'midi *',
            'encrypted-media *'
          ]
        end
      end

      context 'when Chrome is not used' do
        let(:user_agent) do
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1.2 Safari/605.1.15"
        end

        it 'sets allowed origin to "*"' do
          expect(subject).to match_array [
            'geolocation',
            'microphone',
            'camera',
            'midi',
            'encrypted-media'
          ]
        end
      end
    end

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
