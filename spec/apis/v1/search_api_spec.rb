# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../api_spec_helper"

describe SearchController, type: :request do
  before :once do
    @account = Account.default
    course_with_teacher(active_course: true, active_enrollment: true, user: user_with_pseudonym(active_user: true))
    @course.update_attribute(:name, "the course")
    @course.default_section.update(name: "the section")
    @other_section = @course.course_sections.create(name: "the other section")
    @me = @user

    @bob = student_in_course(name: "robert", short_name: "bob")
    @billy = student_in_course(name: "billy")
    @jane = student_in_course(name: "jane")
    @joe = student_in_course(name: "joe")
    @tommy = student_in_course(name: "tommy", section: @other_section)
  end

  def student_in_course(options = {})
    section = options.delete(:section)
    u = User.create(options)
    enrollment = @course.enroll_user(u, "StudentEnrollment", section:)
    enrollment.workflow_state = "active"
    enrollment.save
    u
  end

  context "recipients" do
    before :once do
      @group = @course.groups.create(name: "the group")
      @group.users = [@me, @bob, @joe]
    end

    it "returns recipients" do
      json = api_call(:get,
                      "/api/v1/search/recipients.json?search=o",
                      { controller: "search", action: "recipients", format: "json", search: "o" })
      json.each { |c| c.delete("avatar_url") }
      expect(json).to eql [
        { "id" => "course_#{@course.id}", "name" => "the course", "type" => "context", "user_count" => 6, "permissions" => {} },
        { "id" => "section_#{@other_section.id}", "name" => "the other section", "type" => "context", "user_count" => 1, "context_name" => "the course", "permissions" => {} },
        { "id" => "section_#{@course.default_section.id}", "name" => "the section", "type" => "context", "user_count" => 5, "context_name" => "the course", "permissions" => {} },
        { "id" => "group_#{@group.id}", "name" => "the group", "type" => "context", "user_count" => 3, "context_name" => "the course", "permissions" => {} },
        { "id" => @joe.id, "pronouns" => nil, "name" => "joe", "full_name" => "joe", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => { @group.id.to_s => ["Member"] } },
        { "id" => @me.id, "pronouns" => nil, "name" => @me.short_name, "full_name" => @me.name, "common_courses" => { @course.id.to_s => ["TeacherEnrollment"] }, "common_groups" => { @group.id.to_s => ["Member"] } },
        { "id" => @bob.id, "pronouns" => nil, "name" => "bob", "full_name" => "robert", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => { @group.id.to_s => ["Member"] } },
        { "id" => @tommy.id, "pronouns" => nil, "name" => "tommy", "full_name" => "tommy", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} }
      ]
    end

    it "returns recipients for a given course" do
      json = api_call(:get,
                      "/api/v1/search/recipients.json?context=course_#{@course.id}",
                      { controller: "search", action: "recipients", format: "json", context: "course_#{@course.id}" })
      json.each { |c| c.delete("avatar_url") }
      expect(json).to eql [
        { "id" => @billy.id, "pronouns" => nil, "name" => "billy", "full_name" => "billy", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
        { "id" => @jane.id, "pronouns" => nil, "name" => "jane", "full_name" => "jane", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
        { "id" => @joe.id, "pronouns" => nil, "name" => "joe", "full_name" => "joe", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
        { "id" => @me.id, "pronouns" => nil, "name" => @me.short_name, "full_name" => @me.name, "common_courses" => { @course.id.to_s => ["TeacherEnrollment"] }, "common_groups" => {} },
        { "id" => @bob.id, "pronouns" => nil, "name" => "bob", "full_name" => "robert", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
        { "id" => @tommy.id, "pronouns" => nil, "name" => "tommy", "full_name" => "tommy", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} }
      ]
    end

    it "returns recipients for a given group" do
      json = api_call(:get,
                      "/api/v1/search/recipients.json?context=group_#{@group.id}",
                      { controller: "search", action: "recipients", format: "json", context: "group_#{@group.id}" })
      json.each { |c| c.delete("avatar_url") }
      expect(json).to eql [
        { "id" => @joe.id, "pronouns" => nil, "name" => "joe", "full_name" => "joe", "common_courses" => {}, "common_groups" => { @group.id.to_s => ["Member"] } },
        { "id" => @me.id, "pronouns" => nil, "name" => @me.short_name, "full_name" => @me.name, "common_courses" => {}, "common_groups" => { @group.id.to_s => ["Member"] } },
        { "id" => @bob.id, "pronouns" => nil, "name" => "bob", "full_name" => "robert", "common_courses" => {}, "common_groups" => { @group.id.to_s => ["Member"] } }
      ]
    end

    it "does not duplicate group recipients if users are also in other groups" do
      @group2 = @course.groups.create(name: "another group")
      @group2.users = [@bob]
      @group2.save!

      json = api_call(:get,
                      "/api/v1/search/recipients.json?context=group_#{@group.id}",
                      { controller: "search", action: "recipients", format: "json", context: "group_#{@group.id}" })
      expect(json.pluck("id")).to match_array([@joe.id, @me.id, @bob.id])
    end

    it "returns recipients for a given section" do
      json = api_call(:get,
                      "/api/v1/search/recipients.json?context=section_#{@course.default_section.id}",
                      { controller: "search", action: "recipients", format: "json", context: "section_#{@course.default_section.id}" })
      json.each { |c| c.delete("avatar_url") }
      expect(json).to eql [
        { "id" => @billy.id, "pronouns" => nil, "name" => "billy", "full_name" => "billy", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
        { "id" => @jane.id, "pronouns" => nil, "name" => "jane", "full_name" => "jane", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
        { "id" => @joe.id, "pronouns" => nil, "name" => "joe", "full_name" => "joe", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
        { "id" => @me.id, "pronouns" => nil, "name" => @me.short_name, "full_name" => @me.name, "common_courses" => { @course.id.to_s => ["TeacherEnrollment"] }, "common_groups" => {} },
        { "id" => @bob.id, "pronouns" => nil, "name" => "bob", "full_name" => "robert", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} }
      ]
    end

    it "returns recipients found by id" do
      json = api_call(:get,
                      "/api/v1/search/recipients?user_id=#{@bob.id}",
                      { controller: "search", action: "recipients", format: "json", user_id: @bob.id.to_s })
      json.each { |c| c.delete("avatar_url") }
      expect(json).to eql [
        { "id" => @bob.id, "pronouns" => nil, "name" => "bob", "full_name" => "robert", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => { @group.id.to_s => ["Member"] } },
      ]
    end

    it "returns recipients found by sis id" do
      p = Pseudonym.create(account: @account, user: @bob, unique_id: "bob@example.com")
      p.sis_user_id = "abc123"
      p.save!
      json = api_call(:get,
                      "/api/v1/search/recipients?user_id=sis_user_id:abc123",
                      { controller: "search", action: "recipients", format: "json", user_id: "sis_user_id:abc123" })
      json.each { |c| c.delete("avatar_url") }
      expect(json).to eql [
        { "id" => @bob.id, "pronouns" => nil, "name" => "bob", "full_name" => "robert", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => { @group.id.to_s => ["Member"] } },
      ]
    end

    it "ignores other parameters when searching by id" do
      json = api_call(:get,
                      "/api/v1/search/recipients?user_id=#{@bob.id}&search=asdf",
                      { controller: "search", action: "recipients", format: "json", user_id: @bob.id.to_s, search: "asdf" })
      json.each { |c| c.delete("avatar_url") }
      expect(json).to eql [
        { "id" => @bob.id, "pronouns" => nil, "name" => "bob", "full_name" => "robert", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => { @group.id.to_s => ["Member"] } },
      ]
    end

    it "returns recipients by id if contactable, or if a shared conversation is referenced" do
      other = User.create(name: "other personage")
      json = api_call(:get,
                      "/api/v1/search/recipients?user_id=#{other.id}",
                      { controller: "search", action: "recipients", format: "json", user_id: other.id.to_s })
      expect(json).to eq []
      # now they have a conversation in common
      conversation = Conversation.initiate([@user, other], true)
      json = api_call(:get,
                      "/api/v1/search/recipients?user_id=#{other.id}",
                      { controller: "search", action: "recipients", format: "json", user_id: other.id.to_s })
      expect(json).to eq []
      # ... but it has to be explicity referenced via from_conversation_id
      json = api_call(:get,
                      "/api/v1/search/recipients?user_id=#{other.id}&from_conversation_id=#{conversation.id}",
                      { controller: "search", action: "recipients", format: "json", user_id: other.id.to_s, from_conversation_id: conversation.id.to_s })
      json.each { |c| c.delete("avatar_url") }
      expect(json).to eql [
        { "id" => other.id, "pronouns" => nil, "name" => "other personage", "full_name" => "other personage", "common_courses" => {}, "common_groups" => {} },
      ]
    end

    context "observers" do
      def observer_in_course(options = {})
        section = options.delete(:section)
        associated_user = options.delete(:associated_user)
        u = User.create(options)
        enrollment = @course.enroll_user(u, "ObserverEnrollment", section:)
        enrollment.associated_user = associated_user
        enrollment.workflow_state = "active"
        enrollment.save
        u
      end

      before :once do
        @bobs_mom = observer_in_course(name: "bob's mom", associated_user: @bob)
        @lonely = observer_in_course(name: "lonely observer")
      end

      it "shows all observers to a teacher" do
        json = api_call(:get,
                        "/api/v1/search/recipients.json?context=course_#{@course.id}",
                        { controller: "search", action: "recipients", format: "json", context: "course_#{@course.id}" })
        json.each { |c| c.delete("avatar_url") }
        expect(json).to eql [
          { "id" => @billy.id, "pronouns" => nil, "name" => "billy", "full_name" => "billy", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
          { "id" => @jane.id, "pronouns" => nil, "name" => "jane", "full_name" => "jane", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
          { "id" => @joe.id, "pronouns" => nil, "name" => "joe", "full_name" => "joe", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
          { "id" => @bobs_mom.id, "pronouns" => nil, "name" => "bob's mom", "full_name" => "bob's mom", "common_courses" => { @course.id.to_s => ["ObserverEnrollment"] }, "common_groups" => {} },
          { "id" => @me.id, "pronouns" => nil, "name" => @me.short_name, "full_name" => @me.name, "common_courses" => { @course.id.to_s => ["TeacherEnrollment"] }, "common_groups" => {} },
          { "id" => @lonely.id, "pronouns" => nil, "name" => "lonely observer", "full_name" => "lonely observer", "common_courses" => { @course.id.to_s => ["ObserverEnrollment"] }, "common_groups" => {} },
          { "id" => @bob.id, "pronouns" => nil, "name" => "bob", "full_name" => "robert", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
          { "id" => @tommy.id, "pronouns" => nil, "name" => "tommy", "full_name" => "tommy", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} }
        ]
      end

      it "does not show non-linked students to observers" do
        json = api_call_as_user(@bobs_mom,
                                :get,
                                "/api/v1/search/recipients.json?context=course_#{@course.id}",
                                { controller: "search", action: "recipients", format: "json", context: "course_#{@course.id}" })
        json.each { |c| c.delete("avatar_url") }
        expect(json).to eql [
          { "id" => @bobs_mom.id, "pronouns" => nil, "name" => "bob's mom", "full_name" => "bob's mom", "common_courses" => { @course.id.to_s => ["ObserverEnrollment"] }, "common_groups" => {} },
          { "id" => @me.id, "pronouns" => nil, "name" => @me.short_name, "full_name" => @me.name, "common_courses" => { @course.id.to_s => ["TeacherEnrollment"] }, "common_groups" => {} },
          { "id" => @bob.id, "pronouns" => nil, "name" => "bob", "full_name" => "robert", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} }
        ]

        json = api_call_as_user(@lonely,
                                :get,
                                "/api/v1/search/recipients.json?context=course_#{@course.id}",
                                { controller: "search", action: "recipients", format: "json", context: "course_#{@course.id}" })
        json.each { |c| c.delete("avatar_url") }
        expect(json).to eql [
          { "id" => @me.id, "pronouns" => nil, "name" => @me.short_name, "full_name" => @me.name, "common_courses" => { @course.id.to_s => ["TeacherEnrollment"] }, "common_groups" => {} },
          { "id" => @lonely.id, "pronouns" => nil, "name" => "lonely observer", "full_name" => "lonely observer", "common_courses" => { @course.id.to_s => ["ObserverEnrollment"] }, "common_groups" => {} }
        ]
      end

      it "does not show non-linked observers to students" do
        json = api_call_as_user(@bob,
                                :get,
                                "/api/v1/search/recipients.json?context=course_#{@course.id}",
                                { controller: "search", action: "recipients", format: "json", context: "course_#{@course.id}" })
        json.each { |c| c.delete("avatar_url") }
        expect(json).to eql [
          { "id" => @billy.id, "name" => "billy", "pronouns" => nil, "full_name" => "billy", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
          { "id" => @jane.id, "name" => "jane", "pronouns" => nil, "full_name" => "jane", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
          { "id" => @joe.id, "name" => "joe", "pronouns" => nil, "full_name" => "joe", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
          { "id" => @bobs_mom.id, "name" => "bob's mom", "pronouns" => nil, "full_name" => "bob's mom", "common_courses" => { @course.id.to_s => ["ObserverEnrollment"] }, "common_groups" => {} },
          # must not include lonely observer here
          { "id" => @me.id, "name" => @me.short_name, "full_name" => @me.name, "pronouns" => nil, "common_courses" => { @course.id.to_s => ["TeacherEnrollment"] }, "common_groups" => {} },
          { "id" => @bob.id, "name" => "bob", "full_name" => "robert", "pronouns" => nil, "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
          { "id" => @tommy.id, "name" => "tommy", "full_name" => "tommy", "pronouns" => nil, "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} }
        ]

        json = api_call_as_user(@billy,
                                :get,
                                "/api/v1/search/recipients.json?context=course_#{@course.id}",
                                { controller: "search", action: "recipients", format: "json", context: "course_#{@course.id}" })
        json.each { |c| c.delete("avatar_url") }
        expect(json).to eql [
          { "id" => @billy.id, "pronouns" => nil, "name" => "billy", "full_name" => "billy", "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
          # must not include bob's mom here
          { "id" => @jane.id, "name" => "jane", "full_name" => "jane", "pronouns" => nil, "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
          { "id" => @joe.id, "name" => "joe", "full_name" => "joe", "pronouns" => nil, "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
          # must not include lonely observer here
          { "id" => @me.id, "name" => @me.short_name, "pronouns" => nil, "full_name" => @me.name, "common_courses" => { @course.id.to_s => ["TeacherEnrollment"] }, "common_groups" => {} },
          { "id" => @bob.id, "name" => "bob", "full_name" => "robert", "pronouns" => nil, "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} },
          { "id" => @tommy.id, "name" => "tommy", "full_name" => "tommy", "pronouns" => nil, "common_courses" => { @course.id.to_s => ["StudentEnrollment"] }, "common_groups" => {} }
        ]
      end
    end

    context "synthetic contexts" do
      it "returns synthetic contexts within a course" do
        json = api_call(:get,
                        "/api/v1/search/recipients.json?context=course_#{@course.id}&synthetic_contexts=1",
                        { controller: "search", action: "recipients", format: "json", context: "course_#{@course.id}", synthetic_contexts: "1" })
        json.each { |c| c.delete("avatar_url") }
        expect(json).to eql [
          { "id" => "course_#{@course.id}_teachers", "name" => "Teachers", "type" => "context", "user_count" => 1, "permissions" => {} },
          { "id" => "course_#{@course.id}_students", "name" => "Students", "type" => "context", "user_count" => 5, "permissions" => {} },
          { "id" => "course_#{@course.id}_sections", "name" => "Course Sections", "type" => "context", "item_count" => 2 },
          { "id" => "course_#{@course.id}_groups", "name" => "Student Groups", "type" => "context", "item_count" => 1 }
        ]
      end

      it "returns synthetic contexts within a section" do
        json = api_call(:get,
                        "/api/v1/search/recipients.json?context=section_#{@course.default_section.id}&synthetic_contexts=1",
                        { controller: "search", action: "recipients", format: "json", context: "section_#{@course.default_section.id}", synthetic_contexts: "1" })
        json.each { |c| c.delete("avatar_url") }
        expect(json).to eql [
          { "id" => "section_#{@course.default_section.id}_teachers", "name" => "Teachers", "type" => "context", "user_count" => 1, "permissions" => {} },
          { "id" => "section_#{@course.default_section.id}_students", "name" => "Students", "type" => "context", "user_count" => 4, "permissions" => {} }
        ]
      end

      it "returns groups within a course" do
        json = api_call(:get,
                        "/api/v1/search/recipients.json?context=course_#{@course.id}_groups&synthetic_contexts=1",
                        { controller: "search", action: "recipients", format: "json", context: "course_#{@course.id}_groups", synthetic_contexts: "1" })
        json.each { |c| c.delete("avatar_url") }
        expect(json).to eql [
          { "id" => "group_#{@group.id}", "name" => "the group", "type" => "context", "user_count" => 3, "permissions" => {} }
        ]
      end

      it "returns sections within a course" do
        json = api_call(:get,
                        "/api/v1/search/recipients.json?context=course_#{@course.id}_sections&synthetic_contexts=1",
                        { controller: "search", action: "recipients", format: "json", context: "course_#{@course.id}_sections", synthetic_contexts: "1" })
        json.each { |c| c.delete("avatar_url") }
        expect(json).to eql [
          { "id" => "section_#{@other_section.id}", "name" => @other_section.name, "type" => "context", "user_count" => 1, "permissions" => {} },
          { "id" => "section_#{@course.default_section.id}", "name" => @course.default_section.name, "type" => "context", "user_count" => 5, "permissions" => {} }
        ]
      end
    end

    context "permissions" do
      it "returns valid permission data" do
        json = api_call(:get,
                        "/api/v1/search/recipients.json?search=the%20o&permissions[]=send_messages_all",
                        { controller: "search", action: "recipients", format: "json", search: "the o", permissions: ["send_messages_all"] })
        json.each { |c| c.delete("avatar_url") }
        expect(json).to eql [
          { "id" => "course_#{@course.id}", "name" => "the course", "type" => "context", "user_count" => 6, "permissions" => { "send_messages_all" => true } },
          { "id" => "section_#{@other_section.id}", "name" => "the other section", "type" => "context", "user_count" => 1, "context_name" => "the course", "permissions" => { "send_messages_all" => true } },
          { "id" => "section_#{@course.default_section.id}", "name" => "the section", "type" => "context", "user_count" => 5, "context_name" => "the course", "permissions" => { "send_messages_all" => true } },
          { "id" => "group_#{@group.id}", "name" => "the group", "type" => "context", "user_count" => 3, "context_name" => "the course", "permissions" => { "send_messages_all" => true } }
        ]
      end

      it "does not return invalid permission data" do
        json = api_call(:get,
                        "/api/v1/search/recipients.json?search=the%20o&permissions[]=foo_bar",
                        { controller: "search", action: "recipients", format: "json", search: "the o", permissions: ["foo_bar"] })
        json.each { |c| c.delete("avatar_url") }
        expect(json).to eql [
          { "id" => "course_#{@course.id}", "name" => "the course", "type" => "context", "user_count" => 6, "permissions" => {} },
          { "id" => "section_#{@other_section.id}", "name" => "the other section", "type" => "context", "user_count" => 1, "context_name" => "the course", "permissions" => {} },
          { "id" => "section_#{@course.default_section.id}", "name" => "the section", "type" => "context", "user_count" => 5, "context_name" => "the course", "permissions" => {} },
          { "id" => "group_#{@group.id}", "name" => "the group", "type" => "context", "user_count" => 3, "context_name" => "the course", "permissions" => {} }
        ]
      end
    end

    context "pagination" do
      it "paginates even if no type is specified" do
        create_users_in_course(@course, Array.new(4) { { name: "cletus", sortable_name: "cletus" } })

        json = api_call(:get,
                        "/api/v1/search/recipients.json?search=cletus&per_page=3",
                        { controller: "search", action: "recipients", format: "json", search: "cletus", per_page: "3" })
        expect(json.size).to be 3
        expect(response.headers["Link"]).not_to be_nil
      end

      it "paginates users and return proper pagination headers" do
        create_users_in_course(@course, Array.new(4) { { name: "cletus", sortable_name: "cletus" } })

        json = api_call(:get,
                        "/api/v1/search/recipients.json?search=cletus&type=user&per_page=3",
                        { controller: "search", action: "recipients", format: "json", search: "cletus", type: "user", per_page: "3" })
        expect(json.size).to be 3
        links = Api.parse_pagination_links(response.headers["Link"])
        links.each do |l|
          expect(l[:uri].to_s).to match(%r{api/v1/search/recipients})
          expect(l["search"]).to eq "cletus"
          expect(l["type"]).to eq "user"
        end
        expect(links.pluck(:rel)).to eq %w[current next first]

        # get the next page
        json = follow_pagination_link("next", {
                                        controller: "search",
                                        action: "recipients",
                                        format: "json"
                                      })
        expect(json.size).to be 1
        links = Api.parse_pagination_links(response.headers["Link"])
        links.each do |l|
          expect(l[:uri].to_s).to match(%r{api/v1/search/recipients})
          expect(l["search"]).to eq "cletus"
          expect(l["type"]).to eq "user"
        end
        expect(links.pluck(:rel)).to eq %w[current first last]
      end

      it "paginates contexts and return proper pagination headers" do
        create_courses(Array.new(4) { { name: "ofcourse" } }, enroll_user: @user)

        json = api_call(:get,
                        "/api/v1/search/recipients.json?search=ofcourse&type=context&per_page=3",
                        { controller: "search", action: "recipients", format: "json", search: "ofcourse", type: "context", per_page: "3" })
        expect(json.size).to be 3
        links = Api.parse_pagination_links(response.headers["Link"])
        links.each do |l|
          expect(l[:uri].to_s).to match(%r{api/v1/search/recipients})
          expect(l["search"]).to eq "ofcourse"
          expect(l["type"]).to eq "context"
        end
        expect(links.pluck(:rel)).to eq %w[current next first]

        # get the next page
        json = follow_pagination_link("next", {
                                        controller: "search",
                                        action: "recipients",
                                        format: "json"
                                      })
        expect(json.size).to be 1
        links = Api.parse_pagination_links(response.headers["Link"])
        links.each do |l|
          expect(l[:uri].to_s).to match(%r{api/v1/search/recipients})
          expect(l["search"]).to eq "ofcourse"
          expect(l["type"]).to eq "context"
        end
        expect(links.pluck(:rel)).to eq %w[current first last]
      end

      it "ignores invalid per_page" do
        create_users_in_course(@course, Array.new(11) { { name: "cletus", sortable_name: "cletus" } })

        json = api_call(:get,
                        "/api/v1/search/recipients.json?search=cletus&type=user&per_page=-1",
                        { controller: "search", action: "recipients", format: "json", search: "cletus", type: "user", per_page: "-1" })
        expect(json.size).to be 10
        links = Api.parse_pagination_links(response.headers["Link"])
        links.each do |l|
          expect(l[:uri].to_s).to match(%r{api/v1/search/recipients})
          expect(l["search"]).to eq "cletus"
          expect(l["type"]).to eq "user"
        end
        expect(links.pluck(:rel)).to eq %w[current next first]

        # get the next page
        json = follow_pagination_link("next", {
                                        controller: "search",
                                        action: "recipients",
                                        format: "json"
                                      })
        expect(json.size).to be 1
        links = Api.parse_pagination_links(response.headers["Link"])
        links.each do |l|
          expect(l[:uri].to_s).to match(%r{api/v1/search/recipients})
          expect(l["search"]).to eq "cletus"
          expect(l["type"]).to eq "user"
        end
        expect(links.pluck(:rel)).to eq %w[current first last]
      end

      it "paginates combined context/user results" do
        # 6 courses, 6 users, 12 items total
        courses = create_courses(Array.new(6) { { name: "term" } }, enroll_user: @user, return_type: :record)
        course_ids = courses.map(&:asset_string)
        user_ids = []
        courses.each do |course|
          user_ids.concat create_users_in_course(course, [{ name: "term", sortable_name: "term" }])
        end

        json = api_call(:get,
                        "/api/v1/search/recipients.json?search=term&per_page=4",
                        { controller: "search", action: "recipients", format: "json", search: "term", per_page: "4" })
        expect(json.size).to be 4
        expect(json.pluck("id")).to eq course_ids[0...4]
        links = Api.parse_pagination_links(response.headers["Link"])
        links.each do |l|
          expect(l[:uri].to_s).to match(%r{api/v1/search/recipients})
          expect(l["search"]).to eq "term"
        end
        expect(links.pluck(:rel)).to eq %w[current next first]

        # get the next page
        json = follow_pagination_link("next", {
                                        controller: "search",
                                        action: "recipients",
                                        format: "json"
                                      })
        expect(json.size).to be 4
        expect(json.pluck("id")).to eq course_ids[4...6] + user_ids[0...2]
        links = Api.parse_pagination_links(response.headers["Link"])
        links.each do |l|
          expect(l[:uri].to_s).to match(%r{api/v1/search/recipients})
          expect(l["search"]).to eq "term"
        end
        expect(links.pluck(:rel)).to eq %w[current next first]

        # get the final page
        json = follow_pagination_link("next", {
                                        controller: "search",
                                        action: "recipients",
                                        format: "json"
                                      })
        expect(json.size).to be 4
        expect(json.pluck("id")).to eq user_ids[2...6]
        links = Api.parse_pagination_links(response.headers["Link"])
        links.each do |l|
          expect(l[:uri].to_s).to match(%r{api/v1/search/recipients})
          expect(l["search"]).to eq "term"
        end
        expect(links.pluck(:rel)).to eq %w[current first last]
      end
    end

    describe "sorting contexts" do
      it "sorts contexts by workflow state first when searching" do
        course_with_teacher(active_course: true, active_enrollment: true, user: @user)
        course1 = @course
        course1.update_attribute(:name, "Context Alpha")
        @enrollment.update_attribute(:workflow_state, "completed")

        course_with_teacher(active_course: true, active_enrollment: true, user: @user)
        course2 = @course
        course2.update_attribute(:name, "Context Beta")

        json = api_call(:get,
                        "/api/v1/search/recipients.json?type=context&search=Context&include_inactive=1",
                        { controller: "search", action: "recipients", format: "json", type: "context", search: "Context", include_inactive: "1" })
        expect(json.pluck("id")).to eq [course2.asset_string, course1.asset_string]
      end

      it "sorts contexts by type second when searching" do
        @course.update_attribute(:name, "Context Beta")
        @group.update_attribute(:name, "Context Alpha")
        json = api_call(:get,
                        "/api/v1/search/recipients.json?type=context&search=Context",
                        { controller: "search", action: "recipients", format: "json", type: "context", search: "Context" })
        expect(json.pluck("id")).to eq [@course.asset_string, @group.asset_string]
      end

      it "sorts contexts by name third when searching" do
        course_with_teacher(active_course: true, active_enrollment: true, user: @user)
        course1 = @course
        course_with_teacher(active_course: true, active_enrollment: true, user: @user)
        course2 = @course

        course1.update_attribute(:name, "Context Beta")
        course2.update_attribute(:name, "Context Alpha")

        json = api_call(:get,
                        "/api/v1/search/recipients.json?type=context&search=Context",
                        { controller: "search", action: "recipients", format: "json", type: "context", search: "Context" })
        expect(json.pluck("id")).to eq [course2.asset_string, course1.asset_string]
      end
    end

    context "caching" do
      specs_require_cache(:redis_cache_store)

      it "shows new groups in existing categories" do
        skip("investigate cause for failures beginning 05/05/21 FOO-1950")
        json = api_call(:get,
                        "/api/v1/search/recipients.json?context=course_#{@course.id}_groups&synthetic_contexts=1",
                        { controller: "search", action: "recipients", format: "json", context: "course_#{@course.id}_groups", synthetic_contexts: "1" })
        expect(json.pluck("id")).to eq ["group_#{@group.id}"]

        Timecop.freeze(1.minute.from_now) do
          group2 = @course.groups.create(name: "whee new group", group_category: @group.group_category)
          json2 = api_call(:get,
                           "/api/v1/search/recipients.json?context=course_#{@course.id}_groups&synthetic_contexts=1",
                           { controller: "search", action: "recipients", format: "json", context: "course_#{@course.id}_groups", synthetic_contexts: "1" })
          expect(json2.pluck("id")).to match_array ["group_#{@group.id}", "group_#{group2.id}"]

          new_student = User.create!
          @course.enroll_student(new_student, enrollment_state: "active")
          group2.add_user(new_student)

          # show group members too
          json3 = api_call(:get,
                           "/api/v1/search/recipients.json?context=group_#{group2.id}",
                           { controller: "search", action: "recipients", format: "json", context: "group_#{group2.id}" })
          expect(json3.pluck("id")).to eq [new_student.id]
        end
      end
    end

    context "sharding" do
      specs_require_sharding

      it "finds top-level groups from any shard" do
        @me.associate_with_shard(@shard1)
        @me.associate_with_shard(@shard2)
        @bob.associate_with_shard(@shard1)
        @joe.associate_with_shard(@shard2)

        group1 = nil
        @shard1.activate do
          group1 = Group.create(context: Account.create!, name: "shard 1 group")
          group1.add_user(@me)
          group1.add_user(@bob)
        end

        group2 = nil
        @shard2.activate do
          group2 = Group.create(context: Account.create!, name: "shard 2 group")
          group2.users = [@me, @joe]
          group2.save!
        end

        json = api_call(:get,
                        "/api/v1/search/recipients.json?type=group&search=group",
                        { controller: "search", action: "recipients", format: "json", type: "group", search: "group" })
        ids = json.pluck("id")
        expect(ids).to include(group1.asset_string)
        expect(ids).to include(group2.asset_string)
      end
    end
  end
end
