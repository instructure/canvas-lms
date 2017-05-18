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

require 'spec_helper'

describe BookmarkedCollection::Proxy do
  describe '#paginate' do
    before :each do
      example_class = Class.new(ActiveRecord::Base) do
        self.table_name = 'examples'
      end
      3.times{ example_class.create! }
      @scope = example_class.order(:id)

      @next_bookmark = double
      @bookmarker = double(bookmark_for: @next_bookmark, validate: true)
      @proxy = BookmarkedCollection::Proxy.new(@bookmarker, lambda do |pager|
        results = @scope.paginate(page: 1, per_page: pager.per_page)
        pager.replace results
        pager.has_more! if results.next_page
        pager
      end)
    end

    it 'should require per_page parameter' do
      expect{ @proxy.paginate() }.to raise_error(ArgumentError)
    end

    it('should ignore total_entries parameter') do
      expect(@proxy.paginate(:per_page => 5, :total_entries => 10).total_entries).to be_nil
    end

    it 'should require a bookmark-style page parameter' do
      value = 1
      bookmark1 = 1
      bookmark2 = 'bookmark:W1td' # base64 of '[[]' which should fail to parse
      bookmark3 = "bookmark:#{::JSONToken.encode(value)}"
      expect(@proxy.paginate(:page => bookmark1, :per_page => 5).current_bookmark).to be_nil
      expect(@proxy.paginate(:page => bookmark2, :per_page => 5).current_bookmark).to be_nil
      expect(@proxy.paginate(:page => bookmark3, :per_page => 5).current_bookmark).to eq value
    end

    it 'should produce an appropriate collection type' do
      expect(@proxy.paginate(:per_page => 1)).to be_a(BookmarkedCollection::Collection)
    end

    it 'should include the results' do
      expect(@proxy.paginate(:per_page => 1)).to eq [@scope.first]
      expect(@proxy.paginate(:per_page => @scope.count)).to eq @scope
    end

    it 'should set next_bookmark if the page was not the last' do
      expect(@proxy.paginate(:per_page => 1).next_bookmark).to eq @next_bookmark
    end

    it 'should not set next_bookmark if the page was the last' do
      expect(@proxy.paginate(:per_page => @scope.count).next_bookmark).to be_nil
    end
  end
end
