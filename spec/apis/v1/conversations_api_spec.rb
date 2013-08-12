#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')

describe ConversationsController, :type => :integration do
  before do
    course_with_teacher(:active_course => true, :active_enrollment => true, :user => user_with_pseudonym(:active_user => true))
    @course.update_attribute(:name, "the course")
    @course.default_section.update_attributes(:name => "the section")
    @other_section = @course.course_sections.create(:name => "the other section")
    @me = @user

    @bob = student_in_course(:name => "bob")
    @billy = student_in_course(:name => "billy")
    @jane = student_in_course(:name => "jane")
    @joe = student_in_course(:name => "joe")
    @tommy = student_in_course(:name => "tommy", :section => @other_section)
  end

  def student_in_course(options = {})
    section = options.delete(:section)
    u = User.create(options)
    enrollment = @course.enroll_user(u, 'StudentEnrollment', :section => section)
    enrollment.workflow_state = 'active'
    enrollment.save
    u
  end

  context "conversations" do
    it "should return the conversation list" do
      @c1 = conversation(@bob, :workflow_state => 'read')
      @c2 = conversation(@bob, @billy, :workflow_state => 'unread', :subscribed => false)
      @c3 = conversation(@jane, :workflow_state => 'archived') # won't show up, since it's archived

      json = api_call(:get, "/api/v1/conversations.json",
              { :controller => 'conversations', :action => 'index', :format => 'json' })
      json.each { |c| c.delete("avatar_url") } # this URL could change, we don't care
      json.should eql [
        {
          "id" => @c2.conversation_id,
          "subject" => nil,
          "workflow_state" => "unread",
          "last_message" => "test",
          "last_message_at" => @c2.last_message_at.to_json[1, 20],
          "last_authored_message" => "test",
          "last_authored_message_at" => @c2.last_message_at.to_json[1, 20],
          "message_count" => 1,
          "subscribed" => false,
          "private" => false,
          "starred" => false,
          "properties" => ["last_author"],
          "visible" => true,
          "audience" => [@billy.id, @bob.id],
          "audience_contexts" => {
            "groups" => {},
            "courses" => {@course.id.to_s => []}
          },
          "participants" => [
            {"id" => @me.id, "name" => @me.name},
            {"id" => @billy.id, "name" => @billy.name},
            {"id" => @bob.id, "name" => @bob.name}
          ]
        },
        {
          "id" => @c1.conversation_id,
          "subject" => nil,
          "workflow_state" => "read",
          "last_message" => "test",
          "last_message_at" => @c1.last_message_at.to_json[1, 20],
          "last_authored_message" => "test",
          "last_authored_message_at" => @c1.last_message_at.to_json[1, 20],
          "message_count" => 1,
          "subscribed" => true,
          "private" => true,
          "starred" => false,
          "properties" => ["last_author"],
          "visible" => true,
          "audience" => [@bob.id],
          "audience_contexts" => {
            "groups" => {},
            "courses" => {@course.id.to_s => ["StudentEnrollment"]}
          },
          "participants" => [
            {"id" => @me.id, "name" => @me.name},
            {"id" => @bob.id, "name" => @bob.name}
          ]
        }
      ]
    end

    it "should paginate and return proper pagination headers" do
      7.times{ conversation(student_in_course) }
      @user.conversations.size.should eql 7
      json = api_call(:get, "/api/v1/conversations.json?scope=default&per_page=3",
                      {:controller => 'conversations', :action => 'index', :format => 'json', :scope => 'default', :per_page => '3'})

      json.size.should eql 3
      links = response.headers['Link'].split(",")
      links.all?{ |l| l =~ /api\/v1\/conversations/ }.should be_true
      links.all?{ |l| l.scan(/scope=default/).size == 1 }.should be_true
      links.find{ |l| l.match(/rel="next"/)}.should =~ /page=2&per_page=3>/
      links.find{ |l| l.match(/rel="first"/)}.should =~ /page=1&per_page=3>/
      links.find{ |l| l.match(/rel="last"/)}.should =~ /page=3&per_page=3>/

      # get the last page
      json = api_call(:get, "/api/v1/conversations.json?scope=default&page=3&per_page=3",
                      {:controller => 'conversations', :action => 'index', :format => 'json', :scope => 'default', :page => '3', :per_page => '3'})
      json.size.should eql 1
      links = response.headers['Link'].split(",")
      links.all?{ |l| l =~ /api\/v1\/conversations/ }.should be_true
      links.all?{ |l| l.scan(/scope=default/).size == 1 }.should be_true
      links.find{ |l| l.match(/rel="prev"/)}.should =~ /page=2&per_page=3>/
      links.find{ |l| l.match(/rel="first"/)}.should =~ /page=1&per_page=3>/
      links.find{ |l| l.match(/rel="last"/)}.should =~ /page=3&per_page=3>/
    end

    it "should filter conversations by scope" do
      @c1 = conversation(@bob, :workflow_state => 'read')
      @c2 = conversation(@bob, @billy, :workflow_state => 'unread', :subscribed => false)
      @c3 = conversation(@jane, :workflow_state => 'read')

      json = api_call(:get, "/api/v1/conversations.json?scope=unread",
              { :controller => 'conversations', :action => 'index', :format => 'json', :scope => 'unread' })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {
          "id" => @c2.conversation_id,
          "subject" => nil,
          "workflow_state" => "unread",
          "last_message" => "test",
          "last_message_at" => @c2.last_message_at.to_json[1, 20],
          "last_authored_message" => "test",
          "last_authored_message_at" => @c2.last_message_at.to_json[1, 20],
          "message_count" => 1,
          "subscribed" => false,
          "private" => false,
          "starred" => false,
          "properties" => ["last_author"],
          "visible" => true,
          "audience" => [@billy.id, @bob.id],
          "audience_contexts" => {
            "groups" => {},
            "courses" => {@course.id.to_s => []}
          },
          "participants" => [
            {"id" => @me.id, "name" => @me.name},
            {"id" => @billy.id, "name" => @billy.name},
            {"id" => @bob.id, "name" => @bob.name}
          ]
        }
      ]
    end

    context "filtering by tags" do
      specs_require_sharding

      before do
        @conversations = []
      end

      def verify_filter(filter)
        @user = @me
        json = api_call(:get, "/api/v1/conversations.json?filter=#{filter}",
                { :controller => 'conversations', :action => 'index', :format => 'json', :filter => filter })
        json.size.should == @conversations.size
        json.map{ |item| item["id"] }.sort.should == @conversations.map(&:conversation_id).sort
      end

      context "tag context on default shard" do
        before do
          Shard.default.activate do
            account = Account.create!
            course_with_teacher(:account => account, :active_course => true, :active_enrollment => true, :user => @me)
            @course.update_attribute(:name, "another course")
            @alex = student_in_course(:name => "alex")
            @buster = student_in_course(:name => "buster")
          end

          @conversations << conversation(@alex)
          @conversations << @shard1.activate{ conversation(@buster) }
        end

        it "should recognize filter on the default shard" do
          verify_filter(@course.asset_string)
        end

        it "should recognize filter on an unrelated shard" do
          @shard2.activate{ verify_filter(@course.asset_string) }
        end

        it "should recognize explicitly global filter on the default shard" do
          verify_filter(@course.global_asset_string)
        end
      end

      context "tag context on non-default shard" do
        before do
          @shard1.activate do
            account = Account.create!
            course_with_teacher(:account => account, :active_course => true, :active_enrollment => true, :user => @me)
            @course.update_attribute(:name, "the course 2")
            @alex = student_in_course(:name => "alex")
            @buster = student_in_course(:name => "buster")
          end

          @conversations << @shard1.activate{ conversation(@alex) }
          @conversations << conversation(@buster)
        end

        it "should recognize filter on the default shard" do
          verify_filter(@course.asset_string)
        end

        it "should recognize filter on the context's shard" do
          @shard1.activate{ verify_filter(@course.asset_string) }
        end

        it "should recognize filter on an unrelated shard" do
          @shard2.activate{ verify_filter(@course.asset_string) }
        end

        it "should recognize explicitly global filter on the context's shard" do
          @shard1.activate{ verify_filter(@course.global_asset_string) }
        end
      end

      context "tag user on default shard" do
        before do
          Shard.default.activate do
            account = Account.create!
            course_with_teacher(:account => account, :active_course => true, :active_enrollment => true, :user => @me)
            @course.update_attribute(:name, "another course")
            @alex = student_in_course(:name => "alex")
          end

          @conversations << conversation(@alex)
        end

        it "should recognize filter on the default shard" do
          verify_filter(@alex.asset_string)
        end

        it "should recognize filter on an unrelated shard" do
          @shard2.activate{ verify_filter(@alex.asset_string) }
        end
      end

      context "tag user on non-default shard" do
        before do
          @shard1.activate do
            account = Account.create!
            course_with_teacher(:account => account, :active_course => true, :active_enrollment => true)
            @course.update_attribute(:name, "the course 2")
            @alex = student_in_course(:name => "alex")
            @me = @teacher
          end

          @conversations << @shard1.activate{ conversation(@alex) }
        end

        it "should recognize filter on the default shard" do
          verify_filter(@alex.asset_string)
        end

        it "should recognize filter on the user's shard" do
          @shard1.activate{ verify_filter(@alex.asset_string) }
        end

        it "should recognize filter on an unrelated shard" do
          @shard2.activate{ verify_filter(@alex.asset_string) }
        end
      end
    end

    context "sent scope" do
      it "should sort by last authored date" do
        expected_times = 5.times.to_a.reverse.map{ |h| Time.parse((Time.now.utc - h.hours).to_s) }
        ConversationMessage.any_instance.expects(:current_time_from_proper_timezone).times(5).returns(*expected_times)
        @c1 = conversation(@bob)
        @c2 = conversation(@bob, @billy)
        @c3 = conversation(@jane)

        @m1 = @c1.conversation.add_message(@bob, 'ohai')
        @m2 = @c2.conversation.add_message(@bob, 'ohai')

        json = api_call(:get, "/api/v1/conversations.json?scope=sent",
                { :controller => 'conversations', :action => 'index', :format => 'json', :scope => 'sent' })
        json.size.should eql 3
        json[0]['id'].should eql @c3.conversation_id
        json[0]['last_message_at'].should eql expected_times[2].to_json[1, 20]
        json[0]['last_message'].should eql 'test'
        json[0]['last_authored_message_at'].should eql expected_times[2].to_json[1, 20]
        json[0]['last_authored_message'].should eql 'test'

        json[1]['id'].should eql @c2.conversation_id
        json[1]['last_message_at'].should eql expected_times[4].to_json[1, 20]
        json[1]['last_message'].should eql 'ohai'
        json[1]['last_authored_message_at'].should eql expected_times[1].to_json[1, 20]
        json[1]['last_authored_message'].should eql 'test'

        json[2]['id'].should eql @c1.conversation_id
        json[2]['last_message_at'].should eql expected_times[3].to_json[1, 20]
        json[2]['last_message'].should eql 'ohai'
        json[2]['last_authored_message_at'].should eql expected_times[0].to_json[1, 20]
        json[2]['last_authored_message'].should eql 'test'
      end

      it "should include conversations with at least one message by the author, regardless of workflow_state" do
        @c1 = conversation(@bob)
        @c2 = conversation(@bob, @billy)
        @c2.conversation.add_message(@bob, 'ohai')
        @c2.remove_messages(@message) # delete my original message
        @c3 = conversation(@jane, :workflow_state => 'archived')

        json = api_call(:get, "/api/v1/conversations.json?scope=sent",
                { :controller => 'conversations', :action => 'index', :format => 'json', :scope => 'sent' })
        json.size.should eql 2
        json.map{ |c| c['id'] }.sort.should eql [@c1.conversation_id, @c3.conversation_id]
      end
    end

    it "should show the calculated audience_contexts if the tags have not been migrated yet" do
      @c1 = conversation(@bob, @billy)
      Conversation.update_all "tags = NULL"
      ConversationParticipant.update_all "tags = NULL"
      ConversationMessageParticipant.update_all "tags = NULL"

      @c1.reload.tags.should be_empty
      @c1.context_tags.should eql [@course.asset_string]

      json = api_call(:get, "/api/v1/conversations.json",
              { :controller => 'conversations', :action => 'index', :format => 'json' })
      json.size.should eql 1
      json.first["id"].should eql @c1.conversation_id
      json.first["audience_contexts"].should eql({"groups" => {}, "courses" => {@course.id.to_s => []}})
    end

    it "should include starred conversations in starred scope regardless of if read or archived" do
      @c1 = conversation(@bob, :workflow_state => 'unread', :starred => true)
      @c2 = conversation(@billy, :workflow_state => 'read', :starred => true)
      @c3 = conversation(@jane, :workflow_state => 'archived', :starred => true)

      json = api_call(:get, "/api/v1/conversations.json?scope=starred",
              { :controller => 'conversations', :action => 'index', :format => 'json', :scope => 'starred' })
      json.size.should == 3
      json.map{ |c| c["id"] }.sort.should == [@c1, @c2, @c3].map{ |c| c.conversation_id }.sort
    end

    it "should not include unstarred conversations in starred scope regardless of if read or archived" do
      @c1 = conversation(@bob, :workflow_state => 'unread')
      @c2 = conversation(@billy, :workflow_state => 'read')
      @c3 = conversation(@jane, :workflow_state => 'archived')

      json = api_call(:get, "/api/v1/conversations.json?scope=starred",
              { :controller => 'conversations', :action => 'index', :format => 'json', :scope => 'starred' })
      json.should be_empty
    end

    it "should mark all conversations as read" do
      @c1 = conversation(@bob, :workflow_state => 'unread')
      @c2 = conversation(@bob, @billy, :workflow_state => 'unread')
      @c3 = conversation(@jane, :workflow_state => 'archived')

      json = api_call(:post, "/api/v1/conversations/mark_all_as_read.json",
              { :controller => 'conversations', :action => 'mark_all_as_read', :format => 'json' })
      json.should eql({})

      @me.conversations.unread.size.should eql 0
      @me.conversations.default.size.should eql 2
      @me.conversations.archived.size.should eql 1
    end

    context "create" do
      it "should create a private conversation" do
        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@bob.id], :body => "test" })
        json.each { |c|
          c.delete("avatar_url")
          c["participants"].each{ |p|
            p.delete("avatar_url")
          }
        }
        json.each {|c| c["messages"].each {|m| m["participating_user_ids"].sort!}}
        conversation = @me.all_conversations.order("conversation_id DESC").first
        json.should eql [
          {
            "id" => conversation.conversation_id,
            "subject" => nil,
            "workflow_state" => "read",
            "last_message" => nil,
            "last_message_at" => nil,
            "last_authored_message" => "test",
            "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
            "message_count" => 1,
            "subscribed" => true,
            "private" => true,
            "starred" => false,
            "properties" => ["last_author"],
            "visible" => false,
            "audience" => [@bob.id],
            "audience_contexts" => {
              "groups" => {},
              "courses" => {@course.id.to_s => ["StudentEnrollment"]}
            },
            "participants" => [
              {"id" => @me.id, "name" => @me.name, "common_courses" => {}, "common_groups" => {}},
              {"id" => @bob.id, "name" => @bob.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
            ],
            "messages" => [
              {"id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "test", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => [], "participating_user_ids" => [@me.id, @bob.id].sort}
            ]
          }
        ]
      end

      it "should add a context to a private conversation" do
        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@bob.id], :body => "test", :context_code => "course_#{@course.id}" })
        conversation(@bob).conversation.context.should eql(@course)
      end

      it "should create a group conversation" do
        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@bob.id, @billy.id], :body => "test", :group_conversation => true })
        json.each { |c|
          c.delete("avatar_url")
          c["participants"].each{ |p|
            p.delete("avatar_url")
          }
        }
        json.each {|c| c["messages"].each {|m| m["participating_user_ids"].sort!}}
        conversation = @me.all_conversations.order("conversation_id DESC").first
        json.should eql [
          {
            "id" => conversation.conversation_id,
            "subject" => nil,
            "workflow_state" => "read",
            "last_message" => nil,
            "last_message_at" => nil,
            "last_authored_message" => "test",
            "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
            "message_count" => 1,
            "subscribed" => true,
            "private" => false,
            "starred" => false,
            "properties" => ["last_author"],
            "visible" => false,
            "audience" => [@billy.id, @bob.id],
            "audience_contexts" => {
              "groups" => {},
              "courses" => {@course.id.to_s => []}
            },
            "participants" => [
              {"id" => @me.id, "name" => @me.name, "common_courses" => {}, "common_groups" => {}},
              {"id" => @billy.id, "name" => @billy.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
              {"id" => @bob.id, "name" => @bob.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
            ],
            "messages" => [
              {"id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "test", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => [], "participating_user_ids" => [@me.id, @billy.id, @bob.id].sort}
            ]
          }
        ]
      end

      it "should update the private conversation if it already exists" do
        # set up a private conversation in advance
        conversation = conversation(@bob)

        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@bob.id], :body => "test" })
        conversation.reload
        json.each { |c|
          c.delete("avatar_url")
          c["participants"].each{ |p|
            p.delete("avatar_url")
          }
        }
        json.each {|c| c["messages"].each {|m| m["participating_user_ids"].sort!}} 
        json.should eql [
          {
            "id" => conversation.conversation_id,
            "subject" => nil,
            "workflow_state" => "read",
            "last_message" => "test",
            "last_message_at" => conversation.last_message_at.to_json[1, 20],
            "last_authored_message" => "test",
            "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
            "message_count" => 2, # two messages total now, though we'll only get the latest one in the response
            "subscribed" => true,
            "private" => true,
            "starred" => false,
            "properties" => ["last_author"],
            "visible" => true,
            "audience" => [@bob.id],
            "audience_contexts" => {
              "groups" => {},
              "courses" => {@course.id.to_s => ["StudentEnrollment"]}
            },
            "participants" => [
              {"id" => @me.id, "name" => @me.name, "common_courses" => {}, "common_groups" => {}},
              {"id" => @bob.id, "name" => @bob.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
            ],
            "messages" => [
              {"id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "test", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => [], "participating_user_ids" => [@me.id, @bob.id].sort}
            ]
          }
        ]
      end

      it "should create/update bulk private conversations synchronously" do
        # set up one private conversation in advance
        conversation(@bob)

        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@bob.id, @joe.id, @billy.id], :body => "test" })
        json.size.should eql 3
        json.map{ |c| c['id'] }.sort.should eql @me.all_conversations.map(&:conversation_id).sort

        batch = ConversationBatch.first
        batch.should_not be_nil
        batch.should be_sent

        @me.all_conversations.size.should eql(3)
        @me.conversations.size.should eql(1) # just the initial conversation with bob is visible to @me
        @bob.conversations.size.should eql(1)
        @billy.conversations.size.should eql(1)
        @joe.conversations.size.should eql(1)
      end

      it "should set the context on new synchronous bulk private conversations" do
        # set up one private conversation in advance
        conversation(@bob)

        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@bob.id, @joe.id, @billy.id], :body => "test", :context_code => "course_#{@course.id}" })
        json.size.should eql 3
        json.map{ |c| c['id'] }.sort.should eql @me.all_conversations.map(&:conversation_id).sort

        batch = ConversationBatch.first
        batch.should_not be_nil
        batch.should be_sent

        [@me, @bob].each {|u| u.conversations.first.conversation.context.should be_nil} # an existing conversation does not get a context
        [@billy, @joe].each {|u| u.conversations.first.conversation.context.should eql(@course)}
      end

      it "should create/update bulk private conversations asynchronously" do
        # set up one private conversation in advance
        conversation(@bob)

        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@bob.id, @joe.id, @billy.id], :body => "test", :mode => "async" })
        json.should eql([])

        batch = ConversationBatch.first
        batch.should_not be_nil
        batch.should be_created
        batch.deliver

        @me.all_conversations.size.should eql(3)
        @me.conversations.size.should eql(1) # just the initial conversation with bob is visible to @me
        @bob.conversations.size.should eql(1)
        @billy.conversations.size.should eql(1)
        @joe.conversations.size.should eql(1)
      end

      it "should set the context on new asynchronous bulk private conversations" do
        # set up one private conversation in advance
        conversation(@bob)

        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@bob.id, @joe.id, @billy.id], :body => "test", :mode => "async", :context_code => "course_#{@course.id}" })
        json.should eql([])

        batch = ConversationBatch.first
        batch.should_not be_nil
        batch.should be_created
        batch.deliver

       [@me, @bob].each {|u| u.conversations.first.conversation.context.should be_nil} # an existing conversation does not get a context
        [@billy, @joe].each {|u| u.conversations.first.conversation.context.should eql(@course)}
      end

      it "should create a conversation with forwarded messages" do
        forwarded_message = conversation(@me, :sender => @bob).messages.first
        attachment = @me.conversation_attachments_folder.attachments.create!(:context => @me, :uploaded_data => stub_png_data)
        forwarded_message.attachments << attachment

        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@billy.id], :body => "test", :forwarded_message_ids => [forwarded_message.id] })
        json.each { |c|
          c.delete("avatar_url")
          c["participants"].each{ |p|
            p.delete("avatar_url")
          }
        }
        json.each do |c|
          c["messages"].each do |m|
            m["participating_user_ids"].sort!
            m["forwarded_messages"].each {|fm| fm["participating_user_ids"].sort!}
          end
        end
        conversation = @me.all_conversations.order("last_message_at DESC, conversation_id DESC").first
        json.should eql [
          {
            "id" => conversation.conversation_id,
            "subject" => nil,
            "workflow_state" => "read",
            "last_message" => nil,
            "last_message_at" => nil,
            "last_authored_message" => "test",
            "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
            "message_count" => 1,
            "subscribed" => true,
            "private" => true,
            "starred" => false,
            "properties" => ["last_author"],
            "visible" => false,
            "audience" => [@billy.id],
            "audience_contexts" => {
              "groups" => {},
              "courses" => {@course.id.to_s => ["StudentEnrollment"]}
            },
            "participants" => [
              {"id" => @me.id, "name" => @me.name, "common_courses" => {}, "common_groups" => {}},
              {"id" => @billy.id, "name" => @billy.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
              {"id" => @bob.id, "name" => @bob.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
            ],
            "messages" => [
              {
                "id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "test", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "attachments" => [], "participating_user_ids" => [@me.id, @billy.id].sort,
                "forwarded_messages" => [
                  {
                          "id" => forwarded_message.id, "created_at" => forwarded_message.created_at.to_json[1, 20], "body" => "test", "author_id" => @bob.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [],
                          "attachments" => [{'filename' => 'test my file? hai!&.png', 'url' => "http://www.example.com/files/#{attachment.id}/download?download_frd=1&verifier=#{attachment.uuid}", 'content-type' => 'image/png', 'display_name' => 'test my file? hai!&.png', 'id' => attachment.id, 'size' => attachment.size,
                                             'unlock_at' => nil,
                                             'locked' => false,
                                             'hidden' => false,
                                             'lock_at' => nil,
                                             'locked_for_user' => false,
                                             'hidden_for_user' => false,
                                             'created_at' => attachment.created_at.as_json,
                                             'updated_at' => attachment.updated_at.as_json, 
                                             'thumbnail_url' => attachment.thumbnail_url }], "participating_user_ids" => [@me.id, @bob.id].sort
                  }
                ]
              }
            ]
          }
        ]
      end

      it "should set subject" do
        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@bob.id], :body => "test", :subject => "lunch" })
        json.each { |c|
          c.delete("avatar_url")
          c["participants"].each{ |p|
            p.delete("avatar_url")
          }
        }
        json.each {|c| c["messages"].each {|m| m["participating_user_ids"].sort!}}
        conversation = @me.all_conversations.order("conversation_id DESC").first
        json.should eql [
          {
            "id" => conversation.conversation_id,
            "subject" => "lunch",
            "workflow_state" => "read",
            "last_message" => nil,
            "last_message_at" => nil,
            "last_authored_message" => "test",
            "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
            "message_count" => 1,
            "subscribed" => true,
            "private" => true,
            "starred" => false,
            "properties" => ["last_author"],
            "visible" => false,
            "audience" => [@bob.id],
            "audience_contexts" => {
              "groups" => {},
              "courses" => {@course.id.to_s => ["StudentEnrollment"]}
            },
            "participants" => [
              {"id" => @me.id, "name" => @me.name, "common_courses" => {}, "common_groups" => {}},
              {"id" => @bob.id, "name" => @bob.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
            ],
            "messages" => [
              {"id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "test", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => [], "participating_user_ids" => [@me.id, @bob.id].sort}
            ]
          }
        ]
      end

      it "should set subject on batch conversations" do
        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@bob.id, @joe.id], :body => "test", :subject => "dinner" })
        json.size.should eql 2
        json.each { |c|
          c["subject"].should eql 'dinner'
        }
      end
    end
  end

  context "conversation" do
    it "should return the conversation" do
      conversation = conversation(@bob)
      attachment = @me.conversation_attachments_folder.attachments.create!(:context => @me, :filename => 'test.txt', :display_name => "test.txt", :uploaded_data => StringIO.new('test'))
      media_object = MediaObject.new
      media_object.media_id = '0_12345678'
      media_object.media_type = 'audio'
      media_object.context = @me
      media_object.user = @me
      media_object.title = "test title"
      media_object.save!
      message = conversation.add_message("another", :attachment_ids => [attachment.id], :media_comment => media_object)

      conversation.reload

      json = api_call(:get, "/api/v1/conversations/#{conversation.conversation_id}",
              { :controller => 'conversations', :action => 'show', :id => conversation.conversation_id.to_s, :format => 'json' })
      json.delete("avatar_url")
      json["participants"].each{ |p|
        p.delete("avatar_url")
      }
      json["messages"].each {|m| m["participating_user_ids"].sort!}
      json.should eql({
        "id" => conversation.conversation_id,
        "subject" => nil,
        "workflow_state" => "read",
        "last_message" => "another",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "another",
        "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
        "message_count" => 2,
        "subscribed" => true,
        "private" => true,
        "starred" => false,
        "properties" => ["last_author", "attachments", "media_objects"],
        "visible" => true,
        "audience" => [@bob.id],
        "audience_contexts" => {
          "groups" => {},
          "courses" => {@course.id.to_s => ["StudentEnrollment"]}
        },
        "participants" => [
          {"id" => @me.id, "name" => @me.name, "common_courses" => {}, "common_groups" => {}},
          {"id" => @bob.id, "name" => @bob.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
        ],
        "messages" => [
          {
            "id" => conversation.messages.first.id,
            "created_at" => conversation.messages.first.created_at.to_json[1, 20],
            "body" => "another",
            "author_id" => @me.id,
            "generated" => false,
            "media_comment" => {
              "media_type" => "audio",
              "media_id" => "0_12345678",
              "display_name" => "test title",
              "content-type" => "audio/mp4",
              "url" => "http://www.example.com/users/#{@me.id}/media_download?entryId=0_12345678&redirect=1&type=mp4"
            },
            "forwarded_messages" => [],
            "attachments" => [
              {
                "filename" => "test.txt",
                "url" => "http://www.example.com/files/#{attachment.id}/download?download_frd=1&verifier=#{attachment.uuid}",
                "content-type" => "unknown/unknown",
                "display_name" => "test.txt",
                "id" => attachment.id,
                "size" => attachment.size,
                'unlock_at' => nil,
                'locked' => false,
                'hidden' => false,
                'lock_at' => nil,
                'locked_for_user' => false,
                'hidden_for_user' => false,
                'created_at' => attachment.created_at.as_json,
                'updated_at' => attachment.updated_at.as_json,
                'thumbnail_url' => attachment.thumbnail_url
              }
            ],
            "participating_user_ids" => [@me.id, @bob.id].sort
          },
          {"id" => conversation.messages.last.id, "created_at" => conversation.messages.last.created_at.to_json[1, 20], "body" => "test", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => [], "participating_user_ids" => [@me.id, @bob.id].sort}
        ],
        "submissions" => []
      })
    end

    it "should use participant's last_message_at and not consult the most recent message" do
      expected_lma = '2012-12-21T12:42:00Z'
      conversation = conversation(@bob)
      conversation.last_message_at = Time.zone.parse(expected_lma)
      conversation.save!
      conversation.add_message('another test', :update_for_sender => false)
      json = api_call(:get, "/api/v1/conversations/#{conversation.conversation_id}",
              { :controller => 'conversations', :action => 'show', :id => conversation.conversation_id.to_s, :format => 'json' })
      json['last_message_at'].should eql expected_lma
    end

    context "sharding" do
      specs_require_sharding

      def check_conversation
        json = api_call(:get, "/api/v1/conversations/#{@conversation.conversation_id}",
                        { :controller => 'conversations', :action => 'show', :id => @conversation.conversation_id.to_s, :format => 'json' })
        json.delete("avatar_url")
        json["participants"].each{ |p|
          p.delete("avatar_url")
        }
        json["messages"].each {|m| m["participating_user_ids"].sort!}
        expected = {
          "id" => @conversation.conversation_id,
          "subject" => nil,
          "workflow_state" => "read",
          "last_message" => "test",
          "last_message_at" => @conversation.last_message_at.to_json[1, 20],
          "last_authored_message" => "test",
          "last_authored_message_at" => @conversation.last_message_at.to_json[1, 20],
          "message_count" => 1,
          "subscribed" => true,
          "private" => true,
          "starred" => false,
          "properties" => ["last_author"],
          "visible" => true,
          "audience" => [@bob.id],
          "audience_contexts" => {
              "groups" => {},
              "courses" => {@course.id.to_s => ["StudentEnrollment"]}
          },
          "participants" => [
              {"id" => @me.id, "name" => @me.name, "common_courses" => {}, "common_groups" => {}},
              {"id" => @bob.id, "name" => @bob.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
          ],
          "messages" => [
              {"id" => @conversation.messages.last.id, "created_at" => @conversation.messages.last.created_at.to_json[1, 20], "body" => "test", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => [], "participating_user_ids" => [@me.id, @bob.id].sort}
          ],
          "submissions" => []
        }
        json.should == expected
      end

      it "should show ids relative to the current shard" do
        Setting.set('conversations_sharding_migration_still_running', '0')
        @conversation = @shard1.activate { conversation(@bob) }
        check_conversation
        @shard1.activate { check_conversation }
        @shard2.activate { check_conversation }
      end
    end

    it "should auto-mark-as-read if unread" do
      conversation = conversation(@bob, :workflow_state => 'unread')

      json = api_call(:get, "/api/v1/conversations/#{conversation.conversation_id}?scope=unread",
              { :controller => 'conversations', :action => 'show', :id => conversation.conversation_id.to_s, :scope => 'unread', :format => 'json' })
      json["visible"].should be_false
      conversation.reload.should be_read
    end

    it "should not auto-mark-as-read if auto_mark_as_read = false" do
      conversation = conversation(@bob, :workflow_state => 'unread')

      json = api_call(:get, "/api/v1/conversations/#{conversation.conversation_id}?scope=unread&auto_mark_as_read=0",
              { :controller => 'conversations', :action => 'show', :id => conversation.conversation_id.to_s, :scope => 'unread', :auto_mark_as_read => "0", :format => 'json' })
      json["visible"].should be_true
      conversation.reload.should be_unread
    end

    it "should properly flag if starred in the response" do
      conversation1 = conversation(@bob)
      conversation2 = conversation(@billy, :starred => true)

      json = api_call(:get, "/api/v1/conversations/#{conversation1.conversation_id}",
              { :controller => 'conversations', :action => 'show', :id => conversation1.conversation_id.to_s, :format => 'json' })
      json["starred"].should be_false

      json = api_call(:get, "/api/v1/conversations/#{conversation2.conversation_id}",
              { :controller => 'conversations', :action => 'show', :id => conversation2.conversation_id.to_s, :format => 'json' })
      json["starred"].should be_true
    end

    context "submission comments" do
      before do
        submission1 = submission_model(:course => @course, :user => @bob)
        submission2 = submission_model(:course => @course, :user => @bob)
        conversation(@bob)
        submission1.add_comment(:comment => "hey bob", :author => @me)
        submission1.add_comment(:comment => "wut up teacher", :author => @bob)
        submission2.add_comment(:comment => "my name is bob", :author => @bob)
      end

      it "should return submission and comments with the conversation in api format" do
        json = api_call(:get, "/api/v1/conversations/#{@conversation.conversation_id}",
                { :controller => 'conversations', :action => 'show', :id => @conversation.conversation_id.to_s, :format => 'json' })

        json['messages'].size.should == 1
        json['submissions'].size.should == 2
        jsub = json['submissions'][1]
        jsub['assignment'].should be_present # includes & ['assignment']
        jcom = jsub['submission_comments']
        jcom.should be_present # includes & ['submission_comments']
        jcom.size.should == 2
        jcom[0]['author_id'].should == @me.id
        jcom[1]['author_id'].should == @bob.id

        jsub = json['submissions'][0]
        jcom = jsub['submission_comments']
        jcom.size.should == 1
        jcom[0]['author_id'].should == @bob.id
      end

      it "should interleave submission and comments in the conversation" do
        @conversation.add_message("another message!")

        json = api_call(:get, "/api/v1/conversations/#{@conversation.conversation_id}?interleave_submissions=1",
                { :controller => 'conversations', :action => 'show', :id => @conversation.conversation_id.to_s, :format => 'json', :interleave_submissions => '1' })

        json['submissions'].should be_nil
        json['messages'].size.should eql 4
        json['messages'][0]['body'].should eql 'another message!'

        json['messages'][1]['body'].should eql 'my name is bob'
        jsub = json['messages'][1]['submission']
        jsub['assignment'].should be_present
        jcom = jsub['submission_comments']
        jcom.should be_present
        jcom.size.should == 1
        jcom[0]['author_id'].should == @bob.id

        json['messages'][2]['body'].should eql 'wut up teacher' # most recent comment
        jsub = json['messages'][2]['submission']
        jcom = jsub['submission_comments']
        jcom.size.should == 2
        jcom[0]['author_id'].should == @me.id
        jcom[1]['author_id'].should == @bob.id

        json['messages'][3]['body'].should eql 'test'
      end

    end

    it "should add a message to the conversation" do
      conversation = conversation(@bob)

      json = api_call(:post, "/api/v1/conversations/#{conversation.conversation_id}/add_message",
              { :controller => 'conversations', :action => 'add_message', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :body => "another" })
      conversation.reload
      json.delete("avatar_url")
      json["participants"].each{ |p|
        p.delete("avatar_url")
      }
      json["messages"].each {|m| m["participating_user_ids"].sort!}
      json.should eql({
        "id" => conversation.conversation_id,
        "subject" => nil,
        "workflow_state" => "read",
        "last_message" => "another",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "another",
        "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
        "message_count" => 2, # two messages total now, though we'll only get the latest one in the response
        "subscribed" => true,
        "private" => true,
        "starred" => false,
        "properties" => ["last_author"],
        "visible" => true,
        "audience" => [@bob.id],
        "audience_contexts" => {
          "groups" => {},
          "courses" => {@course.id.to_s => ["StudentEnrollment"]}
        },
        "participants" => [
          {"id" => @me.id, "name" => @me.name, "common_courses" => {}, "common_groups" => {}},
          {"id" => @bob.id, "name" => @bob.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
        ],
        "messages" => [
          {"id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "another", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => [], "participating_user_ids" => [@me.id, @bob.id].sort}
        ]
      })
    end

    it "should create a media object if it doesn't exist" do
      conversation = conversation(@bob)

      MediaObject.count.should eql 0
      json = api_call(:post, "/api/v1/conversations/#{conversation.conversation_id}/add_message",
              { :controller => 'conversations', :action => 'add_message', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :body => "another", :media_comment_id => "asdf", :media_comment_type => "audio" })
      conversation.reload
      mjson = json["messages"][0]["media_comment"]
      mjson.should be_present
      mjson["media_id"].should eql "asdf"
      mjson["media_type"].should eql "audio"
      MediaObject.count.should eql 1
    end


    it "should add recipients to the conversation" do
      conversation = conversation(@bob, @billy)

      json = api_call(:post, "/api/v1/conversations/#{conversation.conversation_id}/add_recipients",
              { :controller => 'conversations', :action => 'add_recipients', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :recipients => [@jane.id.to_s, "course_#{@course.id}"] })
      conversation.reload
      json.delete("avatar_url")
      json["participants"].each{ |p|
        p.delete("avatar_url")
      }
      json["messages"].each {|m| m["participating_user_ids"].sort!}
      json.should eql({
        "id" => conversation.conversation_id,
        "subject" => nil,
        "workflow_state" => "read",
        "last_message" => "test",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "test",
        "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
        "message_count" => 1,
        "subscribed" => true,
        "private" => false,
        "starred" => false,
        "properties" => ["last_author"],
        "visible" => true,
        "audience" => [@billy.id, @bob.id, @jane.id, @joe.id, @tommy.id],
        "audience_contexts" => {
          "groups" => {},
          "courses" => {@course.id.to_s => []}
        },
        "participants" => [
          {"id" => @me.id, "name" => @me.name, "common_courses" => {}, "common_groups" => {}},
          {"id" => @billy.id, "name" => @billy.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
          {"id" => @bob.id, "name" => @bob.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
          {"id" => @jane.id, "name" => @jane.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
          {"id" => @joe.id, "name" => @joe.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
          {"id" => @tommy.id, "name" => @tommy.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
        ],
        "messages" => [
          {"id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "jane, joe, and tommy were added to the conversation by nobody@example.com", "author_id" => @me.id, "generated" => true, "media_comment" => nil, "forwarded_messages" => [], "attachments" => [], "participating_user_ids" => [@me.id, @billy.id, @bob.id, @jane.id, @joe.id, @tommy.id].sort}
        ]
      })
    end

    it "should update the conversation" do
      conversation = conversation(@bob, @billy)

      json = api_call(:put, "/api/v1/conversations/#{conversation.conversation_id}",
              { :controller => 'conversations', :action => 'update', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :conversation => {:subscribed => false, :workflow_state => 'archived'} })
      conversation.reload
      json.delete("avatar_url")
      json["participants"].each{ |p|
        p.delete("avatar_url")
      }
      json.should eql({
        "id" => conversation.conversation_id,
        "subject" => nil,
        "workflow_state" => "archived",
        "last_message" => "test",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "test",
        "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
        "message_count" => 1,
        "subscribed" => false,
        "private" => false,
        "starred" => false,
        "properties" => ["last_author"],
        "visible" => false, # since we archived it, and the default view is assumed
        "audience" => [@billy.id, @bob.id],
        "audience_contexts" => {
          "groups" => {},
          "courses" => {@course.id.to_s => []}
        },
        "participants" => [
          {"id" => @me.id, "name" => @me.name, "common_courses" => {}, "common_groups" => {}},
          {"id" => @billy.id, "name" => @billy.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
          {"id" => @bob.id, "name" => @bob.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
        ]
      })
    end

    it "should be able to star the conversation via update" do
      conversation = conversation(@bob, @billy)

      json = api_call(:put, "/api/v1/conversations/#{conversation.conversation_id}",
              { :controller => 'conversations', :action => 'update', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :conversation => {:starred => true} })
      json["starred"].should be_true
    end

    it "should be able to unstar the conversation via update" do
      conversation = conversation(@bob, @billy, :starred => true)

      json = api_call(:put, "/api/v1/conversations/#{conversation.conversation_id}",
              { :controller => 'conversations', :action => 'update', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :conversation => {:starred => false} })
      json["starred"].should be_false
    end

    it "should leave starryness alone when left out of update" do
      conversation = conversation(@bob, @billy, :starred => true)

      json = api_call(:put, "/api/v1/conversations/#{conversation.conversation_id}",
              { :controller => 'conversations', :action => 'update', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :conversation => {:workflow_state => 'read'} })
      json["starred"].should be_true
    end

    it "should delete messages from the conversation" do
      conversation = conversation(@bob)
      message = conversation.add_message("another one")

      json = api_call(:post, "/api/v1/conversations/#{conversation.conversation_id}/remove_messages",
              { :controller => 'conversations', :action => 'remove_messages', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :remove => [message.id] })
      conversation.reload
      json.delete("avatar_url")
      json["participants"].each{ |p|
        p.delete("avatar_url")
      }
      json.should eql({
        "id" => conversation.conversation_id,
        "subject" => nil,
        "workflow_state" => "read",
        "last_message" => "test",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "test",
        "last_authored_message_at" => conversation.last_authored_message.created_at.to_json[1, 20],
        "message_count" => 1,
        "subscribed" => true,
        "private" => true,
        "starred" => false,
        "properties" => ["last_author"],
        "visible" => true,
        "audience" => [@bob.id],
        "audience_contexts" => {
          "groups" => {},
          "courses" => {@course.id.to_s => ["StudentEnrollment"]}
        },
        "participants" => [
          {"id" => @me.id, "name" => @me.name, "common_courses" => {}, "common_groups" => {}},
          {"id" => @bob.id, "name" => @bob.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
        ]
      })
    end

    it "should delete the conversation" do
      conversation = conversation(@bob)

      json = api_call(:delete, "/api/v1/conversations/#{conversation.conversation_id}",
              { :controller => 'conversations', :action => 'destroy', :id => conversation.conversation_id.to_s, :format => 'json' })
      json.delete("avatar_url")
      json["participants"].each{ |p|
        p.delete("avatar_url")
      }
      json.should eql({
        "id" => conversation.conversation_id,
        "subject" => nil,
        "workflow_state" => "read",
        "last_message" => nil,
        "last_message_at" => nil,
        "last_authored_message" => nil,
        "last_authored_message_at" => nil,
        "message_count" => 0,
        "subscribed" => true,
        "private" => true,
        "starred" => false,
        "properties" => [],
        "visible" => false,
        "audience" => [@bob.id],
        "audience_contexts" => {
          "groups" => {},
          "courses" => {} # tags, and by extension audience_contexts, get cleared out when the conversation is deleted
        },
        "participants" => [
          {"id" => @me.id, "name" => @me.name, "common_courses" => {}, "common_groups" => {}},
          {"id" => @bob.id, "name" => @bob.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
        ]
      })
    end
  end

  context "recipients" do
    before do
      @group = @course.groups.create(:name => "the group")
      @group.users = [@me, @bob, @joe]
    end

    it "should support the deprecated route" do
      json = api_call(:get, "/api/v1/conversations/find_recipients.json?search=o",
              { :controller => 'search', :action => 'recipients', :format => 'json', :search => 'o' })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {"id" => "course_#{@course.id}", "name" => "the course", "type" => "context", "user_count" => 6, "permissions" => {}},
        {"id" => "section_#{@other_section.id}", "name" => "the other section", "type" => "context", "user_count" => 1, "context_name" => "the course", "permissions" => {}},
        {"id" => "section_#{@course.default_section.id}", "name" => "the section", "type" => "context", "user_count" => 5, "context_name" => "the course", "permissions" => {}},
        {"id" => "group_#{@group.id}", "name" => "the group", "type" => "context", "user_count" => 3, "context_name" => "the course", "permissions" => {}},
        {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {@group.id.to_s => ["Member"]}},
        {"id" => @joe.id, "name" => "joe", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {@group.id.to_s => ["Member"]}},
        {"id" => @me.id, "name" => @me.name, "common_courses" => {@course.id.to_s => ["TeacherEnrollment"]}, "common_groups" => {@group.id.to_s => ["Member"]}},
        {"id" => @tommy.id, "name" => "tommy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
      ]
    end
  end

  context "batches" do
    it "should return all in-progress batches" do
      batch1 = ConversationBatch.generate(Conversation.build_message(@me, "hi all"), [@bob, @billy], :async)
      batch2 = ConversationBatch.generate(Conversation.build_message(@me, "ohai"), [@bob, @billy], :sync)
      batch3 = ConversationBatch.generate(Conversation.build_message(@bob, "sup"), [@me, @billy], :async)

      json = api_call(:get, "/api/v1/conversations/batches",
                      :controller => 'conversations',
                      :action => 'batches',
                      :format => 'json')

      json.size.should eql 1 # batch2 already ran, batch3 belongs to someone else
      json[0]["id"].should eql batch1.id
    end
  end

  describe "visibility inference" do
    it "should not break with empty string as filter" do
      # added for 1.9.3
      json = api_call(:post, "/api/v1/conversations",
              { :controller => 'conversations', :action => 'create', :format => 'json' },
              { :recipients => [@bob.id], :body => 'Test Message', :filter => '' })
      json.first['visible'].should be_false
    end
  end

  describe "bulk updates" do
    it "should mark conversations as read" do
      c1 = conversation(@me, @bob, :workflow_state => 'unread')
      c2 = conversation(@me, @jane, :workflow_state => 'read')
      @me.reload.unread_conversations_count.should eql(1)

      conversation_ids = [c1,c2].map {|c| c.conversation.id}
      json = api_call(:put, "/api/v1/conversations",
        { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
        { :event => 'mark_as_read', :conversation_ids => conversation_ids })
      run_jobs
      progress = Progress.find(json['id'])
      progress.message.to_s.should include "#{conversation_ids.size} conversations processed"
      c1.reload.should be_read
      c2.reload.should be_read
      @me.reload.unread_conversations_count.should eql(0)
    end

    it "should mark conversations as unread" do
      c1 = conversation(@me, @bob, :workflow_state => 'unread')
      c2 = conversation(@me, @jane, :workflow_state => 'read')
      @me.reload.unread_conversations_count.should eql(1)

      conversation_ids = [c1,c2].map {|c| c.conversation.id}
      json = api_call(:put, "/api/v1/conversations",
        { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
        { :event => 'mark_as_unread', :conversation_ids => conversation_ids })
      run_jobs
      progress = Progress.find(json['id'])
      progress.message.to_s.should include "#{conversation_ids.size} conversations processed"
      c1.reload.should be_unread
      c2.reload.should be_unread
      @me.reload.unread_conversations_count.should eql(2)
    end

    it "should mark conversations as starred" do
      c1 = conversation(@me, @bob, :workflow_state => 'unread', :starred => true)
      c2 = conversation(@me, @jane, :workflow_state => 'read')
      @me.reload.unread_conversations_count.should eql(1)

      conversation_ids = [c1,c2].map {|c| c.conversation.id}
      json = api_call(:put, "/api/v1/conversations",
        { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
        { :event => 'star', :conversation_ids => conversation_ids })
      run_jobs
      progress = Progress.find(json['id'])
      progress.message.to_s.should include "#{conversation_ids.size} conversations processed"
      c1.reload.starred.should be_true
      c2.reload.starred.should be_true
      @me.reload.unread_conversations_count.should eql(1)
    end

    it "should mark conversations as unstarred" do
      c1 = conversation(@me, @bob, :workflow_state => 'unread', :starred => true)
      c2 = conversation(@me, @jane, :workflow_state => 'read')
      @me.reload.unread_conversations_count.should eql(1)

      conversation_ids = [c1,c2].map {|c| c.conversation.id}
      json = api_call(:put, "/api/v1/conversations",
        { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
        { :event => 'unstar', :conversation_ids => conversation_ids })
      run_jobs
      progress = Progress.find(json['id'])
      progress.message.to_s.should include "#{conversation_ids.size} conversations processed"
      c1.reload.starred.should be_false
      c2.reload.starred.should be_false
      @me.reload.unread_conversations_count.should eql(1)
    end

    # it "should mark conversations as subscribed"
    # it "should mark conversations as unsubscribed"
    it "should archive conversations" do
      conversations = %w(archived read unread).map do |state|
        conversation(@me, @bob, :workflow_state => state)
      end
      @me.reload.unread_conversations_count.should eql(1)

      conversation_ids = conversations.map {|c| c.conversation.id}
      json = api_call(:put, "/api/v1/conversations",
        { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
        { :event => 'archive', :conversation_ids => conversation_ids })
      run_jobs
      progress = Progress.find(json['id'])
      progress.message.to_s.should include "#{conversation_ids.size} conversations processed"
      conversations.each do |c|
        c.reload.should be_archived
      end
      @me.reload.unread_conversations_count.should eql(0)
    end

    it "should destroy conversations" do
      c1 = conversation(@me, @bob, :workflow_state => 'unread')
      c2 = conversation(@me, @jane, :workflow_state => 'read')
      @me.reload.unread_conversations_count.should eql(1)

      conversation_ids = [c1,c2].map {|c| c.conversation.id}
      json = api_call(:put, "/api/v1/conversations",
        { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
        { :event => 'destroy', :conversation_ids => conversation_ids })
      run_jobs
      progress = Progress.find(json['id'])
      progress.message.to_s.should include "#{conversation_ids.size} conversations processed"
      c1.reload.messages.should be_empty
      c2.reload.messages.should be_empty
      @me.reload.unread_conversations_count.should eql(0)
    end

    describe "immediate failures" do
      it "should fail if event is invalid" do
        c1 = conversation(@me, @bob, :workflow_state => 'unread')
        c2 = conversation(@me, @jane, :workflow_state => 'read')
        conversation_ids = [c1,c2].map {|c| c.conversation.id}

        json = api_call(:put, "/api/v1/conversations",
          { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
          { :event => 'NONSENSE', :conversation_ids => conversation_ids },
          {}, {:expected_status => 400})

        json['message'].should include 'invalid event'
      end

      it "should fail if event parameter is not specified" do
        c1 = conversation(@me, @bob, :workflow_state => 'unread')
        c2 = conversation(@me, @jane, :workflow_state => 'read')
        conversation_ids = [c1,c2].map {|c| c.conversation.id}

        json = api_call(:put, "/api/v1/conversations",
          { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
          { :conversation_ids => conversation_ids },
          {}, {:expected_status => 400})

        json['message'].should include 'event not specified'
      end

      it "should fail if conversation_ids is not specified" do
        c1 = conversation(@me, @bob, :workflow_state => 'unread')
        c2 = conversation(@me, @jane, :workflow_state => 'read')
        conversation_ids = [c1,c2].map {|c| c.conversation.id}

        json = api_call(:put, "/api/v1/conversations",
          { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
          { :event => 'mark_as_read' },
          {}, {:expected_status => 400})

        json['message'].should include 'conversation_ids not specified'
      end

      it "should fail if batch size limit is exceeded" do
        conversation_ids = (1..501).to_a
        json = api_call(:put, "/api/v1/conversations",
          { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
          { :event => 'mark_as_read', :conversation_ids => conversation_ids },
          {}, {:expected_status => 400})
        json['message'].should include 'exceeded'
      end
    end

    describe "progress" do
      it "should create and update a progress object" do
        c1 = conversation(@me, @bob, :workflow_state => 'unread')
        c2 = conversation(@me, @jane, :workflow_state => 'read')
        conversation_ids = [c1,c2].map {|c| c.conversation.id}
        json = api_call(:put, "/api/v1/conversations",
          { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
          { :event => 'mark_as_read', :conversation_ids => conversation_ids })
        progress = Progress.find(json['id'])
        progress.should be_present
        progress.should be_queued
        progress.completion.should eql(0.0)
        run_jobs
        progress.reload.should be_completed
        progress.completion.should eql(100.0)
      end

      describe "progress failures" do
        it "should not update conversations the current user does not participate in" do
          c1 = conversation(@me, @bob, :workflow_state => 'unread')
          c2 = conversation(@me, @jane, :workflow_state => 'read')
          c3 = conversation(@bob, @jane, :sender => @bob, :workflow_state => 'unread')
          conversation_ids = [c1,c2,c3].map {|c| c.conversation.id}

          json = api_call(:put, "/api/v1/conversations",
            { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
            { :event => 'mark_as_read', :conversation_ids => conversation_ids })
          run_jobs
          progress = Progress.find(json['id'])
          progress.should be_completed
          progress.completion.should eql(100.0)
          c1.reload.should be_read
          c2.reload.should be_read
          c3.reload.should be_unread
          progress.message.should include 'not participating'
          progress.message.should include '2 conversations processed'
        end

        it "should fail if all conversation ids are invalid" do
          c1 = conversation(@bob, @jane, :sender => @bob, :workflow_state => 'unread')
          conversation_ids = [c1.conversation.id]

          json = api_call(:put, "/api/v1/conversations",
            { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
            { :event => 'mark_as_read', :conversation_ids => conversation_ids })

          run_jobs
          progress = Progress.find(json['id'])
          progress.should be_failed
          progress.completion.should eql(100.0)
          c1.reload.should be_unread
          progress.message.should include 'not participating'
          progress.message.should include '0 conversations processed'
        end

        it "should fail progress if exception is raised in job" do
          begin
            Progress.any_instance.stubs(:complete!).raises "crazy exception"

            c1 = conversation(@me, @jane, :workflow_state => 'unread')
            conversation_ids = [c1.conversation.id]
            json = api_call(:put, "/api/v1/conversations",
              { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
              { :event => 'mark_as_read', :conversation_ids => conversation_ids })
            run_jobs
            progress = Progress.find(json['id'])
            progress.should be_failed
            progress.message.should include 'crazy exception'
          ensure
            Progress.any_instance.unstub(:complete!)
          end
        end
      end
    end
  end

  describe "delete_for_all" do
    it "should require site_admin with become_user permissions" do
      cp = conversation(@me, @bob, @billy, @jane, @joe, @tommy, :sender => @me)
      conv = cp.conversation
      @joe.conversations.size.should eql 1

      account_admin_user_with_role_changes(:account => Account.site_admin, :role_changes => { :become_user => false })
      json = raw_api_call(:delete, "/api/v1/conversations/#{conv.id}/delete_for_all",
        {:controller => 'conversations', :action => 'delete_for_all', :format => 'json', :id => conv.id.to_s},
        {:domain_root_account => Account.site_admin})
      response.status.should eql "401 Unauthorized"

      account_admin_user
      p = Account.default.pseudonyms.create!(:unique_id => 'admin', :user => @user)
      user_session(@user, p)
      json = raw_api_call(:delete, "/api/v1/conversations/#{conv.id}/delete_for_all",
        {:controller => 'conversations', :action => 'delete_for_all', :format => 'json', :id => conv.id.to_s},
        {})
      response.status.should eql "401 Unauthorized"

      user_session(@me)
      json = raw_api_call(:delete, "/api/v1/conversations/#{conv.id}/delete_for_all",
        {:controller => 'conversations', :action => 'delete_for_all', :format => 'json', :id => conv.id.to_s},
        {})
      response.status.should eql "401 Unauthorized"

      @me.all_conversations.size.should eql 1
      @joe.conversations.size.should eql 1
    end

    it "should fail if conversation doesn't exist" do
      user_session(site_admin_user)
      json = raw_api_call(:delete, "/api/v1/conversations/0/delete_for_all",
        {:controller => 'conversations', :action => 'delete_for_all', :format => 'json', :id => "0"},
        {})
      response.status.should eql "404 Not Found"
    end

    it "should delete the conversation for all participants" do
      users = [@me, @bob, @billy, @jane, @joe, @tommy]
      cp = conversation(*users)
      conv = cp.conversation
      users.each do |user|
        user.all_conversations.size.should eql 1
        user.stream_item_instances.size.should eql 1 unless user.id == @me.id
      end

      user_session(site_admin_user)
      json = api_call(:delete, "/api/v1/conversations/#{conv.id}/delete_for_all",
        {:controller => 'conversations', :action => 'delete_for_all', :format => 'json', :id => conv.id.to_s},
        {})

      json.should eql({})

      users.each do |user|
        user.reload.all_conversations.size.should eql 0
        user.stream_item_instances.size.should eql 0
      end
      ConversationParticipant.count.should eql 0
      ConversationMessageParticipant.count.should eql 0
      # should leave the conversation and its message in the database
      Conversation.count.should eql 1
      ConversationMessage.count.should eql 1 
    end

    context "sharding" do
      specs_require_sharding

      it "should delete the conversation for users on multiple shards" do
        users = [@me]
        users << @shard1.activate { User.create! }

        cp = conversation(*users)
        conv = cp.conversation
        users.each do |user|
          user.all_conversations.size.should eql 1
          user.stream_item_instances.size.should eql 1 unless user.id == @me.id
        end

        user_session(site_admin_user)
        @shard2.activate do
          json = api_call(:delete, "/api/v1/conversations/#{conv.id}/delete_for_all",
                          {:controller => 'conversations', :action => 'delete_for_all', :format => 'json', :id => conv.id.to_s},
                          {})

          json.should eql({})
        end

        users.each do |user|
          user.reload.all_conversations.size.should eql 0
          user.stream_item_instances.size.should eql 0
        end
        ConversationParticipant.count.should eql 0
        ConversationMessageParticipant.count.should eql 0
        # should leave the conversation and its message in the database
        Conversation.count.should eql 1
        ConversationMessage.count.should eql 1
      end
    end
  end

  describe 'unread_count' do
    it 'should return the number of unread conversations for the current user' do
      conversation(student_in_course, :workflow_state => 'unread')
      json = api_call(:get, '/api/v1/conversations/unread_count.json',
                      {:controller => 'conversations', :action => 'unread_count', :format => 'json'})
      json.should eql({'unread_count' => '1'})
    end
  end
  
end
