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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe ConversationsController do
  def conversation(opts = {})
    num_other_users = opts[:num_other_users] || 1
    course = opts[:course] || @course
    user_data = num_other_users.times.map{ {name: "User"} }
    users = create_users_in_course(course, user_data, account_associations: true, return_type: :record)
    @conversation = @user.initiate_conversation(users)
    @conversation.add_message(opts[:message] || 'test')
    @conversation.conversation.update_attribute(:context, course)
    @conversation
  end

  describe "GET 'index'" do
    before :once do
      course_with_student(:active_all => true)
    end

    it "should require login" do
      get 'index'
      assert_require_login
    end

    it "should assign variables" do
      user_session(@student)
      conversation

      term = @course.root_account.enrollment_terms.create! :name => "Fall"
      @course.update_attributes! :enrollment_term => term

      get 'index'
      expect(response).to be_success
      expect(assigns[:js_env]).not_to be_nil
    end

    it "should assign variables for json" do
      user_session(@student)
      conversation

      get 'index', :format => 'json'
      expect(response).to be_success
      expect(assigns[:js_env]).to be_nil
      expect(assigns[:conversations_json].map{|c|c[:id]}).to eq @user.conversations.map(&:conversation_id)
    end

    it "should work for an admin as well" do
      account_admin_user
      user_session(@user)
      conversation

      get 'index', :format => 'json'
      expect(response).to be_success
      expect(assigns[:conversations_json].map{|c|c[:id]}).to eq @user.conversations.map(&:conversation_id)
    end

    it "should return all sent conversations" do
      user_session(@student)
      @c1 = conversation
      @c2 = conversation
      @c3 = conversation
      @c3.update_attribute :workflow_state, 'archived'

      get 'index', :scope => 'sent', :format => 'json'
      expect(response).to be_success
      expect(assigns[:conversations_json].size).to eql 3
    end

    it "should return conversations matching the specified filter" do
      user_session(@student)
      @c1 = conversation
      @other_course = course(:active_all => true)
      enrollment = @other_course.enroll_student(@user)
      enrollment.workflow_state = 'active'
      enrollment.save!
      @user.reload
      @c2 = conversation(:num_other_users => 1, :course => @other_course)

      get 'index', :filter => @other_course.asset_string, :format => 'json'
      expect(response).to be_success
      expect(assigns[:conversations_json].size).to eql 1
      expect(assigns[:conversations_json][0][:id]).to eq @c2.conversation_id
    end

    it "should use the boolean operation in filter_mode when combining multiple filters" do
      user_session(@student)
      @course1 = @course
      @c1 = conversation(:course => @course1)
      @course2 = course(:active_all => true)
      enrollment = @course2.enroll_student(@user)
      enrollment.workflow_state = 'active'
      enrollment.save!
      @c2 = conversation(:course => @course2)
      @c3 = conversation(:course => @course2)

      get 'index', :filter => [@course1.asset_string, @course2.asset_string], :filter_mode => 'or', :format => 'json'
      expect(response).to be_success
      expect(assigns[:conversations_json].map{|c| c[:id]}.sort).to eql [@c1, @c2, @c3].map(&:conversation_id).sort

      get 'index', :filter => [@course2.asset_string, @user.asset_string], :filter_mode => 'or', :format => 'json'
      expect(response).to be_success
      expect(assigns[:conversations_json].map{|c| c[:id]}.sort).to eql [@c1, @c2, @c3].map(&:conversation_id).sort

      get 'index', :filter => [@course2.asset_string, @user.asset_string], :filter_mode => 'and', :format => 'json'
      expect(response).to be_success
      expect(assigns[:conversations_json].map{|c| c[:id]}.sort).to eql [@c2, @c3].map(&:conversation_id).sort

      get 'index', :filter => [@course1.asset_string, @course2.asset_string], :filter_mode => 'and', :format => 'json'
      expect(response).to be_success
      expect(assigns[:conversations_json]).to eql []
    end

    it "should return conversations matching a user filter" do
      user_session(@student)
      @c1 = conversation
      @other_course = course(:active_all => true)
      enrollment = @other_course.enroll_student(@user)
      enrollment.workflow_state = 'active'
      enrollment.save!
      @user.reload
      @c2 = conversation(:num_other_users => 1, :course => @other_course)

      get 'index', :filter => @user.asset_string, :format => 'json', :include_all_conversation_ids => 1
      expect(response).to be_success
      expect(assigns[:conversations_json].size).to eql 2
    end

    it "should not allow student view student to load inbox" do
      course_with_teacher_logged_in(:active_all => true)
      @fake_student = @course.student_view_student
      session[:become_user_id] = @fake_student.id

      get 'index'
      assert_unauthorized
    end

    context "masquerading" do
      before :once do
        a = Account.default
        @student = user_with_pseudonym(:active_all => true)
        course_with_student(:active_all => true, :account => a, :user => @student)
        @student.initiate_conversation([user]).add_message('test1', :root_account_id => a.id)
        @student.initiate_conversation([user]).add_message('test2') # no root account, so teacher can't see it

        course_with_teacher(:active_all => true, :account => a)
        a.account_users.create!(user: @user)
      end

      before :each do
        user_session(@teacher)
        session[:become_user_id] = @student.id
      end

      it "should filter conversations" do
        get 'index', :format => 'json'
        expect(response).to be_success
        expect(assigns[:conversations_json].size).to eql 1
      end

      it "should filter conversations when returning ids" do
        get 'index', :format => 'json', :include_all_conversation_ids => true
        expect(response).to be_success
        expect(assigns[:conversations_json][:conversations].size).to eql 1
        expect(assigns[:conversations_json][:conversation_ids].size).to eql 1
      end

      it "should recompute inbox count" do
        # In an effort to make the data fix easy to do and self-healing,
        # recompute the unread inbox count when the page is loaded.
        course_with_student_logged_in(:active_all => true)
        @user.update_attribute(:unread_conversations_count, -20) # create invalid starting value
        @c1 = conversation

        get 'index'
        expect(response).to be_success
        @user.reload
        expect(@user.unread_conversations_count).to eq 0
      end
    end
  end

  describe "GET 'show'" do
    before :once do
      course_with_student(:active_all => true)
    end

    before :each do
      user_session(@student)
      conversation
    end

    it "should redirect if not xhr" do
      get 'show', :id => @conversation.conversation_id
      expect(response).to be_redirect
    end

    it "should assign variables" do
      xhr :get, 'show', :id => @conversation.conversation_id
      expect(response).to be_success
      expect(assigns[:conversation]).to eq @conversation
    end
  end

  describe "POST 'create'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it "should create the conversation" do
      user_session(@student)

      new_user = User.create
      enrollment = @course.enroll_student(new_user)
      enrollment.workflow_state = 'active'
      enrollment.save
      post 'create', :recipients => [new_user.id.to_s], :body => "yo"
      expect(response).to be_success
      expect(assigns[:conversation]).not_to be_nil
    end

    it "should require permissions for sending to other students" do
      user_session(@student)

      new_user = User.create
      enrollment = @course.enroll_student(new_user)
      enrollment.workflow_state = 'active'
      enrollment.save
      @course.account.role_overrides.create!(:permission => :send_messages, :role => student_role, :enabled => false)

      post 'create', :recipients => [new_user.id.to_s], :body => "yo", :context_code => @course.asset_string
      expect(response).to_not be_success
    end

    it "should allow sending to instructors even if permissions are disabled" do
      user_session(@student)
      @course.account.role_overrides.create!(:permission => :send_messages, :role => student_role, :enabled => false)

      post 'create', :recipients => [@teacher.id.to_s], :body => "yo", :context_code => @course.asset_string
      expect(response).to be_success
      expect(assigns[:conversation]).not_to be_nil
    end

    it "should not add the wrong tags in a certain terrible cached edge case" do
      # tl;dr - not including the updated_at when we instantiate the users
      # can cause us to grab stale conversation_context_codes
      # which screws everything up
      enable_cache do
        course1 = course(:active_all => true)

        student1 = user(:active_user => true)
        student2 = user(:active_user => true)

        Timecop.freeze(5.seconds.ago) do
          course1.enroll_user(student1, "StudentEnrollment").accept!
          course1.enroll_user(student2, "StudentEnrollment").accept!

          user_session(student1)
          post 'create', :recipients => [student2.id.to_s], :body => "yo", :message => "you suck", :group_conversation => true,
               :course => course1.asset_string, :context_code => course1.asset_string
          expect(response).to be_success
        end

        course2 = course(:active_all => true)
        course2.enroll_user(student2, "StudentEnrollment").accept!
        course2.enroll_user(student1, "StudentEnrollment").accept!
        user_session(User.find(student1.id)) # clear process local enrollment cache

        # with the address book, there's another level of caching to bust. in
        # non-test usage, this cache only lasts for the duration of the
        # request, so it's not an issue
        RequestStore.clear!

        post 'create', :recipients => [student2.id.to_s], :body => "yo again", :message => "you still suck", :group_conversation => true,
             :course => course2.asset_string, :context_code => course2.asset_string
        expect(response).to be_success

        c = Conversation.where(:context_type => "Course", :context_id => course2).first
        c.conversation_participants.each do |cp|
          expect(cp.tags).to eq [course2.asset_string]
        end
      end
    end

    it "should allow messages to be forwarded from the conversation" do
      user_session(@student)
      conversation.update_attribute(:workflow_state, "unread")

      new_user = User.create
      enrollment = @course.enroll_student(new_user)
      enrollment.workflow_state = 'active'
      enrollment.save
      post 'create', :recipients => [new_user.id.to_s], :body => "here's the info", :forwarded_message_ids => @conversation.messages.map(&:id)
      expect(response).to be_success
      expect(assigns[:conversation]).not_to be_nil
      expect(assigns[:conversation].messages.first.forwarded_message_ids).to eql(@conversation.messages.first.id.to_s)
    end

    context "group conversations" do
      before :once do
        @old_count = Conversation.count

        @new_user1 = User.create
        @course.enroll_student(@new_user1).accept!

        @new_user2 = User.create
        @course.enroll_student(@new_user2).accept!

        @account_id = @course.account_id
      end

      before :each do
        user_session(@teacher)
      end

      ["1", "true", "yes", "on"].each do |truish|
        it "should create a conversation shared by all recipients if group_conversation=#{truish.inspect}" do
          post 'create', :recipients => [@new_user1.id.to_s, @new_user2.id.to_s], :body => "yo", :group_conversation => truish
          expect(response).to be_success

          expect(Conversation.count).to eql(@old_count + 1)
        end
      end

      [nil, "", "0", "false", "no", "off", "wat"].each do |falsish|
        it "should create one conversation per recipient if group_conversation=#{falsish.inspect}" do
          post 'create', :recipients => [@new_user1.id.to_s, @new_user2.id.to_s], :body => "yo", :group_conversation => falsish
          expect(response).to be_success

          expect(Conversation.count).to eql(@old_count + 2)
        end
      end

      it "should set the root account id to the participants for group conversations" do
        post 'create', :recipients => [@new_user1.id.to_s, @new_user2.id.to_s], :body => "yo", :group_conversation => "true"
        expect(response).to be_success

        json = json_parse(response.body)
        json.each do |conv|
          conversation = Conversation.find(conv['id'])
          conversation.conversation_participants.each do |cp|
            expect(cp.root_account_ids).to eq @account_id.to_s
          end
        end
      end

      it "should set the root account id to the participants for bulk private messages" do
        post 'create', :recipients => [@new_user1.id.to_s, @new_user2.id.to_s], :body => "yo", :mode => "sync"
        expect(response).to be_success

        json = json_parse(response.body)
        json.each do |conv|
          conversation = Conversation.find(conv['id'])
          conversation.conversation_participants.each do |cp|
            expect(cp.root_account_ids).to eq @account_id.to_s
          end
        end
      end
    end

    it "should correctly infer context tags" do
      course_with_teacher_logged_in(:active_all => true)
      @course1 = @course
      @course2 = course(:active_all => true)
      @course2.enroll_teacher(@user).accept
      @course3 = course(:active_all => true)
      @course3.enroll_student(@user)
      @group1 = @course1.groups.create!
      @group2 = @course1.groups.create!
      @group3 = @course3.groups.create!
      @group1.users << @user
      @group2.users << @user
      @group3.users << @user

      new_user1 = User.create
      enrollment1 = @course1.enroll_student(new_user1)
      enrollment1.workflow_state = 'active'
      enrollment1.save
      @group1.users << new_user1
      @group2.users << new_user1

      new_user2 = User.create
      enrollment2 = @course1.enroll_student(new_user2)
      enrollment2.workflow_state = 'active'
      enrollment2.save
      @group1.users << new_user2
      @group2.users << new_user2

      new_user3 = User.create
      enrollment3 = @course2.enroll_student(new_user3)
      enrollment3.workflow_state = 'active'
      enrollment3.save

      post 'create', :recipients => [@course2.asset_string + "_students", @group1.asset_string], :body => "yo", :group_conversation => true, :context_code => @group3.asset_string
      expect(response).to be_success

      c = Conversation.first
      expect(c.tags.sort).to eql [@course1.asset_string, @course2.asset_string, @group1.asset_string, @course3.asset_string, @group3.asset_string].sort
      # course1 inferred from group1, course2 inferred from synthetic context,
      # group1 explicit, group2 not present (even though it's shared by everyone)
      # group3 from context_code, course3 inferred from group3
    end

    it "should populate subject" do
      user_session(@student)

      new_user = User.create
      enrollment = @course.enroll_student(new_user)
      enrollment.workflow_state = 'active'
      enrollment.save
      post 'create', :recipients => [new_user.id.to_s], :body => "yo", :subject => "greetings"
      expect(response).to be_success
      expect(assigns[:conversation].conversation.subject).not_to be_nil
    end

    it "should populate subject on batch conversations" do
      user_session(@student)

      new_user1 = User.create
      enrollment1 = @course.enroll_student(new_user1)
      enrollment1.workflow_state = 'active'
      enrollment1.save
      new_user2 = User.create
      enrollment2 = @course.enroll_student(new_user2)
      enrollment2.workflow_state = 'active'
      enrollment2.save
      post 'create', :recipients => [new_user1.id.to_s, new_user2.id.to_s], :body => "later", :subject => "farewell"
      expect(response).to be_success
      json = json_parse(response.body)
      expect(json.size).to eql 2
      json.each { |c|
        expect(c["subject"]).not_to be_nil
      }
    end

    context "user_notes" do
      before :each do
        Account.default.update_attribute :enable_user_notes, true
        user_session(@teacher)

        @students = create_users_in_course(@course, 2, account_associations: true, return_type: :record)
      end

      it "should create user notes" do
        post 'create', :recipients => @students.map(&:id), :body => "yo", :subject => "greetings", :user_note => '1'
        @students.each{|x| expect(x.user_notes.size).to be(1)}
      end
    end
  end

  describe "POST 'update'" do
    it "should update the conversation" do
      course_with_student_logged_in(:active_all => true)
      conversation(:num_other_users => 2).update_attribute(:workflow_state, "unread")

      post 'update', :id => @conversation.conversation_id, :conversation => {:subscribed => "0", :workflow_state => "archived", :starred => "1"}
      expect(response).to be_success
      @conversation.reload
      expect(@conversation.subscribed?).to be_falsey
      expect(@conversation).to be_archived
      expect(@conversation.starred).to be_truthy
    end
  end

  describe "POST 'add_message'" do
    it "should add a message" do
      course_with_student_logged_in(:active_all => true)
      conversation
      expected_lma = Time.zone.parse('2012-12-21T12:42:00Z')
      @conversation.last_message_at = expected_lma
      @conversation.save!

      post 'add_message', :conversation_id => @conversation.conversation_id, :body => "hello world"
      expect(response).to be_success
      expect(@conversation.messages.size).to eq 2
      expect(@conversation.reload.last_message_at).to eql expected_lma
    end

    it "should require permissions" do
      course_with_student_logged_in(:active_all => true)
      conversation
      @course.account.role_overrides.create!(:permission => :send_messages, :role => student_role, :enabled => false)

      post 'add_message', :conversation_id => @conversation.conversation_id, :body => "hello world"
      assert_unauthorized
    end

    it "should queue a job if needed" do
      course_with_student_logged_in(:active_all => true)
      conversation
      expected_lma = Time.zone.parse('2012-12-21T12:42:00Z')
      @conversation.last_message_at = expected_lma
      @conversation.save!

      ConversationParticipant.any_instance.stubs(:should_process_immediately?).returns(false)

      post 'add_message', :conversation_id => @conversation.conversation_id, :body => "hello world"
      expect(response).to be_success
      expect(@conversation.reload.messages.count(:all)).to eq 1
      run_jobs
      expect(@conversation.reload.messages.count(:all)).to eq 2
      expect(@conversation.reload.last_message_at).to eql expected_lma
    end

    it "should generate a user note when requested" do
      Account.default.update_attribute :enable_user_notes, true
      course_with_teacher_logged_in(:active_all => true)
      conversation

      post 'add_message', :conversation_id => @conversation.conversation_id, :body => "hello world"
      expect(response).to be_success
      message = @conversation.messages.first # newest message is first
      student = message.recipients.first
      expect(student.user_notes.size).to eq 0

      post 'add_message', :conversation_id => @conversation.conversation_id, :body => "make a note", :user_note => 1
      expect(response).to be_success
      message = @conversation.messages.first
      student = message.recipients.first
      expect(student.user_notes.size).to eq 1
    end
  end

  describe "POST 'add_recipients'" do
    before :once do
      course_with_student(:active_all => true)
      conversation(:num_other_users => 2)
    end
    before(:each) { user_session(@student) }

    it "should add recipients" do
      new_user = User.create
      enrollment = @course.enroll_student(new_user)
      enrollment.workflow_state = 'active'
      enrollment.save
      post 'add_recipients', :conversation_id => @conversation.conversation_id, :recipients => [new_user.id.to_s]
      expect(response).to be_success
      expect(@conversation.reload.participants.size).to eq 4 # includes @user
    end

    it "should correctly infer context tags" do
      @group = @course.groups.create!
      @conversation.participants.each{ |user| @group.users << user }
      2.times{ @group.users << User.create }

      post 'add_recipients', :conversation_id => @conversation.conversation_id, :recipients => [@group.asset_string]
      expect(response).to be_success

      c = Conversation.first
      expect(c.tags.sort).to eql [@course.asset_string, @group.asset_string]
      # course inferred (when created), group explicit
    end
  end

  describe "POST 'remove_messages'" do
    before(:once) { course_with_student(active_all: true) }
    before(:each) { user_session(@student) }

    it "should remove messages" do
      message = conversation.add_message('another')

      post 'remove_messages', :conversation_id => @conversation.conversation_id, :remove => [message.id.to_s]
      expect(response).to be_success
      expect(@conversation.messages.size).to eq 1
    end

    it "should null a conversation_participant's last_message_at if all message_participants have been destroyed" do
      message = conversation.conversation.conversation_messages.first

      post 'remove_messages', conversation_id: @conversation.conversation_id, :remove => [message.id.to_s]
      expect(@conversation.reload.last_message_at).to be_nil
    end
  end

  describe "DELETE 'destroy'" do
    it "should delete conversations" do
      course_with_student_logged_in(:active_all => true)
      conversation

      delete 'destroy', :id => @conversation.conversation_id
      expect(response).to be_success
      expect(@user.conversations).to be_blank # the conversation_participant is no longer there
      expect(@conversation.conversation).not_to be_nil # though the conversation is
    end
  end

  describe "GET 'public_feed.atom'" do
    before :once do
      course_with_student(:course_name => "Message Course", :active_all => true)
    end

    it "should require authorization" do
      conversation
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code + "x"
      expect(assigns[:problem]).to eql("The verification code is invalid.")
    end

    it "should return basic feed attributes" do
      conversation
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.title).to eq "Conversations Feed"
      expect(feed.links.first.href).to match(/conversations/)
    end

    it "should include message entries" do
      conversation
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code
      expect(assigns[:entries].length).to eq 1
      expect(response).to be_success
    end

    it "should not include messages the user is not a part of" do
      conversation
      student_in_course
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code
      expect(assigns[:entries]).to be_empty
    end

    it "should include part the message text in the title" do
      message = "Sending a test message to some random users, in the hopes that it really works."
      conversation(:message => message)
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.entries.first.title).to match(/Sending a test/)
      expect(feed.entries.first.title).not_to match(message)
    end

    it "should include the message in the content" do
      message = "Sending a test message to some random users, in the hopes that it really works."
      conversation(:message => message)
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.entries.first.content).to match(message)
    end

    it "should include context about the conversation" do
      message = "Sending a test message to some random users, in the hopes that it really works."
      conversation(:num_other_users => 4, :message => message)
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.entries.first.content).to match(/Message Course/)
      expect(feed.entries.first.content).to match(/User/)
      expect(feed.entries.first.content).to match(/others/)
    end

    it "should include an attachment if one exists" do
      conversation
      attachment = @user.conversation_attachments_folder.attachments.create!(:filename => "somefile.doc", :context => @user, :uploaded_data => StringIO.new('test'))
      @conversation.add_message('test attachment', :attachment_ids => [attachment.id])
      HostUrl.stubs(:context_host).returns("test.host")
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      expect(feed).not_to be_nil
      expect(feed.entries.first.content).to match(/somefile\.doc/)
    end
  end

  describe "POST 'toggle_new_conversations'" do
    before :each do
      course_with_student_logged_in(:active_all => true)
    end

    it "should not disable new conversations for a user anymore" do
      post 'toggle_new_conversations'
      @user.reload
      expect(@user.use_new_conversations?).to be_truthy
    end
  end

  context "sharding" do
    specs_require_sharding

    describe 'index' do
      it "should list conversation_ids across shards" do
        users = []
        # Create three users on different shards
        users << user(:name => 'a')
        @shard1.activate { users << user(:name => 'b') }
        @shard2.activate { users << user(:name => 'c') }

        Shard.default.activate do
          # Default shard conversation
          conversation = Conversation.initiate(users, false)
          users.each do |user|
            conversation.add_message(user, "user '#{user.name}' says HI")
          end
        end

        @shard2.activate do
          # Create logged in user
          @logged_in_user = users.last
          course_with_student_logged_in(:user => @logged_in_user, :active_all => true)
          # Shard 2 conversation
          conversation = Conversation.initiate(users, false)
          users.each do |user|
            conversation.add_message(user, "user '#{user.name}' says HI")
          end
        end

        get 'index', :include_all_conversation_ids => true, :format => 'json'

        expect(response).to be_success
        expect(assigns[:js_env]).to be_nil
        # Should assign :conversations and :conversation_ids in json result
        json = assigns[:conversations_json][:conversations]
        ids = assigns[:conversations_json][:conversation_ids]
        # IDs should match in returned lists
        expect(ids.sort).to eq json.map{|c| c[:id]}.sort
        # IDs returned should match IDs for user's conversations
        expect(ids.sort).to eq @logged_in_user.conversations.map(&:conversation_id).sort
        # Expect 2 elements in both groups
        expect(json.length).to eq 2
        expect(ids.length).to eq 2
      end
    end

    describe "show" do
      it "should find conversations across shards" do
        users = []
        users << user(:name => 'a')
        @shard1.activate { users << user(:name => 'b') }

        @shard1.activate do
          @conversation = Conversation.initiate(users, false)
          users.each do |user|
            @conversation.add_message(user, "user '#{user.name}' says HI")
          end
        end
        expect(@conversation.shard).to eq @shard1

        users.each do |user|
          user_session(user) # should work for both users
          get 'show', :id => @conversation.global_id, :format => 'json'
          expect(response).to be_success
        end
      end
    end
  end
end
