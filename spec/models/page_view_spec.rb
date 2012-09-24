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
require File.expand_path(File.dirname(__FILE__) + '/../cassandra_spec_helper.rb')

describe PageView do
  before do
    # sets both @user and @course (@user is a teacher in @course)
    course_model
    @page_view = PageView.new { |p| p.send(:attributes=, { :url => "http://test.one/", :session_id => "phony", :context => @course, :controller => 'courses', :action => 'show', :user_request => true, :render_time => 0.01, :user_agent => 'None', :account_id => Account.default.id, :request_id => "abcde", :interaction_seconds => 5, :user => @user }, false) }
  end

  describe "cassandra page views" do
    it_should_behave_like "cassandra page views"
    it "should store and load from cassandra" do
      expect {
        @page_view.save!
      }.to change { PageView.cassandra.execute("select count(*) from page_views").fetch_row["count"] }.by(1)
      PageView.find(@page_view.id).should == @page_view
      expect { PageView.find("junk") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should paginate with a willpaginate-like array" do
      # some page views we shouldn't find
      page_view_model(:user => user_model)
      page_view_model(:user => user_model)

      user_model
      pvs = []
      4.times { |i| pvs << page_view_model(:user => @user, :created_at => (5 - i).weeks.ago) }
      pager = @user.page_views
      pager.should be_a PageView::CassandraAssociation
      expect { pager.paginate() }.to raise_exception(ArgumentError)
      full = pager.paginate(:per_page => 4)
      full.size.should == 4
      full.next_page.should be_nil

      half = pager.paginate(:per_page => 2)
      half.should == full[0,2]
      half.next_page.should be_present

      second_half = pager.paginate(:per_page => 2, :page => half.next_page)
      second_half.should == full[2,2]
      second_half.next_page.should be_nil
    end

    it "should halt pagination after a set time period" do
      p1 = page_view_model(:user => @user)
      p2 = page_view_model(:user => @user, :created_at => 13.months.ago)
      coll = @user.page_views.paginate(:per_page => 3)
      coll.should == [p1]
      coll.next_page.should be_blank
    end

    it "should ignore an invalid page" do
      @page_view.save!
      @user.page_views.paginate(:per_page => 2, :page => '3').should == [@page_view]
    end
  end

  it "should store directly to the db in db mode" do
    Setting.set('enable_page_views', 'db')
    @page_view.store.should be_true
    PageView.count.should == 1
    PageView.find(@page_view.id).should == @page_view
  end

  if Canvas.redis_enabled?
    before do
      Setting.set('enable_page_views', 'cache')
    end

    it "should store into redis through to the db in cache mode" do
      @page_view.store.should be_true
      PageView.count.should == 0
      PageView.process_cache_queue
      PageView.count.should == 1
      PageView.find(@page_view.id).attributes.except('created_at', 'updated_at', 'summarized').should == @page_view.attributes.except('created_at', 'updated_at', 'summarized')
    end

    it "should store into redis in transactional batches" do
      @page_view.store.should be_true
      PageView.new { |p| p.send(:attributes=, { :user_id => 7, :url => "http://test.one/", :session_id => "phony", :context => @course, :controller => 'courses', :action => 'show', :user_request => true, :render_time => 0.01, :user_agent => 'None', :account_id => Account.default.id, :request_id => "abcdef", :interaction_seconds => 5 }, false) }.store
      PageView.new { |p| p.send(:attributes=, { :user_id => 7, :url => "http://test.one/", :session_id => "phony", :context => @course, :controller => 'courses', :action => 'show', :user_request => true, :render_time => 0.01, :user_agent => 'None', :account_id => Account.default.id, :request_id => "abcdefg", :interaction_seconds => 5 }, false) }.store
      PageView.count.should == 0
      Setting.set('page_view_queue_batch_size', '2')
      PageView.expects(:transaction).at_least(5).yields # 5 times, because 2 outermost transactions, then rails starts a "transaction" for each save (which runs as a no-op, since we're already in a transaction)
      PageView.process_cache_queue
      PageView.count.should == 3
    end

    describe "batch transaction" do
      self.use_transactional_fixtures = false
      it "should not fail the batch if one row fails" do
        expect {
          PageView.transaction do
            PageView.process_cache_queue_item('request_id' => '1234')
            PageView.process_cache_queue_item('request_id' => '1234')
          end
        }.to change(PageView, :count).by(1)
      end

      after do
        PageView.delete_all

        # tear down both the course and the user and their detritus
        Enrollment.delete_all
        UserAccountAssociation.delete_all
        User.delete_all
        CourseAccountAssociation.delete_all
        Course.delete_all
      end
    end

    describe "active user counts" do
      it "should generate bucket names" do
        PageView.user_count_bucket_for_time(Time.zone.parse('2012-01-20T13:41:17Z')).should == 'active_users:2012-01-20T13:40:00Z'
        PageView.user_count_bucket_for_time(Time.zone.parse('2012-01-20T03:25:00Z')).should == 'active_users:2012-01-20T03:25:00Z'
        PageView.user_count_bucket_for_time(Time.zone.parse('2012-01-20T03:29:59Z')).should == 'active_users:2012-01-20T03:25:00Z'
      end

      it "should do nothing if not enabled" do
        Setting.set('page_views_store_active_user_counts', 'false')
        @page_view.store.should be_true
        Canvas.redis.smembers(PageView.user_count_bucket_for_time(Time.now)).should == []
      end

      it "should store if enabled" do
        Setting.set('page_views_store_active_user_counts', 'redis')
        @page_view.store.should be_true
      end

      it "should store user ids in the set for page views" do
        Setting.set('page_views_store_active_user_counts', 'redis')
        store_time = Time.zone.parse('2012-01-13T15:43:21Z')
        @page_view.created_at = store_time
        @page_view.store.should be_true
        bucket = PageView.user_count_bucket_for_time(store_time)
        Canvas.redis.smembers(bucket).should == [@user.global_id.to_s]
        Canvas.redis.ttl(bucket).should > 23.hours

        store_time_2 = Time.zone.parse('2012-01-13T15:47:52Z')
        @user1 = @user
        @user2 = user_model
        pv2 = PageView.new { |p| p.send(:attributes=, { :user => @user2, :url => "http://test.one/", :session_id => "phony", :context => @course, :controller => 'courses', :action => 'show', :user_request => true, :render_time => 0.01, :user_agent => 'None', :account_id => Account.default.id, :request_id => "abcde", :interaction_seconds => 5 }, false) }
        pv3 = PageView.new { |p| p.send(:attributes=, { :user => @user2, :url => "http://test.one/", :session_id => "phony", :context => @course, :controller => 'courses', :action => 'show', :user_request => true, :render_time => 0.01, :user_agent => 'None', :account_id => Account.default.id, :request_id => "abcde", :interaction_seconds => 5 }, false) }
        pv2.created_at = store_time
        pv3.created_at = store_time_2
        pv2.store.should be_true
        pv3.store.should be_true

        Canvas.redis.smembers(bucket).sort.should == [@user1.global_id.to_s, @user2.global_id.to_s]
        Canvas.redis.smembers(PageView.user_count_bucket_for_time(store_time_2)).should == [@user2.global_id.to_s]
      end
    end
  end
end
