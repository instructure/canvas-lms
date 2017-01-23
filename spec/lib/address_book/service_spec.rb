require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper.rb')

describe AddressBook::Service do
  before do
    allow(Canvas::DynamicSettings).to receive(:from_cache).
      with("address-book", anything).
      and_return({'app-host' => 'http://test.host'})

    @sender = user_model
    @address_book = AddressBook::Service.new(@sender)
    @recipient = user_model(name: 'Bob 1')
  end

  def expand_user_ids(returns)
    returns.keys.sort_by(&:name).map(&:global_id)
  end

  def expand_common_contexts(returns)
    common_contexts = {}
    returns.each do |user,result|
      common_contexts[user.global_id] =
        case result
        when :student
          { courses: { 1 => ['StudentEnrollment'] }, groups: {} }
        when Course
          { courses: { result.global_id => ['StudentEnrollment'] }, groups: {} }
        when Group
          { courses: {}, groups: { result.global_id => ['Member'] } }
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

  def stub_common_contexts(args, returns={})
    returns = expand_common_contexts(returns)
    allow(Services::AddressBook).to receive(:common_contexts).with(*args).and_return(returns)
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

    describe "with optional :include_context" do
      def stub_roles_in_context(args, returns={})
        returns = expand_common_contexts(returns)
        allow(Services::AddressBook).to receive(:roles_in_context).with(*args).and_return(returns)
      end

      before do
        stub_common_contexts([@sender, [@recipient.global_id]])

        @course = course_model
        stub_roles_in_context(
          [@course, [@recipient.global_id]],
          { @recipient => @course }
        )

        @group = group_model
        stub_roles_in_context(
          [@group, [@recipient.global_id]],
          { @recipient => @group }
        )
      end

      it "skips course roles in unshared courses when absent" do
        expect(Services::AddressBook).to receive(:roles_in_context).never
        @address_book.known_users([@recipient])
        expect(@address_book.common_courses(@recipient)).not_to include(@course.id)
      end

      it "skips group memberships in unshared groups when absent" do
        expect(Services::AddressBook).to receive(:roles_in_context).never
        @address_book.known_users([@recipient])
        expect(@address_book.common_groups(@recipient)).not_to include(@group.id)
      end

      it "includes otherwise skipped course role in common courses when course specified" do
        @address_book.known_users([@recipient], include_context: @course)
        expect(@address_book.common_courses(@recipient)).to include(@course.id)
      end

      it "includes otherwise skipped groups memberships in common groups when group specified" do
        @address_book.known_users([@recipient], include_context: @group)
        expect(@address_book.common_groups(@recipient)).to include(@group.id)
      end

      it "no effect if no role in the course exists" do
        stub_roles_in_context([@course, [@recipient.global_id]])
        @address_book.known_users([@recipient], include_context: @course)
        expect(@address_book.common_courses(@recipient)).not_to include(@course.id)
      end

      it "no effect if no membership in the group exists" do
        stub_roles_in_context([@group, [@recipient.global_id]])
        @address_book.known_users([@recipient], include_context: @group)
        expect(@address_book.common_courses(@recipient)).not_to include(@group.id)
      end
    end

    describe "with optional :conversation_id" do
      before do
        stub_common_contexts([@sender, [@recipient.global_id]])
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

      it "finds cross-shard known users" do
        xshard_recipient = @shard2.activate{ user_model }
        stub_common_contexts(
          [@sender, [xshard_recipient.global_id]],
          { xshard_recipient => :student }
        )
        known_users = @address_book.known_users([xshard_recipient])
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
      expect(common_courses).to eql({ @course.id => ['StudentEnrollment'] })
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
      expect(common_groups).to eql({ @group.id => ['Member'] })
    end
  end

  describe "known_in_context" do
    def stub_known_in_context(args, compact_returns={})
      user_ids = expand_user_ids(compact_returns)
      common_contexts = expand_common_contexts(compact_returns)
      allow(Services::AddressBook).to receive(:known_in_context).with(*args).and_return([user_ids, common_contexts])
    end

    before do
      @course = course_model
      stub_known_in_context(
        [@sender, @course.global_asset_string, false],
        { @recipient => @course }
      )
    end

    it "limits to users in context" do
      other_recipient = user_model
      known_users = @address_book.known_in_context(@course.asset_string)
      expect(known_users.map(&:id)).to include(@recipient.id)
      expect(known_users.map(&:id)).not_to include(other_recipient.id)
    end

    it "passes :is_admin flag to service" do
      stub_known_in_context([@sender, @course.global_asset_string, false])
      stub_known_in_context(
        [@sender, @course.global_asset_string, true],
        { @recipient => @course }
      )

      known_users = @address_book.known_in_context(@course.asset_string)
      expect(known_users.map(&:id)).not_to include(@recipient.id)

      known_users = @address_book.known_in_context(@course.asset_string, true)
      expect(known_users.map(&:id)).to include(@recipient.id)
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
        @xshard_recipient = @shard2.activate{ user_model }
        @xshard_course = @shard2.activate{ course_model(account: Account.create) }

        stub_known_in_context(
          [@sender, @course.global_asset_string, false],
          { @xshard_recipient => @course }
        )

        stub_known_in_context(
          [@sender, @xshard_course.global_asset_string, false],
          { @xshard_recipient => @xshard_course }
        )
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

  describe "count_in_context" do
    before do
      @course = course_model
      allow(Services::AddressBook).to receive(:count_in_context).
        with(@sender, @course.global_asset_string).
        and_return(3)
    end

    it "returns count from service" do
      expect(@address_book.count_in_context(@course.asset_string)).to eql(3)
    end
  end

  describe "search_users" do
    def stub_search_users(args, compact_returns={})
      user_ids = expand_user_ids(compact_returns)
      common_contexts = expand_common_contexts(compact_returns)
      cursors = expand_cursors(compact_returns)
      returns = [user_ids, common_contexts, cursors]
      allow(Services::AddressBook).to receive(:search_users).with(*args).and_return(returns)
    end

    it "returns a paginatable collection" do
      stub_search_users(
        [@sender, { search: 'Bob' }, { per_page: 1 }],
        { @recipient => :student }
      )

      known_users = @address_book.search_users(search: 'Bob')
      expect(known_users).to respond_to(:paginate)
      expect(known_users.paginate(per_page: 1).size).to eq(1)
    end

    it "defers finding matching known users to service" do
      stub_search_users(
        [@sender, { search: 'Bob' }, { per_page: 10 }],
        { @recipient => :student }
      )

      known_users = @address_book.search_users(search: 'Bob')
      page = known_users.paginate(per_page: 10)
      expect(page.map(&:id)).to include(@recipient.id)
    end

    it "passes optional :exclude_ids parameter to service" do
      other_recipient = user_model
      stub_search_users(
        [@sender, { search: 'Bob', exclude_ids: [@recipient.global_id] }, { per_page: 10 }],
        { other_recipient => :student }
      )

      known_users = @address_book.search_users(search: 'Bob', exclude_ids: [@recipient.global_id])
      page = known_users.paginate(per_page: 10)
      expect(page.map(&:id)).not_to include(@recipient.id)
      expect(page.map(&:id)).to include(other_recipient.id)
    end

    it "passes optional :context parameter to service" do
      course = course_model
      stub_search_users(
        [@sender, { search: 'Bob', context: course.global_asset_string }, { per_page: 10 }],
        { @recipient => :student }
      )

      known_users = @address_book.search_users(search: 'Bob', context: course.global_asset_string)
      page = known_users.paginate(per_page: 10)
      expect(page.map(&:id)).to include(@recipient.id)
    end

    it "passes optional :is_admin parameter with :context to service" do
      course = course_model
      stub_search_users(
        [@sender, { search: 'Bob', context: course.global_asset_string, is_admin: true }, { per_page: 10 }],
        { @recipient => :student }
      )

      known_users = @address_book.search_users(search: 'Bob', context: course.global_asset_string, is_admin: true)
      page = known_users.paginate(per_page: 10)
      expect(page.map(&:id)).to include(@recipient.id)
    end

    it "passes optional :weak_checks parameter to service" do
      stub_search_users(
        [@sender, { search: 'Bob', weak_checks: true }, { per_page: 10 }],
        { @recipient => :student }
      )

      known_users = @address_book.search_users(search: 'Bob', weak_checks: true)
      page = known_users.paginate(per_page: 10)
      expect(page.map(&:id)).to include(@recipient.id)
    end

    it "passes the pager's bookmark as cursor to service" do
      cursor = 5
      stub_search_users(
        [@sender, { search: 'Bob' }, { per_page: 10, cursor: cursor }],
        { @recipient => :student }
      )

      known_users = @address_book.search_users(search: 'Bob')
      bookmark = "bookmark:#{::JSONToken.encode(cursor)}"
      page = known_users.paginate(per_page: 10, page: bookmark)
      expect(page.map(&:id)).to include(@recipient.id)
    end

    it "returns a page that can give a bookmark per contained user" do
      other_recipient = user_model(name: 'Bob 2')
      stub_search_users(
        [@sender, { search: 'Bob' }, { per_page: 10 }],
        { @recipient => :student, other_recipient => :student }
      )

      known_users = @address_book.search_users(search: 'Bob')
      page = known_users.paginate(per_page: 10)
      expect(page.bookmark_for(@recipient)).to eq(0)
      expect(page.bookmark_for(other_recipient)).to eq(1)
    end

    it "uses the last user's bookmark for next page if non-nil" do
      other_recipient = user_model(name: 'Bob 2')
      stub_search_users(
        [@sender, { search: 'Bob' }, { per_page: 1 }],
        { @recipient => :student, other_recipient => :student }
      )

      known_users = @address_book.search_users(search: 'Bob')
      page = known_users.paginate(per_page: 1)
      expected_cursor = page.bookmark_for(other_recipient)
      expected_bookmark = "bookmark:#{::JSONToken.encode(expected_cursor)}"
      expect(page.next_page).to eq(expected_bookmark)
    end

    it "returns a terminal page if the last user's bookmark is nil" do
      other_recipient1 = user_model(name: 'Bob 2')
      other_recipient2 = user_model(name: 'Bob 3')
      stub_search_users(
        [@sender, { search: 'Bob' }, { per_page: 10 }],
        { @recipient => :student, other_recipient1 => :student, other_recipient2 => :student }
      )

      known_users = @address_book.search_users(search: 'Bob')
      page = known_users.paginate(per_page: 10)
      expect(page.next_page).to be_nil
    end

    it "caches the results for known users when a page is materialized" do
      stub_search_users(
        [@sender, { search: 'Bob' }, { per_page: 10 }],
        { @recipient => :student }
      )

      collection = @address_book.search_users(search: 'Bob')
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
