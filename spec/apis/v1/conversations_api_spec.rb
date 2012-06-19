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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

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
    u.associated_accounts << Account.default
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
      response.headers['Link'].should eql(%{</api/v1/conversations.json?scope=default&page=2&per_page=3>; rel="next",</api/v1/conversations.json?scope=default&page=1&per_page=3>; rel="first",</api/v1/conversations.json?scope=default&page=3&per_page=3>; rel="last"})

      # get the last page
      json = api_call(:get, "/api/v1/conversations.json?scope=default&page=3&per_page=3",
                      {:controller => 'conversations', :action => 'index', :format => 'json', :scope => 'default', :page => '3', :per_page => '3'})
      json.size.should eql 1
      response.headers['Link'].should eql(%{</api/v1/conversations.json?scope=default&page=2&per_page=3>; rel="prev",</api/v1/conversations.json?scope=default&page=1&per_page=3>; rel="first",</api/v1/conversations.json?scope=default&page=3&per_page=3>; rel="last"})
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
        @c2.remove_messages([@message]) # delete my original message
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
        conversation = @me.conversations.first
        json.should eql [
          {
            "id" => conversation.conversation_id,
            "workflow_state" => "read",
            "last_message" => "test",
            "last_message_at" => conversation.last_message_at.to_json[1, 20],
            "last_authored_message" => "test",
            "last_authored_message_at" => conversation.last_message_at.to_json[1, 20],
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
              {"id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "test", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => []}
            ]
          }
        ]
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
        conversation = @me.conversations.first
        json.should eql [
          {
            "id" => conversation.conversation_id,
            "workflow_state" => "read",
            "last_message" => "test",
            "last_message_at" => conversation.last_message_at.to_json[1, 20],
            "last_authored_message" => "test",
            "last_authored_message_at" => conversation.last_message_at.to_json[1, 20],
            "message_count" => 1,
            "subscribed" => true,
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
              {"id" => @me.id, "name" => @me.name, "common_courses" => {}, "common_groups" => {}},
              {"id" => @billy.id, "name" => @billy.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
              {"id" => @bob.id, "name" => @bob.name, "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
            ],
            "messages" => [
              {"id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "test", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => []}
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
        json.should eql [
          {
            "id" => conversation.conversation_id,
            "workflow_state" => "read",
            "last_message" => "test",
            "last_message_at" => conversation.last_message_at.to_json[1, 20],
            "last_authored_message" => "test",
            "last_authored_message_at" => conversation.last_message_at.to_json[1, 20],
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
              {"id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "test", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => []}
            ]
          }
        ]
      end

      it "should create/update bulk private conversations" do
        # set up one private conversation in advance
        conversation(@bob)

        json = api_call(:post, "/api/v1/conversations",
                { :controller => 'conversations', :action => 'create', :format => 'json' },
                { :recipients => [@bob.id, @joe.id, @billy.id], :body => "test" })
        json.size.should eql 3
        json.map{ |c| c['id'] }.sort.should eql @me.all_conversations.map(&:conversation_id).sort

        @me.all_conversations.size.should eql(3)
        @me.conversations.size.should eql(1) # just the initial conversation with bob is visible to @me
        @bob.conversations.size.should eql(1)
        @billy.conversations.size.should eql(1)
        @joe.conversations.size.should eql(1)
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
        conversation = @me.conversations.first
        json.should eql [
          {
            "id" => conversation.conversation_id,
            "workflow_state" => "read",
            "last_message" => "test",
            "last_message_at" => conversation.last_message_at.to_json[1, 20],
            "last_authored_message" => "test",
            "last_authored_message_at" => conversation.last_message_at.to_json[1, 20],
            "message_count" => 1,
            "subscribed" => true,
            "private" => true,
            "starred" => false,
            "properties" => ["last_author"],
            "visible" => true,
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
                "id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "test", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "attachments" => [],
                "forwarded_messages" => [
                  {
                    "id" => forwarded_message.id, "created_at" => forwarded_message.created_at.to_json[1, 20], "body" => "test", "author_id" => @bob.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => [{'filename' => 'test my file? hai!&.png', 'url' => "http://www.example.com/files/#{attachment.id}/download?download_frd=1&verifier=#{attachment.uuid}", 'content-type' => 'image/png', 'display_name' => 'test my file? hai!&.png', 'id' => attachment.id, 'size' => attachment.size}]
                  }
                ]
              }
            ]
          }
        ]
      end
    end
  end

  context "find_recipients" do
    before do
      @group = @course.groups.create(:name => "the group")
      @group.users = [@me, @bob, @joe]
    end

    it "should return recipients" do
      json = api_call(:get, "/api/v1/conversations/find_recipients.json?search=o",
              { :controller => 'conversations', :action => 'find_recipients', :format => 'json', :search => 'o' })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {"id" => "course_#{@course.id}", "name" => "the course", "type" => "context", "user_count" => 6},
        {"id" => "section_#{@other_section.id}", "name" => "the other section", "type" => "context", "user_count" => 1, "context_name" => "the course"},
        {"id" => "section_#{@course.default_section.id}", "name" => "the section", "type" => "context", "user_count" => 5, "context_name" => "the course"},
        {"id" => "group_#{@group.id}", "name" => "the group", "type" => "context", "user_count" => 3, "context_name" => "the course"},
        {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {@group.id.to_s => ["Member"]}},
        {"id" => @joe.id, "name" => "joe", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {@group.id.to_s => ["Member"]}},
        {"id" => @me.id, "name" => @me.name, "common_courses" => {@course.id.to_s => ["TeacherEnrollment"]}, "common_groups" => {@group.id.to_s => ["Member"]}},
        {"id" => @tommy.id, "name" => "tommy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
      ]
    end

    it "should return recipients for a given course" do
      json = api_call(:get, "/api/v1/conversations/find_recipients.json?context=course_#{@course.id}",
              { :controller => 'conversations', :action => 'find_recipients', :format => 'json', :context => "course_#{@course.id}" })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {"id" => @billy.id, "name" => "billy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @jane.id, "name" => "jane", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @joe.id, "name" => "joe", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @me.id, "name" => @me.name, "common_courses" => {@course.id.to_s => ["TeacherEnrollment"]}, "common_groups" => {}},
        {"id" => @tommy.id, "name" => "tommy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}}
      ]
    end

    it "should return recipients for a given group" do
      json = api_call(:get, "/api/v1/conversations/find_recipients.json?context=group_#{@group.id}",
              { :controller => 'conversations', :action => 'find_recipients', :format => 'json', :context => "group_#{@group.id}" })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {"id" => @bob.id, "name" => "bob", "common_courses" => {}, "common_groups" => {@group.id.to_s => ["Member"]}},
        {"id" => @joe.id, "name" => "joe", "common_courses" => {}, "common_groups" => {@group.id.to_s => ["Member"]}},
        {"id" => @me.id, "name" => @me.name, "common_courses" => {}, "common_groups" => {@group.id.to_s => ["Member"]}}
      ]
    end

    it "should return recipients for a given section" do
      json = api_call(:get, "/api/v1/conversations/find_recipients.json?context=section_#{@course.default_section.id}",
              { :controller => 'conversations', :action => 'find_recipients', :format => 'json', :context => "section_#{@course.default_section.id}" })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {"id" => @billy.id, "name" => "billy", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @jane.id, "name" => "jane", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @joe.id, "name" => "joe", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {}},
        {"id" => @me.id, "name" => @me.name, "common_courses" => {@course.id.to_s => ["TeacherEnrollment"]}, "common_groups" => {}}
      ]
    end

    it "should return recipients found by id" do
      json = api_call(:get, "/api/v1/conversations/find_recipients?user_id=#{@bob.id}",
              { :controller => 'conversations', :action => 'find_recipients', :format => 'json', :user_id => @bob.id.to_s })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {@group.id.to_s => ["Member"]}},
      ]
    end

    it "should ignore other parameters when searching by id" do
      json = api_call(:get, "/api/v1/conversations/find_recipients?user_id=#{@bob.id}&search=asdf",
              { :controller => 'conversations', :action => 'find_recipients', :format => 'json', :user_id => @bob.id.to_s, :search => "asdf" })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {"id" => @bob.id, "name" => "bob", "common_courses" => {@course.id.to_s => ["StudentEnrollment"]}, "common_groups" => {@group.id.to_s => ["Member"]}},
      ]
    end

    it "should return recipients by id if contactable, or if a shared conversation is referenced" do
      other = User.create(:name => "other personage")
      json = api_call(:get, "/api/v1/conversations/find_recipients?user_id=#{other.id}",
              { :controller => 'conversations', :action => 'find_recipients', :format => 'json', :user_id => other.id.to_s })
      json.should == []
      # now they have a conversation in common
      c = Conversation.initiate([@user.id, other.id], true)
      json = api_call(:get, "/api/v1/conversations/find_recipients?user_id=#{other.id}",
              { :controller => 'conversations', :action => 'find_recipients', :format => 'json', :user_id => other.id.to_s })
      json.should == []
      # ... but it has to be explicity referenced via from_conversation_id
      json = api_call(:get, "/api/v1/conversations/find_recipients?user_id=#{other.id}&from_conversation_id=#{c.id}",
              { :controller => 'conversations', :action => 'find_recipients', :format => 'json', :user_id => other.id.to_s, :from_conversation_id => c.id.to_s })
      json.each { |c| c.delete("avatar_url") }
      json.should eql [
        {"id" => other.id, "name" => "other personage", "common_courses" => {}, "common_groups" => {}},
      ]
    end

    context "synthetic contexts" do
      it "should return synthetic contexts within a course" do
        json = api_call(:get, "/api/v1/conversations/find_recipients.json?context=course_#{@course.id}&synthetic_contexts=1",
                { :controller => 'conversations', :action => 'find_recipients', :format => 'json', :context => "course_#{@course.id}", :synthetic_contexts => "1" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
          {"id" => "course_#{@course.id}_teachers", "name" => "Teachers", "type" => "context", "user_count" => 1},
          {"id" => "course_#{@course.id}_students", "name" => "Students", "type" => "context", "user_count" => 5},
          {"id" => "course_#{@course.id}_sections", "name" => "Course Sections", "type" => "context", "item_count" => 2},
          {"id" => "course_#{@course.id}_groups", "name" => "Student Groups", "type" => "context", "item_count" => 1}
        ]
      end

      it "should return synthetic contexts within a section" do
        json = api_call(:get, "/api/v1/conversations/find_recipients.json?context=section_#{@course.default_section.id}&synthetic_contexts=1",
                { :controller => 'conversations', :action => 'find_recipients', :format => 'json', :context => "section_#{@course.default_section.id}", :synthetic_contexts => "1" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
          {"id" => "section_#{@course.default_section.id}_teachers", "name" => "Teachers", "type" => "context", "user_count" => 1},
          {"id" => "section_#{@course.default_section.id}_students", "name" => "Students", "type" => "context", "user_count" => 4}
        ]
      end

      it "should return groups within a course" do
        json = api_call(:get, "/api/v1/conversations/find_recipients.json?context=course_#{@course.id}_groups&synthetic_contexts=1",
                { :controller => 'conversations', :action => 'find_recipients', :format => 'json', :context => "course_#{@course.id}_groups", :synthetic_contexts => "1" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
          {"id" => "group_#{@group.id}", "name" => "the group", "type" => "context", "user_count" => 3}
        ]
      end

      it "should return sections within a course" do
        json = api_call(:get, "/api/v1/conversations/find_recipients.json?context=course_#{@course.id}_sections&synthetic_contexts=1",
                { :controller => 'conversations', :action => 'find_recipients', :format => 'json', :context => "course_#{@course.id}_sections", :synthetic_contexts => "1" })
        json.each { |c| c.delete("avatar_url") }
        json.should eql [
          {"id" => "section_#{@other_section.id}", "name" => @other_section.name, "type" => "context", "user_count" => 1},
          {"id" => "section_#{@course.default_section.id}", "name" => @course.default_section.name, "type" => "context", "user_count" => 5}
        ]
      end
    end

    context "pagination" do
      it "should not paginate if no type is specified" do
        # it's a synthetic result (we might a few of each type), making
        # pagination pretty tricksy. so we don't allow it
        4.times{ student_in_course(:name => "cletus") }

        json = api_call(:get, "/api/v1/conversations/find_recipients.json?search=cletus&per_page=3",
                        {:controller => 'conversations', :action => 'find_recipients', :format => 'json', :search => 'cletus', :per_page => '3'})
        json.size.should eql 3
        response.headers['Link'].should be_nil
      end

      it "should paginate users and return proper pagination headers" do
        4.times{ student_in_course(:name => "cletus") }

        json = api_call(:get, "/api/v1/conversations/find_recipients.json?search=cletus&type=user&per_page=3",
                        {:controller => 'conversations', :action => 'find_recipients', :format => 'json', :search => 'cletus', :type => 'user', :per_page => '3'})
        json.size.should eql 3
        response.headers['Link'].should eql(%{</api/v1/conversations/find_recipients.json?search=cletus&type=user&page=2&per_page=3>; rel="next",</api/v1/conversations/find_recipients.json?search=cletus&type=user&page=1&per_page=3>; rel="first"})

        # get the next page
        json = api_call(:get, "/api/v1/conversations/find_recipients.json?search=cletus&type=user&page=2&per_page=3",
                        {:controller => 'conversations', :action => 'find_recipients', :format => 'json', :search => 'cletus', :type => 'user', :page => '2', :per_page => '3'})
        json.size.should eql 1
        response.headers['Link'].should eql(%{</api/v1/conversations/find_recipients.json?search=cletus&type=user&page=1&per_page=3>; rel="prev",</api/v1/conversations/find_recipients.json?search=cletus&type=user&page=1&per_page=3>; rel="first"})
      end

      it "should allow fetching all users iff a context is specified" do
        # for admins in particular, there may be *lots* of messageable users,
        # so we don't allow retrieval of all of them unless a context is given
        11.times{ student_in_course(:name => "cletus") }

        json = api_call(:get, "/api/v1/conversations/find_recipients.json?search=cletus&type=user&per_page=-1",
                        {:controller => 'conversations', :action => 'find_recipients', :format => 'json', :search => 'cletus', :type => 'user', :per_page => '-1'})
        json.size.should eql 10
        response.headers['Link'].should eql(%{</api/v1/conversations/find_recipients.json?search=cletus&type=user&page=2&per_page=10>; rel="next",</api/v1/conversations/find_recipients.json?search=cletus&type=user&page=1&per_page=10>; rel="first"})

        json = api_call(:get, "/api/v1/conversations/find_recipients.json?search=cletus&type=user&context=course_#{@course.id}&per_page=-1",
                        {:controller => 'conversations', :action => 'find_recipients', :format => 'json', :search => 'cletus', :context => "course_#{@course.id}", :type => 'user', :per_page => '-1'})
        json.size.should eql 11
        response.headers['Link'].should be_nil
      end

      it "should paginate contexts and return proper pagination headers" do
        4.times{
          course_with_teacher(:active_course => true, :active_enrollment => true, :user => @user)
          @course.update_attribute(:name, "ofcourse")
        }

        json = api_call(:get, "/api/v1/conversations/find_recipients.json?search=ofcourse&type=context&per_page=3",
                        {:controller => 'conversations', :action => 'find_recipients', :format => 'json', :search => 'ofcourse', :type => 'context', :per_page => '3'})
        json.size.should eql 3
        response.headers['Link'].should eql(%{</api/v1/conversations/find_recipients.json?search=ofcourse&type=context&page=2&per_page=3>; rel="next",</api/v1/conversations/find_recipients.json?search=ofcourse&type=context&page=1&per_page=3>; rel="first"})

        # get the next page
        json = api_call(:get, "/api/v1/conversations/find_recipients.json?search=ofcourse&type=context&page=2&per_page=3",
                        {:controller => 'conversations', :action => 'find_recipients', :format => 'json', :search => 'ofcourse', :type => 'context', :page => '2', :per_page => '3'})
        json.size.should eql 1
        response.headers['Link'].should eql(%{</api/v1/conversations/find_recipients.json?search=ofcourse&type=context&page=1&per_page=3>; rel="prev",</api/v1/conversations/find_recipients.json?search=ofcourse&type=context&page=1&per_page=3>; rel="first"})
      end

      it "should allow fetching all contexts" do
        4.times{
          course_with_teacher(:active_course => true, :active_enrollment => true, :user => @user)
          @course.update_attribute(:name, "ofcourse")
        }

        json = api_call(:get, "/api/v1/conversations/find_recipients.json?search=ofcourse&type=context&per_page=-1",
                        {:controller => 'conversations', :action => 'find_recipients', :format => 'json', :search => 'ofcourse', :type => 'context', :per_page => '-1'})
        json.size.should eql 4
        response.headers['Link'].should be_nil
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
      json.should eql({
        "id" => conversation.conversation_id,
        "workflow_state" => "read",
        "last_message" => "another",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "another",
        "last_authored_message_at" => conversation.last_message_at.to_json[1, 20],
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
              }
            ]
          },
          {"id" => conversation.messages.last.id, "created_at" => conversation.messages.last.created_at.to_json[1, 20], "body" => "test", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => []}
        ],
        "submissions" => []
      })
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
      json.should eql({
        "id" => conversation.conversation_id,
        "workflow_state" => "read",
        "last_message" => "another",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "another",
        "last_authored_message_at" => conversation.last_message_at.to_json[1, 20],
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
          {"id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "another", "author_id" => @me.id, "generated" => false, "media_comment" => nil, "forwarded_messages" => [], "attachments" => []}
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
      json.should eql({
        "id" => conversation.conversation_id,
        "workflow_state" => "read",
        "last_message" => "test",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "test",
        "last_authored_message_at" => conversation.last_message_at.to_json[1, 20],
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
          {"id" => conversation.messages.first.id, "created_at" => conversation.messages.first.created_at.to_json[1, 20], "body" => "jane, joe, and tommy were added to the conversation by nobody@example.com", "author_id" => @me.id, "generated" => true, "media_comment" => nil, "forwarded_messages" => [], "attachments" => []}
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
        "workflow_state" => "archived",
        "last_message" => "test",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "test",
        "last_authored_message_at" => conversation.last_message_at.to_json[1, 20],
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
        "workflow_state" => "read",
        "last_message" => "test",
        "last_message_at" => conversation.last_message_at.to_json[1, 20],
        "last_authored_message" => "test",
        "last_authored_message_at" => conversation.last_message_at.to_json[1, 20],
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
end
