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

describe Context do
  context "find_by_asset_string" do
    it "finds a valid course" do
      course = Course.create!
      expect(Context.find_by_asset_string(course.asset_string)).to eql(course)
    end

    it "does not find an invalid course" do
      expect(Context.find_by_asset_string("course_0")).to be_nil
    end

    it "finds a valid group" do
      group = Group.create!(context: Account.default)
      expect(Context.find_by_asset_string(group.asset_string)).to eql(group)
    end

    it "does not find an invalid group" do
      expect(Context.find_by_asset_string("group_0")).to be_nil
    end

    it "finds a valid account" do
      account = Account.create!(name: "test")
      expect(Context.find_by_asset_string(account.asset_string)).to eql(account)
    end

    it "does not find an invalid account" do
      expect(Context.find_by_asset_string("account_#{Account.last.id + 9999}")).to be_nil
    end

    it "finds a valid user" do
      user = User.create!
      expect(Context.find_by_asset_string(user.asset_string)).to eql(user)
    end

    it "does not find an invalid user" do
      expect(Context.find_by_asset_string("user_0")).to be_nil
    end

    it "does not find an invalid asset string" do
      expect(Context.find_by_asset_string("")).to be_nil
      expect(Context.find_by_asset_string("loser_5")).to be_nil
    end

    it "does not find a valid asset" do
      assignment_model
      expect(Context.find_by_asset_string(@assignment.asset_string)).to be_nil
    end

    it "does not find a context with invalid type" do
      expect(Context.find_by_asset_string("WRONG_1")).to be_nil
    end
  end

  context "find_asset_by_asset_string" do
    it "finds a valid assignment" do
      assignment_model
      expect(@course.find_asset(@assignment.asset_string)).to eql(@assignment)
    end

    it "finds a valid wiki page" do
      course_model
      page = @course.wiki_pages.create!(title: "test")
      expect(@course.find_asset(page.asset_string)).to eql(page)
      expect(@course.find_asset(page.asset_string, [:wiki_page])).to eql(page)
    end

    it "does not find a valid wiki page if told to ignore wiki pages" do
      course_model
      page = @course.wiki_pages.create!(title: "test")
      expect(@course.find_asset(page.asset_string, [:assignment])).to be_nil
    end

    it "does not find an invalid assignment" do
      assignment_model
      @course2 = Course.create!
      expect(@course2.find_asset(@assignment.asset_string)).to be_nil
      expect(@course.find_asset("assignment_0")).to be_nil
      expect(@course.find_asset("")).to be_nil
    end

    describe "context" do
      before(:once) do
        @course = Course.create!
        @course2 = Course.create!
        attachment_model context: @course
      end

      it "scopes to context if context is provided" do
        expect(Context.find_asset_by_asset_string(@attachment.asset_string, @course)).to eq(@attachment)
        expect(Context.find_asset_by_asset_string(@attachment.asset_string, @course2)).to be_nil
      end

      it "finds in any context if context is not provided" do
        expect(Context.find_asset_by_asset_string(@attachment.asset_string)).to eq(@attachment)
      end
    end
  end

  context "find_asset_by_url" do
    before :once do
      course_factory
    end

    it "finds files" do
      attachment_model(context: @course).update(locked: true)
      expect(Context.find_asset_by_url("/courses/#{@course.id}/files?preview=#{@attachment.id}")).to eq @attachment
      expect(Context.find_asset_by_url("/courses/#{@course.id}/files/#{@attachment.id}/download?wrap=1")).to eq @attachment
      expect(Context.find_asset_by_url("/courses/#{@course.id}/files/#{@attachment.id}/?wrap=1")).to eq @attachment
      expect(Context.find_asset_by_url("/courses/#{@course.id}/file_contents/course%20files//#{@attachment.name}")).to eq @attachment
      expect(Context.find_asset_by_url("/media_attachments_iframe/#{@attachment.id}?type=video&amp;embedded=true")).to eq @attachment
    end

    it "finds folders" do
      f = Folder.root_folders(@course).first
      child = f.active_sub_folders.build(name: "child")
      child.context = @course
      child.save!
      expect(Context.find_asset_by_url("/courses/#{@course.id}/files/child")).to eq @child
    end

    it "finds assignments" do
      assignment_model(course: @course)
      expect(Context.find_asset_by_url("/courses/#{@course.id}/assignments/#{@assignment.id}")).to eq @assignment
    end

    it "finds wiki pages" do
      wiki_page_model(context: @course, title: "hi")
      expect(Context.find_asset_by_url("/courses/#{@course.id}/pages/hi")).to eq @page
      expect(Context.find_asset_by_url("/courses/#{@course.id}/wiki/hi")).to eq @page
      group_model
      wiki_page_model(context: @group, title: "yo")
      expect(Context.find_asset_by_url("/groups/#{@group.id}/pages/yo")).to eq @page
      expect(Context.find_asset_by_url("/groups/#{@group.id}/wiki/yo")).to eq @page
    end

    it "finds weird wiki pages" do
      wiki_page_model(context: @course, title: "pagewitha+init")
      expect(Context.find_asset_by_url("/courses/#{@course.id}/pages/pagewitha+init")).to eq @page
    end

    it "finds discussion_topics" do
      discussion_topic_model(context: @course)
      expect(Context.find_asset_by_url("/courses/#{@course.id}/discussion_topics/#{@topic.id}")).to eq @topic
      group_model
      discussion_topic_model(context: @group)
      expect(Context.find_asset_by_url("/groups/#{@group.id}/discussion_topics/#{@topic.id}")).to eq @topic
    end

    it "finds quizzes" do
      quiz_model(course: @course)
      expect(Context.find_asset_by_url("/courses/#{@course.id}/quizzes/#{@quiz.id}")).to eq @quiz
    end

    it "finds module items" do
      page = @course.wiki_pages.create! title: "blah"
      mod = @course.context_modules.create! name: "bleh"
      tag = mod.add_item type: "wiki_page", id: page.id
      expect(Context.find_asset_by_url("/courses/#{@course.id}/modules/items/#{tag.id}")).to eq tag
    end

    it "finds media objects" do
      at = attachment_model(context: @course, uploaded_data: stub_file_data("video1.mp4", nil, "video/mp4"))
      data = {
        entries: [
          { entryId: "test", originalId: at.id.to_s }
        ]
      }
      mo = MediaObject.create!(context: @course, media_id: "test")
      MediaObject.build_media_objects(data, Account.default.id)
      expect(Context.find_asset_by_url("/media_objects_iframe/test")).to eq mo
    end

    it "finds users" do
      user = @course.enroll_student(User.create!).user
      expect(Context.find_asset_by_url("/courses/#{@course.id}/users/#{user.id}")).to eq user
    end

    it "finds external tools by url" do
      tool = external_tool_model(context: @course)
      url = "/courses/#{@course.id}/external_tools/retrieve?url=#{CGI.escape(tool.url)}"
      expect(Context.find_asset_by_url(url)).to eq tool
    end

    it "finds external tools by resource link lookup uuid" do
      tool = external_tool_1_3_model(context: @course)
      resource_link = Lti::ResourceLink.create!(
        context: @course,
        lookup_uuid: "90abc684-0f4f-11ed-861d-0242ac120002",
        context_external_tool: tool
      )
      url = "/courses/#{@course.id}/external_tools/retrieve?display=borderless&resource_link_lookup_uuid=#{resource_link.lookup_uuid}"
      expect(Context.find_asset_by_url(url)).to eq tool
    end
  end

  context "self.names_by_context_types_and_ids" do
    it "finds context names" do
      contexts = []
      contexts << Course.create!(name: "a course")
      contexts << Course.create!(name: "another course")
      contexts << Account.default.groups.create!(name: "a group")
      contexts << Account.default.groups.create!(name: "another group")
      contexts << User.create!(name: "a user")
      names = Context.names_by_context_types_and_ids(contexts.map { |c| [c.class.name, c.id] })
      contexts.each do |c|
        expect(names[[c.class.name, c.id]]).to eql(c.name)
      end
    end
  end

  describe ".get_account" do
    it "returns the account given" do
      expect(Context.get_account(Account.default)).to eq(Account.default)
    end

    it "returns a course's account" do
      expect(Context.get_account(course_model(account: Account.default))).to eq(Account.default)
    end

    it "returns a course section's course's account" do
      expect(Context.get_account(course_model(account: Account.default).course_sections.first)).to eq(Account.default)
    end

    it "returns an account level group's account" do
      expect(Context.get_account(group_model(context: Account.default))).to eq(Account.default)
    end

    it "returns a course level group's course's account" do
      expect(Context.get_account(group_model(context: course_model(account: Account.default)))).to eq(Account.default)
    end
  end

  describe "asset_name" do
    before :once do
      course_factory
    end

    it "finds names for outcomes" do
      outcome1 = @course.created_learning_outcomes.create! display_name: "blah", title: "bleh"
      expect(Context.asset_name(outcome1)).to eq "blah"

      outcome2 = @course.created_learning_outcomes.create! title: "bleh"
      expect(Context.asset_name(outcome2)).to eq "bleh"
    end

    it "finds names for calendar events" do
      event1 = @course.calendar_events.create! title: "thing"
      expect(Context.asset_name(event1)).to eq "thing"

      event2 = @course.calendar_events.create! title: ""
      expect(Context.asset_name(event2)).to eq ""
    end
  end

  describe ".rubric_contexts" do
    def add_rubric(context)
      r = Rubric.create!(context:, title: "testing")
      RubricAssociation.create!(context:, rubric: r, purpose: :bookmark, association_object: context)
    end

    it "returns rubric for concluded course enrollment" do
      c1 = Course.create!(name: "c1")
      c2 = Course.create!(name: "c1")
      r = Rubric.create!(context: c1, title: "testing")
      user = user_factory(active_all: true)
      RubricAssociation.create!(context: c1, rubric: r, purpose: :bookmark, association_object: c1)
      enroll = c1.enroll_user(user, "TeacherEnrollment", enrollment_state: "active")
      enroll.conclude
      c2.enroll_user(user, "TeacherEnrollment", enrollment_state: "active")
      expect(c2.rubric_contexts(user)).to eq([{
                                               rubrics: 1,
                                               context_code: c1.asset_string,
                                               name: c1.name
                                             }])
    end

    it "excludes rubrics associated via soft-deleted rubric associations" do
      c1 = Course.create!(name: "c1")
      r = Rubric.create!(context: c1, title: "testing")
      user = user_factory(active_all: true)
      association = RubricAssociation.create!(context: c1, rubric: r, purpose: :bookmark, association_object: c1)
      association.destroy
      c1.enroll_user(user, "TeacherEnrollment", enrollment_state: "active")
      expect(c1.rubric_contexts(user)).to be_empty
    end

    it "returns contexts in alphabetically sorted order" do
      great_grandparent = Account.default
      grandparent = Account.create!(name: "AAA", parent_account: great_grandparent)
      add_rubric(grandparent)
      parent = Account.create!(name: "ZZZ", parent_account: grandparent)
      add_rubric(parent)
      course = Course.create!(name: "MMM", account: parent)
      add_rubric(course)

      contexts = course.rubric_contexts(nil).map { |c| c.slice(:name, :rubrics) }
      expect(contexts).to eq([
                               { name: "AAA", rubrics: 1 },
                               { name: "MMM", rubrics: 1 },
                               { name: "ZZZ", rubrics: 1 }
                             ])
    end

    context "sharding" do
      specs_require_sharding

      it "retrieves rubrics from other shard courses the teacher belongs to" do
        course1 = Course.create!(name: "c1")
        course2 = Course.create!(name: "c2")
        course3 = @shard1.activate do
          a = Account.create!
          Course.create!(name: "c3", account: a)
        end
        user = user_factory(active_all: true)
        [course1, course2, course3].each do |c|
          c.shard.activate do
            r = Rubric.create!(context: c, title: "testing")
            RubricAssociation.create!(context: c, rubric: r, purpose: :bookmark, association_object: c)
            c.enroll_user(user, "TeacherEnrollment", enrollment_state: "active")
          end
        end
        expected = lambda do
          [
            { name: "c1", rubrics: 1, context_code: course1.asset_string },
            { name: "c2", rubrics: 1, context_code: course2.asset_string },
            { name: "c3", rubrics: 1, context_code: course3.asset_string }
          ]
        end
        expect(course1.rubric_contexts(user)).to match_array(expected.call)
        @shard1.activate do
          expect(course2.rubric_contexts(user)).to match_array(expected.call)
        end
      end
    end
  end

  describe "#active_record_types" do
    let(:course) { Course.create! }

    it "looks at the 'everything' cache if asking for just one thing and doesn't have a cache for that" do
      # it should look first for the cache for just the thing we are asking for
      expect(Rails.cache).to receive(:read)
        .with(["active_record_types3", [:assignments], course].cache_key)
        .and_return(nil)

      # if that ^ returns nil, it should then look for for the "everything" cache
      expect(Rails.cache).to receive(:read)
        .with(["active_record_types3", "everything", course].cache_key)
        .and_return({
                      other_thing_we_are_not_asking_for: true,
                      assignments: "the cached value for :assignments from the 'everything' cache"
                    })

      expect(course.active_record_types(only_check: [:assignments])).to eq({
                                                                             assignments: "the cached value for :assignments from the 'everything' cache"
                                                                           })
    end

    it "raises an ArgumentError if you pass (only_check: [])" do
      expect do
        course.active_record_types(only_check: [])
      end.to raise_exception ArgumentError
    end

    it "raises an ArgumentError if you pass bogus values as only_check" do
      expect do
        course.active_record_types(only_check: [:bogus_type, :other_bogus_tab])
      end.to raise_exception ArgumentError
    end
  end

  describe "last_updated_at" do
    before :once do
      @course1 = Course.create!(name: "course1", updated_at: 1.year.ago)
      @course2 = Course.create!(name: "course2", updated_at: 1.week.ago)
      @user1 = User.create!(name: "user1", updated_at: 1.year.ago)
      @user2 = User.create!(name: "user2", updated_at: 1.day.ago)
    end

    it "returns the latest updated_at date for a given set of context ids" do
      expect(Context.last_updated_at(Course => [@course1.id, @course2.id])).to eq @course2.updated_at
    end

    it "raises an error if the class passed is not a context type" do
      expect { Context.last_updated_at(Hash, [1]) }.to raise_error ArgumentError
    end

    it "returns the latest updated_at among multiple classes" do
      expect(Context.last_updated_at(Course => [@course1.id, @course2.id],
                                     User => [@user1.id, @user2.id])).to eq @user2.updated_at
    end

    it "returns nil when no updated_at is found for the given contexts" do
      cs = [@course1, @course2]
      CourseAccountAssociation.where(course_id: cs).delete_all
      PostPolicy.where(course_id: cs).delete_all
      Course.where(id: cs).delete_all

      expect(Context.last_updated_at(Course => [@course1.id, @course2.id])).to be_nil
    end

    context "with sharding" do
      specs_require_sharding

      it "doesn't query multiple shards at once" do
        c = Course.create!
        now = Time.zone.now
        g = @shard1.activate do
          a = Account.create!
          a.groups.create!(updated_at: now + 1.minute)
        end
        expect(g.updated_at).to eq now + 1.minute
        # doesn't find g, because it's on a different shard
        # if it queried both shards, if they're on the same database it will find g,
        # if they're not, it will throw an error
        expect(Context.last_updated_at(Course => [c.id], Group => [g.id])).to eq c.updated_at
      end
    end
  end

  describe "resolved_root_account_id" do
    it "calls root_account_id if present" do
      klass = Class.new do
        include Context

        def root_account_id
          99
        end
      end

      expect(klass.new.resolved_root_account_id).to eq 99
    end

    it "returns nil if root_account_id not present" do
      klass = Class.new { include Context }

      expect(klass.new.resolved_root_account_id).to be_nil
    end
  end
end
