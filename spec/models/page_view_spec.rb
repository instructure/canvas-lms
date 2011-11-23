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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe PageView do
  before do
    @page_view = PageView.new { |p| p.send(:attributes=, { :user_id => 1, :url => "http://test.one/", :session_id => "phony", :context_id => 1, :context_type => 'Course', :controller => 'courses', :action => 'show', :user_request => true, :render_time => 0.01, :user_agent => 'None', :account_id => Account.default.id, :request_id => "abcde", :interaction_seconds => 5 }, false) }
  end

  it "should store directly to the db in db mode" do
    Setting.set('enable_page_views', 'db')
    @page_view.store.should be_true
    PageView.count.should == 1
    PageView.first.should == @page_view
  end

  if Canvas.redis_enabled?
    it "should store into redis through to the db in cache mode" do
      Setting.set('enable_page_views', 'cache')
      @page_view.store.should be_true
      PageView.count.should == 0
      PageView.process_cache_queue
      PageView.count.should == 1
      PageView.first.attributes.except('created_at', 'updated_at').should == @page_view.attributes.except('created_at', 'updated_at')
    end
  end
end
