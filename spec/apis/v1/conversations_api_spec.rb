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

describe ConversationsController, type: :request do
  before :once do
    @other = user(active_all: true)

    course_with_teacher(:active_course => true, :active_enrollment => true, :user => user_with_pseudonym(:active_user => true))
    @course.update_attribute(:name, "the course")
    @course.account.role_overrides.create!(permission: 'send_messages_all', role: teacher_role, enabled: false)
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
      json.each { |c| c.delete("last_authored_message_at") } # This is sometimes not updated. It's a known bug.
      expect(json).to eql [
        {
          "id" => @c2.conversation_id,
          "subject" => nil,
          "workflow_state" => "unread",
          "last_message" => "test",
          "last_message_at" => @c2.last_message_at.to_json[1, 20],
          "last_authored_message" => "test",
          # "last_authored_message_at" => @c2.last_message_at.to_json[1, 20],
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
          ],
          "context_name" => @c2.context_name,
          "context_code" => @c2.conversation.context_code,
        },
        {
          "id" => @c1.conversation_id,
          "subject" => nil,
          "workflow_state" => "read",
          "last_message" => "test",
          "last_message_at" => @c1.last_message_at.to_json[1, 20],
          "last_authored_message" => "test",
          # "last_authored_message_at" => @c1.last_message_at.to_json[1, 20],
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
          ],
          "context_name" => @c1.context_name,
          "context_code" => @c1.conversation.context_code,
        }
      ]
    end

    it "should stringify audience ids if requested" do
      @c1 = conversation(@bob, :workflow_state => 'read')
      @c2 = conversation(@bob, @billy, :workflow_state => 'unread', :subscribed => false)

      json = api_call(:get, "/api/v1/conversations",
              { :controller => 'conversations', :action => 'index', :format => 'json' },
              {},
              {'Accept' => 'application/json+canvas-string-ids'})
      audiences = json.map { |j| j['audience'] }
      expect(audiences).to eq [
        [@billy.id.to_s, @bob.id.to_s],
        [@bob.id.to_s],
      ]
    end

    it "should paginate and return proper pagination headers" do
      students = create_users_in_course(@course, 7, return_type: :record)
      students.each{ |s| conversation(s) }
      expect(@user.conversations.size).to eql 7
      json = api_call(:get, "/api/v1/conversations.json?scope=default&per_page=3",
                      {:controller => 'conversations', :action => 'index', :format => 'json', :scope => 'default', :per_page => '3'})

      expect(json.size).to eql 3
      links = response.headers['Link'].split(",")
      expect(links.all?{ |l| l =~ /api\/v1\/conversations/ }).to be_truthy
      expect(links.all?{ |l| l.scan(/scope=default/).size == 1 }).to be_truthy
      expect(links.find{ |l| l.match(/rel="next"/)}).to match /page=2&per_page=3>/
      expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1&per_page=3>/
      expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3&per_page=3>/

      # get the last page
      json = api_call(:get, "/api/v1/conversations.json?scope=default&page=3&per_page=3",
                      {:controller => 'conversations', :action => 'index', :format => 'json', :scope => 'default', :page => '3', :per_page => '3'})
      expect(json.size).to eql 1
      links = response.headers['Link'].split(",")
      expect(links.all?{ |l| l =~ /api\/v1\/conversations/ }).to be_truthy
      expect(links.all?{ |l| l.scan(/scope=default/).size == 1 }).to be_truthy
      expect(links.find{ |l| l.match(/rel="prev"/)}).to match /page=2&per_page=3>/
      expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1&per_page=3>/
      expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3&per_page=3>/
    end

    it "should filter conversations by scope" do
      @c1 = conversation(@bob, :workflow_state => 'read')
      @c2 = conversation(@bob, @billy, :workflow_state => 'unread', :subscribed => false)
      @c3 = conversation(@jane, :workflow_state => 'read')

      json = api_call(:get, "/api/v1/conversations.json?scope=unread",
              { :controller => 'conversations', :action => 'index', :format => 'json', :scope => 'unread' })
      json.each { |c| c.delete("avatar_url") }
      json.each { |c| c.delete("last_authored_message_at") } # This is sometimes not updated. It's a known bug.
      expect(json).to eql [
        {
          "id" => @c2.conversation_id,
          "subject" => nil,
          "workflow_state" => "unread",
          "last_message" => "test",
          "last_message_at" => @c2.last_message_at.to_json[1, 20],
          "last_authored_message" => "test",
          # "last_authored_message_at" => @c2.last_message_at.to_json[1, 20],
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
          ],
          "context_name" => @c2.context_name,
          "context_code" => @c2.conversation.context_code,
        }
      ]
    end

    describe "context_name" do
      before :once do
        @c1 = conversation(@bob, :workflow_state => 'read') # implicit tag from shared context
        @c2 = conversation(@bob, @billy, :workflow_state => 'unread', :subscribed => false) # manually specified context which would not be implied
        course_with_student(:course_name => 'the other course')
        conversation = @c2.conversation
        conversation.context = @course
        conversation.save!
        @c2.save!
        @c3 = conversation(@student) # no context
        @user = @me
      end

      describe 'index' do
        it "should prefer the context but fall back to the first context tag" do
          json = api_call(:get, "/api/v1/conversations.json",
                          { :controller => 'conversations', :action => 'index', :format => 'json' })
          expect(json.map{|c| c["context_name"]}).to eql([nil, 'the other course', 'the course'])
        end
      end

      describe 'show' do
        it "should prefer the context but fall back to the first context tag" do
          json = api_call(:get, "/api/v1/conversations/#{@c1.conversation.id}",
                          { :controller => 'conversations', :action => 'show', :id => @c1.conversation.id.to_s, :format => 'json' })
          expect(json["context_name"]).to eql('the course')
          json = api_call(:get, "/api/v1/conversations/#{@c2.conversation.id}",
                          { :controller => 'conversations', :action => 'show', :id => @c2.conversation.id.to_s, :format => 'json' })
          expect(json["context_name"]).to eql('the other course')
          json = api_call(:get, "/api/v1/conversations/#{@c3.conversation.id}",
                          { :controller => 'conversations', :action => 'show', :id => @c3.conversation.id.to_s, :format => 'json' })
          expect(json["context_name"]).to be_nil
        end
      end
    end

    context "filtering by tags" do
      specs_require_sharding

      before :once do
        @conversations = []
      end

      def verify_filter(filter)
        @user = @me
        json = api_call(:get, "/api/v1/conversations.json?filter=#{filter}",
                { :controller => 'conversations', :action => 'index', :format => 'json', :filter => filter })
        expect(json.size).to eq @conversations.size
        expect(json.map{ |item| item["id"] }.sort).to eq @conversations.map(&:conversation_id).sort
      end

      context "tag context on default shard" do
        before :once do
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
        before :once do
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
        before :once do
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
        before :once do
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
        expect(json.size).to eql 3
        expect(json[0]['id']).to eql @c3.conversation_id
        expect(json[0]['last_message_at']).to eql expected_times[2].to_json[1, 20]
        expect(json[0]['last_message']).to eql 'test'

        # This is sometimes not updated. It's a known bug.
        #json[0]['last_authored_message_at'].should eql expected_times[2].to_json[1, 20]

        expect(json[0]['last_authored_message']).to eql 'test'

        expect(json[1]['id']).to eql @c2.conversation_id
        expect(json[1]['last_message_at']).to eql expected_times[4].to_json[1, 20]
        expect(json[1]['last_message']).to eql 'ohai'

        # This is sometimes not updated. It's a known bug.
        # json[1]['last_authored_message_at'].should eql expected_times[1].to_json[1, 20]

        expect(json[1]['last_authored_message']).to eql 'test'

        expect(json[2]['id']).to eql @c1.conversation_id
        expect(json[2]['last_message_at']).to eql expected_times[3].to_json[1, 20]
        expect(json[2]['last_message']).to eql 'ohai'

        # This is sometimes not updated. It's a known bug.
        # json[2]['last_authored_message_at'].should eql expected_times[0].to_json[1, 20]

        expect(json[2]['last_authored_message']).to eql 'test'
      end

      it "should include conversations with at least one message by the author, regardless of workflow_state" do
        @c1 = conversation(@bob)
        @c2 = conversation(@bob, @billy)
        @c2.conversation.add_message(@bob, 'ohai')
        @c2.remove_messages(@message) # delete my original message
        @c3 = conversation(@jane, :workflow_state => 'archived')

        json = api_call(:get, "/api/v1/conversations.json?scope=sent",
                { :controller => 'conversations', :action => 'index', :format => 'json', :scope => 'sent' })
        expect(json.size).to eql 2
        expect(json.map{ |c| c['id'] }.sort).to eql [@c1.conversation_id, @c3.conversation_id]
      end
    end

    it "should show the calculated audience_contexts if the tags have not been migrated yet" do
      @c1 = conversation(@bob, @billy)
      Conversation.update_all "tags = NULL"
      ConversationParticipant.update_all "tags = NULL"
      ConversationMessageParticipant.update_all "tags = NULL"

      expect(@c1.reload.tags).to be_empty
      expect(@c1.context_tags).to eql [@course.asset_string]

      json = api_call(:get, "/api/v1/conversations.json",
              { :controller => 'conversations', :action => 'index', :format => 'json' })
      expect(json.size).to eql 1
      expect(json.first["id"]).to eql @c1.conversation_id
      expect(json.first["audience_contexts"]).to eql({"groups" => {}, "courses" => {@course.id.to_s => []}})
    end

    it "should include starred conversations in starred scope regardless of if read or archived" do
      @c1 = conversation(@bob, :workflow_state => 'unread', :starred => true)
      @c2 = conversation(@billy, :workflow_state => 'read', :starred => true)
      @c3 = conversation(@jane, :workflow_state => 'archived', :starred => true)

      json = api_call(:get, "/api/v1/conversations.json?scope=starred",
              { :controller => 'conversations', :action => 'index', :format => 'json', :scope => 'starred' })
      expect(json.size).to eq 3
      expect(json.map{ |c| c["id"] }.sort).to eq [@c1, @c2, @c3].map{ |c| c.conversation_id }.sort
    end

    it "should not include unstarred conversations in starred scope regardless of if read or archived" do
      @c1 = conversation(@bob, :workflow_state => 'unread')
      @c2 = conversation(@billy, :workflow_state => 'read')
      @c3 = conversation(@jane, :workflow_state => 'archived')

      json = api_call(:get, "/api/v1/conversations.json?scope=starred",
              { :controller => 'conversations', :action => 'index', :format => 'json', :scope => 'starred' })
      expect(json).to be_empty
    end

    it "should mark all conversations as read" do
      @c1 = conversation(@bob, :workflow_state => 'unread')
      @c2 = conversation(@bob, @billy, :workflow_state => 'unread')
      @c3 = conversation(@jane, :workflow_state => 'archived')

      json = api_call(:post, "/api/v1/conversations/mark_all_as_read.json",
              { :controller => 'conversations', :action => 'mark_all_as_read', :format => 'json' })
      expect(json).to eql({})

      expect(@me.conversations.unread.size).to eql 0
      expect(@me.conversations.default.size).to eql 2
      expect(@me.conversations.archived.size).to eql 1
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
        json.each { |c| c.delete("last_authored_message_at") } # This is sometimes not updated. It's a known bug.
        conversation = @me.all_conversations.order("conversation_id DESC").first
        expect(json).to eql [
          {
            "id" => conversation.conversation_id,
            "subject" => nil,
            "workflow_state" => "read",
            "last_message" => nil,
            "last_message_at" => nil,
            "last_authored_message" => "test",
            # "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
            "message_count" => 1,
            "subscribed" => true,
            "private" => true,
            "starred" => false,
            "properties" => ["last_author"],
            "visible" => false,
            "context_code" => conversation.conversation.context_code,
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
        expect(conversation(@bob).conversation.context).to eql(@course)
      end

      describe "context is an account for admins validation" do
        it "should allow root account context if the user is an admin on that account" do
          account_admin_user active_all: true
          json = api_call(:post, "/api/v1/conversations",
                  { :controller => 'conversations', :action => 'create', :format => 'json' },
                  { :recipients => [@bob.id], :body => "test", :context_code => "account_#{Account.default.id}" })
          conv = Conversation.find(json.first['id'])
          expect(conv.context).to eq Account.default
        end

        it "should not allow account context if the user is not an admin in that account" do
          raw_api_call(:post, "/api/v1/conversations",
                  { :controller => 'conversations', :action => 'create', :format => 'json' },
                  { :recipients => [@bob.id], :body => "test", :context_code => "account_#{Account.default.id}" })
          assert_status(400)
        end

        it "should allow site admin to set any account context" do
          site_admin_user(name: "site admin", active_all: true)
          json = api_call(:post, "/api/v1/conversations",
                  { :controller => 'conversations', :action => 'create', :format => 'json' },
                  { :recipients => [@bob.id], :body => "test", :context_code => "account_#{Account.default.id}" })
          conv = Conversation.find(json.first['id'])
          expect(conv.context).to eq Account.default
        end

        context "sub-accounts" do
          before :once do
            @sub_account = Account.default.sub_accounts.build(name: "subby")
            @sub_account.root_account_id = Account.default.id
            @sub_account.save!
            account_admin_user(account: @sub_account, name: "sub admin", active_all: true)
          end

          it "should allow root account context if the user is an admin on a sub-account" do
            course_with_student(account: @sub_account, name: "sub student", active_all: true)
            @user = @admin
            json = api_call(:post, "/api/v1/conversations",
                    { :controller => 'conversations', :action => 'create', :format => 'json' },
                    { :recipients => [@student.id], :body => "test", :context_code => "account_#{Account.default.id}" })
            conv = Conversation.find(json.first['id'])
            expect(conv.context).to eq Account.default
          end

          it "should not allow non-root account context" do
            raw_api_call(:post, "/api/v1/conversations",
                    { :controller => 'conversations', :action => 'create', :format => 'json' },
                    { :recipients => [@bob.id], :body => "test", :context_code => "account_#{@sub_account.id}" })
            assert_status(400)
          end
        end
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
        json.each { |c| c.delete("last_authored_message_at") } # This is sometimes not updated. It's a known bug.
        conversation = @me.all_conversations.order("conversation_id DESC").first
        expect(json).to eql [
          {
            "id" => conversation.conversation_id,
            "subject" => nil,
            "workflow_state" => "read",
            "last_message" => nil,
            "last_message_at" => nil,
            "last_authored_message" => "test",
            # "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
            "message_count" => 1,
            "subscribed" => true,
            "private" => false,
            "starred" => false,
            "properties" => ["last_author"],
            "visible" => false,
            "context_code" => conversation.conversation.context_code,
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

      context "private conversations" do
        # set up a private conversation in advance
        before(:once) { @conversation = conversation(@bob) }

        it "should update the private conversation if it already exists" do
          conversation = @conversation
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
          json.each { |c| c.delete("last_authored_message_at") } # This is sometimes not updated. It's a known bug.
          expect(json).to eql [
            {
              "id" => conversation.conversation_id,
              "subject" => nil,
              "workflow_state" => "read",
              "last_message" => "test",
              "last_message_at" => conversation.last_message_at.to_json[1, 20],
              "last_authored_message" => "test",
              # "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
              "message_count" => 2, # two messages total now, though we'll only get the latest one in the response
              "subscribed" => true,
              "private" => true,
              "starred" => false,
              "properties" => ["last_author"],
              "visible" => true,
              "context_code" => conversation.conversation.context_code,
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
          json = api_call(:post, "/api/v1/conversations",
                  { :controller => 'conversations', :action => 'create', :format => 'json' },
                  { :recipients => [@bob.id, @joe.id, @billy.id], :body => "test" })
          expect(json.size).to eql 3
          expect(json.map{ |c| c['id'] }.sort).to eql @me.all_conversations.map(&:conversation_id).sort

          batch = ConversationBatch.first
          expect(batch).not_to be_nil
          expect(batch).to be_sent

          expect(@me.all_conversations.size).to eql(3)
          expect(@me.conversations.size).to eql(1) # just the initial conversation with bob is visible to @me
          expect(@bob.conversations.size).to eql(1)
          expect(@billy.conversations.size).to eql(1)
          expect(@joe.conversations.size).to eql(1)
        end

        it "should set the context on new synchronous bulk private conversations" do
          json = api_call(:post, "/api/v1/conversations",
                  { :controller => 'conversations', :action => 'create', :format => 'json' },
                  { :recipients => [@bob.id, @joe.id, @billy.id], :body => "test", :context_code => "course_#{@course.id}" })
          expect(json.size).to eql 3
          expect(json.map{ |c| c['id'] }.sort).to eql @me.all_conversations.map(&:conversation_id).sort

          batch = ConversationBatch.first
          expect(batch).not_to be_nil
          expect(batch).to be_sent

          [@me, @bob].each {|u| expect(u.conversations.first.conversation.context).to be_nil} # an existing conversation does not get a context
          [@billy, @joe].each {|u| expect(u.conversations.first.conversation.context).to eql(@course)}
        end

        it "should create/update bulk private conversations asynchronously" do
          json = api_call(:post, "/api/v1/conversations",
                  { :controller => 'conversations', :action => 'create', :format => 'json' },
                  { :recipients => [@bob.id, @joe.id, @billy.id], :body => "test", :mode => "async" })
          expect(json).to eql([])

          batch = ConversationBatch.first
          expect(batch).not_to be_nil
          expect(batch).to be_created
          batch.deliver

          expect(@me.all_conversations.size).to eql(3)
          expect(@me.conversations.size).to eql(1) # just the initial conversation with bob is visible to @me
          expect(@bob.conversations.size).to eql(1)
          expect(@billy.conversations.size).to eql(1)
          expect(@joe.conversations.size).to eql(1)
        end

        it "should set the context on new asynchronous bulk private conversations" do
          json = api_call(:post, "/api/v1/conversations",
                  { :controller => 'conversations', :action => 'create', :format => 'json' },
                  { :recipients => [@bob.id, @joe.id, @billy.id], :body => "test", :mode => "async", :context_code => "course_#{@course.id}" })
          expect(json).to eql([])

          batch = ConversationBatch.first
          expect(batch).not_to be_nil
          expect(batch).to be_created
          batch.deliver

         [@me, @bob].each {|u| expect(u.conversations.first.conversation.context).to be_nil} # an existing conversation does not get a context
          [@billy, @joe].each {|u| expect(u.conversations.first.conversation.context).to eql(@course)}
        end
      end

      it "should create a conversation with forwarded messages" do
        forwarded_message = conversation(@me, :sender => @bob).messages.first
        attachment = @me.conversation_attachments_folder.attachments.create!(:context => @me, :uploaded_data => stub_png_data)
        forwarded_message.attachments << attachment

        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@billy.id], :body => "test", :forwarded_message_ids => [forwarded_message.id] })
        json.each { |c| c.delete("last_authored_message_at") } # This is sometimes not updated. It's a known bug.
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
        conversation = @me.all_conversations.order(Conversation.nulls(:first, :last_message_at, :desc)).order("conversation_id DESC").first
        expected = [
          {
            "id" => conversation.conversation_id,
            "subject" => nil,
            "workflow_state" => "read",
            "last_message" => nil,
            "last_message_at" => nil,
            "last_authored_message" => "test",
            # "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
            "message_count" => 1,
            "subscribed" => true,
            "private" => true,
            "starred" => false,
            "properties" => ["last_author"],
            "visible" => false,
            "context_code" => conversation.conversation.context_code,
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
                          "attachments" => [{'filename' => attachment.filename,
                                             'url' => "http://www.example.com/files/#{attachment.id}/download?download_frd=1&verifier=#{attachment.uuid}",
                                             'content-type' => 'image/png',
                                             'display_name' => 'test my file? hai!&.png',
                                             'id' => attachment.id,
                                             'folder_id' => attachment.folder_id,
                                             'size' => attachment.size,
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
        expect(json).to eql expected
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
        json.each { |c| c.delete("last_authored_message_at") } # This is sometimes not updated. It's a known bug.
        conversation = @me.all_conversations.order("conversation_id DESC").first
        expect(json).to eql [
          {
            "id" => conversation.conversation_id,
            "subject" => "lunch",
            "workflow_state" => "read",
            "last_message" => nil,
            "last_message_at" => nil,
            "last_authored_message" => "test",
            # "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
            "message_count" => 1,
            "subscribed" => true,
            "private" => true,
            "starred" => false,
            "properties" => ["last_author"],
            "visible" => false,
            "context_code" => conversation.conversation.context_code,
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
        expect(json.size).to eql 2
        json.each { |c|
          expect(c["subject"]).to eql 'dinner'
        }
      end

      it "should constrain subject length" do
        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@bob.id], :body => "test", :subject => "a" * 256 },
                headers={},
                {expected_status: 400})
        expect(json["errors"]).not_to be_nil
        expect(json["errors"]["subject"]).not_to be_nil
      end

      it "respects course's send_messages_all permission" do
        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@bob.id, @course.asset_string], :body => "test", :subject => "hey erryone" },
                headers={},
                {expected_status: 400})
        expect(json[0]["attribute"]).to eql "recipients"
        expect(json[0]["message"]).to eql "restricted by role"
      end

      it "should send bulk group messages" do
        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@bob.id, @joe.id], :body => "test",
                  :group_conversation => "true", :bulk_message => "true" })
        expect(json.size).to eql 2
      end

      it "should send bulk group messages with a single recipient" do
        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@bob.id], :body => "test",
                  :group_conversation => "true", :bulk_message => "true" })
        expect(json.size).to eql 1
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
      json.delete("last_authored_message_at") # This is sometimes not updated. It's a known bug.
      expect(json).to eql({
        "id" => conversation.conversation_id,
        "subject" => nil,
        "workflow_state" => "read",
        "last_message" => "another",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "another",
        # "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
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
                "folder_id" => attachment.folder_id,
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
        "submissions" => [],
        "context_name" => conversation.context_name,
        "context_code" => conversation.conversation.context_code,
      })
    end

    it "should still include attachment verifiers when using session auth" do
      conversation = conversation(@bob)
      attachment = @me.conversation_attachments_folder.attachments.create!(:context => @me, :filename => 'test.txt', :display_name => "test.txt", :uploaded_data => StringIO.new('test'))
      message = conversation.add_message("another", :attachment_ids => [attachment.id], :media_comment => media_object)
      conversation.reload
      user_session(@user)
      get "/api/v1/conversations/#{conversation.conversation_id}"
      json = json_parse
      expect(json['messages'][0]['attachments'][0]['url']).to eq "http://www.example.com/files/#{attachment.id}/download?download_frd=1&verifier=#{attachment.uuid}"
    end

    it "should use participant's last_message_at and not consult the most recent message" do
      expected_lma = '2012-12-21T12:42:00Z'
      conversation = conversation(@bob)
      conversation.last_message_at = Time.zone.parse(expected_lma)
      conversation.save!
      conversation.add_message('another test', :update_for_sender => false)
      json = api_call(:get, "/api/v1/conversations/#{conversation.conversation_id}",
              { :controller => 'conversations', :action => 'show', :id => conversation.conversation_id.to_s, :format => 'json' })
      expect(json['last_message_at']).to eql expected_lma
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
        json.delete("last_authored_message_at") # This is sometimes not updated. It's a known bug.
        expected = {
          "id" => @conversation.conversation_id,
          "subject" => nil,
          "workflow_state" => "read",
          "last_message" => "test",
          "last_message_at" => @conversation.last_message_at.to_json[1, 20],
          "last_authored_message" => "test",
          # "last_authored_message_at" => @conversation.last_message_at.to_json[1, 20],
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
          "submissions" => [],
          "context_name" => @conversation.context_name,
          "context_code" => @conversation.conversation.context_code,
        }
        expect(json).to eq expected
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
      expect(json["visible"]).to be_falsey
      expect(conversation.reload).to be_read
    end

    it "should not auto-mark-as-read if auto_mark_as_read = false" do
      conversation = conversation(@bob, :workflow_state => 'unread')

      json = api_call(:get, "/api/v1/conversations/#{conversation.conversation_id}?scope=unread&auto_mark_as_read=0",
              { :controller => 'conversations', :action => 'show', :id => conversation.conversation_id.to_s, :scope => 'unread', :auto_mark_as_read => "0", :format => 'json' })
      expect(json["visible"]).to be_truthy
      expect(conversation.reload).to be_unread
    end

    it "should properly flag if starred in the response" do
      conversation1 = conversation(@bob)
      conversation2 = conversation(@billy, :starred => true)

      json = api_call(:get, "/api/v1/conversations/#{conversation1.conversation_id}",
              { :controller => 'conversations', :action => 'show', :id => conversation1.conversation_id.to_s, :format => 'json' })
      expect(json["starred"]).to be_falsey

      json = api_call(:get, "/api/v1/conversations/#{conversation2.conversation_id}",
              { :controller => 'conversations', :action => 'show', :id => conversation2.conversation_id.to_s, :format => 'json' })
      expect(json["starred"]).to be_truthy
    end

    it "should not link submission comments and conversations anymore" do
      submission1 = submission_model(:course => @course, :user => @bob)
      submission2 = submission_model(:course => @course, :user => @bob)
      conversation(@bob)
      submission1.add_comment(:comment => "hey bob", :author => @me)
      submission1.add_comment(:comment => "wut up teacher", :author => @bob)
      submission2.add_comment(:comment => "my name is bob", :author => @bob)

      json = api_call(:get, "/api/v1/conversations/#{@conversation.conversation_id}",
                      { :controller => 'conversations', :action => 'show', :id => @conversation.conversation_id.to_s, :format => 'json' })

      expect(json['messages'].size).to eq 1
      expect(json['submissions'].size).to eq 0
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
      json.delete("last_authored_message_at") # This is sometimes not updated. It's a known bug.
      expect(json).to eql({
        "id" => conversation.conversation_id,
        "subject" => nil,
        "workflow_state" => "read",
        "last_message" => "another",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "another",
        # "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
        "message_count" => 2, # two messages total now, though we'll only get the latest one in the response
        "subscribed" => true,
        "private" => true,
        "starred" => false,
        "properties" => ["last_author"],
        "visible" => true,
        "context_code" => conversation.conversation.context_code,
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

    it "should only add participants for the new message to the given recipients" do
      conversation = conversation(@bob, private: false)

      json = api_call(:post, "/api/v1/conversations/#{conversation.conversation_id}/add_message",
              { :controller => 'conversations', :action => 'add_message', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :body => "another", :recipients => [@billy.id]})
      conversation.reload
      json.delete("avatar_url")
      json["participants"].each{ |p|
        p.delete("avatar_url")
      }
      json["audience"].sort!
      json["messages"].each {|m| m["participating_user_ids"].sort!}
      json.delete("last_authored_message_at") # This is sometimes not updated. It's a known bug.
      expect(json).to eql({
        "id" => conversation.conversation_id,
        "subject" => nil,
        "workflow_state" => "read",
        "last_message" => "another",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "another",
        # "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
        "message_count" => 2, # two messages total now, though we'll only get the latest one in the response
        "subscribed" => true,
        "private" => false,
        "starred" => false,
        "properties" => ["last_author"],
        "visible" => true,
        "context_code" => conversation.conversation.context_code,
        "audience" => [@bob.id, @billy.id].sort,
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
          {"id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "another", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => [], "participating_user_ids" => [@me.id, @billy.id].sort}
        ]
      })
    end

    it "should add participants for the given messages to the given recipients" do
      conversation = conversation(@bob, private: false)
      message = conversation.add_message("another one")

      json = api_call(:post, "/api/v1/conversations/#{conversation.conversation_id}/add_message",
              { :controller => 'conversations', :action => 'add_message', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :body => "partially hydrogenated context oils", :recipients => [@billy.id], :included_messages => [message.id]})
      conversation.reload
      json.delete("avatar_url")
      json["participants"].each{ |p|
        p.delete("avatar_url")
      }
      json["audience"].sort!
      json["messages"].each {|m| m["participating_user_ids"].sort!}
      json.delete("last_authored_message_at") # This is sometimes not updated. It's a known bug.
      expect(json).to eql({
        "id" => conversation.conversation_id,
        "subject" => nil,
        "workflow_state" => "read",
        "last_message" => "partially hydrogenated context oils",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "partially hydrogenated context oils",
        # "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
        "message_count" => 3,
        "subscribed" => true,
        "private" => false,
        "starred" => false,
        "properties" => ["last_author"],
        "visible" => true,
        "context_code" => conversation.conversation.context_code,
        "audience" => [@bob.id, @billy.id].sort,
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
          {"id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "partially hydrogenated context oils", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => [], "participating_user_ids" => [@me.id, @billy.id].sort}
        ]
      })
      message.reload
      expect(message.conversation_message_participants.where(:user_id => @billy.id).exists?).to be_truthy
    end

    it "should exclude participants that aren't in the recipient list" do
      conversation = conversation(@bob, @billy, private: false)
      message = conversation.add_message("another one")

      json = api_call(:post, "/api/v1/conversations/#{conversation.conversation_id}/add_message",
              { :controller => 'conversations', :action => 'add_message', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :body => "partially hydrogenated context oils", :recipients => [@billy.id], :included_messages => [message.id]})
      conversation.reload
      json.delete("last_authored_message_at") # This is sometimes not updated. It's a known bug.
      json.delete("avatar_url")
      json["participants"].each{ |p|
        p.delete("avatar_url")
      }
      json["audience"].sort!
      json["messages"].each {|m| m["participating_user_ids"].sort!}
      expect(json).to eql({
        "id" => conversation.conversation_id,
        "subject" => nil,
        "workflow_state" => "read",
        "last_message" => "partially hydrogenated context oils",
        # "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "partially hydrogenated context oils",
        "message_count" => 3,
        "subscribed" => true,
        "private" => false,
        "starred" => false,
        "properties" => ["last_author"],
        "visible" => true,
        "context_code" => conversation.conversation.context_code,
        "audience" => [@bob.id, @billy.id].sort,
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
          {"id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "partially hydrogenated context oils", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => [], "participating_user_ids" => [@me.id, @billy.id].sort}
        ]
      })
      message.reload
      expect(message.conversation_message_participants.where(:user_id => @billy.id).exists?).to be_truthy
    end

    it "should add message participants for all conversation participants (if recipients are not specified) to included messages only" do
      conversation = conversation(@bob, private: false)
      message = conversation.add_message("you're swell, @bob")

      json = api_call(:post, "/api/v1/conversations/#{conversation.conversation_id}/add_message",
              { :controller => 'conversations', :action => 'add_message', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :body => "man, @bob sure does suck", :recipients => [@billy.id] })
      # at this point, @billy can see ^^^ that message, but not the first one. @bob can't see ^^^ that one. everyone is a conversation participant now
      conversation.reload
      bob_sucks = conversation.conversation.conversation_messages.first

      # implicitly send to all the conversation participants, including the original message. this will let @billy see it
      json = api_call(:post, "/api/v1/conversations/#{conversation.conversation_id}/add_message",
              { :controller => 'conversations', :action => 'add_message', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :body => "partially hydrogenated context oils", :included_messages => [message.id]})
      conversation.reload
      json.delete("avatar_url")
      json["participants"].each{ |p|
        p.delete("avatar_url")
      }
      json["audience"].sort!
      json.delete("last_authored_message_at") # This is sometimes not updated. It's a known bug.
      json["messages"].each {|m| m["participating_user_ids"].sort!}
      expect(json).to eql({
        "id" => conversation.conversation_id,
        "subject" => nil,
        "workflow_state" => "read",
        "last_message" => "partially hydrogenated context oils",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "partially hydrogenated context oils",
        # "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
        "message_count" => 4,
        "subscribed" => true,
        "private" => false,
        "starred" => false,
        "properties" => ["last_author"],
        "visible" => true,
        "context_code" => conversation.conversation.context_code,
        "audience" => [@bob.id, @billy.id].sort,
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
          {"id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "partially hydrogenated context oils", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => [], "participating_user_ids" => [@me.id, @bob.id, @billy.id].sort}
        ]
      })
      message.reload
      expect(message.conversation_message_participants.where(:user_id => @billy.id).exists?).to be_truthy
      bob_sucks.reload
      expect(bob_sucks.conversation_message_participants.where(:user_id => @billy.id).exists?).to be_truthy
      expect(bob_sucks.conversation_message_participants.where(:user_id => @bob.id).exists?).to be_falsey
    end

    it "should allow users to respond to admin initiated conversations" do
      account_admin_user active_all: true
      cp = conversation(@other, sender: @admin, private: false)
      real_conversation = cp.conversation
      real_conversation.context = Account.default
      real_conversation.save!

      @user = @other
      json = api_call(:post, "/api/v1/conversations/#{real_conversation.id}/add_message",
        { :controller => 'conversations', :action => 'add_message', :id => real_conversation.id.to_s, :format => 'json' },
        { :body => "ok", :recipients => [@admin.id.to_s] })
      real_conversation.reload
      new_message = real_conversation.conversation_messages.first
      expect(new_message.conversation_message_participants.size).to eq 2
    end

    it "should allow users to respond to anyone who is already a participant" do
      cp = conversation(@bob, @billy, @jane, @joe, sender: @bob)
      real_conversation = cp.conversation
      real_conversation.context = @course
      real_conversation.save!

      @joe.enrollments.each { |e| e.destroy }
      @user = @billy
      json = api_call(:post, "/api/v1/conversations/#{real_conversation.id}/add_message",
        { :controller => 'conversations', :action => 'add_message', :id => real_conversation.id.to_s, :format => 'json' },
        { :body => "ok", :recipients => [@bob, @billy, @jane, @joe].map(&:id).map(&:to_s) })
      real_conversation.reload
      new_message = real_conversation.conversation_messages.first
      expect(new_message.conversation_message_participants.size).to eq 4
    end

    it "should create a media object if it doesn't exist" do
      conversation = conversation(@bob)

      expect(MediaObject.count).to eql 0
      json = api_call(:post, "/api/v1/conversations/#{conversation.conversation_id}/add_message",
              { :controller => 'conversations', :action => 'add_message', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :body => "another", :media_comment_id => "asdf", :media_comment_type => "audio" })
      conversation.reload
      mjson = json["messages"][0]["media_comment"]
      expect(mjson).to be_present
      expect(mjson["media_id"]).to eql "asdf"
      expect(mjson["media_type"]).to eql "audio"
      expect(MediaObject.count).to eql 1
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
      json.delete("last_authored_message_at") # This is sometimes not updated. It's a known bug.
      expect(json).to eql({
        "id" => conversation.conversation_id,
        "subject" => nil,
        "workflow_state" => "read",
        "last_message" => "test",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "test",
        # "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
        "message_count" => 1,
        "subscribed" => true,
        "private" => false,
        "starred" => false,
        "properties" => ["last_author"],
        "context_code" => conversation.conversation.context_code,
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
      json.delete("last_authored_message_at") # This is sometimes not updated. It's a known bug.
      expect(json).to eql({
        "id" => conversation.conversation_id,
        "subject" => nil,
        "workflow_state" => "archived",
        "last_message" => "test",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "test",
        # "last_authored_message_at" => conversation.last_authored_at.to_json[1, 20],
        "message_count" => 1,
        "subscribed" => false,
        "private" => false,
        "starred" => false,
        "properties" => ["last_author"],
        "visible" => false, # since we archived it, and the default view is assumed
        "context_code" => conversation.conversation.context_code,
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
      expect(json["starred"]).to be_truthy
    end

    it "should be able to unstar the conversation via update" do
      conversation = conversation(@bob, @billy, :starred => true)

      json = api_call(:put, "/api/v1/conversations/#{conversation.conversation_id}",
              { :controller => 'conversations', :action => 'update', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :conversation => {:starred => false} })
      expect(json["starred"]).to be_falsey
    end

    it "should leave starryness alone when left out of update" do
      conversation = conversation(@bob, @billy, :starred => true)

      json = api_call(:put, "/api/v1/conversations/#{conversation.conversation_id}",
              { :controller => 'conversations', :action => 'update', :id => conversation.conversation_id.to_s, :format => 'json' },
              { :conversation => {:workflow_state => 'read'} })
      expect(json["starred"]).to be_truthy
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
      json.delete("last_authored_message_at") # This is sometimes not updated. It's a known bug.

      expect(json).to eql({
        "id" => conversation.conversation_id,
        "subject" => nil,
        "workflow_state" => "read",
        "last_message" => "test",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "test",
        # "last_authored_message_at" => conversation.last_authored_message.created_at.to_json[1, 20],
        "message_count" => 1,
        "subscribed" => true,
        "private" => true,
        "starred" => false,
        "properties" => ["last_author"],
        "visible" => true,
        "context_code" => conversation.conversation.context_code,
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
      expect(json).to eql({
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
        "context_code" => conversation.conversation.context_code,
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
    before :once do
      @group = @course.groups.create(:name => "the group")
      @group.users = [@me, @bob, @joe]
    end

    it "should support the deprecated route" do
      json = api_call(:get, "/api/v1/conversations/find_recipients.json?search=o",
              { :controller => 'search', :action => 'recipients', :format => 'json', :search => 'o' })
      json.each { |c| c.delete("avatar_url") }
      expect(json).to eql [
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

      expect(json.size).to eql 1 # batch2 already ran, batch3 belongs to someone else
      expect(json[0]["id"]).to eql batch1.id
    end
  end

  describe "visibility inference" do
    it "should not break with empty string as filter" do
      # added for 1.9.3
      json = api_call(:post, "/api/v1/conversations",
              { :controller => 'conversations', :action => 'create', :format => 'json' },
              { :recipients => [@bob.id], :body => 'Test Message', :filter => '' })
      expect(json.first['visible']).to be_falsey
    end
  end

  describe "bulk updates" do
    let_once(:c1) { conversation(@me, @bob, :workflow_state => 'unread') }
    let_once(:c2) { conversation(@me, @jane, :workflow_state => 'read') }
    let_once(:conversation_ids) { [c1,c2].map {|c| c.conversation.id} }

    it "should mark conversations as read" do
      json = api_call(:put, "/api/v1/conversations",
        { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
        { :event => 'mark_as_read', :conversation_ids => conversation_ids })
      run_jobs
      progress = Progress.find(json['id'])
      expect(progress.message.to_s).to include "#{conversation_ids.size} conversations processed"
      expect(c1.reload).to be_read
      expect(c2.reload).to be_read
      expect(@me.reload.unread_conversations_count).to eql(0)
    end

    it "should mark conversations as unread" do
      json = api_call(:put, "/api/v1/conversations",
        { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
        { :event => 'mark_as_unread', :conversation_ids => conversation_ids })
      run_jobs
      progress = Progress.find(json['id'])
      expect(progress.message.to_s).to include "#{conversation_ids.size} conversations processed"
      expect(c1.reload).to be_unread
      expect(c2.reload).to be_unread
      expect(@me.reload.unread_conversations_count).to eql(2)
    end

    it "should mark conversations as starred" do
      c1.update_attribute :starred, true

      json = api_call(:put, "/api/v1/conversations",
        { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
        { :event => 'star', :conversation_ids => conversation_ids })
      run_jobs
      progress = Progress.find(json['id'])
      expect(progress.message.to_s).to include "#{conversation_ids.size} conversations processed"
      expect(c1.reload.starred).to be_truthy
      expect(c2.reload.starred).to be_truthy
      expect(@me.reload.unread_conversations_count).to eql(1)
    end

    it "should mark conversations as unstarred" do
      c1.update_attribute :starred, true

      json = api_call(:put, "/api/v1/conversations",
        { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
        { :event => 'unstar', :conversation_ids => conversation_ids })
      run_jobs
      progress = Progress.find(json['id'])
      expect(progress.message.to_s).to include "#{conversation_ids.size} conversations processed"
      expect(c1.reload.starred).to be_falsey
      expect(c2.reload.starred).to be_falsey
      expect(@me.reload.unread_conversations_count).to eql(1)
    end

    # it "should mark conversations as subscribed"
    # it "should mark conversations as unsubscribed"
    it "should archive conversations" do
      conversations = %w(archived read unread).map do |state|
        conversation(@me, @bob, :workflow_state => state)
      end
      expect(@me.reload.unread_conversations_count).to eql(1)

      conversation_ids = conversations.map {|c| c.conversation.id}
      json = api_call(:put, "/api/v1/conversations",
        { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
        { :event => 'archive', :conversation_ids => conversation_ids })
      run_jobs
      progress = Progress.find(json['id'])
      expect(progress.message.to_s).to include "#{conversation_ids.size} conversations processed"
      conversations.each do |c|
        expect(c.reload).to be_archived
      end
      expect(@me.reload.unread_conversations_count).to eql(0)
    end

    it "should destroy conversations" do
      json = api_call(:put, "/api/v1/conversations",
        { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
        { :event => 'destroy', :conversation_ids => conversation_ids })
      run_jobs
      progress = Progress.find(json['id'])
      expect(progress.message.to_s).to include "#{conversation_ids.size} conversations processed"
      expect(c1.reload.messages).to be_empty
      expect(c2.reload.messages).to be_empty
      expect(@me.reload.unread_conversations_count).to eql(0)
    end

    describe "immediate failures" do
      it "should fail if event is invalid" do
        json = api_call(:put, "/api/v1/conversations",
          { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
          { :event => 'NONSENSE', :conversation_ids => conversation_ids },
          {}, {:expected_status => 400})

        expect(json['message']).to include 'invalid event'
      end

      it "should fail if event parameter is not specified" do
        json = api_call(:put, "/api/v1/conversations",
          { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
          { :conversation_ids => conversation_ids },
          {}, {:expected_status => 400})

        expect(json['message']).to include 'event not specified'
      end

      it "should fail if conversation_ids is not specified" do
        json = api_call(:put, "/api/v1/conversations",
          { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
          { :event => 'mark_as_read' },
          {}, {:expected_status => 400})

        expect(json['message']).to include 'conversation_ids not specified'
      end

      it "should fail if batch size limit is exceeded" do
        conversation_ids = (1..501).to_a
        json = api_call(:put, "/api/v1/conversations",
          { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
          { :event => 'mark_as_read', :conversation_ids => conversation_ids },
          {}, {:expected_status => 400})
        expect(json['message']).to include 'exceeded'
      end
    end

    describe "progress" do
      it "should create and update a progress object" do
        json = api_call(:put, "/api/v1/conversations",
          { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
          { :event => 'mark_as_read', :conversation_ids => conversation_ids })
        progress = Progress.find(json['id'])
        expect(progress).to be_present
        expect(progress).to be_queued
        expect(progress.completion).to eql(0.0)
        run_jobs
        expect(progress.reload).to be_completed
        expect(progress.completion).to eql(100.0)
      end

      describe "progress failures" do
        it "should not update conversations the current user does not participate in" do
          c3 = conversation(@bob, @jane, :sender => @bob, :workflow_state => 'unread')
          conversation_ids = [c1,c2,c3].map {|c| c.conversation.id}

          json = api_call(:put, "/api/v1/conversations",
            { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
            { :event => 'mark_as_read', :conversation_ids => conversation_ids })
          run_jobs
          progress = Progress.find(json['id'])
          expect(progress).to be_completed
          expect(progress.completion).to eql(100.0)
          expect(c1.reload).to be_read
          expect(c2.reload).to be_read
          expect(c3.reload).to be_unread
          expect(progress.message).to include 'not participating'
          expect(progress.message).to include '2 conversations processed'
        end

        it "should fail if all conversation ids are invalid" do
          c1 = conversation(@bob, @jane, :sender => @bob, :workflow_state => 'unread')
          conversation_ids = [c1.conversation.id]

          json = api_call(:put, "/api/v1/conversations",
            { :controller => 'conversations', :action => 'batch_update', :format => 'json' },
            { :event => 'mark_as_read', :conversation_ids => conversation_ids })

          run_jobs
          progress = Progress.find(json['id'])
          expect(progress).to be_failed
          expect(progress.completion).to eql(100.0)
          expect(c1.reload).to be_unread
          expect(progress.message).to include 'not participating'
          expect(progress.message).to include '0 conversations processed'
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
            expect(progress).to be_failed
            expect(progress.message).to include 'crazy exception'
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
      expect(@joe.conversations.size).to eql 1

      account_admin_user_with_role_changes(:account => Account.site_admin, :role_changes => { :become_user => false })
      json = raw_api_call(:delete, "/api/v1/conversations/#{conv.id}/delete_for_all",
        {:controller => 'conversations', :action => 'delete_for_all', :format => 'json', :id => conv.id.to_s},
        {:domain_root_account => Account.site_admin})
      assert_status(401)

      account_admin_user
      p = Account.default.pseudonyms.create!(:unique_id => 'admin', :user => @user)
      json = raw_api_call(:delete, "/api/v1/conversations/#{conv.id}/delete_for_all",
        {:controller => 'conversations', :action => 'delete_for_all', :format => 'json', :id => conv.id.to_s},
        {})
      assert_status(401)

      @user = @me
      json = raw_api_call(:delete, "/api/v1/conversations/#{conv.id}/delete_for_all",
        {:controller => 'conversations', :action => 'delete_for_all', :format => 'json', :id => conv.id.to_s},
        {})
      assert_status(401)

      expect(@me.all_conversations.size).to eql 1
      expect(@joe.conversations.size).to eql 1
    end

    it "should fail if conversation doesn't exist" do
      site_admin_user
      json = raw_api_call(:delete, "/api/v1/conversations/0/delete_for_all",
        {:controller => 'conversations', :action => 'delete_for_all', :format => 'json', :id => "0"},
        {})
      assert_status(404)
    end

    it "should delete the conversation for all participants" do
      users = [@me, @bob, @billy, @jane, @joe, @tommy]
      cp = conversation(*users)
      conv = cp.conversation
      users.each do |user|
        expect(user.all_conversations.size).to eql 1
        expect(user.stream_item_instances.size).to eql 1 unless user.id == @me.id
      end

      site_admin_user
      json = api_call(:delete, "/api/v1/conversations/#{conv.id}/delete_for_all",
        {:controller => 'conversations', :action => 'delete_for_all', :format => 'json', :id => conv.id.to_s},
        {})

      expect(json).to eql({})

      users.each do |user|
        expect(user.reload.all_conversations.size).to eql 0
        expect(user.stream_item_instances.size).to eql 0
      end
      expect(ConversationParticipant.count).to eql 0
      expect(ConversationMessageParticipant.count).to eql 0
      # should leave the conversation and its message in the database
      expect(Conversation.count).to eql 1
      expect(ConversationMessage.count).to eql 1 
    end

    context "sharding" do
      specs_require_sharding

      it "should delete the conversation for users on multiple shards" do
        users = [@me]
        users << @shard1.activate { User.create! }

        cp = conversation(*users)
        conv = cp.conversation
        users.each do |user|
          expect(user.all_conversations.size).to eql 1
          expect(user.stream_item_instances.size).to eql 1 unless user.id == @me.id
        end

        site_admin_user
        @shard2.activate do
          json = api_call(:delete, "/api/v1/conversations/#{conv.id}/delete_for_all",
                          {:controller => 'conversations', :action => 'delete_for_all', :format => 'json', :id => conv.id.to_s},
                          {})

          expect(json).to eql({})
        end

        users.each do |user|
          expect(user.reload.all_conversations.size).to eql 0
          expect(user.stream_item_instances.size).to eql 0
        end
        expect(ConversationParticipant.count).to eql 0
        expect(ConversationMessageParticipant.count).to eql 0
        # should leave the conversation and its message in the database
        expect(Conversation.count).to eql 1
        expect(ConversationMessage.count).to eql 1
      end
    end
  end

  describe 'unread_count' do
    it 'should return the number of unread conversations for the current user' do
      conversation(student_in_course, :workflow_state => 'unread')
      json = api_call(:get, '/api/v1/conversations/unread_count.json',
                      {:controller => 'conversations', :action => 'unread_count', :format => 'json'})
      expect(json).to eql({'unread_count' => '1'})
    end
  end
  
end
