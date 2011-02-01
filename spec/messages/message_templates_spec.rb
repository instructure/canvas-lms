#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'message templates' do
  # it "should have tests for all message templates" do
    Dir.glob(File.join(RAILS_ROOT, 'app', 'messages', '*.erb')) do |filename|
      filename = File.split(filename)[1]
      if !filename.match(/^_/)
        it "should have a spec test for #{filename}" unless File.exists?(File.expand_path(File.dirname(__FILE__) + '/' + filename + '_spec.rb'))
        # File.should be_exists(File.expand_path(File.dirname(__FILE__) + '/' + filename + '_spec.rb'))
      end
    end
  # end
end
