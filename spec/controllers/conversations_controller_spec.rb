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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ConversationsController do
  def conversation(opts = {})
    num_other_users = opts[:num_other_users] || 1
    course = opts[:course] || @course
    users = num_other_users.times.map{
      u = User.create
      enrollment = course.enroll_student(u)
      enrollment.workflow_state = 'active'
      enrollment.save
      u
    }
    @conversation = @user.initiate_conversation(users)
    @conversation.add_message(opts[:message] || 'test')
    @conversation
  end

  describe "GET 'index'" do
    it "should require login" do
      course_with_student(:active_all => true)
      get 'index'
      assert_require_login
    end

    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      conversation

      term = @course.root_account.enrollment_terms.create! :name => "Fall"
      @course.update_attributes! :enrollment_term => term

      get 'index'
      response.should be_success
      assigns[:js_env].should_not be_nil
      assigns[:contexts][:courses].to_a.map{|p|p[1]}.
        reduce(true){|truth, con| truth and con.has_key?(:url)}.should be_true
      assigns[:contexts][:courses][@course.id][:term].should == "Fall"
    end

    it "should assign variables for json" do
      course_with_student_logged_in(:active_all => true)
      conversation

      get 'index', :format => 'json'
      response.should be_success
      assigns[:js_env].should be_nil
      assigns[:conversations_json].map{|c|c[:id]}.should == @user.conversations.map(&:conversation_id)
    end

    it "should work for an admin as well" do
      course
      account_admin_user
      user_session(@user)
      conversation

      get 'index', :format => 'json'
      response.should be_success
      assigns[:conversations_json].map{|c|c[:id]}.should == @user.conversations.map(&:conversation_id)
    end

    it "should return all sent conversations" do
      course_with_student_logged_in(:active_all => true)
      @c1 = conversation
      @c2 = conversation
      @c3 = conversation
      @c3.update_attribute :workflow_state, 'archived'

      get 'index', :scope => 'sent', :format => 'json'
      response.should be_success
      assigns[:conversations_json].size.should eql 3
    end

    it "should return conversations matching the specified filter" do
      course_with_student_logged_in(:active_all => true)
      @c1 = conversation
      @other_course = course(:active_all => true)
      enrollment = @other_course.enroll_student(@user)
      enrollment.workflow_state = 'active'
      enrollment.save!
      @user.reload
      @c2 = conversation(:num_other_users => 1, :course => @other_course)

      get 'index', :filter => @other_course.asset_string, :format => 'json'
      response.should be_success
      assigns[:conversations_json].size.should eql 1
      assigns[:conversations_json][0][:id].should == @c2.conversation_id
    end

    it "should use the boolean operation in filter_mode when combining multiple filters" do
      course_with_student_logged_in(:active_all => true)
      @course1 = @course
      @c1 = conversation(:course => @course1)
      @course2 = course(:active_all => true)
      enrollment = @course2.enroll_student(@user)
      enrollment.workflow_state = 'active'
      enrollment.save!
      @c2 = conversation(:course => @course2)
      @c3 = conversation(:course => @course2)

      get 'index', :filter => [@course1.asset_string, @course2.asset_string], :filter_mode => 'or', :format => 'json'
      response.should be_success
      assigns[:conversations_json].map{|c| c[:id]}.sort.should eql [@c1, @c2, @c3].map(&:conversation_id).sort

      get 'index', :filter => [@course2.asset_string, @user.asset_string], :filter_mode => 'or', :format => 'json'
      response.should be_success
      assigns[:conversations_json].map{|c| c[:id]}.sort.should eql [@c1, @c2, @c3].map(&:conversation_id).sort

      get 'index', :filter => [@course2.asset_string, @user.asset_string], :filter_mode => 'and', :format => 'json'
      response.should be_success
      assigns[:conversations_json].map{|c| c[:id]}.sort.should eql [@c2, @c3].map(&:conversation_id).sort

      get 'index', :filter => [@course1.asset_string, @course2.asset_string], :filter_mode => 'and', :format => 'json'
      response.should be_success
      assigns[:conversations_json].should eql []
    end

    it "should return conversations matching a user filter" do
      course_with_student_logged_in(:active_all => true)
      @c1 = conversation
      @other_course = course(:active_all => true)
      enrollment = @other_course.enroll_student(@user)
      enrollment.workflow_state = 'active'
      enrollment.save!
      @user.reload
      @c2 = conversation(:num_other_users => 1, :course => @other_course)

      get 'index', :filter => @user.asset_string, :format => 'json', :include_all_conversation_ids => 1
      response.should be_success
      assigns[:conversations_json].size.should eql 2
    end

    it "should not allow student view student to load inbox" do
      course_with_teacher_logged_in(:active_all => true)
      @fake_student = @course.student_view_student
      session[:become_user_id] = @fake_student.id

      get 'index'
      assert_unauthorized
    end

    context "masquerading" do
      before do
        a = Account.default
        @student = user_with_pseudonym(:active_all => true)
        course_with_student(:active_all => true, :account => a, :user => @student)
        @student.initiate_conversation([user]).add_message('test1', :root_account_id => a.id)
        @student.initiate_conversation([user]).add_message('test2') # no root account, so teacher can't see it

        course_with_teacher_logged_in(:active_all => true, :account => a)
        a.add_user(@user)
        session[:become_user_id] = @student.id
      end

      it "should filter conversations" do
        get 'index', :format => 'json'
        response.should be_success
        assigns[:conversations_json].size.should eql 1
      end

      it "should filter conversations when returning ids" do
        get 'index', :format => 'json', :include_all_conversation_ids => true
        response.should be_success
        assigns[:conversations_json][:conversations].size.should eql 1
        assigns[:conversations_json][:conversation_ids].size.should eql 1
      end

      it "should recompute inbox count" do
        # In an effort to make the data fix easy to do and self-healing,
        # recompute the unread inbox count when the page is loaded.
        course_with_student_logged_in(:active_all => true)
        @user.update_attribute(:unread_conversations_count, -20) # create invalid starting value
        @c1 = conversation

        get 'index'
        response.should be_success
        @user.reload
        @user.unread_conversations_count.should == 0
      end
    end
  end

  describe "GET 'show'" do
    it "should redirect if not xhr" do
      course_with_student_logged_in(:active_all => true)
      conversation

      get 'show', :id => @conversation.conversation_id
      response.should be_redirect
    end

    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      conversation

      xhr :get, 'show', :id => @conversation.conversation_id
      response.should be_success
      assigns[:conversation].should == @conversation
    end
  end

  describe "POST 'create'" do
    it "should create the conversation" do
      course_with_student_logged_in(:active_all => true)

      new_user = User.create
      enrollment = @course.enroll_student(new_user)
      enrollment.workflow_state = 'active'
      enrollment.save
      post 'create', :recipients => [new_user.id.to_s], :body => "yo"
      response.should be_success
      assigns[:conversation].should_not be_nil
    end

    it "should allow messages to be forwarded from the conversation" do
      course_with_student_logged_in(:active_all => true)
      conversation.update_attribute(:workflow_state, "unread")

      new_user = User.create
      enrollment = @course.enroll_student(new_user)
      enrollment.workflow_state = 'active'
      enrollment.save
      post 'create', :recipients => [new_user.id.to_s], :body => "here's the info", :forwarded_message_ids => @conversation.messages.map(&:id)
      response.should be_success
      assigns[:conversation].should_not be_nil
      assigns[:conversation].messages.first.forwarded_message_ids.should eql(@conversation.messages.first.id.to_s)
    end

    context "group conversations" do
      before do
        @old_count = Conversation.count
  
        course_with_teacher_logged_in(:active_all => true)
  
        @new_user1 = User.create
        @course.enroll_student(@new_user1).accept!
  
        @new_user2 = User.create
        @course.enroll_student(@new_user2).accept!

        @account_id = @course.account_id
      end

      ["1", "true", "yes", "on"].each do |truish|
        it "should create a conversation shared by all recipients if group_conversation=#{truish.inspect}" do
          post 'create', :recipients => [@new_user1.id.to_s, @new_user2.id.to_s], :body => "yo", :group_conversation => truish
          response.should be_success
    
          Conversation.count.should eql(@old_count + 1)
        end
      end

      [nil, "", "0", "false", "no", "off", "wat"].each do |falsish|
        it "should create one conversation per recipient if group_conversation=#{falsish.inspect}" do
          post 'create', :recipients => [@new_user1.id.to_s, @new_user2.id.to_s], :body => "yo", :group_conversation => falsish
          response.should be_success
    
          Conversation.count.should eql(@old_count + 2)
        end
      end

      it "should set the root account id to the participants for group conversations" do
        post 'create', :recipients => [@new_user1.id.to_s, @new_user2.id.to_s], :body => "yo", :group_conversation => "true"
        response.should be_success

        json = json_parse(response.body)
        json.each do |conv|
          conversation = Conversation.find(conv['id'])
          conversation.conversation_participants.each do |cp|
            cp.root_account_ids.should == @account_id.to_s
          end
        end
      end

      it "should set the root account id to the participants for bulk private messages" do
        post 'create', :recipients => [@new_user1.id.to_s, @new_user2.id.to_s], :body => "yo", :mode => "sync"
        response.should be_success

        json = json_parse(response.body)
        json.each do |conv|
          conversation = Conversation.find(conv['id'])
          conversation.conversation_participants.each do |cp|
            cp.root_account_ids.should == @account_id.to_s
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
      response.should be_success

      c = Conversation.first
      c.tags.sort.should eql [@course1.asset_string, @course2.asset_string, @group1.asset_string, @course3.asset_string, @group3.asset_string].sort
      # course1 inferred from group1, course2 inferred from synthetic context,
      # group1 explicit, group2 not present (even though it's shared by everyone)
      # group3 from context_code, course3 inferred from group3
    end

    it "should populate subject" do
      course_with_student_logged_in(:active_all => true)

      new_user = User.create
      enrollment = @course.enroll_student(new_user)
      enrollment.workflow_state = 'active'
      enrollment.save
      post 'create', :recipients => [new_user.id.to_s], :body => "yo", :subject => "greetings"
      response.should be_success
      assigns[:conversation].conversation.subject.should_not be_nil
    end

    it "should populate subject on batch conversations" do
      course_with_student_logged_in(:active_all => true)

      new_user1 = User.create
      enrollment1 = @course.enroll_student(new_user1)
      enrollment1.workflow_state = 'active'
      enrollment1.save
      new_user2 = User.create
      enrollment2 = @course.enroll_student(new_user2)
      enrollment2.workflow_state = 'active'
      enrollment2.save
      post 'create', :recipients => [new_user1.id.to_s, new_user2.id.to_s], :body => "later", :subject => "farewell"
      response.should be_success
      json = json_parse(response.body)
      json.size.should eql 2
      json.each { |c|
        c["subject"].should_not be_nil
      }
    end

    context "user_notes" do
      before :each do
        Account.default.update_attribute :enable_user_notes, true
        course_with_teacher_logged_in(:active_all => true)

        @students = (1..2).map{
          student = User.create
          enrollment = @course.enroll_student(student)
          enrollment.workflow_state = 'active'
          enrollment.save
          student
        }
      end

      it "should create user notes" do
        post 'create', :recipients => @students.map(&:id), :body => "yo", :subject => "greetings", :user_note => '1'
        @students.each{|x| x.user_notes.size.should be(1)}
      end
    end
  end

  describe "POST 'update'" do
    it "should update the conversation" do
      course_with_student_logged_in(:active_all => true)
      conversation(:num_other_users => 2).update_attribute(:workflow_state, "unread")

      post 'update', :id => @conversation.conversation_id, :conversation => {:subscribed => "0", :workflow_state => "archived", :starred => "1"}
      response.should be_success
      @conversation.reload
      @conversation.subscribed?.should be_false
      @conversation.should be_archived
      @conversation.starred.should be_true
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
      response.should be_success
      @conversation.messages.size.should == 2
      @conversation.reload.last_message_at.should eql expected_lma
    end

    it "should generate a user note when requested" do
      Account.default.update_attribute :enable_user_notes, true
      course_with_teacher_logged_in(:active_all => true)
      conversation

      post 'add_message', :conversation_id => @conversation.conversation_id, :body => "hello world"
      response.should be_success
      message = @conversation.messages.first # newest message is first
      student = message.recipients.first
      student.user_notes.size.should == 0

      post 'add_message', :conversation_id => @conversation.conversation_id, :body => "make a note", :user_note => 1
      response.should be_success
      message = @conversation.messages.first
      student = message.recipients.first
      student.user_notes.size.should == 1
    end
  end

  describe "POST 'add_recipients'" do
    it "should add recipients" do
      course_with_student_logged_in(:active_all => true)
      conversation(:num_other_users => 2)

      new_user = User.create
      enrollment = @course.enroll_student(new_user)
      enrollment.workflow_state = 'active'
      enrollment.save
      post 'add_recipients', :conversation_id => @conversation.conversation_id, :recipients => [new_user.id.to_s]
      response.should be_success
      @conversation.reload.participants.size.should == 4 # includes @user
    end

    it "should correctly infer context tags" do
      course_with_student_logged_in(:active_all => true)
      conversation(:num_other_users => 2)

      @group = @course.groups.create!
      @conversation.participants.each{ |user| @group.users << user }
      2.times{ @group.users << User.create }

      post 'add_recipients', :conversation_id => @conversation.conversation_id, :recipients => [@group.asset_string]
      response.should be_success

      c = Conversation.first
      c.tags.sort.should eql [@course.asset_string, @group.asset_string]
      # course inferred (when created), group explicit
    end
  end

  describe "POST 'remove_messages'" do
    it "should remove messages" do
      course_with_student_logged_in(:active_all => true)
      message = conversation.add_message('another')

      post 'remove_messages', :conversation_id => @conversation.conversation_id, :remove => [message.id.to_s]
      response.should be_success
      @conversation.messages.size.should == 1
    end

    it "should null a conversation_participant's last_message_at if all message_participants have been destroyed" do
      course_with_student_logged_in(active_all: true)
      message = conversation.conversation.conversation_messages.first

      post 'remove_messages', conversation_id: @conversation.conversation_id, :remove => [message.id.to_s]
      @conversation.reload.last_message_at.should be_nil
    end
  end

  describe "DELETE 'destroy'" do
    it "should delete conversations" do
      course_with_student_logged_in(:active_all => true)
      conversation

      delete 'destroy', :id => @conversation.conversation_id
      response.should be_success
      @user.conversations.should be_blank # the conversation_participant is no longer there
      @conversation.conversation.should_not be_nil # though the conversation is
    end
  end

  describe "GET 'public_feed.atom'" do
    it "should require authorization" do
      course_with_student
      conversation
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code + "x"
      assigns[:problem].should eql("The verification code is invalid.")
    end

    it "should return basic feed attributes" do
      course_with_student
      conversation
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.title.should == "Conversations Feed"
      feed.links.first.href.should match(/conversations/)
    end

    it "should include message entries" do
      course_with_student
      conversation
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code
      assigns[:entries].length.should == 1
      response.should be_success
    end

    it "should not include messages the user is not a part of" do
      course_with_student
      conversation
      student_in_course
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code
      assigns[:entries].should be_empty
    end

    it "should include part the message text in the title" do
      course_with_student
      message = "Sending a test message to some random users, in the hopes that it really works."
      conversation(:message => message)
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.entries.first.title.should match(/Sending a test/)
      feed.entries.first.title.should_not match(message)
    end

    it "should include the message in the content" do
      course_with_student
      message = "Sending a test message to some random users, in the hopes that it really works."
      conversation(:message => message)
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.entries.first.content.should match(message)
    end

    it "should include context about the conversation" do
      course_with_student(:course_name => "Message Course", :active_all => true)
      message = "Sending a test message to some random users, in the hopes that it really works."
      conversation(:num_other_users => 4, :message => message)
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.entries.first.content.should match(/Message Course/)
      feed.entries.first.content.should match(/User/)
      feed.entries.first.content.should match(/others/)
    end

    it "should include an attachment if one exists" do
      course_with_student
      conversation
      attachment = @user.conversation_attachments_folder.attachments.create!(:filename => "somefile.doc", :context => @user, :uploaded_data => StringIO.new('test'))
      @conversation.add_message('test attachment', :attachment_ids => [attachment.id])
      HostUrl.stubs(:context_host).returns("test.host")
      get 'public_feed', :format => 'atom', :feed_code => @student.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.entries.first.content.should match(/somefile\.doc/)
    end
  end

  describe "POST 'toggle_new_conversations'" do
    before :each do
      course_with_student_logged_in(:active_all => true)
    end

    it "should not disable new conversations for a user anymore" do
      post 'toggle_new_conversations'
      @user.reload
      @user.use_new_conversations?.should be_true
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

        response.should be_success
        assigns[:js_env].should be_nil
        # Should assign :conversations and :conversation_ids in json result
        json = assigns[:conversations_json][:conversations]
        ids = assigns[:conversations_json][:conversation_ids]
        # IDs should match in returned lists
        ids.sort.should == json.map{|c| c[:id]}.sort
        # IDs returned should match IDs for user's conversations
        ids.sort.should == @logged_in_user.conversations.map(&:conversation_id).sort
        # Expect 2 elements in both groups
        json.length.should == 2
        ids.length.should == 2
      end
    end
  end
end
