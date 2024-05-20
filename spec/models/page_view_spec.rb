# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../cassandra_spec_helper"

describe PageView do
  before do
    # sets both @user and @course (@user is a teacher in @course)
    course_model(account: Account.default.manually_created_courses_account)
    @page_view = PageView.new { |p| p.assign_attributes({ created_at: Time.now, url: "http://test.one/", session_id: "phony", context: @course, controller: "courses", action: "show", user_request: true, render_time: 0.01, user_agent: "None", account_id: Account.default.id, request_id: "abcde", interaction_seconds: 5, user: @user }) }
  end

  describe "sharding" do
    specs_require_sharding

    it "does not assign the default shard" do
      expect(PageView.new.shard).to eq Shard.default
      @shard1.activate do
        expect(PageView.new.shard).to eq @shard1
      end
    end
  end

  describe "token" do
    it "generates a valid jwt token" do
      token = @page_view.token
      data = Canvas::Security.decode_jwt(token)
      expect(data[:i]).to eq @page_view.request_id
      expect(data[:u]).to eq @user.global_id
      expect(data[:c]).to eq @page_view.created_at.utc.iso8601(2)
    end
  end

  describe "cassandra page views" do
    include_examples "cassandra page views"
    it "stores and load from cassandra" do
      expect do
        @page_view.request_id = "abcde1"
        @page_view.save!
      end.to change { PageView::EventStream.database.execute("select count(*) from page_views").fetch_row["count"] }.by(1)
      expect(PageView.find(@page_view.id)).to eq @page_view
      expect { PageView.find("junk") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not start a db transaction on save" do
      PageView.new { |p| p.assign_attributes({ user: @user, url: "http://test.one/", session_id: "phony", context: @course, controller: "courses", action: "show", user_request: true, render_time: 0.01, user_agent: "None", account_id: Account.default.id, request_id: "abcdef", interaction_seconds: 5 }) }.store
      expect(PageView.connection).not_to receive(:transaction)
      expect(PageView.find("abcdef")).to be_present
    end

    it "logs on error without blowing up" do
      expect { PageView::EventStream.on_error[0].call("write", { user: @user }, StandardError.new) }.to_not raise_error
    end

    describe "sharding" do
      specs_require_sharding

      it "always assigns the birth shard" do
        expect(PageView.new.shard).to eq Shard.birth
        pv = nil
        u = User.create!
        @shard1.activate do
          pv = page_view_model
          expect(pv.shard).to eq Shard.birth
          pv.user = u
          pv.save!
          expect(pv.read_attribute(:user_id)).to eq u.local_id
          pv = PageView.find(pv.request_id)
          expect(pv).to be_present
          expect(pv.shard).to eq Shard.birth
        end
        pv = PageView.find(pv.request_id)
        expect(pv).to be_present
        expect(pv.shard).to eq Shard.birth
        pv.interaction_seconds = 25
        pv.save!
        pv = PageView.find(pv.request_id)
        expect(pv.interaction_seconds).to eq 25
      end

      it "stores and load from cassandra when the birth shard is not the default shard" do
        allow(Shard).to receive(:birth).and_return(@shard1)
        @shard2.activate do
          expect do
            @page_view.request_id = "abcde2"
            @page_view.save!
          end.to change { PageView::EventStream.database.execute("select count(*) from page_views").fetch_row["count"] }.by(1)
          expect(PageView.find(@page_view.id)).to eq @page_view
          expect { PageView.find("junk") }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    it "paginates with a willpaginate-like array" do
      # some page views we shouldn't find
      page_view_model(user: user_model)
      page_view_model(user: user_model)

      user_model
      pvs = []
      4.times { |i| pvs << page_view_model(user: @user, created_at: (5 - i).weeks.ago) }
      pager = @user.page_views
      expect(pager).to be_a PaginatedCollection::Proxy
      expect { pager.paginate }.to raise_exception(ArgumentError)
      full = pager.paginate(per_page: 4)
      expect(full.size).to eq 4
      expect(full.next_page).to be_nil

      half = pager.paginate(per_page: 2)
      expect(half).to eq full[0, 2]
      expect(half.next_page).to be_present

      second_half = pager.paginate(per_page: 2, page: half.next_page)
      expect(second_half).to eq full[2, 2]
      expect(second_half.next_page).to be_nil
    end

    it "halts pagination after a set time period" do
      p1 = page_view_model(user: @user)
      page_view_model(user: @user, created_at: 13.months.ago)
      coll = @user.page_views.paginate(per_page: 3)
      expect(coll).to eq [p1]
      expect(coll.next_page).to be_blank
    end

    it "ignores an invalid page" do
      @page_view.save!
      expect(@user.page_views.paginate(per_page: 2, page: "3")).to eq [@page_view]
    end

    context "filtering" do
      it "restricts results to accounts that the viewer can see" do
        @page_view.save!
        user = @user
        viewer1 = User.create!
        viewer2 = account_admin_user
        viewer3 = account_admin_user(account: @course.account)
        expect(@course.account).not_to eq Account.default

        other_root = Account.create!
        user.pseudonyms.create!(account: other_root, unique_id: "bob")
        expect(user.associated_accounts).to include(other_root)
        viewer4 = account_admin_user(account: other_root)
        expect(user.grants_right?(viewer4, :view_statistics)).to be true

        expect(user.page_views(viewer: viewer1).paginate(per_page: 2)).to eq []
        expect(user.page_views(viewer: viewer2).paginate(per_page: 2)).to eq [@page_view]
        expect(user.page_views(viewer: viewer3).paginate(per_page: 2)).to eq [@page_view]
        expect(user.page_views(viewer: viewer4).paginate(per_page: 2)).to eq []
      end
    end

    describe "db migrator" do
      it "migrates the relevant page views" do
        a1 = account_model
        a2 = account_model
        a3 = account_model
        Setting.set("enable_page_views", "db")
        moved = (0..1).map { page_view_model(account: a1, created_at: 1.day.ago) }
        moved_a3 = page_view_model(account: a3, created_at: 4.hours.ago)
        # this one is more recent in time and will be processed last
        moved_later = page_view_model(account: a1, created_at: 2.hours.ago)
        # this one is in a deleted account
        deleted = page_view_model(account: a2, created_at: 2.hours.ago)
        a2.destroy
        # too far back
        old = page_view_model(account: a1, created_at: 13.months.ago)

        Setting.set("enable_page_views", "cassandra")
        migrator = PageView::CassandraMigrator.new
        expect(PageView.find_all_by_id(moved.map(&:request_id)).size).to eq 0
        migrator.run_once(2)
        expect(PageView.find_all_by_id(moved.map(&:request_id)).size).to eq 2
        # should migrate all active accounts
        expect(PageView.find(moved_a3.request_id).request_id).to eq moved_a3.request_id
        expect { PageView.find(moved_later.request_id) }.to raise_error(ActiveRecord::RecordNotFound)
        # it should resume where the last migrator left off
        migrator = PageView::CassandraMigrator.new
        # it could find the first two twice if we're on mysql, due to no sub-second precision,
        # so do a batch of 3
        migrator.run_once(3)
        expect(PageView.find(moved.map(&:request_id) + [moved_later.request_id]).size).to eq 3

        expect { PageView.find(deleted.request_id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect { PageView.find(old.request_id) }.to raise_error(ActiveRecord::RecordNotFound)

        # running again should migrate new page views as time advances
        Setting.set("enable_page_views", "db")
        # shouldn't actually happen, but create an older page view to verify
        # we're not migrating old page views again
        not_moved = page_view_model(account: a1, created_at: 1.day.ago)
        newly_moved = page_view_model(account: a1, created_at: 1.hour.ago)
        Setting.set("enable_page_views", "cassandra")
        migrator = PageView::CassandraMigrator.new
        migrator.run_once(2)
        expect { PageView.find(not_moved.request_id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect(PageView.find(newly_moved.request_id).request_id).to eq newly_moved.request_id
      end
    end
  end

  it "stores directly to the db in db mode" do
    Setting.set("enable_page_views", "db")
    expect(@page_view.store).to be_truthy
    expect(PageView.count).to eq 1
    expect(PageView.find(@page_view.id)).to eq @page_view
  end

  it "does not store if the page view has no user" do
    Setting.set("enable_page_views", "db")
    @page_view.user = nil
    expect(@page_view).not_to be_valid
  end

  if Canvas.redis_enabled?
    describe "active user counts" do
      before :once do
        Setting.set("enable_page_views", "db")
      end

      it "generates bucket names" do
        expect(PageView.user_count_bucket_for_time(Time.zone.parse("2012-01-20T13:41:17Z"))).to be_starts_with "active_users:2012-01-20T13:40:00Z"
        expect(PageView.user_count_bucket_for_time(Time.zone.parse("2012-01-20T03:25:00Z"))).to be_starts_with "active_users:2012-01-20T03:25:00Z"
        expect(PageView.user_count_bucket_for_time(Time.zone.parse("2012-01-20T03:29:59Z"))).to be_starts_with "active_users:2012-01-20T03:25:00Z"
      end

      it "does nothing if not enabled" do
        Setting.set("page_views_store_active_user_counts", "false")
        expect(@page_view.store).to be_truthy
        expect(Canvas.redis.smembers(PageView.user_count_bucket_for_time(Time.now))).to eq []
      end

      it "stores if enabled" do
        Setting.set("page_views_store_active_user_counts", "redis")
        expect(@page_view.store).to be_truthy
      end

      it "stores user ids in the set for page views" do
        Setting.set("page_views_store_active_user_counts", "redis")
        store_time = Time.zone.parse("2012-01-13T15:43:21Z")
        @page_view.created_at = store_time
        expect(@page_view.store).to be_truthy
        bucket = PageView.user_count_bucket_for_time(store_time)
        expect(Canvas.redis.smembers(bucket)).to eq [@user.global_id.to_s]
        expect(Canvas.redis.ttl(bucket)).to be > 23.hours.to_i

        store_time_2 = Time.zone.parse("2012-01-13T15:47:52Z")
        @user1 = @user
        @user2 = user_model
        pv2 = PageView.new { |p| p.assign_attributes({ user: @user2, url: "http://test.one/", session_id: "phony", context: @course, controller: "courses", action: "show", user_request: true, render_time: 0.01, user_agent: "None", account_id: Account.default.id, request_id: "req1", interaction_seconds: 5 }) }
        pv3 = PageView.new { |p| p.assign_attributes({ user: @user2, url: "http://test.one/", session_id: "phony", context: @course, controller: "courses", action: "show", user_request: true, render_time: 0.01, user_agent: "None", account_id: Account.default.id, request_id: "req2", interaction_seconds: 5 }) }
        pv2.created_at = store_time
        pv3.created_at = store_time_2
        expect(pv2.store).to be_truthy
        expect(pv3.store).to be_truthy

        expect(Canvas.redis.smembers(bucket).sort).to eq [@user1.global_id.to_s, @user2.global_id.to_s].sort
        expect(Canvas.redis.smembers(PageView.user_count_bucket_for_time(store_time_2))).to eq [@user2.global_id.to_s]
      end
    end
  end

  describe "for_users" do
    before :once do
      Setting.set("enable_page_views", "db")
      course_model
      @page_view = PageView.new { |p| p.assign_attributes({ url: "http://test.one/", session_id: "phony", context: @course, controller: "courses", action: "show", user_request: true, render_time: 0.01, user_agent: "None", account_id: Account.default.id, request_id: "abcde", interaction_seconds: 5, user: @user }) }
      @page_view.save!
    end

    it "works with User objects" do
      expect(PageView.for_users([@user])).to eq [@page_view]
      expect(PageView.for_users([User.create!])).to eq []
    end

    it "works with a User ids" do
      expect(PageView.for_users([@user.id])).to eq [@page_view]
      expect(PageView.for_users([@user.id + 1])).to eq []
    end

    it "withs with an empty list" do
      expect(PageView.for_users([])).to eq []
    end
  end

  describe ".generate" do
    subject { PageView.generate(request, attributes) }

    let(:params) { { action: "path", controller: "some" } }
    let(:session) { { id: "42" } }
    let(:request) { double(url: @url || "host.com/some/path", path_parameters: params, user_agent: "Mozilla", session_options: session, method: :get, remote_ip: "0.0.0.0", request_method: "GET") }
    let(:user) { User.new }
    let(:attributes) { { real_user: user, user: } }

    before { allow(RequestContextGenerator).to receive_messages(request_id: "xyz") }

    describe "#url" do
      subject { super().url }

      it { is_expected.to eq request.url }
    end

    describe "#user" do
      subject { super().user }

      it { is_expected.to eq user }
    end

    describe "#controller" do
      subject { super().controller }

      it { is_expected.to eq params[:controller] }
    end

    describe "#action" do
      subject { super().action }

      it { is_expected.to eq params[:action] }
    end

    describe "#session_id" do
      subject { super().session_id }

      it { is_expected.to eq session[:id] }
    end

    describe "#real_user" do
      subject { super().real_user }

      it { is_expected.to eq user }
    end

    describe "#user_agent" do
      subject { super().user_agent }

      it { is_expected.to eq request.user_agent }
    end

    describe "#interaction_seconds" do
      subject { super().interaction_seconds }

      it { is_expected.to eq 5 }
    end

    describe "#created_at" do
      subject { super().created_at }

      it { is_expected.not_to be_nil }
    end

    describe "#updated_at" do
      subject { super().updated_at }

      it { is_expected.not_to be_nil }
    end

    describe "#http_method" do
      subject { super().http_method }

      it { is_expected.to eq "get" }
    end

    describe "#remote_ip" do
      subject { super().remote_ip }

      it { is_expected.to eq "0.0.0.0" }
    end

    it "filters sensitive url params" do
      @url = "http://canvas.example.com/api/v1/courses/1?access_token=SUPERSECRET"
      pv = PageView.generate(request, attributes)
      expect(pv.url).to eq "http://canvas.example.com/api/v1/courses/1?access_token=[FILTERED]"
    end

    it "filters sensitive url params on the way out" do
      pv = PageView.generate(request, attributes)
      pv.update_attribute(:url, "http://canvas.example.com/api/v1/courses/1?access_token=SUPERSECRET")
      pv.reload
      expect(pv.url).to eq  "http://canvas.example.com/api/v1/courses/1?access_token=[FILTERED]"
    end

    it "forces encoding on string fields" do
      request = double(url: @url || "host.com/some/path", path_parameters: params, user_agent: "Mozilla", session_options: session, method: :get, remote_ip: "0.0.0.0".encode(Encoding::US_ASCII), request_method: "GET")
      pv = PageView.generate(request, attributes)

      expect(pv.remote_ip.encoding).to eq Encoding::UTF_8
    end
  end

  describe ".find_all_by_id" do
    context "db-backed" do
      before :once do
        Setting.set("enable_page_views", "db")
      end

      it "returns the existing page view" do
        page_views = Array.new(4) { page_view_model }
        page_view_ids = page_views.map(&:request_id)

        expect(PageView.find_all_by_id(page_view_ids)).to match_array page_views
      end

      it "returns nothing with unknown request id" do
        expect(PageView.find_all_by_id(["unknown", "unknown"]).size).to be(0)
      end
    end

    context "cassandra-backed" do
      include_examples "cassandra page views"

      it "returns the existing page view" do
        page_views = Array.new(4) { page_view_model }
        page_view_ids = page_views.map(&:request_id)

        expect(PageView.find_all_by_id(page_view_ids)).to match_array page_views
      end

      it "returns nothing with unknown request id" do
        expect(PageView.find_all_by_id(["unknown", "unknown"]).size).to be(0)
      end
    end
  end

  describe ".find_by" do
    context "db-backed" do
      before :once do
        Setting.set("enable_page_views", "db")
      end

      it "returns the existing page view" do
        pv = page_view_model
        expect(PageView.find_by(id: pv.request_id)).to eq pv
      end

      it "returns nothing with unknown request id" do
        expect(PageView.find_by(id: "unknown")).to be_nil
      end
    end

    context "cassandra-backed" do
      include_examples "cassandra page views"

      it "returns the existing page view" do
        pv = page_view_model
        expect(PageView.find_by(id: pv.request_id)).to eq pv
      end

      it "returns nothing with unknown request id" do
        expect(PageView.find_by(id: "unknown")).to be_nil
      end
    end
  end

  describe ".find_one" do
    context "db-backed" do
      before :once do
        Setting.set("enable_page_views", "db")
      end

      it "returns the existing page view" do
        pv = page_view_model
        expect(PageView.find(pv.request_id)).to eq pv
      end

      it "raises ActiveRecord::RecordNotFound with unknown request id" do
        expect { PageView.find("unknown") }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "cassandra-backed" do
      include_examples "cassandra page views"

      it "returns the existing page view" do
        pv = page_view_model
        expect(PageView.find(pv.request_id)).to eq pv
      end

      it "raises ActiveRecord::RecordNotFound with unknown request id" do
        expect { PageView.find("unknown") }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe ".find_for_update" do
    context "db-backed" do
      before :once do
        Setting.set("enable_page_views", "db")
      end

      it "returns the existing page view" do
        pv = page_view_model
        expect(PageView.find_for_update(pv.request_id)).to eq pv
      end

      it "returns nothing with unknown request id" do
        expect(PageView.find_for_update("unknown")).to be_nil
      end
    end

    context "cassandra-backed" do
      include_examples "cassandra page views"

      it "returns the existing page view" do
        pv = page_view_model
        expect(PageView.find_for_update(pv.request_id)).to eq pv
      end
    end
  end

  describe ".from_attributes" do
    specs_require_sharding

    before do
      @attributes = valid_page_view_attributes.stringify_keys
    end

    it "returns a PageView object" do
      expect(PageView.from_attributes(@attributes)).to be_a(PageView)
    end

    it "looks like an existing PageView" do
      expect(PageView.from_attributes(@attributes)).not_to be_new_record
    end

    it "uses the provided attributes" do
      expect(PageView.from_attributes(@attributes).url).to eq @attributes["url"]
    end

    it "sets missing attributes to nil" do
      expect(PageView.from_attributes(@attributes).user_id).to be_nil
    end

    context "db-backed" do
      before do
        Setting.set("enable_page_views", "db")
      end

      it "interprets ids relative to the current shard" do
        user_id = 1
        attributes = @attributes.merge("user_id" => user_id)
        page_view1 = @shard1.activate { PageView.from_attributes(attributes) }
        page_view2 = @shard2.activate { PageView.from_attributes(attributes) }
        [@shard1, @shard2].each do |shard|
          shard.activate do
            expect(page_view1.user_id).to eq Shard.relative_id_for(user_id, @shard1, Shard.current)
            expect(page_view2.user_id).to eq Shard.relative_id_for(user_id, @shard2, Shard.current)
          end
        end
      end
    end

    context "cassandra-backed" do
      include_examples "cassandra page views"

      it "interprets ids relative to the default shard" do
        user_id = 1
        attributes = @attributes.merge("user_id" => user_id)
        page_view1 = @shard1.activate { PageView.from_attributes(attributes) }
        page_view2 = @shard2.activate { PageView.from_attributes(attributes) }
        [@shard1, @shard2].each do |shard|
          shard.activate do
            expect(page_view1.user_id).to eq Shard.relative_id_for(user_id, Shard.default, Shard.current)
            expect(page_view2.user_id).to eq Shard.relative_id_for(user_id, Shard.default, Shard.current)
          end
        end
      end
    end
  end

  context "pv4" do
    before do
      allow(PageView).to receive_messages(pv4?: true, page_view_method: :pv4)
    end

    it "store doesn't do anything" do
      pv = PageView.new
      expect(pv).not_to receive(:save)
      expect(pv).to receive(:store_page_view_to_user_counts)
      pv.user = User.new
      pv.store
    end

    it "do_update still updates fields" do
      pv = PageView.new
      pv.do_update("interaction_seconds" => 5)
      expect(pv.is_update).to be true
      expect(pv.interaction_seconds).to eq 5
    end

    it "find_for_update returns a dummy record" do
      pv = PageView.find_for_update("someuuid")
      expect(pv).to_not be_nil
      expect(pv.id).to eq "someuuid"
    end
  end
end
