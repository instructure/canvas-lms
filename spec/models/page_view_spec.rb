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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../cassandra_spec_helper.rb')

describe PageView do
  before do
    # sets both @user and @course (@user is a teacher in @course)
    course_model
    @page_view = PageView.new { |p| p.assign_attributes({ :url => "http://test.one/", :session_id => "phony", :context => @course, :controller => 'courses', :action => 'show', :user_request => true, :render_time => 0.01, :user_agent => 'None', :account_id => Account.default.id, :request_id => "abcde", :interaction_seconds => 5, :user => @user }, :without_protection => true) }
  end

  describe "sharding" do
      specs_require_sharding

      it "should not assign the default shard" do
        PageView.new.shard.should == Shard.default
        @shard1.activate do
          PageView.new.shard.should == @shard1
        end
      end
  end

  describe "cassandra page views" do
    include_examples "cassandra page views"
    it "should store and load from cassandra" do
      expect {
        @page_view.request_id = "abcde1"
        @page_view.save!
      }.to change { PageView::EventStream.database.execute("select count(*) from page_views").fetch_row["count"] }.by(1)
      PageView.find(@page_view.id).should == @page_view
      expect { PageView.find("junk") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should not start a db transaction on save" do
      PageView.new { |p| p.assign_attributes({ :user => @user, :url => "http://test.one/", :session_id => "phony", :context => @course, :controller => 'courses', :action => 'show', :user_request => true, :render_time => 0.01, :user_agent => 'None', :account_id => Account.default.id, :request_id => "abcdef", :interaction_seconds => 5 }, :without_protection => true) }.store
      PageView.connection.expects(:transaction).never
      PageView.find("abcdef").should be_present
    end

    describe "sharding" do
      specs_require_sharding

      it "should always assign the birth shard" do
        PageView.new.shard.should == Shard.birth
        pv = nil
        u = User.create!
        @shard1.activate do
          pv = page_view_model
          pv.shard.should == Shard.birth
          pv.user = u
          pv.save!
          pv.read_attribute(:user_id).should == u.local_id
          pv = PageView.find(pv.request_id)
          pv.should be_present
          pv.shard.should == Shard.birth
        end
        pv = PageView.find(pv.request_id)
        pv.should be_present
        pv.shard.should == Shard.birth
        pv.interaction_seconds = 25
        pv.save!
        pv = PageView.find(pv.request_id)
        pv.interaction_seconds.should == 25
      end

      it "should store and load from cassandra when the birth shard is not the default shard" do
        Shard.stubs(:birth).returns(@shard1)
        @shard2.activate do
          expect {
            @page_view.request_id = "abcde2"
            @page_view.save!
          }.to change { PageView::EventStream.database.execute("select count(*) from page_views").fetch_row["count"] }.by(1)
          PageView.find(@page_view.id).should == @page_view
          expect { PageView.find("junk") }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    it "should paginate with a willpaginate-like array" do
      # some page views we shouldn't find
      page_view_model(:user => user_model)
      page_view_model(:user => user_model)

      user_model
      pvs = []
      4.times { |i| pvs << page_view_model(:user => @user, :created_at => (5 - i).weeks.ago) }
      pager = @user.page_views
      pager.should be_a PaginatedCollection::Proxy
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

    describe "db migrator" do
      it "should migrate the relevant page views" do
        a1 = account_model
        a2 = account_model
        a3 = account_model
        Setting.set('enable_page_views', 'db')
        moved = (0..1).map { page_view_model(:account => a1, :created_at => 1.day.ago) }
        moved_a3 = page_view_model(:account => a3, :created_at => 4.hours.ago)
        # this one is more recent in time and will be processed last
        moved_later = page_view_model(:account => a1, :created_at => 2.hours.ago)
        # this one is in a deleted account
        deleted = page_view_model(:account => a2, :created_at => 2.hours.ago)
        a2.destroy
        # too far back
        old = page_view_model(:account => a1, :created_at => 13.months.ago)

        Setting.set('enable_page_views', 'cassandra')
        migrator = PageView::CassandraMigrator.new
        PageView.find_all_by_id(moved.map(&:request_id)).size.should == 0
        migrator.run_once(2)
        PageView.find_all_by_id(moved.map(&:request_id)).size.should == 2
        # should migrate all active accounts
        PageView.find(moved_a3.request_id).request_id.should == moved_a3.request_id
        expect { PageView.find(moved_later.request_id) }.to raise_error(ActiveRecord::RecordNotFound)
        # it should resume where the last migrator left off
        migrator = PageView::CassandraMigrator.new
        # it could find the first two twice if we're on mysql, due to no sub-second precision,
        # so do a batch of 3
        migrator.run_once(3)
        PageView.find(moved.map(&:request_id) + [moved_later.request_id]).size.should == 3

        expect { PageView.find(deleted.request_id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect { PageView.find(old.request_id) }.to raise_error(ActiveRecord::RecordNotFound)

        # running again should migrate new page views as time advances
        Setting.set('enable_page_views', 'db')
        # shouldn't actually happen, but create an older page view to verify
        # we're not migrating old page views again
        not_moved = page_view_model(:account => a1, :created_at => 1.day.ago)
        newly_moved = page_view_model(:account => a1, :created_at => 1.hour.ago)
        Setting.set('enable_page_views', 'cassandra')
        migrator = PageView::CassandraMigrator.new
        migrator.run_once(2)
        expect { PageView.find(not_moved.request_id) }.to raise_error(ActiveRecord::RecordNotFound)
        PageView.find(newly_moved.request_id).request_id.should == newly_moved.request_id
      end
    end
  end

  it "should store directly to the db in db mode" do
    Setting.set('enable_page_views', 'db')
    @page_view.store.should be_true
    PageView.count.should == 1
    PageView.find(@page_view.id).should == @page_view
  end

  it "should not store if the page view has no user" do
    Setting.set('enable_page_views', 'db')
    @page_view.user = nil
    @page_view.store.should be_false
    PageView.count.should == 0
  end

  if Canvas.redis_enabled?
    describe "active user counts" do
      before :once do
        Setting.set('enable_page_views', 'db')
      end

      it "should generate bucket names" do
        PageView.user_count_bucket_for_time(Time.zone.parse('2012-01-20T13:41:17Z')).should be_starts_with 'active_users:2012-01-20T13:40:00Z'
        PageView.user_count_bucket_for_time(Time.zone.parse('2012-01-20T03:25:00Z')).should be_starts_with 'active_users:2012-01-20T03:25:00Z'
        PageView.user_count_bucket_for_time(Time.zone.parse('2012-01-20T03:29:59Z')).should be_starts_with 'active_users:2012-01-20T03:25:00Z'
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
        pv2 = PageView.new { |p| p.assign_attributes({ :user => @user2, :url => "http://test.one/", :session_id => "phony", :context => @course, :controller => 'courses', :action => 'show', :user_request => true, :render_time => 0.01, :user_agent => 'None', :account_id => Account.default.id, :request_id => "req1", :interaction_seconds => 5 }, :without_protection => true) }
        pv3 = PageView.new { |p| p.assign_attributes({ :user => @user2, :url => "http://test.one/", :session_id => "phony", :context => @course, :controller => 'courses', :action => 'show', :user_request => true, :render_time => 0.01, :user_agent => 'None', :account_id => Account.default.id, :request_id => "req2", :interaction_seconds => 5 }, :without_protection => true) }
        pv2.created_at = store_time
        pv3.created_at = store_time_2
        pv2.store.should be_true
        pv3.store.should be_true

        Canvas.redis.smembers(bucket).sort.should == [@user1.global_id.to_s, @user2.global_id.to_s]
        Canvas.redis.smembers(PageView.user_count_bucket_for_time(store_time_2)).should == [@user2.global_id.to_s]
      end
    end
  end

  describe "for_users" do
    before :once do
      course_model
      @page_view = PageView.new { |p| p.assign_attributes({ :url => "http://test.one/", :session_id => "phony", :context => @course, :controller => 'courses', :action => 'show', :user_request => true, :render_time => 0.01, :user_agent => 'None', :account_id => Account.default.id, :request_id => "abcde", :interaction_seconds => 5, :user => @user }, :without_protection => true) }
      @page_view.save!
    end

    it "should work with User objects" do
      PageView.for_users([@user]).should == [@page_view]
      PageView.for_users([User.create!]).should == []
    end

    it "should work with a User ids" do
      PageView.for_users([@user.id]).should == [@page_view]
      PageView.for_users([@user.id + 1]).should == []
    end

    it "should with with an empty list" do
      PageView.for_users([]).should == []
    end
  end

  describe '.generate' do
    let(:params) { {:action => 'path', :controller => 'some'} }
    let(:session) { {:id => '42'} }
    let(:request) { stub(:url => (@url || 'host.com/some/path'), :path_parameters => params, :user_agent => 'Mozilla', :session_options => session, :method => :get, :remote_ip => '0.0.0.0', :request_method => 'GET') }
    let(:user) { User.new }
    let(:attributes) { {:real_user => user, :user => user } }

    before { RequestContextGenerator.stubs( :request_id => 'xyz' ) }
    after { RequestContextGenerator.unstub :request_id }

    subject { PageView.generate(request, attributes) }

    its(:url) { should == request.url }
    its(:user) { should == user }
    its(:controller) { should == params[:controller] }
    its(:action) { should == params[:action] }
    its(:session_id) { should == session[:id] }
    its(:real_user) { should == user }
    its(:user_agent) { should == request.user_agent }
    its(:interaction_seconds) { should == 5 }
    its(:created_at) { should_not be_nil }
    its(:updated_at) { should_not be_nil }
    its(:http_method) { should == 'get' }
    its(:remote_ip) { should == '0.0.0.0' }

    it "should filter sensitive url params" do
      @url = 'http://canvas.example.com/api/v1/courses/1?access_token=SUPERSECRET'
      pv = PageView.generate(request, attributes)
      pv.url.should ==  'http://canvas.example.com/api/v1/courses/1?access_token=[FILTERED]'
    end

    it "should filter sensitive url params on the way out" do
      pv = PageView.generate(request, attributes)
      pv.update_attribute(:url, 'http://canvas.example.com/api/v1/courses/1?access_token=SUPERSECRET')
      pv.reload
      pv.url.should ==  'http://canvas.example.com/api/v1/courses/1?access_token=[FILTERED]'
    end

    it "should force encoding on string fields" do
      request = stub(:url => (@url || 'host.com/some/path'), :path_parameters => params, :user_agent => 'Mozilla', :session_options => session, :method => :get, :remote_ip => '0.0.0.0'.encode(Encoding::US_ASCII), :request_method => 'GET')
      pv = PageView.generate(request,attributes)

      pv.remote_ip.encoding.should == Encoding::UTF_8
    end
  end

  describe ".find_all_by_id" do
    context "db-backed" do
      before :once do
        Setting.set('enable_page_views', 'db')
      end

      it "should return the existing page view" do
        page_views = (0..3).map { |index| page_view_model }
        page_view_ids = page_views.map { |page_view| page_view.request_id }

        PageView.find_all_by_id(page_view_ids).should == page_views
      end

      it "should return nothing with unknown request id" do
        PageView.find_all_by_id(['unknown', 'unknown']).size.should eql(0)
      end
    end

    context "cassandra-backed" do
      include_examples "cassandra page views"

      it "should return the existing page view" do
        page_views = (0..3).map { |index| page_view_model }
        page_view_ids = page_views.map { |page_view| page_view.request_id }

        PageView.find_all_by_id(page_view_ids).should == page_views
      end

      it "should return nothing with unknown request id" do
        PageView.find_all_by_id(['unknown', 'unknown']).size.should eql(0)
      end
    end
  end

  describe ".find_by_id" do
    context "db-backed" do
      before :once do
        Setting.set('enable_page_views', 'db')
      end

      it "should return the existing page view" do
        pv = page_view_model
        PageView.find_by_id(pv.request_id).should == pv
      end

      it "should return nothing with unknown request id" do
        PageView.find_by_id('unknown').should be_nil
      end
    end

    context "cassandra-backed" do
      include_examples "cassandra page views"

      it "should return the existing page view" do
        pv = page_view_model
        PageView.find_by_id(pv.request_id).should == pv
      end

      it "should return nothing with unknown request id" do
        PageView.find_by_id('unknown').should be_nil
      end
    end
  end

   describe ".find_one" do
    context "db-backed" do
      before :once do
        Setting.set('enable_page_views', 'db')
      end

      it "should return the existing page view" do
        pv = page_view_model
        PageView.find(pv.request_id).should == pv
      end

      it "should raise ActiveRecord::RecordNotFound with unknown request id" do
        expect { PageView.find('unknown') }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "cassandra-backed" do
      include_examples "cassandra page views"

      it "should return the existing page view" do
        pv = page_view_model
        PageView.find(pv.request_id).should == pv
      end

      it "should raise ActiveRecord::RecordNotFound with unknown request id" do
        expect { PageView.find('unknown') }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe ".find_for_update" do
    context "db-backed" do
      before :once do
        Setting.set('enable_page_views', 'db')
      end

      it "should return the existing page view" do
        pv = page_view_model
        PageView.find_for_update(pv.request_id).should == pv
      end

      it "should return nothing with unknown request id" do
        PageView.find_for_update('unknown').should be_nil
      end
    end

    context "cassandra-backed" do
      include_examples "cassandra page views"

      it "should return the existing page view" do
        pv = page_view_model
        PageView.find_for_update(pv.request_id).should == pv
      end
    end
  end

  describe ".from_attributes" do
    specs_require_sharding

    before do
      @attributes = valid_page_view_attributes.stringify_keys
    end

    it "should return a PageView object" do
      PageView.from_attributes(@attributes).should be_a(PageView)
    end

    it "should look like an existing PageView" do
      PageView.from_attributes(@attributes).should_not be_new_record
    end

    it "should use the provided attributes" do
      PageView.from_attributes(@attributes).url.should == @attributes['url']
    end

    it "should set missing attributes to nil" do
      PageView.from_attributes(@attributes).user_id.should be_nil
    end

    context "db-backed" do
      before do
        Setting.set('enable_page_views', 'db')
      end

      it "should interpret ids relative to the current shard" do
        user_id = 1
        attributes = @attributes.merge('user_id' => user_id)
        page_view1 = @shard1.activate{ PageView.from_attributes(attributes) }
        page_view2 = @shard2.activate{ PageView.from_attributes(attributes) }
        [@shard1, @shard2].each do |shard|
          shard.activate do
            page_view1.user_id.should == Shard.relative_id_for(user_id, @shard1, Shard.current)
            page_view2.user_id.should == Shard.relative_id_for(user_id, @shard2, Shard.current)
          end
        end
      end
    end

    context "cassandra-backed" do
      include_examples "cassandra page views"

      it "should interpret ids relative to the default shard" do
        user_id = 1
        attributes = @attributes.merge('user_id' => user_id)
        page_view1 = @shard1.activate{ PageView.from_attributes(attributes) }
        page_view2 = @shard2.activate{ PageView.from_attributes(attributes) }
        [@shard1, @shard2].each do |shard|
          shard.activate do
            page_view1.user_id.should == Shard.relative_id_for(user_id, Shard.default, Shard.current)
            page_view2.user_id.should == Shard.relative_id_for(user_id, Shard.default, Shard.current)
          end
        end
      end
    end
  end
end
