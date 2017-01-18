#
# Copyright (C) 2015 Instructure, Inc.
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

describe Lti::ReRegConstraint do

  describe '#matches?' do
    it 'returns true if the header VND-IMS-CONFIRM-URL is present' do
      mock_request = mock('mock_request')
      mock_request.stubs(:headers).returns({'VND-IMS-CONFIRM-URL' => 'http://i-am-a-place-on-the-internet.dev/'})
      mock_request.stubs(:format).returns('json')
      expect(subject.matches?(mock_request)).to be_truthy
    end

    it 'returns failse if the format is not json' do
      mock_request = mock('mock_request')
      mock_request.stubs(:headers).returns({'VND-IMS-CONFIRM-URL' => 'http://i-am-a-place-on-the-internet.dev/'})
      mock_request.stubs(:format).returns('xml')
      expect(subject.matches?(mock_request)).to be_falsey
    end

  end

end
