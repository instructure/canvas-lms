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

describe QuizzesHelper do
  include ApplicationHelper
  include QuizzesHelper

  context 'render_score' do
    it 'should render nil scores' do
      render_score(nil).should == '_'
    end

    it 'should render non-nil scores' do
      render_score(1).should == '1'
      render_score(100).should == '100'
      render_score(1.123).should == '1.12'
      render_score(1000.45166).should == '1000.45'
      render_score(1000.45966).should == '1000.46'
      render_score('100').should == '100'
      render_score('1.43').should == '1.43'
    end
  end
end
