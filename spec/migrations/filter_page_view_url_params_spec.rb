#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../cassandra_spec_helper.rb')
require 'lib/data_fixup/filter_page_view_url_params'

describe 'DataFixup::FilterPageViewUrlParams' do
  shared_examples_for 'DataFixup::FilterPageViewUrlParams' do
    it "should filter existing page view urls" do
      @pv = page_view_model(url: 'http://canvas.example.com/api/v1/courses/1?access_token=xyz')
      @pv.reload.read_attribute(:url).should == 'http://canvas.example.com/api/v1/courses/1?access_token=xyz'
      DataFixup::FilterPageViewUrlParams.run
      @pv.reload.read_attribute(:url).should == 'http://canvas.example.com/api/v1/courses/1?access_token=[FILTERED]'
    end
  end

  describe "db" do
    it_should_behave_like 'DataFixup::FilterPageViewUrlParams'
  end

  describe "cassandra" do
    it_should_behave_like "cassandra page views"
    it_should_behave_like 'DataFixup::FilterPageViewUrlParams'
  end
end

