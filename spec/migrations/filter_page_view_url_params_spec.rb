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
      Setting.set('filter_page_view_url_params_batch_size', '2')
      3.times { page_view_model() }
      @pv = page_view_model(url: 'http://canvas.example.com/api/v1/courses/1?access_token=xyz')
      expect(@pv.reload.read_attribute(:url)).to eq 'http://canvas.example.com/api/v1/courses/1?access_token=xyz'
      DataFixup::FilterPageViewUrlParams.run
      expect(@pv.reload.read_attribute(:url)).to eq 'http://canvas.example.com/api/v1/courses/1?access_token=[FILTERED]'
    end
  end

  describe "db" do
    include_examples 'DataFixup::FilterPageViewUrlParams'
  end

  describe "cassandra" do
    include_examples "cassandra page views"
    include_examples 'DataFixup::FilterPageViewUrlParams'
  end
end

