#
# Copyright (C) 2012-2014 Instructure, Inc.
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

describe PaginatedCollection do
  describe '.build' do
    it 'returns a #paginate proxy' do
      expect { PaginatedCollection.build }.to raise_error(ArgumentError)
      proxy = PaginatedCollection.build { |pager| pager }
      expect(proxy).to be_a_kind_of(PaginatedCollection::Proxy)

      expect(proxy.paginate(:per_page => 5).size).to eq 0
    end
  end

  describe '#paginate' do
    it 'uses the provided collection' do
      expect { PaginatedCollection.build { |pager| [] }.paginate(:per_page => 5) }.to raise_error(ArgumentError)
      items = PaginatedCollection.build { |pager| pager.replace([1, 2]) }.paginate(:page => 1, :per_page => 5)
      expect(items).to eq [1, 2]
      expect(items.size).to eq 2
      expect(items.current_page).to eq 1
      expect(items.per_page).to eq 5
      expect(items.last_page).to eq 1
      %w(first_page next_page previous_page total_entries).each do |a|
        expect(items.send(a)).to be_nil
      end
    end

    it 'uses the pager returned' do
      example_klass = Class.new(ActiveRecord::Base) do
        self.table_name = 'examples'
      end

      3.times { example_klass.create! }

      proxy = PaginatedCollection.build do |pager|
        result = example_klass.paginate(page: pager.current_page, per_page: pager.per_page)
        result.map! { |example| example.id }
        result
      end

      p1 = proxy.paginate(:page => 1, :per_page => 2)
      expect(p1.current_page).to eq 1
      expect(p1.next_page).to eq 2
      expect(p1.previous_page).to be_nil

      p2 = proxy.paginate(:page => 2, :per_page => 2)
      expect(p2.current_page).to eq 2
      expect(p2.next_page).to be_nil
      expect(p2.previous_page).to eq 1

      expect(p1).to eq example_klass.all.map(&:id)[0, 2]
      expect(p2).to eq example_klass.all.map(&:id)[2, 1]
    end
  end
end
