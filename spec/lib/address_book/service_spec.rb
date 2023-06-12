# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe AddressBook::Service do
  before do
    allow(DynamicSettings).to receive(:find).with(any_args).and_call_original
    allow(DynamicSettings).to receive(:find)
      .with("address-book", anything)
      .and_return({ "app-host" => "http://test.host" })

    @sender = user_model
    @address_book = AddressBook::Service.new(@sender)
    @recipient = user_model(name: "Bob 1")
  end

  def expand_user_ids(returns)
    returns.keys.sort_by(&:name).map(&:global_id)
  end

  def expand_common_contexts(returns)
    common_contexts = {}
    returns.each do |user, result|
      common_contexts[user.global_id] =
        case result
        when :student
          { courses: { 1 => ["StudentEnrollment"] }, groups: {} }
        when Course
          { courses: { result.global_id => ["StudentEnrollment"] }, groups: {} }
        when Group
          { courses: {}, groups: { result.global_id => ["Member"] } }
        else
          result
        end
    end
    common_contexts
  end

  def expand_cursors(returns)
    returns = returns.size.times.to_a
    if returns.size >= 3 # terminal page
      returns[-1] = nil
    end
    returns
  end

  def stub_common_contexts(args, returns = {})
    args << false # ignore_result
    returns = expand_common_contexts(returns)
    allow(Services::AddressBook).to receive(:common_contexts).with(*args).and_return(returns)
  end

  def stub_known_in_context(args, compact_returns = {})
    args << nil if args.length < 3 # user_ids
    args << false if args.length < 4 # ignore_result
    user_ids = expand_user_ids(compact_returns)
    common_contexts = expand_common_contexts(compact_returns)
    allow(Services::AddressBook).to receive(:known_in_context).with(*args).and_return([user_ids, common_contexts])
  end

  describe "known_users" do
    it "includes only known users" do
      other_recipient = user_model
      stub_common_contexts(
        [@sender, [@recipient.global_id, other_recipient.global_id]],
        { @recipient => :student }
      )

      known_users = @address_book.known_users([@recipient, other_recipient])
      expect(known_users).to include(@recipient)
      expect(known_users).not_to include(other_recipient)
    end

    it "caches the results for known users" do
      stub_common_contexts(
        [@sender, [@recipient.global_id]],
        { @recipient => :student }
      )

      expect(@address_book.known_users([@recipient])).to be_present
      expect(@address_book.cached?(@recipient)).to be_truthy
    end

    it "caches the failure for unknown users" do
      stub_common_contexts([@sender, [@recipient.global_id]])
      expect(@address_book.known_users([@recipient])).to be_empty
      expect(@address_book.cached?(@recipient)).to be_truthy
    end

    it "doesn't refetch already cached users" do
      other_recipient = user_model
      stub_common_contexts(
        [@sender, [@recipient.global_id]],
        { @recipient => :student }
      )
      stub_common_contexts(
        [@sender, [other_recipient.global_id]],
        { other_recipient => :student }
      )

      @address_book.known_users([@recipient])
      known_users = @address_book.known_users([@recipient, other_recipient])
      expect(known_users).to include(@recipient)
      expect(known_users).to include(other_recipient)
    end

    describe "with optional :context" do
      def stub_roles_in_context(args, returns = {})
        args << false # ignore_result
        returns = expand_common_contexts(returns)
        allow(Services::AddressBook).to receive(:roles_in_context).with(*args).and_return(returns)
      end

      before do
        # recipient participates in three courses, (visible without a sender)
        @course1 = course_model
        @course2 = course_model
        @course3 = course_model
        stub_roles_in_context([@course1, [@recipient.global_id]], { @recipient => @course1 })
        stub_roles_in_context([@course2, [@recipient.global_id]], { @recipient => @course2 })
        stub_roles_in_context([@course3, [@recipient.global_id]], { @recipient => @course3 })

        # but only two are shared with sender (visible with the sender)
        stub_known_in_context([@sender, @course1, [@recipient.global_id]], { @recipient => @course1 })
        stub_known_in_context([@sender, @course2, [@recipient.global_id]], { @recipient => @course2 })
        stub_known_in_context([@sender, @course3, [@recipient.global_id]], {})
        stub_common_contexts([@sender, [@recipient.global_id]], { @recipient => {
                               courses: {
                                 @course1.global_id => ["StudentEnrollment"],
                                 @course2.global_id => ["StudentEnrollment"]
                               },
                               groups: {}
                             } })
      end

      it "includes all known contexts when absent" do
        expect(@address_book.known_users([@recipient])).to include(@recipient)
        expect(@address_book.common_courses(@recipient)).to include(@course1.id)
        expect(@address_book.common_courses(@recipient)).to include(@course2.id)
      end

      it "excludes unknown contexts when absent, even if admin" do
        account_admin_user(user: @sender, account: @course3.account)
        expect(@address_book.known_users([@recipient])).to include(@recipient)
        expect(@address_book.common_courses(@recipient)).not_to include(@course3.id)
      end

      it "excludes other known contexts when specified" do
        expect(@address_book.known_users([@recipient], context: @course1)).to include(@recipient)
        expect(@address_book.common_courses(@recipient)).to include(@course1.id)
        expect(@address_book.common_courses(@recipient)).not_to include(@course2.id)
      end

      it "excludes specified unknown context when sender is non-admin" do
        expect(@address_book.known_users([@recipient], context: @course3)).not_to include(@recipient)
        expect(@address_book.common_courses(@recipient)).not_to include(@course3.id)
      end

      it "excludes specified unknown course when sender is a participant admin" do
        # i.e. the sender does partipate in the course, at a level that
        # nominally gives them read_as_admin (e.g. teacher, usually), but still
        # doesn't know of recipient's participation, likely because of section
        # limited enrollment.
        section = @course3.course_sections.create!
        teacher_in_course(user: @sender, course: @course3, active_all: true, section:, limit_privileges_to_course_section: true)
        expect(@address_book.known_users([@recipient], context: @course3)).not_to include(@recipient)
        expect(@address_book.common_courses(@recipient)).not_to include(@course3.id)
      end

      it "includes specified unknown context when sender is non-participant admin" do
        account_admin_user(user: @sender, account: @course3.account)
        expect(@address_book.known_users([@recipient], context: @course3)).to include(@recipient)
        expect(@address_book.common_courses(@recipient)).to include(@course3.id)
      end
    end

    describe "with optional :conversation_id" do
      before do
        stub_common_contexts([@sender, [@recipient.global_id]])
      end

      it "conversation_id can be passed blank" do
        expect { @address_book.known_users([@recipient], conversation_id: "") }.not_to raise_error
      end

      it "conversation_id can be passed with garbage" do
        expect { @address_book.known_users([@recipient], conversation_id: "garbage") }.not_to raise_error
      end

      it "treats unknown users in that conversation as known" do
        conversation = Conversation.initiate([@sender, @recipient], true)
        known_users = @address_book.known_users([@recipient], conversation_id: conversation.id)
        expect(known_users).to include(@recipient)
      end

      it "ignores if sender is not a participant in the conversation" do
        other_recipient = user_model
        conversation = Conversation.initiate([@recipient, other_recipient], true)
        known_users = @address_book.known_users([@recipient], conversation_id: conversation.id)
        expect(known_users).not_to include(@recipient)
      end
    end

    describe "sharding" do
      specs_require_sharding

      let(:xshard_recipient) { @shard2.activate { user_model } }

      before do
        stub_common_contexts(
          [@sender, [xshard_recipient.global_id]],
          { xshard_recipient => :student }
        )
      end

      it "finds cross-shard known users" do
        known_users = @address_book.known_users([xshard_recipient])
        expect(known_users).to include(xshard_recipient)
      end

      it "works when given local ids" do
        known_users = @shard2.activate { @address_book.known_users([xshard_recipient.id]) }
        expect(known_users).to include(xshard_recipient)
      end
    end
  end

  describe "known_user" do
    it "returns the user if known" do
      stub_common_contexts(
        [@sender, [@recipient.global_id]],
        { @recipient => :student }
      )
      known_user = @address_book.known_user(@recipient)
      expect(known_user).not_to be_nil
    end

    it "returns nil if not known" do
      stub_common_contexts([@sender, [@recipient.global_id]])
      known_user = @address_book.known_user(@recipient)
      expect(known_user).to be_nil
    end
  end

  describe "common_courses" do
    before do
      @course = course_model
      stub_common_contexts(
        [@sender, [@recipient.global_id]],
        { @recipient => @course }
      )
    end

    it "pulls the corresponding user's common_courses" do
      common_courses = @address_book.common_courses(@recipient)
      expect(common_courses).to eql({ @course.id => ["StudentEnrollment"] })
    end
  end

  describe "common_groups" do
    before do
      @group = group_model
      stub_common_contexts(
        [@sender, [@recipient.global_id]],
        { @recipient => @group }
      )
    end

    it "pulls the corresponding user's common_groups" do
      common_groups = @address_book.common_groups(@recipient)
      expect(common_groups).to eql({ @group.id => ["Member"] })
    end
  end

  describe "known_in_context" do
    before do
      @course = course_model
      stub_known_in_context([@sender, @course.global_asset_string], { @recipient => @course })
    end

    it "limits to users in context" do
      other_recipient = user_model
      known_users = @address_book.known_in_context(@course.asset_string)
      expect(known_users.map(&:id)).to include(@recipient.id)
      expect(known_users.map(&:id)).not_to include(other_recipient.id)
    end

    it "caches the results for known users" do
      @address_book.known_in_context(@course.asset_string)
      expect(@address_book.cached?(@recipient)).to be_truthy
    end

    it "does not cache unknown users" do
      other_recipient = user_model
      @address_book.known_in_context(@course.asset_string)
      expect(@address_book.cached?(other_recipient)).to be_falsey
    end

    describe "sharding" do
      specs_require_sharding

      before do
        @xshard_recipient = @shard2.activate { user_model }
        @xshard_course = @shard2.activate { course_model(account: Account.create) }
        stub_known_in_context([@sender, @course.global_asset_string], { @xshard_recipient => @course })
        stub_known_in_context([@sender, @xshard_course.global_asset_string], { @xshard_recipient => @xshard_course })
      end

      it "works for cross-shard courses" do
        known_users = @address_book.known_in_context(@xshard_course.asset_string)
        expect(known_users.map(&:id)).to include(@xshard_recipient.id)
      end

      it "finds known cross-shard users in course" do
        known_users = @address_book.known_in_context(@course.asset_string)
        expect(known_users.map(&:id)).to include(@xshard_recipient.id)
      end
    end
  end

  describe "search_users" do
    def stub_search_users(args, compact_returns = {})
      args << false # ignore_result
      user_ids = expand_user_ids(compact_returns)
      common_contexts = expand_common_contexts(compact_returns)
      cursors = expand_cursors(compact_returns)
      returns = [user_ids, common_contexts, cursors]
      allow(Services::AddressBook).to receive(:search_users).with(*args).and_return(returns)
    end

    it "returns a paginatable collection" do
      stub_search_users(
        [@sender, { search: "Bob" }, { per_page: 1 }],
        { @recipient => :student }
      )

      known_users = @address_book.search_users(search: "Bob")
      expect(known_users).to respond_to(:paginate)
      expect(known_users.paginate(per_page: 1).size).to eq(1)
    end

    it "defers finding matching known users to service" do
      stub_search_users(
        [@sender, { search: "Bob" }, { per_page: 10 }],
        { @recipient => :student }
      )

      known_users = @address_book.search_users(search: "Bob")
      page = known_users.paginate(per_page: 10)
      expect(page.map(&:id)).to include(@recipient.id)
    end

    it "passes optional :exclude_ids parameter to service" do
      other_recipient = user_model
      stub_search_users(
        [@sender, { search: "Bob", exclude_ids: [@recipient.global_id] }, { per_page: 10 }],
        { other_recipient => :student }
      )

      known_users = @address_book.search_users(search: "Bob", exclude_ids: [@recipient.global_id])
      page = known_users.paginate(per_page: 10)
      expect(page.map(&:id)).not_to include(@recipient.id)
      expect(page.map(&:id)).to include(other_recipient.id)
    end

    it "passes optional :context parameter to service" do
      course = course_model
      stub_search_users(
        [@sender, { search: "Bob", context: course.global_asset_string }, { per_page: 10 }],
        { @recipient => :student }
      )

      known_users = @address_book.search_users(search: "Bob", context: course.global_asset_string)
      page = known_users.paginate(per_page: 10)
      expect(page.map(&:id)).to include(@recipient.id)
    end

    it "omits sender in service call if sender is a non-participating admin over :context" do
      course = course_model
      account_admin_user(user: @sender, account: course.account)
      stub_search_users(
        [nil, { search: "Bob", context: course.global_asset_string }, { per_page: 10 }],
        { @recipient => :student }
      )

      known_users = @address_book.search_users(search: "Bob", context: course.global_asset_string)
      page = known_users.paginate(per_page: 10)
      expect(page.map(&:id)).to include(@recipient.id)
    end

    it "retains sender in service call if sender is a participating admin over :context" do
      course = course_model
      teacher_in_course(user: @sender, course:, active_all: true)
      stub_search_users(
        [@sender, { search: "Bob", context: course.global_asset_string }, { per_page: 10 }],
        { @recipient => :student }
      )

      known_users = @address_book.search_users(search: "Bob", context: course.global_asset_string)
      page = known_users.paginate(per_page: 10)
      expect(page.map(&:id)).to include(@recipient.id)
    end

    it "passes optional :weak_checks parameter to service" do
      stub_search_users(
        [@sender, { search: "Bob", weak_checks: true }, { per_page: 10 }],
        { @recipient => :student }
      )

      known_users = @address_book.search_users(search: "Bob", weak_checks: true)
      page = known_users.paginate(per_page: 10)
      expect(page.map(&:id)).to include(@recipient.id)
    end

    it "passes the pager's bookmark as cursor to service" do
      cursor = 5
      stub_search_users(
        [@sender, { search: "Bob" }, { per_page: 10, cursor: }],
        { @recipient => :student }
      )

      known_users = @address_book.search_users(search: "Bob")
      bookmark = "bookmark:#{JSONToken.encode(cursor)}"
      page = known_users.paginate(per_page: 10, page: bookmark)
      expect(page.map(&:id)).to include(@recipient.id)
    end

    it "returns a page that can give a bookmark per contained user" do
      other_recipient = user_model(name: "Bob 2")
      stub_search_users(
        [@sender, { search: "Bob" }, { per_page: 10 }],
        { @recipient => :student, other_recipient => :student }
      )

      known_users = @address_book.search_users(search: "Bob")
      page = known_users.paginate(per_page: 10)
      expect(page.bookmark_for(@recipient)).to eq(0)
      expect(page.bookmark_for(other_recipient)).to eq(1)
    end

    it "uses the last user's bookmark for next page if non-nil" do
      other_recipient = user_model(name: "Bob 2")
      stub_search_users(
        [@sender, { search: "Bob" }, { per_page: 1 }],
        { @recipient => :student, other_recipient => :student }
      )

      known_users = @address_book.search_users(search: "Bob")
      page = known_users.paginate(per_page: 1)
      expected_cursor = page.bookmark_for(other_recipient)
      expected_bookmark = "bookmark:#{JSONToken.encode(expected_cursor)}"
      expect(page.next_page).to eq(expected_bookmark)
    end

    it "returns a terminal page if the last user's bookmark is nil" do
      other_recipient1 = user_model(name: "Bob 2")
      other_recipient2 = user_model(name: "Bob 3")
      stub_search_users(
        [@sender, { search: "Bob" }, { per_page: 10 }],
        { @recipient => :student, other_recipient1 => :student, other_recipient2 => :student }
      )

      known_users = @address_book.search_users(search: "Bob")
      page = known_users.paginate(per_page: 10)
      expect(page.next_page).to be_nil
    end

    it "caches the results for known users when a page is materialized" do
      stub_search_users(
        [@sender, { search: "Bob" }, { per_page: 10 }],
        { @recipient => :student }
      )

      collection = @address_book.search_users(search: "Bob")
      expect(@address_book.cached?(@recipient)).to be_falsey
      collection.paginate(per_page: 10)
      expect(@address_book.cached?(@recipient)).to be_truthy
    end
  end

  describe "preload_users" do
    it "caches provided users" do
      stub_common_contexts(
        [@sender, [@recipient.global_id]],
        { @recipient => :student }
      )

      @address_book.preload_users([@recipient])
      expect(@address_book.cached?(@recipient)).to be_truthy
    end

    it "including results with no common_contexts (made known by virtue of preload)" do
      stub_common_contexts([@sender, [@recipient.global_id]])
      @address_book.preload_users([@recipient])
      expect(@address_book.cached?(@recipient)).to be_truthy
      expect(@address_book.known_user(@recipient)).not_to be_nil
      expect(@address_book.common_courses(@recipient)).to be_empty
      expect(@address_book.common_groups(@recipient)).to be_empty
    end
  end
end
