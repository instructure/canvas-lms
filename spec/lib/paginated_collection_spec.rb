#
# Copyright (C) 2012 Instructure, Inc.
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

describe "PaginatedCollection" do
  describe ".build" do
    it "should return a #paginate proxy" do
      expect { PaginatedCollection.build() }.to raise_error(ArgumentError)
      proxy = PaginatedCollection.build { |pager| pager }
      proxy.should be_is_a PaginatedCollection::Proxy
      proxy.paginate(:per_page => 5).size.should == 0
    end
  end

  describe "#paginate" do
    it "should use the provided collection" do
      expect { PaginatedCollection.build { |pager| [] }.paginate(:per_page => 5) }.to raise_error(ArgumentError)
      items = PaginatedCollection.build { |pager| pager.replace([1,2]) }.paginate(:page => 1, :per_page => 5)
      items.should == [1,2]
      items.size.should == 2
      items.current_page.should == 1
      items.per_page.should == 5
      %w(next_page previous_page first_page last_page total_entries).each { |a| items.send(a).should be_nil }
    end

    it "should use the pager returned" do
      3.times { user_model }
      proxy = PaginatedCollection.build do |pager|
        result = User.active.paginate(:page => pager.current_page, :per_page => pager.per_page, :order => :id)
        result.map! { |u| u.id }
      end
      p1 = proxy.paginate(:page => 1, :per_page => 2)
      p1.current_page.should == 1
      p1.next_page.should == 2
      p1.previous_page.should be_nil
      p2 = proxy.paginate(:page => 2, :per_page => 2)
      p2.current_page.should == 2
      p2.next_page.should be_nil
      p2.previous_page.should == 1
      p1.should == User.active.order(:id).pluck(:id)[0,2]
      p2.should == User.active.order(:id).pluck(:id)[2,1]
    end
  end
end
