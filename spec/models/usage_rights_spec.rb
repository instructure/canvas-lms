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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe UsageRights do

  describe '#license_url' do
    it 'returns the private license url if no license is specified' do
      expect(subject.license_url).to eq 'http://en.wikipedia.org/wiki/Copyright'
    end

    it 'returns the url for the license' do
      subject.license = 'cc_by_nc_nd'
      expect(subject.license_url).to eq 'http://creativecommons.org/licenses/by-nc-nd/4.0/'
    end
  end

end
