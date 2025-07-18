# frozen_string_literal: true

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

require_relative "../api_spec_helper"
require_relative "../locked_examples"

require "nokogiri"

class DiscussionTopicsTestCourseApi
  include Api
  include Api::V1::DiscussionTopics

  def feeds_topic_format_path(topic_id, code, format)
    "feeds_topic_format_path(#{topic_id.inspect}, #{code.inspect}, #{format.inspect})"
  end

  def named_context_url(*args)
    "named_context_url(#{args.inspect[1..-2]})"
  end

  def course_assignment_submissions_url(*args)
    "course_assignment_submissions_url(#{args.inspect[1..-2]})"
  end

  def course_assignment_url(*args)
    "course_assignment_url(#{args.inspect[1..-2]})"
  end
end

describe Api::V1::DiscussionTopics do
  before :once do
    @test_api = DiscussionTopicsTestCourseApi.new
    @test_api.instance_variable_set :@domain_root_account, Account.default
    course_with_teacher(active_all: true, user: user_with_pseudonym)
    @me = @user
    student_in_course(active_all: true, course: @course)
    @topic = @course.discussion_topics.create
  end

  describe "include root data if requested" do
    before :once do
      @delayed_post_time = 1.day.from_now
      @lock_at_time = 2.days.from_now.change(min: 1)
      @group_topic = group_discussion_topic_model(delayed_post_at: @delayed_post_time, lock_at: @lock_at_time)
    end

    it "get root topic data" do
      root_topics = @test_api.get_root_topic_data(@group_topic.child_topics, [:delayed_post_at, :lock_at])
      expect(root_topics.length).to eq 1
      # Key by the root, not the child topic
      expect(root_topics[@group_topic.child_topics.first.id]).to be_nil
      root_topic = root_topics[@group_topic.id]
      expect(root_topic).not_to be_nil
      expect(root_topic[:id]).to eq @group_topic.id
      expect(root_topic[:delayed_post_at]).to eq @delayed_post_time
      expect(root_topic[:lock_at]).to eq @lock_at_time
    end

    it "include if requested and not prefetched" do
      root_topic_fields = [:delayed_post_at]
      json = @test_api.discussion_topic_api_json(
        @group_topic.child_topics.first,
        @course,
        @user,
        {},
        { root_topic_fields: },
        nil
      )
      expect(json[:delayed_post_at]).to eq @delayed_post_time
      expect(json[:lock_at]).to be_nil  # We didn't ask for it, so don't fill it
      expect(json[:id]).to eq @group_topic.child_topics.first.id
    end

    it "include if requested and prefetched" do
      root_topic_fields = [:delayed_post_at]
      root_topics = @test_api.get_root_topic_data(@group_topic.child_topics, root_topic_fields)
      json = @test_api.discussion_topic_api_json(
        @group_topic.child_topics.first,
        @course,
        @user,
        {},
        { root_topic_fields: },
        root_topics
      )
      expect(json[:delayed_post_at]).to eq @delayed_post_time
      expect(json[:lock_at]).to be_nil  # We didn't ask for it, so don't fill it
      expect(json[:id]).to eq @group_topic.child_topics.first.id
    end

    it "dont include if not requested" do
      root_topic_fields = []
      json = @test_api.discussion_topic_api_json(
        @group_topic.child_topics.first,
        @course,
        @user,
        {},
        { root_topic_fields: }
      )
      expect(json[:delayed_post_at]).to be_nil
      expect(json[:lock_at]).to be_nil  # We didn't ask for it, so don't fill it
      expect(json[:id]).to eq @group_topic.child_topics.first.id
    end
  end

  it "includes the user's pronouns when enabled" do
    @me.update! pronouns: "she/her"
    @me.account.settings[:can_add_pronouns] = true
    @me.account.save!

    expect(
      @test_api.discussion_topic_api_json(@topic, @topic.context, @me, nil)
    ).to have_key("user_pronouns")
    expect(
      @test_api.discussion_topic_api_json(@topic, @topic.context, @me, nil)["user_pronouns"]
    ).to eq "she/her"
  end

  describe "includes 'in_paced_course' if enabled" do
    it "says yes if course has enable_course_paces enabled" do
      @course.enable_course_paces = true
      @course.save!
      expect(
        @test_api.discussion_topic_api_json(@topic, @topic.context, @me, nil)[:in_paced_course]
      ).to be true
    end

    it "says no if course has enable_course_paces disabled" do
      @course.enable_course_paces = false
      @course.save!
      expect(
        @test_api.discussion_topic_api_json(@topic, @topic.context, @me, nil)[:in_paced_course]
      ).to be_nil
    end
  end

  it "renders a podcast_url using the discussion topic's context if there is no @context_enrollment/@context" do
    @topic.update_attribute :podcast_enabled, true
    data = nil
    expect do
      data = @test_api.discussion_topic_api_json(@topic, @topic.context, @me, {})
    end.not_to raise_error
    expect(data[:podcast_url]).to match(/feeds_topic_format_path/)
  end

  it "sets can_post_attachments" do
    data = @test_api.discussion_topic_api_json(@topic, @topic.context, @me, nil)
    expect(data[:permissions][:attach]).to be true # teachers can always attach

    data = @test_api.discussion_topic_api_json(@topic, @topic.context, @student, nil)
    expect(data[:permissions][:attach]).to be true # students can attach by default

    @topic.context.update_attribute(:allow_student_forum_attachments, true)
    AdheresToPolicy::Cache.clear
    data = @test_api.discussion_topic_api_json(@topic, @topic.context, @student, nil)
    expect(data[:permissions][:attach]).to be true
  end

  it "includes assignment" do
    data = @test_api.discussion_topic_api_json(@topic, @topic.context, @me, nil)
    expect(data[:assignment]).to be_nil
  end

  it "does not die if user is nil (like when a non-logged-in user visits a public course)" do
    data = @test_api.discussion_topic_api_json(@topic, @topic.context, nil, nil)
    expect(data).to be_present
  end

  context "with assignment" do
    before :once do
      @topic.assignment = assignment_model(course: @course)
      @topic.save!
    end

    it "includes assignment" do
      data = @test_api.discussion_topic_api_json(@topic, @topic.context, @me, nil)
      expect(data[:assignment]).not_to be_nil
    end

    it "includes all_dates" do
      data = @test_api.discussion_topic_api_json(@topic, @topic.context, @me, nil)
      expect(data[:assignment][:all_dates]).to be_nil

      data = @test_api.discussion_topic_api_json(@topic,
                                                 @topic.context,
                                                 @me,
                                                 nil,
                                                 include_all_dates: true)
      expect(data[:assignment][:all_dates]).not_to be_nil
    end
  end
end

describe DiscussionTopicsController, type: :request do
  include Api::V1::User
  include AvatarHelper

  context "locked api item" do
    let(:item_type) { "discussion_topic" }

    include_examples "a locked api item"

    let_once(:locked_item) do
      @course.discussion_topics.create!(user: @user, message: "Locked Discussion")
    end

    def api_get_json
      @course.clear_permissions_cache(@user)
      api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{locked_item.id}",
        { controller: "discussion_topics_api", action: "show", format: "json", course_id: @course.id.to_s, topic_id: locked_item.id.to_s }
      )
    end
  end

  context "anonymous discussion gets 404" do
    let_once(:discussion_topic) do
      dt = @course.discussion_topics.create!(user: @user, message: "Locked Discussion", anonymous_state: "full_anonymity")

      entry = dt.discussion_entries.create!(message: "first message", user: @student)
      entry.save

      dt
    end

    it "show" do
      api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{discussion_topic.id}",
        { controller: "discussion_topics_api", action: "show", format: "json", course_id: @course.id.to_s, topic_id: discussion_topic.id.to_s },
        {},
        {},
        expected_status: 404
      )
    end

    it "view" do
      api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{discussion_topic.id}/view",
        { controller: "discussion_topics_api", action: "view", format: "json", course_id: @course.id.to_s, topic_id: discussion_topic.id.to_s },
        {},
        {},
        expected_status: 404
      )
    end

    it "entries" do
      api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{discussion_topic.id}/entries",
        { controller: "discussion_topics_api", action: "entries", format: "json", course_id: @course.id.to_s, topic_id: discussion_topic.id.to_s },
        {},
        {},
        expected_status: 404
      )
    end

    it "replies" do
      api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{discussion_topic.id}/entries/#{discussion_topic.discussion_entries.last.id}/replies",
        { controller: "discussion_topics_api", action: "replies", format: "json", course_id: @course.id.to_s, topic_id: discussion_topic.id.to_s, entry_id: discussion_topic.discussion_entries.last.id.to_s },
        {},
        {},
        expected_status: 404
      )
    end

    it "entry_list" do
      api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{discussion_topic.id}/entry_list?ids[]=#{discussion_topic.discussion_entries.last.id}",
        { controller: "discussion_topics_api", action: "entry_list", format: "json", course_id: @course.id.to_s, topic_id: discussion_topic.id.to_s, entry_id: discussion_topic.discussion_entries.last.id.to_s, ids: [discussion_topic.discussion_entries.last.id.to_s] },
        {},
        {},
        expected_status: 404
      )
    end
  end

  before(:once) do
    course_with_teacher(active_all: true, user: user_with_pseudonym)
    user = @user
    student_in_course(active_all: true, course: @course)
    @user = user
  end

  describe "user_display_json" do
    it "returns a html_url based on parent_context" do
      expect(user_display_json(@user)[:html_url]).to eq "http://www.example.com/users/#{@user.id}"
      expect(user_display_json(@user, nil)[:html_url]).to eq "http://www.example.com/users/#{@user.id}"
      expect(user_display_json(@user, :profile)[:html_url]).to eq "http://www.example.com/about/#{@user.id}"
      expect(user_display_json(@user, @course)[:html_url]).to eq "http://www.example.com/courses/#{@course.id}/users/#{@user.id}"
    end
  end

  context "create topic" do
    it "checks permissions" do
      @user = user_factory(active_all: true)
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics",
               { controller: "discussion_topics", action: "create", format: "json", course_id: @course.to_param },
               { title: "hai", message: "test message" },
               {},
               expected_status: 403)
    end

    it "makes a basic topic" do
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics",
               { controller: "discussion_topics", action: "create", format: "json", course_id: @course.to_param },
               { title: "test title", message: "test <b>message</b>" })
      @topic = @course.discussion_topics.order(:id).last
      expect(@topic.title).to eq "test title"
      expect(@topic.message).to eq "test <b>message</b>"
      expect(@topic.threaded?).to be_truthy
      expect(@topic.published?).to be_falsey
      expect(@topic.post_delayed?).to be_falsey
      expect(@topic.podcast_enabled?).to be_falsey
      expect(@topic.podcast_has_student_posts?).to be_falsey
      expect(@topic.require_initial_post?).to be_falsey
    end

    it "creates attachment associations when a file is attached" do
      aa_test_data = AttachmentAssociationsSpecHelper.new(@course.account, @course)
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics",
               { controller: "discussion_topics", action: "create", format: "json", course_id: @course.to_param },
               { title: "test title", message: aa_test_data.base_html })
      @topic = @course.discussion_topics.order(:id).last
      aas = AttachmentAssociation.where(context_type: "DiscussionTopic", context_id: @topic.id)
      expect(aas.count).to eq 1
      expect(aas.first.attachment_id).to eq aa_test_data.attachment1.id
    end

    it "will not create an announcement with sections if context is a group" do
      user_session(@teacher)
      section1 = @course.course_sections.create!(name: "Section 1")
      section2 = @course.course_sections.create!(name: "Section 2")
      @course.enroll_teacher(@teacher, section: section1, allow_multiple_enrollments: true).accept(true)
      @course.enroll_teacher(@teacher, section: section2, allow_multiple_enrollments: true).accept(true)
      @group_category = @course.group_categories.create(name: "gc")
      @group = @course.groups.create!(group_category: @group_category)
      api_call(:post,
               "/api/v1/groups/#{@group.id}/discussion_topics",
               { controller: "discussion_topics", action: "create", format: "json", group_id: @group.to_param },
               { title: "test title",
                 message: "test <b>message</b>",
                 is_announcement: true,
                 specific_sections: [section1.id, section2.id] })
      expect(response).to have_http_status :bad_request
    end

    it "processes html content in message on create" do
      should_process_incoming_user_content(@course) do |content|
        api_call(:post,
                 "/api/v1/courses/#{@course.id}/discussion_topics",
                 { controller: "discussion_topics", action: "create", format: "json", course_id: @course.to_param },
                 { title: "test title", message: content })

        @topic = @course.discussion_topics.order(:id).last
        @topic.message
      end
    end

    it "posts an announcment" do
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics",
               { controller: "discussion_topics", action: "create", format: "json", course_id: @course.to_param },
               { title: "test title", message: "test <b>message</b>", is_announcement: true, published: true })
      @topic = @course.announcements.order(:id).last
      expect(@topic.title).to eq "test title"
      expect(@topic.message).to eq "test <b>message</b>"
    end

    it "creates a topic with all the bells and whistles" do
      post_at = 1.month.from_now
      lock_at = 2.months.from_now
      todo_date = 1.day.from_now.change(sec: 0)
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics",
               { controller: "discussion_topics",
                 action: "create",
                 format: "json",
                 course_id: @course.to_param },
               { title: "test title",
                 message: "test <b>message</b>",
                 discussion_type: "threaded",
                 published: true,
                 todo_date:,
                 delayed_post_at: post_at.as_json,
                 lock_at: lock_at.as_json,
                 podcast_has_student_posts: "1",
                 require_initial_post: "1" })
      @topic = @course.discussion_topics.order(:id).last
      expect(@topic.title).to eq "test title"
      expect(@topic.message).to eq "test <b>message</b>"
      expect(@topic.threaded?).to be true
      expect(@topic.post_delayed?).to be true
      expect(@topic.published?).to be_truthy
      expect(@topic.delayed_post_at.to_i).to eq post_at.to_i
      expect(@topic.lock_at.to_i).to eq lock_at.to_i
      expect(@topic.podcast_enabled?).to be true
      expect(@topic.podcast_has_student_posts?).to be true
      expect(@topic.require_initial_post?).to be true
      expect(@topic.todo_date).to eq todo_date
    end

    context "publishing" do
      it "creates a draft state topic" do
        api_call(:post,
                 "/api/v1/courses/#{@course.id}/discussion_topics",
                 { controller: "discussion_topics", action: "create", format: "json", course_id: @course.to_param },
                 { title: "test title", message: "test <b>message</b>", published: "false" })
        @topic = @course.discussion_topics.order(:id).last
        expect(@topic.published?).to be_falsey
      end

      it "does not allow announcements to be draft state" do
        result = api_call(:post,
                          "/api/v1/courses/#{@course.id}/discussion_topics",
                          { controller: "discussion_topics", action: "create", format: "json", course_id: @course.to_param },
                          { title: "test title", message: "test <b>message</b>", published: "false", is_announcement: true },
                          {},
                          { expected_status: 400 })
        expect(result["errors"]["published"]).to be_present
      end

      it "requires moderation permissions to create a draft state topic" do
        course_with_student_logged_in(course: @course, active_all: true)
        result = api_call(:post,
                          "/api/v1/courses/#{@course.id}/discussion_topics",
                          { controller: "discussion_topics", action: "create", format: "json", course_id: @course.to_param },
                          { title: "test title", message: "test <b>message</b>", published: "false" },
                          {},
                          { expected_status: 400 })
        expect(result["errors"]["published"]).to be_present
      end

      it "allows non-moderators to set published" do
        course_with_student_logged_in(course: @course, active_all: true)
        api_call(:post,
                 "/api/v1/courses/#{@course.id}/discussion_topics",
                 { controller: "discussion_topics", action: "create", format: "json", course_id: @course.to_param },
                 { title: "test title", message: "test <b>message</b>", published: "true" })
        @topic = @course.discussion_topics.order(:id).last
        expect(@topic.published?).to be_truthy
      end
    end

    it "allows creating a discussion assignment" do
      due_date = 1.week.from_now
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics",
               { controller: "discussion_topics", action: "create", format: "json", course_id: @course.to_param },
               { title: "test title", message: "test <b>message</b>", assignment: { points_possible: 15, grading_type: "percent", due_at: due_date.as_json, name: "override!" } })
      @topic = @course.discussion_topics.order(:id).last
      expect(@topic.title).to eq "test title"
      expect(@topic.assignment).to be_present
      expect(@topic.assignment.points_possible).to eq 15
      expect(@topic.assignment.grading_type).to eq "percent"
      expect(@topic.assignment.due_at.to_i).to eq due_date.to_i
      expect(@topic.assignment.submission_types).to eq "discussion_topic"
      expect(@topic.assignment.title).to eq "test title"
    end

    it "does not allow students to create a discussion assignment" do
      @course.allow_student_discussion_topics = true
      @user = @student
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics",
               { controller: "discussion_topics", action: "create", format: "json", course_id: @course.to_param },
               { title: "pwn3d ur grade", message: "lol", assignment: { points_possible: 1000, due_at: 1.week.ago.as_json } },
               {},
               { expected_status: 403 })
    end

    it "does not create an assignment on a discussion topic when set_assignment is false" do
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics",
               { controller: "discussion_topics", action: "create", format: "json", course_id: @course.to_param },
               { title: "test title", message: "test <b>message</b>", assignment: { set_assignment: "false" } })
      @topic = @course.discussion_topics.order(:id).last
      expect(@topic.title).to eq "test title"
      expect(@topic.assignment).to be_nil
    end

    it "create sort order field" do
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics",
               { controller: "discussion_topics", action: "create", format: "json", course_id: @course.to_param },
               { sort_order: "asc", sort_order_locked: "true" })
      @topic = @course.discussion_topics.order(:id).last
      expect(@topic.sort_order).to eq "asc"
      expect(@topic.sort_order_locked).to be true
    end

    it "create expanded field order" do
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics",
               { controller: "discussion_topics", action: "create", format: "json", course_id: @course.to_param },
               { expanded: "true", expanded_locked: "true" })
      @topic = @course.discussion_topics.order(:id).last
      expect(@topic.expanded).to be true
      expect(@topic.expanded_locked).to be true
    end

    it "should not allow !expanded and expanded_locked" do
      result = api_call(:post,
                        "/api/v1/courses/#{@course.id}/discussion_topics",
                        { controller: "discussion_topics", action: "create", format: "json", course_id: @course.to_param },
                        { expanded: "false", expanded_locked: "true" })
      expect(result["errors"]["expanded_locked"]).to be_present
    end
  end

  context "anonymous discussions" do
    before do
      Account.site_admin.enable_feature! :react_discussions_post
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics",
               { controller: "discussion_topics",
                 action: "create",
                 format: "json",
                 course_id: @course.to_param },
               { title: "test title",
                 message: "test <b>message</b>",
                 discussion_type: "threaded",
                 anonymous_state: "full_anonymity" })
      @topic = @course.discussion_topics.order(:id).last
    end

    it "creates a fully anonymous discussion" do
      expect(@topic["anonymous_state"]).to eq "full_anonymity"
    end

    it "update to anonymous_state returns 200 if there is no reply" do
      api_call(:put,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
               { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
               { anonymous_state: nil },
               {},
               { expected_status: 200 })
    end

    it "able to update the anonymous state of an existing topic if there is no reply" do
      api_call(:put,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
               { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
               { anonymous_state: "partial_anonymity" },
               {},
               { expected_status: 200 })
      @topic.reload
      expect(@topic["anonymous_state"]).to eq "partial_anonymity"
    end

    context "student permissions" do
      before { Account.site_admin.enable_feature!(:react_discussions_post) }

      it "unable to create an anonymous topic if course setting is turned off" do
        @user = @student
        @course.allow_student_anonymous_discussion_topics = false
        @course.save!
        api_call(:post,
                 "/api/v1/courses/#{@course.id}/discussion_topics",
                 { controller: "discussion_topics",
                   action: "create",
                   format: "json",
                   course_id: @course.to_param },
                 { title: "test title",
                   message: "test <b>message</b>",
                   discussion_type: "threaded",
                   anonymous_state: "full_anonymity" },
                 {},
                 { expected_status: 400 })
      end

      it "able to create an anonymous topic if course setting is turned on" do
        @user = @student
        @course.allow_student_anonymous_discussion_topics = true
        @course.save!
        api_call(:post,
                 "/api/v1/courses/#{@course.id}/discussion_topics",
                 { controller: "discussion_topics",
                   action: "create",
                   format: "json",
                   course_id: @course.to_param },
                 { title: "test title",
                   message: "test <b>message</b>",
                   discussion_type: "threaded",
                   anonymous_state: "full_anonymity" },
                 {},
                 { expected_status: 200 })
      end
    end

    it "unable to create an anonymous topic for a group discussion" do
      group_category = @course.group_categories.create(name: "Group")
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics",
               { controller: "discussion_topics",
                 action: "create",
                 format: "json",
                 course_id: @course.to_param },
               { title: "test title",
                 message: "test <b>message</b>",
                 discussion_type: "threaded",
                 anonymous_state: "full_anonymity",
                 group_category_id: group_category.id },
               {},
               { expected_status: 400 })
    end

    it "unable to create a graded anonymous topic" do
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics",
               { controller: "discussion_topics",
                 action: "create",
                 format: "json",
                 course_id: @course.to_param },
               { title: "test title",
                 message: "test <b>message</b>",
                 discussion_type: "threaded",
                 anonymous_state: "full_anonymity",
                 assignment: {
                   assignment_overrides: [],
                   turnitin_settings: {
                     s_paper_check: false,
                     originality_report_visibility: "immediate",
                     internet_check: false,
                     exclude_biblio: false,
                     exclude_quoted: false,
                     journal_check: false,
                     exclude_small_matches_value: 0,
                     submit_papers_to: true
                   },
                   hidden: false,
                   unpublishable: true,
                   only_visible_to_overrides: false,
                   set_assignment: "1",
                   points_possible: 0,
                   grading_type: "points",
                   grading_standard_id: "",
                   assignment_group_id: "1",
                   peer_reviews: "0",
                   automatic_peer_reviews: "0",
                   peer_review_count: 0,
                   peer_reviews_assign_at: nil,
                   intra_group_peer_reviews: "0",
                   lock_at: nil,
                   unlock_at: nil,
                   due_at: nil
                 } },
               {},
               { expected_status: 400 })
    end

    it "not able to update the anonymous state if there is at least 1 reply" do
      @entry = create_entry(@topic, message: "top-level entry")
      @reply = create_reply(@entry, message: "test reply")
      @topic.anonymous_state = "full_anonymity"
      @topic.save!
      api_call(:put,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
               { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
               { anonymous_state: nil },
               {},
               { expected_status: 400 })

      @topic.reload
      expect(@topic["anonymous_state"]).to eq "full_anonymity"
    end
  end

  context "when file_association_access feature flag is enabled" do
    before do
      @attachment = create_attachment(@course)
      @attachment.root_account.enable_feature!(:file_association_access)
      @topic = create_topic(@course, title: "Topic 1", message: "/users/#{@user.id}/files/#{@attachment.id}", attachment: @attachment)
    end

    it "return topic response with tagging files with their location in message key" do
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/discussion_topics.json",
                      { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s })

      expect(json.first["message"]).to include("location=#{@topic.asset_string}")
    end
  end

  context "With item" do
    before :once do
      @attachment = create_attachment(@course)
      @topic = create_topic(@course, title: "Topic 1", message: "<p>content here</p>", podcast_enabled: true, attachment: @attachment)
    end

    let(:topic_response_json) do
      lambda do |disable_adding_uuid_verifier_in_api = false|
        { "read_state" => "read",
          "unread_count" => 0,
          "podcast_url" => "/feeds/topics/#{@topic.id}/enrollment_randomness.rss",
          "user_can_see_posts" => @topic.user_can_see_posts?(@user),
          "subscribed" => @topic.subscribed?(@user),
          "require_initial_post" => nil,
          "title" => "Topic 1",
          "discussion_subentry_count" => 0,
          "assignment_id" => nil,
          "is_section_specific" => @topic.is_section_specific,
          "summary_enabled" => @topic.summary_enabled,
          "published" => true,
          "can_unpublish" => true,
          "delayed_post_at" => nil,
          "lock_at" => nil,
          "created_at" => @topic.created_at.iso8601,
          "id" => @topic.id,
          "user_name" => @user.name,
          "last_reply_at" => @topic.last_reply_at.as_json,
          "message" => "<p>content here</p>",
          "posted_at" => @topic.posted_at.as_json,
          "root_topic_id" => nil,
          "pinned" => false,
          "position" => @topic.position,
          "url" => "http://www.example.com/courses/#{@course.id}/discussion_topics/#{@topic.id}",
          "html_url" => "http://www.example.com/courses/#{@course.id}/discussion_topics/#{@topic.id}",
          "podcast_has_student_posts" => false,
          "attachments" => [{ "content-type" => "text/plain",
                              "url" => "http://www.example.com/files/#{@attachment.id}/download?download_frd=1#{"&verifier=#{@attachment.uuid}" unless disable_adding_uuid_verifier_in_api}",
                              "filename" => "content.txt",
                              "display_name" => "content.txt",
                              "id" => @attachment.id,
                              "folder_id" => @attachment.folder_id,
                              "size" => @attachment.size,
                              "unlock_at" => nil,
                              "locked" => false,
                              "hidden" => false,
                              "lock_at" => nil,
                              "locked_for_user" => false,
                              "hidden_for_user" => false,
                              "created_at" => @attachment.created_at.as_json,
                              "updated_at" => @attachment.updated_at.as_json,
                              "upload_status" => "success",
                              "modified_at" => @attachment.modified_at.as_json,
                              "thumbnail_url" => nil,
                              "mime_class" => @attachment.mime_class,
                              "media_entry_id" => @attachment.media_entry_id,
                              "category" => "uncategorized",
                              "visibility_level" => @attachment.visibility_level }],
          "discussion_type" => "threaded",
          "locked" => false,
          "can_lock" => true,
          "comments_disabled" => false,
          "locked_for_user" => false,
          "author" => user_display_json(@topic.user, @topic.context).stringify_keys!,
          "permissions" => { "delete" => true, "attach" => true, "update" => true, "reply" => true, "manage_assign_to" => true },
          "can_group" => true,
          "allow_rating" => false,
          "only_graders_can_rate" => false,
          "sort_by_rating" => false,
          "sort_order" => "desc",
          "sort_order_locked" => false,
          "expanded" => false,
          "expanded_locked" => false,
          "todo_date" => nil,
          "group_category_id" => nil,
          "topic_children" => [],
          "group_topic_children" => [],
          "is_announcement" => false,
          "ungraded_discussion_overrides" => [],
          "anonymous_state" => nil }
      end
    end

    let(:root_topic_response_json) do
      lambda do |disable_adding_uuid_verifier_in_api = false|
        topic_response_json.call(disable_adding_uuid_verifier_in_api).merge(
          "group_category_id" => @group_category.id,
          "topic_children" => [@sub.id],
          "group_topic_children" => [{ "id" => @sub.id, "group_id" => @sub.context_id }],
          "subscription_hold" => "not_in_group_set"
        )
      end
    end

    describe "GET 'index'" do
      double_testing_with_disable_adding_uuid_verifier_in_api_ff do
        it "returns discussion topic list" do
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/discussion_topics.json",
                          { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s })

          expect(json.size).to eq 1
          # get rid of random characters in podcast url
          json.last["podcast_url"].gsub!(/_[^.]*/, "_randomness")
          expect(json.last).to eq topic_response_json.call(disable_adding_uuid_verifier_in_api).merge("subscribed" => @topic.subscribed?(@user))
        end

        it "returns discussion topic list for root topics" do
          @group_category = @course.group_categories.create(name: "watup")
          @group = @group_category.groups.create!(name: "group1", context: @course)
          @topic.update_attribute(:group_category, @group_category)
          @sub = @topic.child_topics.first # create a sub topic the way we actually do - i.e. through groups
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/discussion_topics.json",
                          { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s })

          expect(json.size).to eq 1
          # get rid of random characters in podcast url
          json.last["podcast_url"].gsub!(/_[^.]*/, "_randomness")
          expect(json.last).to eq root_topic_response_json.call(disable_adding_uuid_verifier_in_api).merge("subscribed" => @topic.subscribed?(@user))
        end
      end

      it "searches discussion topics by title" do
        ids = @course.discussion_topics.map(&:id)
        create_topic(@course, title: "ignore me", message: "<p>i'm subversive</p>")
        create_topic(@course, title: "ignore me2", message: "<p>i'm subversive</p>")
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics.json?search_term=topic",
                        { controller: "discussion_topics",
                          action: "index",
                          format: "json",
                          course_id: @course.id.to_s,
                          search_term: "topic" })

        expect(json.pluck("id").sort).to eq ids.sort
      end

      it "orders topics by descending position by default" do
        @topic2 = create_topic(@course, title: "Topic 2", message: "<p>content here</p>")
        @topic3 = create_topic(@course, title: "Topic 3", message: "<p>content here</p>")
        topics = [@topic3, @topic, @topic2]
        topics.reverse.each_with_index do |topic, index|
          topic.position = index + 1
          topic.save!
        end

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics.json",
                        { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s })
        expect(json.pluck("id")).to eq topics.map(&:id)
      end

      it "orders topics by descending last_reply_at when order_by parameter is specified" do
        @topic2 = create_topic(@course, title: "Topic 2", message: "<p>content here</p>")
        @topic3 = create_topic(@course, title: "Topic 3", message: "<p>content here</p>")

        topics = [@topic3, @topic, @topic2]
        topic_reply_date = 1.day.ago
        topics.each do |topic|
          topic.last_reply_at = topic_reply_date
          topic.save!
          topic_reply_date -= 1.day
        end

        # topic that hasn't had a reply yet should be at the top
        @topic4 = create_topic(@course, title: "Topic 4", message: "<p>content here</p>")
        topics.unshift(@topic4)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics.json?order_by=recent_activity",
                        { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s, order_by: "recent_activity" })
        expect(json.pluck("id")).to eq topics.map(&:id)
      end

      it "orders topics by title when order_by parameter is specified" do
        @topic2 = create_topic(@course, title: "Topic 2", message: "<p>content here</p>")
        @topic3 = create_topic(@course, title: "Topic 3", message: "<p>content here</p>")

        topics = [@topic, @topic2, @topic3]
        topic_reply_date = 1.day.ago
        topics.each do |topic|
          topic.last_reply_at = topic_reply_date
          topic.save!
          topic_reply_date -= 1.day
        end

        @topic4 = create_topic(@course, title: "Topic 4", message: "<p>content here</p>")
        topics << @topic4
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics.json?order_by=title",
                        { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s, order_by: "title" })
        expect(json.pluck("id")).to eq topics.map(&:id)
      end

      it "raises error when trying to lock before Due Date" do
        @topic2 = create_topic(@course, title: "Topic 2", message: "<p>content here</p>")

        @assignment = @topic2.context.assignments.build
        @assignment.due_at = 3.days.from_now
        @topic2.assignment = @assignment
        @topic2.save!

        expect do
          @topic2.lock
        end.to raise_error DiscussionTopic::Errors::LockBeforeDueDate
      end

      it "only includes topics with a given scope when specified" do
        @topic2 = create_topic(@course, title: "Topic 2", message: "<p>content here</p>")
        @topic3 = create_topic(@course, title: "Topic 3", message: "<p>content here</p>")
        [@topic, @topic2, @topic3].each(&:save!)
        [@topic2, @topic3].each(&:lock!)
        @topic2.update_attribute(:pinned, true)

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=10&scope=unlocked",
                        { controller: "discussion_topics",
                          action: "index",
                          format: "json",
                          course_id: @course.id.to_s,
                          per_page: "10",
                          scope: "unlocked" })
        expect(json.size).to eq 1
        links = response.headers["Link"].split(",")
        links.each do |link|
          expect(link).to match("scope=unlocked")
        end

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=10&scope=locked",
                        { controller: "discussion_topics",
                          action: "index",
                          format: "json",
                          course_id: @course.id.to_s,
                          per_page: "10",
                          scope: "locked" })
        expect(json.size).to eq 2
        links = response.headers["Link"].split(",")
        links.each do |link|
          expect(link).to match("scope=locked")
        end

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=10&scope=pinned",
                        { controller: "discussion_topics",
                          action: "index",
                          format: "json",
                          course_id: @course.id.to_s,
                          per_page: "10",
                          scope: "pinned" })
        expect(json.size).to eq 1

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=10&scope=unpinned",
                        { controller: "discussion_topics",
                          action: "index",
                          format: "json",
                          course_id: @course.id.to_s,
                          per_page: "10",
                          scope: "unpinned" })
        expect(json.size).to eq 2

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=10&scope=locked,unpinned",
                        { controller: "discussion_topics",
                          action: "index",
                          format: "json",
                          course_id: @course.id.to_s,
                          per_page: "10",
                          scope: "locked,unpinned" })
        expect(json.size).to eq 1
      end

      it "includes all parameters in pagination urls" do
        @topic2 = create_topic(@course, title: "Topic 2", message: "<p>content here</p>")
        @topic3 = create_topic(@course, title: "Topic 3", message: "<p>content here</p>")
        [@topic, @topic2, @topic3].each do |topic|
          topic.type = "Announcement"
          topic.save!
        end

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=2&only_announcements=true&order_by=recent_activity&scope=unlocked",
                        { controller: "discussion_topics",
                          action: "index",
                          format: "json",
                          course_id: @course.id.to_s,
                          per_page: "2",
                          order_by: "recent_activity",
                          only_announcements: "true",
                          scope: "unlocked" })
        expect(json.size).to eq 2
        links = response.headers["Link"].split(",")
        links.each do |link|
          expect(link).to match("only_announcements=true")
          expect(link).to match("order_by=recent_activity")
          expect(link).to match("scope=unlocked")
        end
      end

      it "returns group_topic_children for group discussions" do
        group_topic = group_discussion_topic_model(context: @course)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics.json",
                        { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s })

        json_topic = json.find { |t| t["group_category_id"] }

        expect(json_topic).not_to be_nil
        expect(json_topic["group_category_id"]).to eq group_topic.group_category_id
        expect(json_topic["group_topic_children"]).to eq(
          group_topic.child_topics.map { |topic| { "id" => topic.id, "group_id" => topic.context_id } }
        )
      end

      it "ignores sections_user_count when context is Group" do
        group_category = @course.group_categories.create(name: "watup")
        group = group_category.groups.create!(name: "group1", context: @course)
        gtopic = create_topic(group, title: "topic")

        json = api_call(:get,
                        "/api/v1/groups/#{group.id}/discussion_topics",
                        { controller: "discussion_topics",
                          action: "index",
                          format: "json",
                          group_id: group.to_param,
                          include: ["sections", "sections_user_count"] })
        expect(json[0]["user_count"]).to be_nil
        expect(json[0]["sections"]).to be_nil
        expect(json[0]["id"]).to eq gtopic.id
      end

      context "when a course has users enrolled in multiple sections" do
        before(:once) do
          course_with_teacher(active_course: true)
          @section1 = @course.course_sections.create!(name: "section1")
          @section2 = @course.course_sections.create!(name: "section2")

          @student1, @student2 = create_users(2, return_type: :record)
          @course.enroll_student(@student1, enrollment_state: "active", section: @section1, allow_multiple_enrollments: true)
          @course.enroll_student(@student1, enrollment_state: "active", section: @section2, allow_multiple_enrollments: true)
          @course.enroll_student(@student2, enrollment_state: "active", section: @section2)

          @announcement = @course.announcements.create!(user: @teacher, message: "hello my favorite section!")
        end

        it "only counts multple-section users once" do
          json = api_call_as_user(@student1,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/discussion_topics?only_announcements=1",
                                  {
                                    controller: "discussion_topics",
                                    action: "index",
                                    format: "json",
                                    course_id: @course.id.to_s,
                                    only_announcements: 1,
                                    include: ["sections", "sections_user_count"]
                                  })

          expect(json.count).to eq(1)
          expect(json[0]["id"]).to eq(@announcement.id)
          expect(json[0]["user_count"]).to eq 3 # had student1 been double counted, this count would be 4
        end
      end

      describe "section specific announcements" do
        before(:once) do
          course_with_teacher(active_course: true)
          @section = @course.course_sections.create!(name: "test section")

          @announcement = @course.announcements.create!(user: @teacher, message: "hello my favorite section!")
          @announcement.is_section_specific = true
          @announcement.course_sections = [@section]
          @announcement.save!

          @student1, @student2 = create_users(2, return_type: :record)
          @course.enroll_student(@student1, enrollment_state: "active")
          @course.enroll_student(@student2, enrollment_state: "active")
          student_in_section(@section, user: @student1)
        end

        it "renders correct page count for users even with delayed posted date" do
          @topic2 = create_topic(@course, title: "Topic 2", message: "<p>content here</p>", delayed_post_at: 2.days.from_now)
          @topic3 = create_topic(@course, title: "Topic 3", message: "<p>content here</p>")
          [@topic2, @topic3].each do |topic|
            topic.type = "Announcement"
            topic.save!
          end

          api_call_as_user(@student1,
                           :get,
                           "/api/v1/courses/#{@course.id}/discussion_topics?only_announcements=1&per_page=2",
                           {
                             controller: "discussion_topics",
                             action: "index",
                             format: "json",
                             course_id: @course.id.to_s,
                             only_announcements: 1,
                             per_page: 2,
                           })
          expect(!response.headers["Link"].split(",").last.include?("&page=2&")).to be(true)
        end

        it "teacher should be able to see section specific announcements" do
          json = api_call_as_user(@teacher,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/discussion_topics?only_announcements=1",
                                  {
                                    controller: "discussion_topics",
                                    action: "index",
                                    format: "json",
                                    course_id: @course.id.to_s,
                                    only_announcements: 1,
                                  })

          expect(json.count).to eq(1)
          expect(json[0]["id"]).to eq(@announcement.id)
          expect(json[0]["is_section_specific"]).to be(true)
        end

        it "teacher should be able to see section specific announcements and include sections" do
          json = api_call_as_user(@teacher,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/discussion_topics?only_announcements=1",
                                  {
                                    controller: "discussion_topics",
                                    action: "index",
                                    format: "json",
                                    course_id: @course.id.to_s,
                                    only_announcements: 1,
                                    include: ["sections"],
                                  })

          expect(json.count).to eq(1)
          expect(json[0]["id"]).to eq(@announcement.id)
          expect(json[0]["is_section_specific"]).to be(true)
          expect(json[0]["sections"].count).to eq(1)
          expect(json[0]["sections"][0]["id"]).to eq(@section.id)
        end

        it "teacher should be able to see section specific announcements and include sections and sections user count" do
          json = api_call_as_user(@teacher,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/discussion_topics?only_announcements=1",
                                  {
                                    controller: "discussion_topics",
                                    action: "index",
                                    format: "json",
                                    course_id: @course.id.to_s,
                                    only_announcements: 1,
                                    include: ["sections", "sections_user_count"],
                                  })

          expect(json.count).to eq(1)
          expect(json[0]["id"]).to eq(@announcement.id)
          expect(json[0]["is_section_specific"]).to be(true)
          expect(json[0]["sections"].count).to eq(1)
          expect(json[0]["sections"][0]["id"]).to eq(@section.id)
          expect(json[0]["sections"][0]["user_count"]).to eq(1)
        end

        it "student in section should be able to see section specific announcements" do
          json = api_call_as_user(@student1,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/discussion_topics?only_announcements=1",
                                  {
                                    controller: "discussion_topics",
                                    action: "index",
                                    format: "json",
                                    course_id: @course.id.to_s,
                                    only_announcements: 1,
                                  })

          expect(json.count).to eq(1)
          expect(json[0]["id"]).to eq(@announcement.id)
          expect(json[0]["is_section_specific"]).to be(true)
        end

        it "student in section should be able to get the announcement details" do
          json = api_call_as_user(@student1,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/discussion_topics/#{@announcement.id}",
                                  {
                                    controller: "discussion_topics_api",
                                    action: "show",
                                    format: "json",
                                    course_id: @course.id,
                                    topic_id: @announcement.id,
                                  })

          expect(json["id"]).to eq(@announcement.id)
        end

        it "student not in section should not be able to get the announcement details" do
          api_call_as_user(@student2,
                           :get,
                           "/api/v1/courses/#{@course.id}/discussion_topics/#{@announcement.id}",
                           {
                             controller: "discussion_topics_api",
                             action: "show",
                             format: "json",
                             course_id: @course.id,
                             topic_id: @announcement.id,
                           },
                           {},
                           {},
                           { expected_status: 403 })
        end

        it "student not in section should not be able to see section specific announcements" do
          json = api_call_as_user(@student2,
                                  :get,
                                  "/api/v1/courses/#{@course.id}/discussion_topics?only_announcements=1",
                                  {
                                    controller: "discussion_topics",
                                    action: "index",
                                    format: "json",
                                    course_id: @course.id.to_s,
                                    only_announcements: 1,
                                  })

          expect(json.count).to eq(0)
        end

        describe "with multiple sections" do
          before(:once) do
            @section2 = @course.course_sections.create!(name: "test section 2")

            @announcement2 = @course.announcements.create!(user: @teacher, message: "hello section 2")
            @announcement2.is_section_specific = true
            @announcement2.course_sections = [@section2]
            @announcement2.save!

            student_in_section(@section2, user: @student2)
          end

          it "paginates visible items" do
            json = api_call_as_user(
              @student2,
              :get,
              api_v1_course_discussion_topics_url(@course),
              {
                controller: "discussion_topics",
                action: "index",
                format: "json",
                course_id: @course.id.to_s,
                per_page: "1",
                only_announcements: 1
              }
            )
            expect(!!response.headers["Link"].split(",").last.include?("&page=2&")).to be false
            expect(json.count).to eq 1
            expect(json.first["id"]).to eq @announcement2.id
          end

          context "as a user that can view all sections" do
            it "includes all announcements" do
              json = api_call_as_user(
                @teacher,
                :get,
                api_v1_course_discussion_topics_url(@course),
                {
                  controller: "discussion_topics",
                  action: "index",
                  format: "json",
                  course_id: @course.id.to_s,
                  only_announcements: 1
                }
              )
              expect(json.count).to eq 2
              expect(json.pluck("id")).to match_array [@announcement.id, @announcement2.id]
            end
          end
        end
      end

      describe "differentiated modules" do
        context "ungraded discussions" do
          before do
            course_factory(active_all: true)
            @course_section = @course.course_sections.create

            @student1, @student2 = create_users(2, return_type: :record)
            @course.enroll_student(@student1, enrollment_state: "active")
            @course.enroll_student(@student2, enrollment_state: "active")
            student_in_section(@course.course_sections.first, user: @student1)
            student_in_section(@course.course_sections.second, user: @student2)

            @teacher = teacher_in_course(course: @course, active_enrollment: true).user
            @topic_visible_to_everyone = discussion_topic_model(user: @teacher, context: @course)
            @topic = discussion_topic_model(user: @teacher, context: @course)
            @topic.update!(only_visible_to_overrides: true)
          end

          it "shows only the visible topics" do
            override = @topic.assignment_overrides.create!
            override.assignment_override_students.create!(user: @student1)

            @user = @student2

            json = api_call(:get,
                            "/api/v1/courses/#{@course.id}/discussion_topics.json",
                            { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s })
            expect(json.size).to eq 1

            @user = @student1

            json = api_call(:get,
                            "/api/v1/courses/#{@course.id}/discussion_topics.json",
                            { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s })
            expect(json.size).to eq 2
          end

          it "is visible only to users who can access the assigned section" do
            @topic.assignment_overrides.create!(set: @course_section)

            @user = @student2
            json = api_call(:get,
                            "/api/v1/courses/#{@course.id}/discussion_topics.json",
                            { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s })
            expect(json.size).to eq 2

            @user = @student1
            json = api_call(:get,
                            "/api/v1/courses/#{@course.id}/discussion_topics.json",
                            { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s })
            expect(json.size).to eq 1
          end

          it "is visible only to students in module override section" do
            context_module = @course.context_modules.create!(name: "module")
            context_module.content_tags.create!(content: @topic, context: @course)

            override2 = @topic.assignment_overrides.create!(unlock_at: "2022-02-01T01:00:00Z",
                                                            unlock_at_overridden: true,
                                                            lock_at: "2022-02-02T01:00:00Z",
                                                            lock_at_overridden: true)
            override2.assignment_override_students.create!(user: @student2)

            @user = @student2
            json = api_call(:get,
                            "/api/v1/courses/#{@course.id}/discussion_topics.json",
                            { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s })
            expect(json.size).to eq 2

            @user = @student1
            json = api_call(:get,
                            "/api/v1/courses/#{@course.id}/discussion_topics.json",
                            { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s })
            expect(json.size).to eq 1
          end
        end
      end
    end

    describe "GET 'show'" do
      double_testing_with_disable_adding_uuid_verifier_in_api_ff do
        it "returns an individual topic" do
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                          { controller: "discussion_topics_api", action: "show", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s })

          # get rid of random characters in podcast url
          json["podcast_url"].gsub!(/_[^.]*/, "_randomness")
          expect(json.sort.to_h).to eq topic_response_json.call(disable_adding_uuid_verifier_in_api).merge("subscribed" => @topic.subscribed?(@user)).sort.to_h
        end

        it "returns an individual root topic" do
          @group_category = @course.group_categories.create(name: "watup")
          @group = @group_category.groups.create!(name: "group1", context: @course)
          @topic.update_attribute(:group_category, @group_category)
          @sub = @topic.child_topics.first # create a sub topic the way we actually do - i.e. through groups
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                          { controller: "discussion_topics_api", action: "show", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s })

          # get rid of random characters in podcast url
          json["podcast_url"].gsub!(/_[^.]*/, "_randomness")
          expect(json.sort.to_h).to eq root_topic_response_json.call(disable_adding_uuid_verifier_in_api).merge("subscribed" => @topic.subscribed?(@user)).sort.to_h
        end
      end

      it "does not show information for a deleted child topic" do
        @group_category = @course.group_categories.create(name: "watup")
        @group = @group_category.groups.create!(name: "group1", context: @course)
        @topic.update_attribute(:group_category, @group_category)
        @sub = @topic.child_topics.first # create a sub topic the way we actually do - i.e. through groups
        @group.destroy
        @topic.refresh_subtopics
        expect(@sub.reload).to be_deleted
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                        { controller: "discussion_topics_api", action: "show", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s })
        expect(json["group_topic_children"]).to be_empty
        expect(json["topic_children"]).to be_empty
      end

      it "requires course to be published for students" do
        @course.claim
        api_call_as_user(@student,
                         :get,
                         "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                         { controller: "discussion_topics_api",
                           action: "show",
                           format: "json",
                           course_id: @course.id.to_s,
                           topic_id: @topic.id.to_s },
                         {},
                         {},
                         expected_status: 403)
      end

      it "returns group_topic_children for group discussions" do
        group_topic = group_discussion_topic_model(context: @course)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{group_topic.id}",
                        { controller: "discussion_topics_api", action: "show", format: "json", course_id: @course.id.to_s, topic_id: group_topic.id.to_s })

        expect(json).not_to be_nil
        expect(json["group_category_id"]).to eq group_topic.group_category_id
        expect(json["group_topic_children"]).to eq(
          group_topic.child_topics.map { |topic| { "id" => topic.id, "group_id" => topic.context_id } }
        )
      end

      it "properly translates a video media comment in the discussion topic's message" do
        @topic.update(
          message: '<p><a id="media_comment_m-spHRwKY5ATHvPQAMKdZV_g" class="instructure_inline_media_comment video_comment" href="/media_objects/m-spHRwKY5ATHvPQAMKdZV_g">this is a media comment</a></p>'
        )

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                        { controller: "discussion_topics_api", action: "show", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s })

        video_tag = Nokogiri::XML(json["message"]).css("p video").first
        expect(video_tag["poster"]).to eq "http://www.example.com/media_objects/m-spHRwKY5ATHvPQAMKdZV_g/thumbnail?height=448&type=3&width=550"
        expect(video_tag["data-media_comment_type"]).to eq "video"
        expect(video_tag["preload"]).to eq "none"
        expect(video_tag["class"]).to eq "instructure_inline_media_comment"
        expect(video_tag["data-media_comment_id"]).to eq "m-spHRwKY5ATHvPQAMKdZV_g"
        expect(video_tag["controls"]).to eq "controls"
        expect(video_tag["src"]).to eq "http://www.example.com/courses/#{@course.id}/media_download?entryId=m-spHRwKY5ATHvPQAMKdZV_g&media_type=video&redirect=1"
        expect(video_tag.inner_text).to eq "this is a media comment"
      end

      it "properly translates a audio media comment in the discussion topic's message" do
        @topic.update(
          message: '<p><a id="media_comment_m-QgvagKCQATEtJAAMKdZV_g" class="instructure_inline_media_comment audio_comment"></a>this is a media comment</p>'
        )

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                        { controller: "discussion_topics_api", action: "show", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s })

        message = Nokogiri::XML(json["message"])
        audio_tag = message.css("p audio").first
        expect(audio_tag["data-media_comment_type"]).to eq "audio"
        expect(audio_tag["preload"]).to eq "none"
        expect(audio_tag["class"]).to eq "instructure_inline_media_comment"
        expect(audio_tag["data-media_comment_id"]).to eq "m-QgvagKCQATEtJAAMKdZV_g"
        expect(audio_tag["controls"]).to eq "controls"
        expect(audio_tag["src"]).to eq "http://www.example.com/courses/#{@course.id}/media_download?entryId=m-QgvagKCQATEtJAAMKdZV_g&media_type=audio&redirect=1"
        expect(message.css("p").inner_text).to eq "this is a media comment"
      end

      it "includes all_dates if they are asked for" do
        due_date = 3.days.from_now
        @assignment = @topic.context.assignments.build
        @assignment.due_at = due_date
        @topic.assignment = @assignment
        @topic.save!

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                        { controller: "discussion_topics_api",
                          action: "show",
                          format: "json",
                          course_id: @course.id.to_s,
                          topic_id: @topic.id.to_s },
                        { include: ["all_dates"] })

        expect(json["assignment"]["all_dates"]).not_to be_nil
      end

      it "includes overrides if they are asked for" do
        @assignment = @topic.context.assignments.build
        override = @assignment.assignment_overrides.build
        override.set = @section
        override.title = "extension"
        override.due_at = 2.days.from_now
        override.due_at_overridden = true
        override.save!
        @topic.assignment = @assignment
        @topic.save!

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                        { controller: "discussion_topics_api",
                          action: "show",
                          format: "json",
                          course_id: @course.id.to_s,
                          topic_id: @topic.id.to_s },
                        { include: ["overrides"] })

        expect(json["assignment"]["overrides"]).not_to be_nil
      end

      it "includes sections if the discussion is section specific and they are asked for" do
        section = @course.course_sections.create!
        @topic.is_section_specific = true
        @topic.discussion_topic_section_visibilities << DiscussionTopicSectionVisibility.new(
          discussion_topic: @topic,
          course_section: section,
          workflow_state: "active"
        )
        @topic.save!

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                        { controller: "discussion_topics_api",
                          action: "show",
                          format: "json",
                          course_id: @course.id.to_s,
                          topic_id: @topic.id.to_s },
                        { include: ["sections"] })

        expect(json["is_section_specific"]).to be(true)
        expect(json["sections"][0]["id"]).to be(section.id)
      end

      it "includes section user accounts if they are asked for" do
        section = @course.course_sections.create!
        @topic.is_section_specific = true
        @topic.discussion_topic_section_visibilities << DiscussionTopicSectionVisibility.new(
          discussion_topic: @topic,
          course_section: section,
          workflow_state: "active"
        )
        @topic.save!

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                        { controller: "discussion_topics_api",
                          action: "show",
                          format: "json",
                          course_id: @course.id.to_s,
                          topic_id: @topic.id.to_s },
                        { include: ["sections", "sections_user_count"] })

        expect(json["sections"][0]["user_count"]).not_to be_nil
      end
    end

    describe "PUT 'update'" do
      it "requires authorization" do
        @user = user_factory(active_all: true)
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { title: "hai", message: "test message" },
                 {},
                 expected_status: 403)
      end

      it "updates the entry" do
        post_at = 1.month.from_now
        lock_at = 2.months.from_now
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { title: "test title",
                   message: "test <b>message</b>",
                   discussion_type: "threaded",
                   delayed_post_at: post_at.as_json,
                   lock_at: lock_at.as_json,
                   podcast_has_student_posts: "1",
                   require_initial_post: "1" })
        @topic.reload
        expect(@topic.title).to eq "test title"
        expect(@topic.message).to eq "test <b>message</b>"
        expect(@topic.threaded?).to be true
        expect(@topic.post_delayed?).to be true
        expect(@topic.delayed_post_at.to_i).to eq post_at.to_i
        expect(@topic.lock_at.to_i).to eq lock_at.to_i
        expect(@topic.podcast_enabled?).to be true
        expect(@topic.podcast_has_student_posts?).to be true
        expect(@topic.require_initial_post?).to be true
      end

      it "updates attachment associations when a new file is attached" do
        aa_test_data = AttachmentAssociationsSpecHelper.new(@course.account, @course)
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { message: aa_test_data.base_html })
        @topic.reload
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { message: aa_test_data.added_html })
        aas = AttachmentAssociation.where(context_type: "DiscussionTopic", context_id: @topic.id)
        expect(aas.count).to eq 2
        attachment_ids = aas.pluck(:attachment_id)
        expect(attachment_ids).to match_array [aa_test_data.attachment1.id, aa_test_data.attachment2.id]
      end

      it "updates attachment associations when no file is attached" do
        aa_test_data = AttachmentAssociationsSpecHelper.new(@course.account, @course)
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { message: aa_test_data.base_html })
        @topic.reload
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { message: aa_test_data.removed_html })
        aas = AttachmentAssociation.where(context_type: "DiscussionTopic", context_id: @topic.id)
        expect(aas.count).to eq 0
      end

      it "returns section count if section specific" do
        post_at = 1.month.from_now
        lock_at = 2.months.from_now
        discussion_topic_model(context: @course, title: "Section Specific Topic", user: @teacher)
        section1 = @course.course_sections.create!
        @course.course_sections.create! # just to make sure we only copy the right one
        @topic.is_section_specific = true
        @topic.discussion_topic_section_visibilities << DiscussionTopicSectionVisibility.new(
          discussion_topic: @topic,
          course_section: section1,
          workflow_state: "active"
        )
        @topic.save!
        api_response = api_call(:put,
                                "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                                { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                                { title: "test title",
                                  message: "test <b>message</b>",
                                  discussion_type: "threaded",
                                  delayed_post_at: post_at.as_json,
                                  lock_at: lock_at.as_json,
                                  podcast_has_student_posts: "1",
                                  require_initial_post: "1" })
        expect(api_response["sections"].count).to eq 1
      end

      it "does not unlock topic if lock_at changes but is still in the past" do
        lock_at = 1.month.ago
        new_lock_at = 1.week.ago
        @topic.workflow_state = "active"
        @topic.locked = true
        @topic.lock_at = lock_at
        @topic.save!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { lock_at: new_lock_at.as_json })
        @topic.reload
        expect(@topic.lock_at.to_i).to eq new_lock_at.to_i
        expect(@topic).to be_locked
      end

      it "updates workflow_state if delayed_post_at changed to future" do
        post_at = 1.month.from_now
        @topic.workflow_state = "active"
        @topic.locked = true
        @topic.save!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { delayed_post_at: post_at.as_json })
        @topic.reload
        expect(@topic.delayed_post_at.to_i).to eq post_at.to_i
        expect(@topic).to be_post_delayed
      end

      it "does not change workflow_state if lock_at does not change" do
        lock_at = 1.month.from_now.change(usec: 0)
        @topic.lock_at = lock_at
        @topic.workflow_state = "active"
        @topic.save!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { lock_at: lock_at.as_json })

        @topic.reload
        expect(@topic.lock_at).to eq lock_at
        expect(@topic).to be_active
      end

      it "unlocks topic if lock_at is changed to future" do
        old_lock_at = 1.month.ago
        new_lock_at = 1.month.from_now
        @topic.lock_at = old_lock_at
        @topic.workflow_state = "active"
        @topic.locked = true
        @topic.save!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { lock_at: new_lock_at.as_json })

        @topic.reload
        expect(@topic.lock_at.to_i).to eq new_lock_at.to_i
        expect(@topic).to be_active
        expect(@topic).not_to be_locked
      end

      it "locks the topic if lock_at is changed to the past" do
        old_lock_at = 1.month.from_now
        new_lock_at = 1.month.ago
        @topic.lock_at = old_lock_at
        @topic.workflow_state = "active"
        @topic.save!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { lock_at: new_lock_at.as_json })

        @topic.reload
        expect(@topic.lock_at.to_i).to eq new_lock_at.to_i
        expect(@topic).to be_locked
      end

      it "does not lock the topic if lock_at is cleared" do
        @topic.lock_at = 1.month.ago
        @topic.workflow_state = "active"
        @topic.save!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { lock_at: "" })

        @topic.reload
        expect(@topic.lock_at).to be_nil
        expect(@topic).to be_active
        expect(@topic).not_to be_locked
      end

      it "does not update certain attributes for group discussions" do
        group_category = @course.group_categories.create(name: "watup")
        group = group_category.groups.create!(name: "group1", context: @course)
        gtopic = create_topic(group, title: "topic")

        api_call(:put,
                 "/api/v1/groups/#{group.id}/discussion_topics/#{gtopic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", group_id: group.to_param, topic_id: gtopic.to_param },
                 { allow_rating: "1", require_initial_post: "1" })

        gtopic.reload
        expect(gtopic.allow_rating).to be_truthy
        expect(gtopic.require_initial_post).to_not be_truthy
      end

      it "does not allow updating certain attributes for group sub-discussions" do
        # but should allow them to pin/unpin them
        group_category = @course.group_categories.create(name: "watup")
        group = group_category.groups.create!(name: "group1", context: @course)
        rtopic = @course.discussion_topics.create!(group_category:)
        gtopic = rtopic.child_topics.first

        api_call(:put,
                 "/api/v1/groups/#{group.id}/discussion_topics/#{gtopic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", group_id: group.to_param, topic_id: gtopic.to_param },
                 { message: "new message" },
                 {},
                 { expected_status: 403 })

        api_call(:put,
                 "/api/v1/groups/#{group.id}/discussion_topics/#{gtopic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", group_id: group.to_param, topic_id: gtopic.to_param },
                 { pinned: "1" },
                 {},
                 { expected_status: 200 })

        expect(gtopic.reload.pinned).to be_truthy
      end

      context "publishing" do
        it "publishes a draft state topic" do
          @topic.workflow_state = "unpublished"
          @topic.save!
          expect(@topic).not_to be_published
          api_call(:put,
                   "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                   { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                   { published: "true" })
          expect(@topic.reload).to be_published
        end

        it "does not allow announcements to be draft state" do
          @topic.type = "Announcement"
          @topic.save!
          result = api_call(:put,
                            "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                            { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                            { published: "false" },
                            {},
                            { expected_status: 400 })
          expect(result["errors"]["published"]).to be_present
        end

        it "allows a topic with no posts to set draft state" do
          api_call(:put,
                   "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                   { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                   { published: "false" })
          expect(@topic.reload).not_to be_published
        end

        it "prevents a topic with posts from setting draft state" do
          student_in_course(course: @course, active_all: true)
          create_entry(@topic, user: @student)

          @user = @teacher
          api_call(:put,
                   "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                   { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                   { published: "false" },
                   {},
                   { expected_status: 400 })
          expect(@topic.reload).to be_published
        end

        it "requires moderation permissions to set draft state" do
          course_with_student_logged_in(course: @course, active_all: true)
          @topic = create_topic(@course, user: @student)
          api_call(:put,
                   "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                   { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                   { published: "false" },
                   {},
                   { expected_status: 400 })
          expect(@topic.reload).to be_published
        end

        it "allows non-moderators to set published" do
          course_with_student_logged_in(course: @course, active_all: true)
          @topic = create_topic(@course, user: @student)
          api_call(:put,
                   "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                   { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                   { published: "true" })
          expect(@topic.reload).to be_published
        end
      end

      it "processes html content in message on update" do
        should_process_incoming_user_content(@course) do |content|
          api_call(:put,
                   "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                   { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                   { message: content })

          @topic.reload
          @topic.message
        end
      end

      it "sets the editor_id to whoever edited to entry" do
        @original_user = @user
        @editing_user = user_model
        @course.enroll_teacher(@editing_user).accept

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { title: "edited by someone else" })
        @topic.reload
        expect(@topic.editor).to eql(@editing_user)
        expect(@topic.user).to eql(@original_user)
      end

      it "does not drift when saving delayed_post_at with user-preferred timezone set" do
        @user.time_zone = "Alaska"
        @user.save

        expected_time = @user.time_zone.parse("Fri Aug 26, 2031 8:39AM")

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { delayed_post_at: expected_time.as_json })

        @topic.reload
        expect(@topic.delayed_post_at).to eq expected_time
      end

      it "allows creating assignment on update" do
        due_date = 1.week.ago
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { assignment: { points_possible: 15, grading_type: "percent", due_at: due_date.as_json, name: "override!" } })
        @topic.reload

        expect(@topic.title).to eq "Topic 1"
        expect(@topic.assignment).to be_present
        expect(@topic.assignment.points_possible).to eq 15
        expect(@topic.assignment.grading_type).to eq "percent"
        expect(@topic.assignment.due_at.to_i).to eq due_date.to_i
        expect(@topic.assignment.submission_types).to eq "discussion_topic"
        expect(@topic.assignment.title).to eq "Topic 1"
      end

      it "allows removing assignment on update" do
        @assignment = @topic.context.assignments.build
        @topic.assignment = @assignment
        @topic.save!
        expect(@topic.assignment).to be_present

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { assignment: { set_assignment: false } })
        @topic.reload
        @assignment.reload

        expect(@topic.title).to eq "Topic 1"
        expect(@topic.assignment).to be_nil
        expect(@topic.old_assignment_id).to eq @assignment.id
        expect(@assignment).to be_deleted
      end

      it "allows editing an assignment on update" do
        @assignment = @topic.context.assignments.build(points_possible: 50)
        @topic.assignment = @assignment
        @topic.save!
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { assignment: { points_possible: 100 } })

        expect(@assignment.reload.points_possible).to eq 100
      end

      it "does not circumvent assignment permissions when updating" do
        @assignment = @topic.context.assignments.build(points_possible: 50)
        @topic.assignment = @assignment
        @topic.save!
        account_admin_user_with_role_changes(role_changes: RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS.index_with(false))
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { assignment: { points_possible: 100 } },
                 {},
                 { expected_status: 403 })

        expect(@assignment.reload.points_possible).to eq 50
      end

      it "nulls availability dates on the topic if assignment ones are provided" do
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { delayed_post_at: 2.weeks.ago.as_json,
                   lock_at: 1.week.ago.as_json,
                   assignment: { unlock_at: 1.week.from_now.as_json, lock_at: 2.weeks.from_now.as_json } })

        expect(@topic.reload.assignment.reload.unlock_at).to be > Time.zone.now
        expect(@topic.assignment.lock_at).to be > Time.zone.now
        expect(@topic).not_to be_locked
        expect(@topic.delayed_post_at).to be_nil
        expect(@topic.lock_at).to be_nil

        # should work even if the assignment dates are nil
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { delayed_post_at: 2.weeks.ago.as_json,
                   lock_at: 1.week.ago.as_json,
                   assignment: { unlock_at: nil, lock_at: nil } })
        expect(@topic.reload.assignment.reload.unlock_at).to be_nil
        expect(@topic.assignment.lock_at).to be_nil
        expect(@topic.delayed_post_at).to be_nil
        expect(@topic.lock_at).to be_nil
      end

      it "updates due dates with cache enabled" do
        old_due_date = 1.day.ago
        @assignment = @topic.context.assignments.build
        @assignment.due_at = old_due_date
        @topic.assignment = @assignment
        @topic.save!
        expect(@topic.assignment).to be_present

        new_due_date = 2.days.ago
        enable_cache do
          Timecop.freeze do
            api_call(:put,
                     "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                     { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                     { assignment: { due_at: new_due_date.iso8601 } })
            @topic.reload
          end
          expect(@topic.assignment.overridden_for(@user).due_at.iso8601).to eq new_due_date.iso8601
        end
      end

      it "updates due dates with cache enabled and overrides already present" do
        old_due_date = 1.day.ago
        @assignment = @topic.context.assignments.build
        @assignment.due_at = old_due_date
        @topic.assignment = @assignment
        @topic.save!
        expect(@topic.assignment).to be_present

        lock_at_date = 1.day.from_now
        assignment_override_model(assignment: @assignment, lock_at: lock_at_date)
        @override.set = @course.default_section
        @override.save!

        new_due_date = 2.days.ago
        enable_cache do
          Timecop.freeze do
            api_call(:put,
                     "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                     { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                     { assignment: { due_at: new_due_date.iso8601 } })
            @topic.reload
          end
          expect(@topic.assignment.overridden_for(@user).due_at.iso8601).to eq new_due_date.iso8601
        end
      end

      it "transfers assignment group category to the discussion" do
        group_category = @course.group_categories.create(name: "watup")
        group = group_category.groups.create!(name: "group1", context: @course)
        group.add_user(@user)
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { assignment: { group_category_id: group_category.id } })
        @topic.reload

        expect(@topic.title).to eq "Topic 1"
        expect(@topic.group_category).to eq group_category
        expect(@topic.assignment).to be_present
        expect(@topic.assignment.group_category).to be_nil
      end

      it "allows pinning a topic" do
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { pinned: true })
        expect(@topic.reload).to be_pinned
      end

      it "allows unpinning a topic" do
        @topic.update_attribute(:pinned, true)
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { pinned: false })
        expect(@topic.reload).not_to be_pinned
      end

      it "allows unlocking a locked topic" do
        @topic.lock!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { locked: false })

        @topic.reload
        expect(@topic).not_to be_locked
      end

      it "allows locking a topic after due date" do
        due_date = 1.week.ago
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { assignment: { due_at: due_date.as_json } })
        @topic.reload
        expect(@topic.assignment.due_at.to_i).to eq due_date.to_i

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { locked: true })

        @topic.reload
        expect(@topic).to be_locked

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { locked: false })

        @topic.reload
        expect(@topic).not_to be_locked
      end

      it "does not allow locking a topic before due date" do
        due_date = 1.week.from_now
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { assignment: { due_at: due_date.as_json } })
        @topic.reload
        expect(@topic.assignment.due_at.to_i).to eq due_date.to_i

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { locked: true },
                 {},
                 expected_status: 500)

        @topic.reload
        expect(@topic).not_to be_locked
      end

      it "update sort order field" do
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { sort_order: "asc", sort_order_locked: "true" })
        @topic.reload
        expect(@topic.sort_order).to eq "asc"
        expect(@topic.sort_order_locked).to be true
      end

      it "update expanded field order" do
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "update", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 { expanded: "true", expanded_locked: "true" })
        @topic.reload
        expect(@topic.expanded).to be true
        expect(@topic.expanded_locked).to be true
      end
    end

    describe "DELETE 'destroy'" do
      it "requires authorization" do
        @user = user_factory(active_all: true)
        api_call(:delete,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "destroy", format: "json", course_id: @course.to_param, topic_id: @topic.to_param },
                 {},
                 {},
                 expected_status: 403)
        expect(@topic.reload).not_to be_deleted
      end

      it "deletes the topic" do
        api_call(:delete,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                 { controller: "discussion_topics", action: "destroy", format: "json", course_id: @course.to_param, topic_id: @topic.to_param })
        expect(@topic.reload).to be_deleted
      end
    end
  end

  context "differentiated assignments" do
    def calls_display_topic(topic, opts = { except: [] })
      get_index(topic.context)
      expect(JSON.parse(response.body).to_s).to include(topic.assignment.title.to_s)

      calls = %i[get_show get_entries get_replies add_entry add_reply]
      calls.reject! { |call| opts[:except].include?(call) }
      calls.each { |call| expect(send(call, topic).to_s).not_to eq "401" }
    end

    def calls_do_not_show_topic(topic)
      get_index(topic.context)
      expect(JSON.parse(response.body).to_s).not_to include(topic.assignment.title.to_s)

      calls = %i[get_show get_entries get_replies add_entry add_reply]
      calls.each { |call| expect(send(call, topic).to_s).to eq "403" }
    end

    def get_index(course)
      raw_api_call(:get,
                   "/api/v1/courses/#{course.id}/discussion_topics.json",
                   { controller: "discussion_topics", action: "index", format: "json", course_id: course.id.to_s })
    end

    def get_show(topic)
      raw_api_call(:get,
                   "/api/v1/courses/#{topic.context.id}/discussion_topics/#{topic.id}",
                   { controller: "discussion_topics_api", action: "show", format: "json", course_id: topic.context.id.to_s, topic_id: topic.id.to_s })
    end

    def get_entries(topic)
      url = "/api/v1/courses/#{topic.context.id}/discussion_topics/#{topic.id}/entries"
      raw_api_call(:get, url, controller: "discussion_topics_api", action: "entries", format: "json", course_id: topic.context.to_param, topic_id: topic.id.to_s)
    end

    def get_replies(topic)
      raw_api_call(:get,
                   "/api/v1/courses/#{topic.context.id}/discussion_topics/#{topic.id}/entries/#{topic.discussion_entries.last.id}/replies",
                   { controller: "discussion_topics_api", action: "replies", format: "json", course_id: topic.context.id.to_s, topic_id: topic.id.to_s, entry_id: topic.discussion_entries.last.id.to_s })
    end

    def add_entry(topic)
      raw_api_call(:post,
                   "/api/v1/courses/#{topic.context.id}/discussion_topics/#{topic.id}/entries.json",
                   { controller: "discussion_topics_api",
                     action: "add_entry",
                     format: "json",
                     course_id: topic.context.id.to_s,
                     topic_id: topic.id.to_s },
                   { message: "example entry" })
    end

    def add_reply(topic)
      raw_api_call(:post,
                   "/api/v1/courses/#{topic.context.id}/discussion_topics/#{topic.id}/entries/#{topic.discussion_entries.last.id}/replies.json",
                   { controller: "discussion_topics_api",
                     action: "add_reply",
                     format: "json",
                     course_id: topic.context.id.to_s,
                     topic_id: topic.id.to_s,
                     entry_id: topic.discussion_entries.last.id.to_s },
                   { message: "example reply" })
    end

    def create_graded_discussion_for_da(assignment_opts = {})
      assignment = @course.assignments.create!(assignment_opts)
      assignment.submission_types = "discussion_topic"
      assignment.save!
      topic = @course.discussion_topics.create!(user: @teacher, title: assignment_opts[:title], message: "woo", assignment:)
      entry = topic.discussion_entries.create!(message: "second message", user: @student)
      entry.save
      [assignment, topic]
    end

    before do
      course_with_teacher(active_all: true, user: user_with_pseudonym)
      @student_with_override, @student_without_override = create_users(2, return_type: :record)

      @assignment_1, @topic_with_restricted_access = create_graded_discussion_for_da(title: "only visible to student one", only_visible_to_overrides: true)
      @assignment_2, @topic_visible_to_all = create_graded_discussion_for_da(title: "assigned to all", only_visible_to_overrides: false)

      @course.enroll_student(@student_without_override, enrollment_state: "active")
      @section = @course.course_sections.create!(name: "test section")
      student_in_section(@section, user: @student_with_override)
      create_section_override_for_assignment(@assignment_1, { course_section: @section })

      @observer = User.create
      @observer_enrollment = @course.enroll_user(@observer, "ObserverEnrollment", section: @course.course_sections.first, enrollment_state: "active")
      @observer_enrollment.update_attribute(:associated_user_id, @student_with_override.id)
    end

    it "lets the teacher see all topics" do
      @user = @teacher
      [@topic_with_restricted_access, @topic_visible_to_all].each { |t| calls_display_topic(t) }
    end

    it "lets students with visibility see topics" do
      @user = @student_with_override
      [@topic_with_restricted_access, @topic_visible_to_all].each { |t| calls_display_topic(t) }
    end

    it "gives observers the same visibility as their student" do
      @user = @observer
      [@topic_with_restricted_access, @topic_visible_to_all].each { |t| calls_display_topic(t, except: [:add_entry, :add_reply]) }
    end

    it "observers without students see all" do
      @observer_enrollment.update_attribute(:associated_user_id, nil)
      @user = @observer
      [@topic_with_restricted_access, @topic_visible_to_all].each { |t| calls_display_topic(t, except: [:add_entry, :add_reply]) }
    end

    it "restricts access to students without visibility" do
      @user = @student_without_override
      calls_do_not_show_topic(@topic_with_restricted_access)
      calls_display_topic(@topic_visible_to_all)
    end

    it "doesnt show extra assignments with overrides in the index" do
      @assignment_3, @topic_assigned_to_empty_section = create_graded_discussion_for_da(title: "assigned to none", only_visible_to_overrides: true)
      @unassigned_section = @course.course_sections.create!(name: "unassigned section")
      create_section_override_for_assignment(@assignment_3, { course_section: @unassigned_section })

      @user = @student_with_override
      get_index(@course)
      expect(JSON.parse(response.body).to_s).not_to include(@assignment_3.title.to_s)
    end

    it "doesnt hide topics without assignment" do
      @non_graded_topic = @course.discussion_topics.create!(user: @teacher, title: "non_graded_topic", message: "hi")

      @user = @student_without_override
      get_index(@course)
      expect(JSON.parse(response.body).to_s).to include(@non_graded_topic.title.to_s)
    end
  end

  it "translates user content in topics" do
    should_translate_user_content(@course) do |user_content|
      @topic ||= create_topic(@course, title: "Topic 1", message: user_content)
      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics",
        { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s }
      )
      expect(json.size).to eq 1
      json.first["message"]
    end
  end

  it "translates user content in topics without verifiers" do
    should_translate_user_content(@course, false) do |user_content|
      @topic ||= create_topic(@course, title: "Topic 1", message: user_content)
      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics",
        { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s, no_verifiers: true }
      )
      expect(json.size).to eq 1
      json.first["message"]
    end
  end

  it "paginates by the per_page" do
    100.times { |i| @course.discussion_topics.create!(title: i.to_s, message: i.to_s) }
    expect(@course.discussion_topics.count).to eq 100
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=90",
                    { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s, per_page: "90" })

    expect(json.length).to eq 90
  end

  it "paginates and return proper pagination headers for courses" do
    7.times { |i| @course.discussion_topics.create!(title: i.to_s, message: i.to_s) }
    expect(@course.discussion_topics.count).to eq 7
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/discussion_topics.json?per_page=3",
                    { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s, per_page: "3" })

    expect(json.length).to eq 3
    links = response.headers["Link"].split(",")
    expect(links.all? { |l| l =~ %r{api/v1/courses/#{@course.id}/discussion_topics} }).to be_truthy
    expect(links.find { |l| l.include?('rel="next"') }).to match(/page=2&per_page=3>/)
    expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1&per_page=3>/)
    expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3&per_page=3>/)

    # get the last page
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/discussion_topics.json?page=3&per_page=3",
                    { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s, page: "3", per_page: "3" })
    expect(json.length).to eq 1
    links = response.headers["Link"].split(",")
    expect(links.all? { |l| l =~ %r{api/v1/courses/#{@course.id}/discussion_topics} }).to be_truthy
    expect(links.find { |l| l.include?('rel="prev"') }).to match(/page=2&per_page=3>/)
    expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1&per_page=3>/)
    expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3&per_page=3>/)
  end

  context "where double testing verifiers with disable_adding_uuid_verifier_in_api ff" do
    before do
      @attachment = create_attachment(@course)
    end

    double_testing_with_disable_adding_uuid_verifier_in_api_ff do
      it "works with groups" do
        group_category = @course.group_categories.create(name: "watup")
        group = group_category.groups.create!(name: "group1", context: @course)
        group.add_user(@user)
        gtopic = create_topic(group, title: "Group Topic 1", message: "<p>content here</p>", attachment: @attachment)

        json = api_call(:get,
                        "/api/v1/groups/#{group.id}/discussion_topics.json",
                        { controller: "discussion_topics", action: "index", format: "json", group_id: group.id.to_s }).first
        expected = {
          "read_state" => "read",
          "unread_count" => 0,
          "user_can_see_posts" => true,
          "is_section_specific" => gtopic.is_section_specific,
          "summary_enabled" => gtopic.summary_enabled,
          "subscribed" => true,
          "podcast_url" => nil,
          "podcast_has_student_posts" => false,
          "require_initial_post" => nil,
          "title" => "Group Topic 1",
          "discussion_subentry_count" => 0,
          "assignment_id" => nil,
          "published" => true,
          "can_unpublish" => true,
          "delayed_post_at" => nil,
          "lock_at" => nil,
          "created_at" => gtopic.created_at.iso8601,
          "id" => gtopic.id,
          "is_announcement" => false,
          "user_name" => @user.name,
          "last_reply_at" => gtopic.last_reply_at.as_json,
          "message" => "<p>content here</p>",
          "pinned" => false,
          "position" => gtopic.position,
          "url" => "http://www.example.com/groups/#{group.id}/discussion_topics/#{gtopic.id}",
          "html_url" => "http://www.example.com/groups/#{group.id}/discussion_topics/#{gtopic.id}",
          "attachments" =>
            [{ "content-type" => "text/plain",
               "url" => "http://www.example.com/files/#{@attachment.id}/download?download_frd=1#{"&verifier=#{@attachment.uuid}" unless disable_adding_uuid_verifier_in_api}",
               "filename" => "content.txt",
               "display_name" => "content.txt",
               "id" => @attachment.id,
               "folder_id" => @attachment.folder_id,
               "size" => @attachment.size,
               "unlock_at" => nil,
               "locked" => false,
               "hidden" => false,
               "lock_at" => nil,
               "locked_for_user" => false,
               "hidden_for_user" => false,
               "created_at" => @attachment.created_at.as_json,
               "updated_at" => @attachment.updated_at.as_json,
               "upload_status" => "success",
               "thumbnail_url" => nil,
               "modified_at" => @attachment.modified_at.as_json,
               "mime_class" => @attachment.mime_class,
               "media_entry_id" => @attachment.media_entry_id,
               "category" => "uncategorized",
               "visibility_level" => @attachment.visibility_level }],
          "posted_at" => gtopic.posted_at.as_json,
          "root_topic_id" => nil,
          "topic_children" => [],
          "group_topic_children" => [],
          "discussion_type" => "threaded",
          "permissions" => { "delete" => true, "attach" => true, "update" => true, "reply" => true, "manage_assign_to" => false },
          "locked" => false,
          "can_lock" => true,
          "comments_disabled" => false,
          "locked_for_user" => false,
          "author" => user_display_json(gtopic.user, gtopic.context).stringify_keys!,
          "group_category_id" => nil,
          "can_group" => true,
          "allow_rating" => false,
          "only_graders_can_rate" => false,
          "sort_by_rating" => false,
          "sort_order" => "desc",
          "sort_order_locked" => false,
          "expanded" => false,
          "expanded_locked" => false,
          "todo_date" => nil,
          "anonymous_state" => nil,
          "ungraded_discussion_overrides" => nil,
        }
        expect(json.sort.to_h).to eq expected.sort.to_h
      end
    end
  end

  it "works with account groups" do
    @sub_account = Account.default.sub_accounts.create!
    @group = @sub_account.groups.create! name: "Account group"
    @group.add_user(@user)

    announcement = @group.announcements.create!(
      title: "Group Announcement",
      message: "Group",
      user: @user
    )
    json = api_call(
      :get,
      "/api/v1/groups/#{@group.id}/discussion_topics?only_announcements=true&per_page=40&page=1&filter_by=all&no_avatar_fallback=1",
      {
        controller: "discussion_topics",
        action: "index",
        format: "json",
        group_id: @group.id.to_s,
        only_announcements: "true",
        per_page: 40,
        page: 1,
        filter_by: "all",
        no_avatar_fallback: 1,
      }
    ).first

    expected_response = {
      "allow_rating" => false,
      "anonymous_state" => nil,
      "assignment_id" => nil,
      "attachments" => [],
      "author" => user_display_json(announcement.user, announcement.context).stringify_keys!,
      "can_group" => false,
      "can_lock" => true,
      "can_unpublish" => false,
      "comments_disabled" => false,
      "created_at" => announcement.created_at.iso8601,
      "delayed_post_at" => nil,
      "discussion_subentry_count" => 0,
      "discussion_type" => "threaded",
      "group_category_id" => nil,
      "group_topic_children" => [],
      "html_url" => "http://www.example.com/groups/#{@group.id}/discussion_topics/#{announcement.id}",
      "id" => announcement.id,
      "is_announcement" => true,
      "is_section_specific" => false,
      "summary_enabled" => false,
      "last_reply_at" => announcement.last_reply_at.as_json,
      "lock_at" => nil,
      "locked" => false,
      "locked_for_user" => false,
      "message" => "Group",
      "only_graders_can_rate" => false,
      "permissions" => {
        "attach" => false,
        "update" => true,
        "reply" => true,
        "delete" => true,
        "manage_assign_to" => false
      },
      "pinned" => false,
      "podcast_has_student_posts" => false,
      "podcast_url" => nil,
      "position" => 1,
      "posted_at" => announcement.posted_at.as_json,
      "published" => true,
      "read_state" => "read",
      "require_initial_post" => nil,
      "root_topic_id" => nil,
      "sort_by_rating" => false,
      "subscribed" => false,
      "subscription_hold" => "topic_is_announcement",
      "title" => "Group Announcement",
      "todo_date" => nil,
      "topic_children" => [],
      "unread_count" => 0,
      "url" => "http://www.example.com/groups/#{@group.id}/discussion_topics/#{announcement.id}",
      "user_can_see_posts" => true,
      "user_name" => @user.name,
      "ungraded_discussion_overrides" => nil,
      "sort_order" => "desc",
      "sort_order_locked" => false,
      "expanded" => false,
      "expanded_locked" => false,
    }

    expect(response).to have_http_status(:ok)
    expect(json.sort.to_h).to eq(expected_response)
  end

  it "paginates and return proper pagination headers for groups" do
    group_category = @course.group_categories.create(name: "watup")
    group = group_category.groups.create!(name: "group1", context: @course)
    7.times { |i| create_topic(group, title: i.to_s, message: i.to_s) }
    expect(group.discussion_topics.count).to eq 7
    json = api_call(:get,
                    "/api/v1/groups/#{group.id}/discussion_topics.json?per_page=3",
                    { controller: "discussion_topics", action: "index", format: "json", group_id: group.id.to_s, per_page: "3" })

    expect(json.length).to eq 3
    links = response.headers["Link"].split(",")
    expect(links.all? { |l| l =~ %r{api/v1/groups/#{group.id}/discussion_topics} }).to be_truthy
    expect(links.find { |l| l.include?('rel="next"') }).to match(/page=2&per_page=3>/)
    expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1&per_page=3>/)
    expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3&per_page=3>/)

    # get the last page
    json = api_call(:get,
                    "/api/v1/groups/#{group.id}/discussion_topics.json?page=3&per_page=3",
                    { controller: "discussion_topics", action: "index", format: "json", group_id: group.id.to_s, page: "3", per_page: "3" })
    expect(json.length).to eq 1
    links = response.headers["Link"].split(",")
    expect(links.all? { |l| l =~ %r{api/v1/groups/#{group.id}/discussion_topics} }).to be_truthy
    expect(links.find { |l| l.include?('rel="prev"') }).to match(/page=2&per_page=3>/)
    expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1&per_page=3>/)
    expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3&per_page=3>/)
  end

  it "fulfills module viewed requirements when marking a topic read" do
    @module = @course.context_modules.create!(name: "some module")
    @topic = create_topic(@course, title: "Topic 1", message: "<p>content here</p>")
    tag = @module.add_item(id: @topic.id, type: "discussion_topic")
    @module.completion_requirements = { tag.id => { type: "must_view" } }
    @module.save!
    course_with_student(course: @course, active_all: true)

    expect(@module.evaluate_for(@user)).to be_unlocked
    raw_api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/read",
                 { controller: "discussion_topics_api",
                   action: "mark_topic_read",
                   format: "json",
                   course_id: @course.id.to_s,
                   topic_id: @topic.id.to_s })
    expect(@module.evaluate_for(@user)).to be_completed
  end

  it "fulfills module viewed requirements when re-marking a topic read" do
    @module = @course.context_modules.create!(name: "some module")
    @topic = create_topic(@course, title: "Topic 1", message: "<p>content here</p>")
    course_with_student(course: @course, active_all: true)
    raw_api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/read",
                 { controller: "discussion_topics_api",
                   action: "mark_topic_read",
                   format: "json",
                   course_id: @course.id.to_s,
                   topic_id: @topic.id.to_s })

    tag = @module.add_item(id: @topic.id, type: "discussion_topic")
    @module.completion_requirements = { tag.id => { type: "must_view" } }
    @module.save!

    expect(@module.evaluate_for(@user)).to be_unlocked
    raw_api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/read",
                 { controller: "discussion_topics_api",
                   action: "mark_topic_read",
                   format: "json",
                   course_id: @course.id.to_s,
                   topic_id: @topic.id.to_s })
    expect(@module.evaluate_for(@user)).to be_completed
  end

  it "fulfills module viewed requirements when marking a topic and all its entries read" do
    @module = @course.context_modules.create!(name: "some module")
    @topic = create_topic(@course, title: "Topic 1", message: "<p>content here</p>")
    tag = @module.add_item(id: @topic.id, type: "discussion_topic")
    @module.completion_requirements = { tag.id => { type: "must_view" } }
    @module.save!
    course_with_student(course: @course, active_all: true)

    expect(@module.evaluate_for(@user)).to be_unlocked
    raw_api_call(:put,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/read_all",
                 { controller: "discussion_topics_api",
                   action: "mark_all_read",
                   format: "json",
                   course_id: @course.id.to_s,
                   topic_id: @topic.id.to_s })
    expect(@module.evaluate_for(@user)).to be_completed
  end

  context "creating an entry under a topic" do
    before :once do
      @topic = create_topic(@course, title: "Topic 1", message: "<p>content here</p>")
      @message = "my message"
      @attachment = create_attachment(@course)
    end

    it "allows creating an entry under a topic and create it correctly" do
      json = api_call(
        :post,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { controller: "discussion_topics_api",
          action: "add_entry",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s },
        { message: @message }
      )
      expect(json).not_to be_nil
      expect(json["id"]).not_to be_nil
      @entry = DiscussionEntry.where(id: json["id"]).first
      expect(@entry).not_to be_nil
      expect(@entry.discussion_topic).to eq @topic
      expect(@entry.user).to eq @user
      expect(@entry.parent_entry).to be_nil
      expect(@entry.message).to eq @message
    end

    it "creates attachment associations for an entry is a file is attached" do
      aa_test_data = AttachmentAssociationsSpecHelper.new(@user.account, @user)
      json = api_call(
        :post,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { controller: "discussion_topics_api",
          action: "add_entry",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s },
        { message: aa_test_data.base_html }
      )
      expect(json).not_to be_nil
      expect(json["id"]).not_to be_nil
      aas = AttachmentAssociation.where(context_type: "DiscussionEntry", context_id: json["id"])
      expect(aas.count).to eq 1
      expect(aas.first.attachment_id).to eq aa_test_data.attachment1.id
    end

    it "does not allow students to create an entry under a topic that is closed for comments" do
      @topic.lock!
      student_in_course(course: @course, active_all: true)
      api_call(
        :post,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { controller: "discussion_topics_api",
          action: "add_entry",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s },
        { message: @message },
        {},
        expected_status: 403
      )
    end

    it "does not allow students to create an entry under an announcement that is closed for comments" do
      @announcement = @course.announcements.create!(message: "lorem ipsum", locked: true)
      student_in_course(course: @course, active_all: true)
      api_call(
        :post,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@announcement.id}/entries.json",
        { controller: "discussion_topics_api",
          action: "add_entry",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @announcement.id.to_s },
        { message: @message },
        {},
        expected_status: 403
      )
    end

    it "returns json representation of the new entry" do
      json = api_call(
        :post,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { controller: "discussion_topics_api",
          action: "add_entry",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s },
        { message: @message }
      )
      @entry = DiscussionEntry.where(id: json["id"]).first
      expect(json).to eq({
                           "id" => @entry.id,
                           "parent_id" => @entry.parent_id,
                           "user_id" => @user.id,
                           "user_name" => @user.name,
                           "user" => user_display_json(@user, @course).stringify_keys!,
                           "read_state" => "read",
                           "forced_read_state" => false,
                           "message" => @message,
                           "created_at" => @entry.created_at.utc.iso8601,
                           "updated_at" => @entry.updated_at.as_json,
                           "rating_sum" => nil,
                           "rating_count" => nil,
                         })
    end

    it "allows creating a reply to an existing top-level entry" do
      top_entry = create_entry(@topic, message: "top-level message")
      json = api_call(
        :post,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{top_entry.id}/replies.json",
        { controller: "discussion_topics_api",
          action: "add_reply",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s,
          entry_id: top_entry.id.to_s },
        { message: @message }
      )
      @entry = DiscussionEntry.where(id: json["id"]).first
      expect(@entry.parent_entry).to eq top_entry
    end

    it "allows including attachments on top-level entries" do
      data = fixture_file_upload("docs/txt.txt", "text/plain", true)
      json = api_call(
        :post,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { controller: "discussion_topics_api",
          action: "add_entry",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s },
        { message: @message, attachment: data }
      )
      @entry = DiscussionEntry.where(id: json["id"]).first
      expect(@entry.attachment).not_to be_nil
      expect(@entry.attachment.context).to eql @user
    end

    it "includes attachments on replies to top-level entries" do
      top_entry = create_entry(@topic, message: "top-level message")
      data = fixture_file_upload("docs/txt.txt", "text/plain", true)
      json = api_call(
        :post,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{top_entry.id}/replies.json",
        { controller: "discussion_topics_api",
          action: "add_reply",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s,
          entry_id: top_entry.id.to_s },
        { message: @message, attachment: data }
      )
      @entry = DiscussionEntry.where(id: json["id"]).first
      expect(@entry.attachment).not_to be_nil
      expect(@entry.attachment.context).to eql @user
    end

    double_testing_with_disable_adding_uuid_verifier_in_api_ff do
      it "handles duplicate files when attaching" do
        data = fixture_file_upload("docs/txt.txt", "text/plain", true)
        attachment_model context: @user, uploaded_data: data, folder: Folder.unfiled_folder(@user)
        json = api_call(
          :post,
          "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
          { controller: "discussion_topics_api",
            action: "add_entry",
            format: "json",
            course_id: @course.id.to_s,
            topic_id: @topic.id.to_s },
          { message: @message, attachment: data }
        )
        expect(json["attachment"]).to be_present
        new_file = Attachment.find(json["attachment"]["id"])
        expect(new_file.display_name).to match(/txt-[0-9]+\.txt/)
        expect(json["attachment"]["display_name"]).to eq new_file.display_name
        expect(json["attachment"]["url"]).to include "verifier=" unless disable_adding_uuid_verifier_in_api
      end
    end

    it "creates a submission from an entry on a graded topic" do
      @topic.assignment = assignment_model(course: @course)
      @topic.save

      student_in_course(active_all: true)
      expect(@user.submissions.not_placeholder).to be_empty

      api_call(
        :post,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { controller: "discussion_topics_api",
          action: "add_entry",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s },
        { message: @message }
      )

      @user.reload
      expect(@user.submissions.not_placeholder.size).to eq 1
      expect(@user.submissions.not_placeholder.first.submission_type).to eq "discussion_topic"
    end

    it "creates a submission from a reply on a graded topic" do
      top_entry = create_entry(@topic, message: "top-level message")

      @topic.assignment = assignment_model(course: @course)
      @topic.save

      student_in_course(active_all: true)
      expect(@user.submissions.not_placeholder).to be_empty

      api_call(
        :post,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{top_entry.id}/replies.json",
        { controller: "discussion_topics_api",
          action: "add_reply",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s,
          entry_id: top_entry.id.to_s },
        { message: @message }
      )

      @user.reload
      expect(@user.submissions.not_placeholder.size).to eq 1
      expect(@user.submissions.not_placeholder.first.submission_type).to eq "discussion_topic"
    end
  end

  context "listing top-level discussion entries" do
    before :once do
      @topic = create_topic(@course, title: "topic", message: "topic")
      @attachment = create_attachment(@course)
      @entry = create_entry(@topic, message: "first top-level entry", attachment: @attachment)
      @reply = create_reply(@entry, message: "reply to first top-level entry")
    end

    context "when file_association_access ff is enabled" do
      it "tags attachment urls with location of the asset" do
        @attachment.root_account.enable_feature!(:file_association_access)
        message = "<img src='/courses/#{@course.id}/files/#{@attachment.id}'>"
        @entry.update!(message:)
        json = api_call(
          :get,
          "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
          { controller: "discussion_topics_api",
            action: "entries",
            format: "json",
            course_id: @course.id.to_s,
            topic_id: @topic.id.to_s }
        )

        expect(json.first["message"]).to include("location=#{@entry.asset_string}")
      end
    end

    it "returns top level entries for a topic" do
      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { controller: "discussion_topics_api",
          action: "entries",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s }
      )
      expect(json.size).to eq 1
      entry_json = json.first
      expect(entry_json["id"]).to eq @entry.id
    end

    double_testing_with_disable_adding_uuid_verifier_in_api_ff do
      it "returns attachments on top level entries" do
        json = api_call(
          :get,
          "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
          { controller: "discussion_topics_api",
            action: "entries",
            format: "json",
            course_id: @course.id.to_s,
            topic_id: @topic.id.to_s }
        )
        entry_json = json.first
        expect(entry_json["attachment"]).not_to be_nil
        expect(entry_json["attachment"]["url"]).to eq "http://www.example.com/files/#{@attachment.id}/download?download_frd=1#{"&verifier=#{@attachment.uuid}" unless disable_adding_uuid_verifier_in_api}"
      end
    end

    it "includes replies on top level entries" do
      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { controller: "discussion_topics_api",
          action: "entries",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s }
      )
      entry_json = json.first
      expect(entry_json["recent_replies"].size).to eq 1
      expect(entry_json["has_more_replies"]).to be_falsey
      reply_json = entry_json["recent_replies"].first
      expect(reply_json["id"]).to eq @reply.id
    end

    it "sorts top-level entries by descending created_at" do
      @older_entry = create_entry(@topic, message: "older top-level entry", created_at: 1.minute.ago)
      @newer_entry = create_entry(@topic, message: "newer top-level entry", created_at: 1.minute.from_now)
      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { controller: "discussion_topics_api",
          action: "entries",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s }
      )
      expect(json.size).to eq 3
      expect(json.first["id"]).to eq @newer_entry.id
      expect(json.last["id"]).to eq @older_entry.id
    end

    it "sorts replies included on top-level entries by descending created_at" do
      @older_reply = create_reply(@entry, message: "older reply", created_at: 1.minute.ago)
      @newer_reply = create_reply(@entry, message: "newer reply", created_at: 1.minute.from_now)
      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { controller: "discussion_topics_api",
          action: "entries",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s }
      )
      expect(json.size).to eq 1
      reply_json = json.first["recent_replies"]
      expect(reply_json.size).to eq 3
      expect(reply_json.first["id"]).to eq @newer_reply.id
      expect(reply_json.last["id"]).to eq @older_reply.id
    end

    it "paginates top-level entries" do
      # put in lots of entries
      entries = []
      7.times { |i| entries << create_entry(@topic, message: i.to_s, created_at: Time.zone.now + (i + 1).minutes) }

      # first page
      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json?per_page=3",
        { controller: "discussion_topics_api",
          action: "entries",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s,
          per_page: "3" }
      )
      expect(json.length).to eq 3
      expect(json.pluck("id")).to eq entries.last(3).reverse.map(&:id)
      links = response.headers["Link"].split(",")
      expect(links.all? { |l| l =~ %r{api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries} }).to be_truthy
      expect(links.find { |l| l.include?('rel="next"') }).to match(/page=2&per_page=3>/)
      expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1&per_page=3>/)
      expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3&per_page=3>/)

      # last page
      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json?page=3&per_page=3",
        { controller: "discussion_topics_api",
          action: "entries",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s,
          page: "3",
          per_page: "3" }
      )
      expect(json.length).to eq 2
      expect(json.pluck("id")).to eq [entries.first, @entry].map(&:id)
      links = response.headers["Link"].split(",")
      expect(links.all? { |l| l =~ %r{api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries} }).to be_truthy
      expect(links.find { |l| l.include?('rel="prev"') }).to match(/page=2&per_page=3>/)
      expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1&per_page=3>/)
      expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3&per_page=3>/)
    end

    it "only includes the first 10 replies for each top-level entry" do
      # put in lots of replies
      replies = []
      12.times { |i| replies << create_reply(@entry, message: i.to_s, created_at: Time.zone.now + (i + 1).minutes) }

      # get entry
      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { controller: "discussion_topics_api",
          action: "entries",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s }
      )
      expect(json.length).to eq 1
      reply_json = json.first["recent_replies"]
      expect(reply_json.length).to eq 10
      expect(reply_json.pluck("id")).to eq replies.last(10).reverse.map(&:id)
      expect(json.first["has_more_replies"]).to be_truthy
    end
  end

  context "listing replies" do
    before :once do
      @topic = create_topic(@course, title: "topic", message: "topic")
      @entry = create_entry(@topic, message: "top-level entry")
      @reply = create_reply(@entry, message: "first reply")
    end

    it "returns replies for an entry" do
      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
        { controller: "discussion_topics_api",
          action: "replies",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s,
          entry_id: @entry.id.to_s }
      )
      expect(json.size).to eq 1
      expect(json.first["id"]).to eq @reply.id
    end

    it "translates user content in replies" do
      should_translate_user_content(@course) do |user_content|
        @reply.update_attribute("message", user_content)
        json = api_call(
          :get,
          "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
          { controller: "discussion_topics_api",
            action: "replies",
            format: "json",
            course_id: @course.id.to_s,
            topic_id: @topic.id.to_s,
            entry_id: @entry.id.to_s }
        )
        expect(json.size).to eq 1
        json.first["message"]
      end
    end

    it "translates user content in replies without verifiers" do
      should_translate_user_content(@course, false) do |user_content|
        @reply.update_attribute("message", user_content)
        json = api_call(
          :get,
          "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
          { controller: "discussion_topics_api",
            action: "replies",
            format: "json",
            course_id: @course.id.to_s,
            topic_id: @topic.id.to_s,
            entry_id: @entry.id.to_s,
            no_verifiers: true }
        )
        expect(json.size).to eq 1
        json.first["message"]
      end
    end

    it "sorts replies by descending created_at" do
      @older_reply = create_reply(@entry, message: "older reply", created_at: 1.minute.ago)
      @newer_reply = create_reply(@entry, message: "newer reply", created_at: 1.minute.from_now)
      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
        { controller: "discussion_topics_api",
          action: "replies",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s,
          entry_id: @entry.id.to_s }
      )
      expect(json.size).to eq 3
      expect(json.first["id"]).to eq @newer_reply.id
      expect(json.last["id"]).to eq @older_reply.id
    end

    it "paginates replies" do
      # put in lots of replies
      replies = []
      7.times { |i| replies << create_reply(@entry, message: i.to_s, created_at: Time.zone.now + (i + 1).minutes) }

      # first page
      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json?per_page=3",
        { controller: "discussion_topics_api",
          action: "replies",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s,
          entry_id: @entry.id.to_s,
          per_page: "3" }
      )
      expect(json.length).to eq 3
      expect(json.pluck("id")).to eq replies.last(3).reverse.map(&:id)
      links = response.headers["Link"].split(",")
      expect(links.all? { |l| l =~ %r{api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies} }).to be_truthy
      expect(links.find { |l| l.include?('rel="next"') }).to match(/page=2&per_page=3>/)
      expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1&per_page=3>/)
      expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3&per_page=3>/)

      # last page
      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json?page=3&per_page=3",
        { controller: "discussion_topics_api",
          action: "replies",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s,
          entry_id: @entry.id.to_s,
          page: "3",
          per_page: "3" }
      )
      expect(json.length).to eq 2
      expect(json.pluck("id")).to eq [replies.first, @reply].map(&:id)
      links = response.headers["Link"].split(",")
      expect(links.all? { |l| l =~ %r{api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies} }).to be_truthy
      expect(links.find { |l| l.include?('rel="prev"') }).to match(/page=2&per_page=3>/)
      expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1&per_page=3>/)
      expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3&per_page=3>/)
    end
  end

  # stolen and adjusted from spec/controllers/discussion_topics_controller_spec.rb
  context "require initial post" do
    before(:once) do
      course_with_student(active_all: true)

      @observer = user_factory(name: "Observer", active_all: true)
      e = @course.enroll_user(@observer, "ObserverEnrollment")
      e.associated_user = @student
      e.save
      @observer.reload

      course_with_teacher(course: @course, active_all: true)
      @context = @course
      discussion_topic_model
      @topic.require_initial_post = true
      @topic.save
    end

    describe "teacher" do
      before do
        @user = @teacher
        @url = "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries"
      end

      it "sees topic entries without posting" do
        @topic.reply_from(user: @student, text: "hai")
        json = api_call(:get,
                        @url,
                        controller: "discussion_topics_api",
                        action: "entries",
                        format: "json",
                        course_id: @course.to_param,
                        topic_id: @topic.to_param)

        expect(json.length).to eq 1
      end
    end

    describe "student" do
      before(:once) do
        @topic.reply_from(user: @teacher, text: "Lorem ipsum dolor")
        @user = @student
        @url = "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}"
      end

      it "sees topic information before posting" do
        api_call(:get,
                 @url,
                 controller: "discussion_topics_api",
                 action: "show",
                 format: "json",
                 course_id: @course.to_param,
                 topic_id: @topic.to_param)
        expect(response).to have_http_status :ok
      end

      it "does not see entries before posting" do
        raw_api_call(:get,
                     "#{@url}/entries",
                     controller: "discussion_topics_api",
                     action: "entries",
                     format: "json",
                     course_id: @course.to_param,
                     topic_id: @topic.to_param)
        expect(response.body).to eq "require_initial_post"
        expect(response).to have_http_status :forbidden
      end

      it "sees entries after posting" do
        @topic.reply_from(user: @student, text: "hai")
        api_call(:get,
                 "#{@url}/entries",
                 controller: "discussion_topics_api",
                 action: "entries",
                 format: "json",
                 course_id: @course.to_param,
                 topic_id: @topic.to_param)
        expect(response).to have_http_status :ok
      end
    end

    describe "observer" do
      before(:once) do
        @topic.reply_from(user: @teacher, text: "Lorem ipsum")
        @user = @observer
        @url = "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries"
      end

      it "does not see entries before posting" do
        raw_api_call(:get,
                     @url,
                     controller: "discussion_topics_api",
                     action: "entries",
                     format: "json",
                     course_id: @course.to_param,
                     topic_id: @topic.to_param)
        expect(response.body).to eq "require_initial_post"
        expect(response).to have_http_status :forbidden
      end

      it "sees entries after posting" do
        @topic.reply_from(user: @student, text: "Lorem ipsum dolor")
        api_call(:get,
                 @url,
                 controller: "discussion_topics_api",
                 action: "entries",
                 format: "json",
                 course_id: @course.to_param,
                 topic_id: @topic.to_param)
        expect(response).to have_http_status :ok
      end
    end
  end

  context "update entry" do
    before :once do
      @topic = create_topic(@course, title: "topic", message: "topic")
      @entry = create_entry(@topic, message: "<p>top-level entry</p>")
    end

    it "403s if the user can't update" do
      student_in_course(course: @course, user: user_with_pseudonym)
      api_call(:put,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { controller: "discussion_entries", action: "update", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, id: @entry.id.to_s },
               { message: "haxor" },
               {},
               expected_status: 403)
      expect(@entry.reload.message).to eq "<p>top-level entry</p>"
    end

    it "404s if the entry is deleted" do
      @entry.destroy
      api_call(:put,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { controller: "discussion_entries", action: "update", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, id: @entry.id.to_s },
               { message: "haxor" },
               {},
               expected_status: 404)
    end

    it "updates the message" do
      api_call(:put,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { controller: "discussion_entries", action: "update", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, id: @entry.id.to_s },
               { message: "<p>i had a spleling error</p>" })
      expect(@entry.reload.message).to eq "<p>i had a spleling error</p>"
    end

    it "updates attachment associations if the entry message has changed" do
      aa_test_data = AttachmentAssociationsSpecHelper.new(@user.account, @user)
      api_call(:put,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { controller: "discussion_entries", action: "update", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, id: @entry.id.to_s },
               { message: aa_test_data.added_html })

      aas = AttachmentAssociation.where(context_type: "DiscussionEntry", context_id: @entry.id)
      expect(aas.count).to eq 2
      attachment_ids = aas.pluck(:attachment_id)
      expect(attachment_ids).to match_array [aa_test_data.attachment1.id, aa_test_data.attachment2.id]
    end

    it "removes attachment associations if the entry message has changed" do
      aa_test_data = AttachmentAssociationsSpecHelper.new(@user.account, @user)
      api_call(:put,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { controller: "discussion_entries", action: "update", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, id: @entry.id.to_s },
               { message: aa_test_data.removed_html })

      aas = AttachmentAssociation.where(context_type: "DiscussionEntry", context_id: @entry.id)
      expect(aas.count).to eq 0
    end

    it "allows passing an plaintext message (undocumented)" do
      # undocumented but used by the dashboard right now (this'll go away eventually)
      api_call(:put,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { controller: "discussion_entries", action: "update", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, id: @entry.id.to_s },
               { plaintext_message: "i had a spleling error" })
      expect(@entry.reload.message).to eq "i had a spleling error"
    end

    it "allows teachers to edit student entries" do
      @teacher = @user
      student_in_course(course: @course, user: user_with_pseudonym)
      @student = @user
      @user = @teacher
      @entry = create_entry(@topic, message: "i am a student", user: @student)
      expect(@entry.user).to eq @student
      expect(@entry.editor).to be_nil

      api_call(:put,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { controller: "discussion_entries", action: "update", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, id: @entry.id.to_s },
               { message: "<p>denied</p>" })
      expect(@entry.reload.message).to eq "<p>denied</p>"
      expect(@entry.editor).to eq @teacher
    end
  end

  context "delete entry" do
    before :once do
      @topic = create_topic(@course, title: "topic", message: "topic")
      @entry = create_entry(@topic, message: "top-level entry")
    end

    it "403s if the user can't delete" do
      student_in_course(course: @course, user: user_with_pseudonym)
      api_call(:delete,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
               { controller: "discussion_entries", action: "destroy", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, id: @entry.id.to_s },
               {},
               {},
               expected_status: 403)
      expect(@entry.reload).not_to be_deleted
    end

    it "soft-deletes the entry" do
      raw_api_call(:delete,
                   "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
                   { controller: "discussion_entries", action: "destroy", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, id: @entry.id.to_s },
                   {},
                   {},
                   expected_status: 204)
      expect(response.body).to be_blank
      expect(@entry.reload).to be_deleted
    end

    it "allows teachers to delete student entries" do
      @teacher = @user
      student_in_course(course: @course, user: user_with_pseudonym)
      @student = @user
      @user = @teacher
      @entry = create_entry(@topic, message: "i am a student", user: @student)
      expect(@entry.user).to eq @student
      expect(@entry.editor).to be_nil

      raw_api_call(:delete,
                   "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}",
                   { controller: "discussion_entries", action: "destroy", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, id: @entry.id.to_s },
                   {},
                   {},
                   expected_status: 204)
      expect(@entry.reload).to be_deleted
      expect(@entry.editor).to eq @teacher
    end
  end

  context "observer" do
    it "allows observer by default" do
      course_with_teacher
      create_topic(@course, title: "topic", message: "topic")
      course_with_observer_logged_in(course: @course)
      @course.offer
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/discussion_topics.json",
                      { controller: "discussion_topics",
                        action: "index",
                        format: "json",
                        course_id: @course.id.to_s })

      expect(json).not_to be_nil
      expect(json).not_to be_empty
    end

    it "rejects observer if read_forum role is false" do
      course_with_teacher
      @topic = create_topic(@course, title: "topic", message: "topic")
      course_with_observer_logged_in(course: @course)
      RoleOverride.create!(context: @course.account,
                           permission: "read_forum",
                           role: observer_role,
                           enabled: false)

      api_call(:get,
               "/api/v1/courses/#{@course.id}/discussion_topics.json",
               { controller: "discussion_topics",
                 action: "index",
                 format: "json",
                 course_id: @course.id.to_s })
      expect(response).to be_client_error
    end
  end

  context "read/unread state" do
    before(:once) do
      @topic = create_topic(@course, title: "topic", message: "topic")
      @entry = create_entry(@topic, message: "top-level entry")
      @reply = create_reply(@entry, message: "first reply")
    end

    it "immediately marks messages you write as 'read'" do
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/discussion_topics.json",
                      { controller: "discussion_topics",
                        action: "index",
                        format: "json",
                        course_id: @course.id.to_s })
      expect(json.first["read_state"]).to eq "read"
      expect(json.first["unread_count"]).to eq 0

      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { controller: "discussion_topics_api",
          action: "entries",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s }
      )
      expect(json.first["read_state"]).to eq "read"

      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
        { controller: "discussion_topics_api",
          action: "replies",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s,
          entry_id: @entry.id.to_s }
      )
      expect(json.first["read_state"]).to eq "read"
    end

    it "is unread by default for a new user" do
      student_in_course(active_all: true)
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/discussion_topics.json",
                      { controller: "discussion_topics",
                        action: "index",
                        format: "json",
                        course_id: @course.id.to_s })
      expect(json.first["read_state"]).to eq "unread"
      expect(json.first["unread_count"]).to eq 2

      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries.json",
        { controller: "discussion_topics_api",
          action: "entries",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s }
      )
      expect(json.first["read_state"]).to eq "unread"

      json = api_call(
        :get,
        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies.json",
        { controller: "discussion_topics_api",
          action: "replies",
          format: "json",
          course_id: @course.id.to_s,
          topic_id: @topic.id.to_s,
          entry_id: @entry.id.to_s }
      )
      expect(json.first["read_state"]).to eq "unread"
    end

    def call_mark_topic_read(course, topic)
      raw_api_call(:put,
                   "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/read.json",
                   { controller: "discussion_topics_api",
                     action: "mark_topic_read",
                     format: "json",
                     course_id: course.id.to_s,
                     topic_id: topic.id.to_s })
    end

    def call_mark_topic_unread(course, topic)
      raw_api_call(:delete,
                   "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/read.json",
                   { controller: "discussion_topics_api",
                     action: "mark_topic_unread",
                     format: "json",
                     course_id: course.id.to_s,
                     topic_id: topic.id.to_s })
    end

    it "sets the read state for a topic" do
      student_in_course(active_all: true)
      call_mark_topic_read(@course, @topic)
      assert_status(204)
      @topic.reload
      expect(@topic.read?(@user)).to be_truthy
      expect(@topic.unread_count(@user)).to eq 2

      call_mark_topic_unread(@course, @topic)
      assert_status(204)
      @topic.reload
      expect(@topic.read?(@user)).to be_falsey
      expect(@topic.unread_count(@user)).to eq 2
    end

    it "is idempotent for setting topic read state" do
      student_in_course(active_all: true)
      call_mark_topic_read(@course, @topic)
      assert_status(204)
      @topic.reload
      expect(@topic.read?(@user)).to be_truthy
      expect(@topic.unread_count(@user)).to eq 2

      call_mark_topic_read(@course, @topic)
      assert_status(204)
      @topic.reload
      expect(@topic.read?(@user)).to be_truthy
      expect(@topic.unread_count(@user)).to eq 2
    end

    def call_mark_entry_read(course, topic, entry)
      raw_api_call(:put,
                   "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/entries/#{entry.id}/read.json",
                   { controller: "discussion_topics_api",
                     action: "mark_entry_read",
                     format: "json",
                     course_id: course.id.to_s,
                     topic_id: topic.id.to_s,
                     entry_id: entry.id.to_s })
    end

    def call_mark_entry_unread(course, topic, entry)
      raw_api_call(:delete,
                   "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/entries/#{entry.id}/read.json?forced_read_state=true",
                   { controller: "discussion_topics_api",
                     action: "mark_entry_unread",
                     format: "json",
                     course_id: course.id.to_s,
                     topic_id: topic.id.to_s,
                     entry_id: entry.id.to_s,
                     forced_read_state: "true" })
    end

    it "sets the read state for a entry" do
      student_in_course(active_all: true)
      call_mark_entry_read(@course, @topic, @entry)
      assert_status(204)
      expect(@entry.read?(@user)).to be_truthy
      expect(@entry.find_existing_participant(@user)).not_to be_forced_read_state
      expect(@topic.unread_count(@user)).to eq 1

      call_mark_entry_unread(@course, @topic, @entry)
      assert_status(204)
      expect(@entry.read?(@user)).to be_falsey
      expect(@entry.find_existing_participant(@user)).to be_forced_read_state
      expect(@topic.unread_count(@user)).to eq 2

      call_mark_entry_read(@course, @topic, @entry)
      assert_status(204)
      expect(@entry.read?(@user)).to be_truthy
      expect(@entry.find_existing_participant(@user)).to be_forced_read_state
      expect(@topic.unread_count(@user)).to eq 1
    end

    it "is idempotent for setting entry read state" do
      student_in_course(active_all: true)
      call_mark_entry_read(@course, @topic, @entry)
      assert_status(204)
      expect(@entry.read?(@user)).to be_truthy
      expect(@topic.unread_count(@user)).to eq 1

      call_mark_entry_read(@course, @topic, @entry)
      assert_status(204)
      expect(@entry.read?(@user)).to be_truthy
      expect(@topic.unread_count(@user)).to eq 1
    end

    def call_mark_all_as_read_state(new_state, opts = {})
      method = (new_state == "read") ? :put : :delete
      url = "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/read_all.json"
      expected_params = { controller: "discussion_topics_api",
                          action: "mark_all_#{new_state}",
                          format: "json",
                          course_id: @course.id.to_s,
                          topic_id: @topic.id.to_s }
      if opts.key?(:forced)
        url << "?forced_read_state=#{opts[:forced]}"
        expected_params[:forced_read_state] = opts[:forced].to_s
      end
      raw_api_call(method, url, expected_params)
    end

    it "allows mark all as read without forced update" do
      student_in_course(active_all: true)
      @entry.change_read_state("read", @user, forced: true)

      call_mark_all_as_read_state("read")
      assert_status(204)
      @topic.reload
      expect(@topic.read?(@user)).to be_truthy

      expect(@entry.read?(@user)).to be_truthy
      expect(@entry.find_existing_participant(@user)).to be_forced_read_state

      expect(@reply.read?(@user)).to be_truthy
      expect(@reply.find_existing_participant(@user)).not_to be_forced_read_state

      expect(@topic.unread_count(@user)).to eq 0
    end

    it "allows mark all as unread with forced update" do
      [@topic, @entry].each { |e| e.change_read_state("read", @user) }

      call_mark_all_as_read_state("unread", forced: true)
      assert_status(204)
      @topic.reload
      expect(@topic.read?(@user)).to be_falsey

      expect(@entry.read?(@user)).to be_falsey
      expect(@entry.find_existing_participant(@user)).to be_forced_read_state

      expect(@reply.read?(@user)).to be_falsey
      expect(@reply.find_existing_participant(@user)).to be_forced_read_state

      expect(@topic.unread_count(@user)).to eq 2
    end
  end

  context "rating" do
    before(:once) do
      @topic = create_topic(@course, title: "topic", message: "topic", allow_rating: true)
      @entry = create_entry(@topic, message: "top-level entry")
      @reply = create_reply(@entry, message: "first reply")
    end

    def call_rate_entry(course, topic, entry, rating)
      raw_api_call(:post,
                   "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/entries/#{entry.id}/rating.json",
                   { controller: "discussion_topics_api",
                     action: "rate_entry",
                     format: "json",
                     course_id: course.id.to_s,
                     topic_id: topic.id.to_s,
                     entry_id: entry.id.to_s,
                     rating: })
    end

    it "rates an entry" do
      student_in_course(active_all: true)
      call_rate_entry(@course, @topic, @entry, 1)
      assert_status(204)
      expect(@entry.rating(@user)).to eq 1
    end
  end

  context "subscribing" do
    before :once do
      student_in_course(active_all: true)
      @topic1 = create_topic(@course, user: @student)
      @topic2 = create_topic(@course, user: @teacher, require_initial_post: true)
    end

    def call_subscribe(topic, user, course = @course)
      @user = user
      raw_api_call(:put,
                   "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/subscribed",
                   { controller: "discussion_topics_api", action: "subscribe_topic", format: "json", course_id: course.id.to_s, topic_id: topic.id.to_s })
    end

    def call_unsubscribe(topic, user, course = @course)
      @user = user
      raw_api_call(:delete,
                   "/api/v1/courses/#{course.id}/discussion_topics/#{topic.id}/subscribed",
                   { controller: "discussion_topics_api", action: "unsubscribe_topic", format: "json", course_id: course.id.to_s, topic_id: topic.id.to_s })
    end

    it "allows subscription" do
      expect(call_subscribe(@topic1, @teacher)).to eq 204
      expect(@topic1.subscribed?(@teacher)).to be_truthy
    end

    it "allows unsubscription" do
      expect(call_unsubscribe(@topic2, @teacher)).to eq 204
      expect(@topic2.subscribed?(@teacher)).to be_falsey
    end

    it "is idempotent" do
      expect(call_unsubscribe(@topic1, @teacher)).to eq 204
      expect(call_subscribe(@topic1, @student)).to eq 204
    end

    it "does not 500 when user is not related to a child topic" do
      gc = @course.group_categories.create!(name: "children")
      gc.groups.create!(name: "first", context: @course, root_account_id: @course.root_account_id)
      @topic1.group_category_id = gc
      @topic1.save!
      expect(call_subscribe(@topic1, @student)).to eq 400
    end

    context "when initial_post_required" do
      it "allows subscription with an initial post" do
        @user = @student
        create_reply(@topic2, message: "first post!")
        expect(call_subscribe(@topic2, @student)).to eq 204
        expect(@topic2.subscribed?(@student)).to be_truthy
      end

      it "does not allow subscription without an initial post" do
        expect(call_subscribe(@topic2, @student)).to eq 403
      end

      it "allows unsubscription even without an initial post" do
        @topic2.subscribe(@student)
        expect(@topic2.subscribed?(@student)).to be_truthy
        expect(call_unsubscribe(@topic2, @student)).to eq 204
        expect(@topic2.subscribed?(@student)).to be_falsey
      end

      it "unsubscribes a user if all their posts get deleted" do
        @user = @student
        @entry = create_reply(@topic2, message: "first post!")
        expect(call_subscribe(@topic2, @student)).to eq 204
        expect(@topic2.subscribed?(@student)).to be_truthy
        @entry.destroy
        expect(@topic2.subscribed?(@student)).to be_falsey
      end
    end
  end

  context "subscription holds" do
    it "holds when an initial post is required" do
      @topic = create_topic(@course, require_initial_post: true)
      student_in_course(active_all: true)
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/discussion_topics",
                      { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s })
      expect(json[0]["subscription_hold"]).to eql("initial_post_required")
    end

    it "holds when the user isn't in a group set" do
      teacher_in_course(active_all: true)
      group_discussion_assignment
      @topic.publish if @topic.unpublished?
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/discussion_topics",
                      { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s })
      expect(json[0]["subscription_hold"]).to eql("not_in_group_set")
    end

    it "holds when the user isn't in a group" do
      teacher_in_course(active_all: true)
      group_discussion_assignment
      @topic.publish if @topic.unpublished?
      child = @topic.child_topics.first
      group = child.context
      json = api_call(:get,
                      "/api/v1/groups/#{group.id}/discussion_topics",
                      { controller: "discussion_topics", action: "index", format: "json", group_id: group.id.to_s })
      expect(json[0]["subscription_hold"]).to eql("not_in_group")
    end
  end

  describe "threaded discussions" do
    before :once do
      student_in_course(active_all: true)
      @topic = create_topic(@course, threaded: true)
      @entry = create_entry(@topic)
      @sub1 = create_reply(@entry)
      @sub2 = create_reply(@sub1)
      @sub3 = create_reply(@sub2)
      @side2 = create_reply(@entry)
      @entry2 = create_entry(@topic)
    end

    context "in the original API" do
      it "responds with information on the threaded discussion" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics",
                        { controller: "discussion_topics", action: "index", format: "json", course_id: @course.id.to_s })
        expect(json[0]["discussion_type"]).to eq "threaded"
      end

      it "returns nested discussions in a flattened format" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries",
                        { controller: "discussion_topics_api", action: "entries", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s })
        expect(json.size).to eq 2
        expect(json[0]["id"]).to eq @entry2.id
        e1 = json[1]
        expect(e1["id"]).to eq @entry.id
        expect(e1["recent_replies"].pluck("id")).to eq [@side2.id, @sub3.id, @sub2.id, @sub1.id]
        expect(e1["recent_replies"].pluck("parent_id")).to eq [@entry.id, @sub2.id, @sub1.id, @entry.id]

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies",
                        { controller: "discussion_topics_api", action: "replies", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, entry_id: @entry.id.to_s })
        expect(json.size).to eq 4
        expect(json.pluck("id")).to eq [@side2.id, @sub3.id, @sub2.id, @sub1.id]
        expect(json.pluck("parent_id")).to eq [@entry.id, @sub2.id, @sub1.id, @entry.id]
      end

      it "allows posting a reply to a sub-entry" do
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@sub2.id}/replies",
                        { controller: "discussion_topics_api", action: "add_reply", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, entry_id: @sub2.id.to_s },
                        { message: "ohai" })
        expect(json["parent_id"]).to eq @sub2.id
        @sub4 = DiscussionEntry.order(:id).last
        expect(@sub4.id).to eq json["id"]

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{@entry.id}/replies",
                        { controller: "discussion_topics_api", action: "replies", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, entry_id: @entry.id.to_s })
        expect(json.size).to eq 5
        expect(json.pluck("id")).to eq [@sub4.id, @side2.id, @sub3.id, @sub2.id, @sub1.id]
        expect(json.pluck("parent_id")).to eq [@sub2.id, @entry.id, @sub2.id, @sub1.id, @entry.id]
      end

      it "sets and return editor_id if editing another user's post" do
        pending "WIP: Not implemented"
        raise
      end

      it "fails if the max entry depth is reached" do
        entry = @entry
        (DiscussionEntry::MAX_DEPTH - 1).times do
          entry = create_reply(entry)
        end
        api_call(:post,
                 "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entries/#{entry.id}/replies",
                 { controller: "discussion_topics_api", action: "add_reply", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, entry_id: entry.id.to_s },
                 { message: "ohai" },
                 {},
                 { expected_status: 400 })
      end
    end

    context "in the updated API" do
      it "returns a paginated entry_list" do
        entries = [@entry2, @sub1, @side2]
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entry_list?per_page=2",
                        { controller: "discussion_topics_api", action: "entry_list", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, per_page: "2" },
                        { ids: entries.map(&:id) })
        expect(json.size).to eq 2
        # response order is by id
        expect(json.pluck("id")).to eq [@sub1.id, @side2.id]
        expect(response["Link"]).to match(/next/)
      end

      it "returns deleted entries, but with limited data" do
        @sub1.destroy
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/entry_list",
                        { controller: "discussion_topics_api", action: "entry_list", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s },
                        { ids: @sub1.id })
        expect(json.size).to eq 1
        expect(json.first["id"]).to eq @sub1.id
        expect(json.first["deleted"]).to be true
        expect(json.first["read_state"]).to eq "read"
        expect(json.first["parent_id"]).to eq @entry.id
        expect(json.first["updated_at"]).to eq @sub1.updated_at.as_json
        expect(json.first["created_at"]).to eq @sub1.created_at.as_json
        expect(json.first["edited_by"]).to be_nil
      end
    end
  end

  context "materialized view API" do
    before :once do
      @attachment = attachment_model
    end

    double_testing_with_disable_adding_uuid_verifier_in_api_ff do
      it "responds with the materialized information about the discussion" do
        topic_with_nested_replies
        # mark a couple entries as read
        @user = @student
        @root2.change_read_state("read", @user)
        @reply3.change_read_state("read", @user)
        # have the teacher edit one of the student's replies
        @reply_reply1.editor = @teacher
        @reply_reply1.update(message: "<p>censored</p>")

        @all_entries.each(&:reload)

        # materialized view jobs are now delayed
        Timecop.travel(20.seconds.from_now) do
          run_jobs
        end

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/view",
                        { controller: "discussion_topics_api", action: "view", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s })

        expect(json["unread_entries"].size).to eq 2 # two marked read, then ones this user wrote are never unread
        expect(json["unread_entries"].sort).to eq (@topic.discussion_entries - [@root2, @reply3] - @topic.discussion_entries.select { |e| e.user == @user }).map(&:id).sort

        expect(json["participants"].sort_by { |h| h["id"] }).to eq([
          { "id" => @student.id, "anonymous_id" => @student.id.to_s(36), "pronouns" => nil, "display_name" => @student.short_name, "avatar_image_url" => User.avatar_fallback_url(nil, request), "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@student.id}" },
          { "id" => @teacher.id, "anonymous_id" => @teacher.id.to_s(36), "pronouns" => nil, "display_name" => @teacher.short_name, "avatar_image_url" => User.avatar_fallback_url(nil, request), "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@teacher.id}" },
        ].sort_by { |h| h["id"] })

        reply_reply1_attachment_json = {
          "content-type" => "application/unknown",
          "url" => "http://www.example.com/files/#{@attachment.id}/download?download_frd=1#{"&verifier=#{@attachment.uuid}" unless disable_adding_uuid_verifier_in_api}",
          "filename" => "unknown.example",
          "display_name" => "unknown.example",
          "id" => @attachment.id,
          "folder_id" => @attachment.folder_id,
          "size" => 100,
          "unlock_at" => nil,
          "locked" => false,
          "hidden" => false,
          "lock_at" => nil,
          "locked_for_user" => false,
          "hidden_for_user" => false,
          "created_at" => @attachment.created_at.as_json,
          "updated_at" => @attachment.updated_at.as_json,
          "upload_status" => "success",
          "thumbnail_url" => nil,
          "modified_at" => @attachment.modified_at.as_json,
          "mime_class" => @attachment.mime_class,
          "media_entry_id" => @attachment.media_entry_id,
          "category" => "uncategorized",
          "visibility_level" => @attachment.visibility_level
        }

        v0 = json["view"][0]
        expect(v0["id"]).to eq @root1.id
        expect(v0["user_id"]).to eq @student.id
        expect(v0["message"]).to eq "root1"
        expect(v0["parent_id"]).to be_nil
        expect(v0["created_at"]).to eq @root1.created_at.as_json
        expect(v0["updated_at"]).to eq @root1.updated_at.as_json

        v0_r0 = v0["replies"][0]
        expect(v0_r0["id"]).to eq @reply1.id
        expect(v0_r0["deleted"]).to be true
        expect(v0_r0["parent_id"]).to eq @root1.id
        expect(v0_r0["created_at"]).to eq @reply1.created_at.as_json
        expect(v0_r0["updated_at"]).to eq @reply1.updated_at.as_json

        v0_r0_r0 = v0_r0["replies"][0]
        expect(v0_r0_r0["id"]).to eq @reply_reply2.id
        expect(v0_r0_r0["user_id"]).to eq @student.id
        expect(v0_r0_r0["message"]).to eq "reply_reply2"
        expect(v0_r0_r0["parent_id"]).to eq @reply1.id
        expect(v0_r0_r0["created_at"]).to eq @reply_reply2.created_at.as_json
        expect(v0_r0_r0["updated_at"]).to eq @reply_reply2.updated_at.as_json

        v0_r1 = v0["replies"][1]
        expect(v0_r1["id"]).to eq @reply2.id
        expect(v0_r1["user_id"]).to eq @teacher.id

        message = Nokogiri::HTML5.fragment(v0_r1["message"])

        a_tag = message.css("p a").first
        expect(a_tag["href"]).to eq "http://www.example.com/courses/#{@course.id}/files/#{@reply2_attachment.id}/download"
        expect(a_tag["data-api-endpoint"]).to eq "http://www.example.com/api/v1/courses/#{@course.id}/files/#{@reply2_attachment.id}"
        expect(a_tag["data-api-returntype"]).to eq "File"
        expect(a_tag.inner_text).to eq "This is a file link"

        video_tag = message.css("p video").first
        expect(video_tag["poster"]).to eq "http://www.example.com/media_objects/0_abcde/thumbnail?height=448&type=3&width=550"
        expect(video_tag["data-media_comment_type"]).to eq "video"
        expect(video_tag["preload"]).to eq "none"
        expect(video_tag["class"]).to eq "instructure_inline_media_comment"
        expect(video_tag["data-media_comment_id"]).to eq "0_abcde"
        expect(video_tag["controls"]).to eq "controls"
        expect(video_tag["src"]).to eq "http://www.example.com/courses/#{@course.id}/media_download?entryId=0_abcde&media_type=video&redirect=1"
        expect(video_tag.inner_text).to eq "link"

        expect(v0_r1["parent_id"]).to eq @root1.id
        expect(v0_r1["created_at"]).to eq @reply2.created_at.as_json
        expect(v0_r1["updated_at"]).to eq @reply2.updated_at.as_json

        v0_r1_r0 = v0_r1["replies"][0]
        expect(v0_r1_r0["id"]).to eq @reply_reply1.id
        expect(v0_r1_r0["user_id"]).to eq @student.id
        expect(v0_r1_r0["editor_id"]).to eq @teacher.id
        expect(v0_r1_r0["message"]).to eq "<p>censored</p>"
        expect(v0_r1_r0["parent_id"]).to eq @reply2.id
        expect(v0_r1_r0["created_at"]).to eq @reply_reply1.created_at.as_json
        expect(v0_r1_r0["updated_at"]).to eq @reply_reply1.updated_at.as_json
        expect(v0_r1_r0["attachment"]).to eq reply_reply1_attachment_json
        expect(v0_r1_r0["attachments"]).to eq [reply_reply1_attachment_json]

        v1 = json["view"][1]
        expect(v1["id"]).to eq @root2.id
        expect(v1["user_id"]).to eq @student.id
        expect(v1["message"]).to eq "root2"
        expect(v1["parent_id"]).to be_nil
        expect(v1["created_at"]).to eq @root2.created_at.as_json
        expect(v1["updated_at"]).to eq @root2.updated_at.as_json

        v1_r0 = v1["replies"][0]
        expect(v1_r0["id"]).to eq @reply3.id
        expect(v1_r0["user_id"]).to eq @student.id
        expect(v1_r0["message"]).to eq "reply3"
        expect(v1_r0["parent_id"]).to eq @root2.id
        expect(v1_r0["created_at"]).to eq @reply3.created_at.as_json
        expect(v1_r0["updated_at"]).to eq @reply3.updated_at.as_json
      end
    end

    it "can include extra information for context cards" do
      topic_with_nested_replies
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/view",
                      { controller: "discussion_topics_api", action: "view", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s, include_new_entries: "1", include_context_card_info: "1" })
      participants = json["participants"]
      expect(participants.pluck("course_id")).to eq [@course.to_param, @course.to_param]
      expect(participants.find { |p| !p["is_student"] }["id"]).to eq @teacher.id
      expect(participants.find { |p| p["is_student"] }["id"]).to eq @student.id
    end

    context "with mobile overrides" do
      before :once do
        course_with_teacher(active_all: true)
        student_in_course(course: @course, active_all: true)
        @topic = @course.discussion_topics.create!(title: "title", message: "message", user: @teacher, discussion_type: "threaded")
        @root1 = @topic.reply_from(user: @student, html: "root1")
        @reply1 = @root1.reply_from(user: @teacher, html: "reply1")

        # materialized view jobs are now delayed
        Timecop.travel(20.seconds.from_now) do
          run_jobs

          # make everything slightly in the past to test updating
          DiscussionEntry.update_all(updated_at: 5.minutes.ago)
          @reply2 = @root1.reply_from(user: @teacher, html: "reply2")
        end

        account = @course.root_account
        bc = BrandConfig.create(mobile_css_overrides: "somewhere.css")
        account.brand_config_md5 = bc.md5
        account.save!

        @tag = "<link rel=\"stylesheet\" href=\"somewhere.css\">"
      end

      it "includes mobile overrides in the html if not in-app" do
        allow_any_instance_of(DiscussionTopicsApiController).to receive(:in_app?).and_return(false)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/view",
                        { controller: "discussion_topics_api", action: "view", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s },
                        { include_new_entries: "1" })

        expect(json["view"].first["message"]).to start_with(@tag)
        expect(json["view"].first["replies"].first["message"]).to start_with(@tag)
        expect(json["new_entries"].first["message"]).to start_with(@tag)
      end

      it "does not include mobile overrides in the html if in-app" do
        allow_any_instance_of(DiscussionTopicsApiController).to receive(:in_app?).and_return(true)

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/view",
                        { controller: "discussion_topics_api", action: "view", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s },
                        { include_new_entries: "1" })

        expect(json["view"].first["message"]).to_not start_with(@tag)
        expect(json["view"].first["replies"].first["message"]).to_not start_with(@tag)
        expect(json["new_entries"].first["message"]).to_not start_with(@tag)
      end
    end

    it "includes new entries if the flag is given" do
      course_with_teacher(active_all: true)
      student_in_course(course: @course, active_all: true)
      @topic = @course.discussion_topics.create!(title: "title", message: "message", user: @teacher, discussion_type: "threaded")
      @root1 = @topic.reply_from(user: @student, html: "root1")

      # materialized view jobs are now delayed
      Timecop.travel(20.seconds.from_now) do
        run_jobs

        # make everything slightly in the past to test updating
        DiscussionEntry.update_all(updated_at: 5.minutes.ago)
        @reply1 = @root1.reply_from(user: @teacher, html: "reply1")
        @reply2 = @root1.reply_from(user: @teacher, html: "reply2")
      end

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/view",
                      { controller: "discussion_topics_api", action: "view", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s },
                      { include_new_entries: "1" })
      expect(json["unread_entries"].size).to eq 2
      expect(json["unread_entries"].sort).to eq [@reply1.id, @reply2.id]

      expect(json["participants"].pluck("id").sort).to eq [@teacher.id, @student.id]

      expect(json["view"]).to eq [
        "id" => @root1.id,
        "parent_id" => nil,
        "user_id" => @student.id,
        "message" => "root1",
        "created_at" => @root1.created_at.as_json,
        "updated_at" => @root1.updated_at.as_json,
        "rating_sum" => nil,
        "rating_count" => nil,
      ]

      # it's important that these are returned in created_at order
      expect(json["new_entries"]).to eq [
        {
          "id" => @reply1.id,
          "created_at" => @reply1.created_at.as_json,
          "updated_at" => @reply1.updated_at.as_json,
          "message" => "reply1",
          "parent_id" => @root1.id,
          "user_id" => @teacher.id,
          "rating_sum" => nil,
          "rating_count" => nil,
        },
        {
          "id" => @reply2.id,
          "created_at" => @reply2.created_at.as_json,
          "updated_at" => @reply2.updated_at.as_json,
          "message" => "reply2",
          "parent_id" => @root1.id,
          "user_id" => @teacher.id,
          "rating_sum" => nil,
          "rating_count" => nil,
        },
      ]
    end

    it "resolves the placeholder domain in new entries" do
      course_with_teacher(active_all: true)
      student_in_course(course: @course, active_all: true)
      @topic = @course.discussion_topics.create!(title: "title", message: "message", user: @teacher, discussion_type: "threaded")
      @root1 = @topic.reply_from(user: @student, html: "root1")

      link = "/courses/#{@course.id}/discussion_topics"
      # materialized view jobs are now delayed
      Timecop.travel(20.seconds.from_now) do
        run_jobs

        # make everything slightly in the past to test updating
        DiscussionEntry.update_all(updated_at: 5.minutes.ago)
        @reply1 = @root1.reply_from(user: @teacher, html: "<a href='#{link}'>locallink</a>")
        attachment = create_attachment(@course)
        @reply1.attachment = attachment
        @reply1.save!
      end

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/view",
                      { controller: "discussion_topics_api", action: "view", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s },
                      { include_new_entries: "1" })

      new_entry = json["new_entries"].first
      message = new_entry["message"]
      expect(message).to_not include("placeholder.invalid")
      expect(message).to include("www.example.com#{link}")
      att_url = new_entry["attachments"].first["url"]
      expect(att_url).to_not include("placeholder.invalid")
      expect(att_url).to include("www.example.com")
    end
  end

  it "returns due dates as they apply to the user" do
    course_with_student(active_all: true)
    @user = @student
    @student.enrollments.map(&:destroy_permanently!)
    @section = @course.course_sections.create! name: "afternoon delight"
    @course.enroll_user(@student,
                        "StudentEnrollment",
                        section: @section,
                        enrollment_state: :active)

    @topic = @course.discussion_topics.create!(title: "title", message: "message", user: @teacher, discussion_type: "threaded")
    @assignment = @course.assignments.build(submission_types: "discussion_topic", title: @topic.title, due_at: 1.day.from_now)
    @assignment.saved_by = :discussion_topic
    @topic.assignment = @assignment
    @topic.save

    override = @assignment.assignment_overrides.build
    override.set = @section
    override.title = "extension"
    override.due_at = 2.days.from_now
    override.due_at_overridden = true
    override.save!

    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
                    { controller: "discussion_topics_api", action: "show", format: "json", course_id: @course.id.to_s, topic_id: @topic.id.to_s })
    expect(json["assignment"]).not_to be_nil
    expect(json["assignment"]["due_at"]).to eq override.due_at.iso8601
  end

  describe "duplicate" do
    before :once do
      course_with_teacher(active_all: true)
      @student = User.create!(name: "foo", short_name: "fo")
      student_in_course(course: @course, active_all: true)
      group_discussion_topic_model
    end

    it "checks permissions" do
      @user = @student
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@group_topic.id}/duplicate",
               { controller: "discussion_topics_api",
                 action: "duplicate",
                 format: "json",
                 course_id: @course.to_param,
                 topic_id: @group_topic.to_param },
               {},
               {},
               expected_status: 403)
    end

    it "cannot duplicate announcements" do
      @user = @teacher
      announcement_model
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@a.id}/duplicate",
               { controller: "discussion_topics_api",
                 action: "duplicate",
                 format: "json",
                 course_id: @course.to_param,
                 topic_id: @a.to_param },
               {},
               {},
               expected_status: 400)
    end

    it "does not duplicate child topics" do
      @user = @teacher
      child_topic = @group_topic.child_topics[0]
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{child_topic.id}/duplicate",
               { controller: "discussion_topics_api",
                 action: "duplicate",
                 format: "json",
                 course_id: @course.to_param,
                 topic_id: child_topic.to_param },
               {},
               {},
               expected_status: 404)
    end

    it "404s if topic does not exist" do
      @user = @teacher
      bad_id = DiscussionTopic.maximum(:id) + 100
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{bad_id}/duplicate",
               { controller: "discussion_topics_api",
                 action: "duplicate",
                 format: "json",
                 course_id: @course.to_param,
                 topic_id: bad_id.to_s },
               {},
               {},
               expected_status: 404)
    end

    it "404s if deleted" do
      @user = @teacher
      discussion_topic_model
      @topic.destroy
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/duplicate",
               { controller: "discussion_topics_api",
                 action: "duplicate",
                 format: "json",
                 course_id: @course.to_param,
                 topic_id: @topic.to_param },
               {},
               {},
               expected_status: 404)
    end

    it "duplicate works if teacher" do
      @user = @teacher
      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@group_topic.id}/duplicate",
               { controller: "discussion_topics_api",
                 action: "duplicate",
                 format: "json",
                 course_id: @course.to_param,
                 topic_id: @group_topic.to_param },
               {},
               {},
               expected_status: 200)
    end

    it "duplicate doesn't work if student" do
      @user = student_in_course(active_all: true).user

      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@group_topic.id}/duplicate",
               { controller: "discussion_topics_api",
                 action: "duplicate",
                 format: "json",
                 course_id: @course.to_param,
                 topic_id: @group_topic.to_param },
               {},
               {},
               expected_status: 403)
    end

    it "duplicate work if admin" do
      @user = account_admin_user

      api_call(:post,
               "/api/v1/courses/#{@course.id}/discussion_topics/#{@group_topic.id}/duplicate",
               { controller: "discussion_topics_api",
                 action: "duplicate",
                 format: "json",
                 course_id: @course.to_param,
                 topic_id: @group_topic.to_param },
               {},
               {},
               expected_status: 200)
    end

    it "duplicate carries sections over" do
      @user = @teacher
      discussion_topic_model(context: @course, title: "Section Specific Topic", user: @teacher)
      section1 = @course.course_sections.create!
      @course.course_sections.create! # just to make sure we only copy the right one
      @topic.is_section_specific = true
      @topic.discussion_topic_section_visibilities << DiscussionTopicSectionVisibility.new(
        discussion_topic: @topic,
        course_section: section1,
        workflow_state: "active"
      )
      @topic.save!
      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/duplicate",
                      { controller: "discussion_topics_api",
                        action: "duplicate",
                        format: "json",
                        course_id: @course.to_param,
                        topic_id: @topic.to_param },
                      {},
                      {},
                      expected_status: 200)
      expect(json["title"]).to eq "Section Specific Topic Copy"
      expect(json["sections"].length).to eq 1
      expect(json["sections"][0]["id"]).to eq section1.id
    end

    it "duplicate carries anonymous_state over" do
      @user = @teacher
      discussion_topic_model(context: @course, title: "Section Specific Topic", user: @teacher, anonymous_state: "full_anonymity")
      @topic.save!

      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}/duplicate",
                      { controller: "discussion_topics_api",
                        action: "duplicate",
                        format: "json",
                        course_id: @course.to_param,
                        topic_id: @topic.to_param },
                      {},
                      {},
                      expected_status: 200)

      expect(json["anonymous_state"]).to eq @topic.anonymous_state
    end

    it "duplicate publishes group context discussions if its a student duplicating" do
      @user = @student
      group_category = @course.group_categories.create!(name: "group category")
      @course.enroll_student(@student, enrollment_state: "active")
      group = group_category.groups.create!(name: "group", context: @course)
      group.add_user(@student)
      topic = group.discussion_topics.create!(title: "student topic",
                                              user: @student,
                                              workflow_state: "active",
                                              message: "hello")
      json = api_call(:post,
                      "/api/v1/groups/#{group.id}/discussion_topics/#{topic.id}/duplicate",
                      { controller: "discussion_topics_api",
                        action: "duplicate",
                        format: "json",
                        group_id: group.to_param,
                        topic_id: topic.to_param },
                      {},
                      {},
                      expected_status: 200)
      duplicated_topic = DiscussionTopic.last
      expect(duplicated_topic.published?).to be_truthy
      expect(json["published"]).to be_truthy
    end

    it "duplicate does not publish group context discussions if its a teacher duplicating" do
      @user = @teacher
      group_category = @course.group_categories.create!(name: "group category")
      group = group_category.groups.create!(name: "group", context: @course)
      topic = group.discussion_topics.create!(title: "teacher topic",
                                              user: @teacher,
                                              workflow_state: "active",
                                              message: "hello")
      json = api_call(:post,
                      "/api/v1/groups/#{group.id}/discussion_topics/#{topic.id}/duplicate",
                      { controller: "discussion_topics_api",
                        action: "duplicate",
                        format: "json",
                        group_id: group.to_param,
                        topic_id: topic.to_param },
                      {},
                      {},
                      expected_status: 200)
      duplicated_topic = DiscussionTopic.last
      expect(duplicated_topic.published?).to be_falsey
      expect(json["published"]).to be_falsey
    end

    it "duplicate updates positions" do
      @user = @teacher
      topic1 = DiscussionTopic.create!(context: @course,
                                       pinned: true,
                                       position: 20,
                                       title: "Foo",
                                       message: "bar")
      topic2 = DiscussionTopic.create!(context: @course,
                                       pinned: true,
                                       position: 21,
                                       title: "Bar",
                                       message: "baz")
      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/discussion_topics/#{topic1.id}/duplicate",
                      { controller: "discussion_topics_api",
                        action: "duplicate",
                        format: "json",
                        course_id: @course.to_param,
                        topic_id: topic1.to_param },
                      {},
                      {},
                      expected_status: 200)
      # The new topic should have position 21, and topic2 should be bumped
      # up to 22
      new_positions = json["new_positions"]
      topic1.reload
      expect(new_positions[topic1.id.to_s]).to eq 20
      expect(topic1.position).to eq 20
      new_topic = DiscussionTopic.last
      expect(new_positions[new_topic.id.to_s]).to eq 21
      expect(new_topic.position).to eq 21
      topic2.reload
      expect(new_positions[topic2.id.to_s]).to eq 22
      expect(topic2.position).to eq 22
    end
  end

  context "public courses" do
    let(:announcements_view_api) do
      lambda do |user, course_id, announcement_id, status = 200|
        old_at_user = @user
        @user = user # this is required because of api_call :-(
        json = api_call(
          :get,
          "/api/v1/courses/#{course_id}/discussion_topics/#{announcement_id}/view?include_new_entries=1",
          {
            controller: "discussion_topics_api",
            action: "view",
            format: "json",
            course_id: course_id.to_s,
            topic_id: announcement_id.to_s,
            include_new_entries: 1
          },
          {},
          {},
          {
            expected_status: status
          }
        )
        @user = old_at_user
        json
      end
    end

    before do
      course_with_teacher(active_all: true, is_public: true) # sets @teacher and @course
      account_admin_user(account: @course.account) # sets @admin
      @student1 = student_in_course(active_all: true).user
      @student2 = student_in_course(active_all: true).user

      @context = @course
      @announcement = announcement_model(user: @teacher) # sets @a

      s1e = @announcement.discussion_entries.create!(user: @student1, message: "Hello I'm student 1!")
      @announcement.discussion_entries.create!(user: @student2, parent_entry: s1e, message: "Hello I'm student 2!")
    end

    context "should be shown" do
      def check_access(json)
        expect(json["new_entries"]).not_to be_nil
        expect(json["new_entries"].count).to eq(2)
        expect(json["new_entries"].first["user_id"]).to eq(@student1.id)
        expect(json["new_entries"].second["user_id"]).to eq(@student2.id)
      end

      it "shows student comments to students" do
        check_access(announcements_view_api.call(@student1, @course.id, @announcement.id))
      end

      it "shows student comments to teachers" do
        check_access(announcements_view_api.call(@teacher, @course.id, @announcement.id))
      end

      it "shows student comments to admins" do
        check_access(announcements_view_api.call(@admin, @course.id, @announcement.id))
      end
    end

    context "should not be shown" do
      def check_access(json)
        expect(json["new_entries"]).to be_nil
        expect(json["status"]).to be_in %w[unauthorized unauthenticated]
      end

      before do
        prev_course = @course
        course_with_teacher
        @student = student_in_course.user
        @course = prev_course
      end

      it "does not show student comments to unauthenticated users" do
        check_access(announcements_view_api.call(nil, @course.id, @announcement.id, 401))
      end

      it "does not show student comments to other students not in the course" do
        check_access(announcements_view_api.call(@student, @course.id, @announcement.id, 403))
      end

      it "does not show student comments to other teachers not in the course" do
        check_access(announcements_view_api.call(@teacher, @course.id, @announcement.id, 403))
      end
    end
  end

  it "orders Announcement items by posted_at rather than by position" do
    course_with_teacher(active_all: true)
    account_admin_user(account: @course.account) # sets @admin

    ann_ids_ordered_by_posted_at = Array.new(10) do |i|
      ann = Announcement.create!({
                                   context: @course,
                                   message: "Test Message",
                                 })
      ann.posted_at = i.days.ago
      ann.position = 1
      ann.save!
      ann.id
    end

    json = api_call(
      :get,
      "/api/v1/courses/#{@course.id}/discussion_topics?only_announcements=1",
      {
        controller: "discussion_topics",
        action: "index",
        format: "json",
        course_id: @course.id.to_s,
        only_announcements: 1,
      },
      {}
    )

    expect(json.pluck("id")).to eq(ann_ids_ordered_by_posted_at)
  end

  context "cross-sharding" do
    specs_require_sharding

    context "require initial post" do
      before(:once) do
        # In default shard, create the course and discussion topic
        course_with_student(active_all: true)
        @default_shard_student = @student
        @context = @course
        discussion_topic_model
        @topic.require_initial_post = true
        @topic.save

        # Create a user on another shard
        @shard1.activate do
          @shard_student = user_factory(name: "shard1 student", active_all: true)
        end

        # Enroll shard student into the course on the default shard
        @course.enroll_student(@shard_student, enrollment_state: "active")
      end

      describe "student" do
        before do
          user_session(@shard_student)
        end

        it "does not see entries before posting" do
          @shard1.activate do
            url = "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}"
            raw_api_call(:get,
                         "#{url}/entries",
                         controller: "discussion_topics_api",
                         action: "entries",
                         format: "json",
                         course_id: @course.id.to_s,
                         topic_id: @topic.id.to_s)
          end
          expect(response.body).to eq "require_initial_post"
          expect(response).to have_http_status :forbidden
        end

        it "sees entries after posting" do
          @topic.reply_from(user: @shard_student, text: "Lorem ipsum dolor")
          @shard1.activate do
            url = "/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}"
            api_call(:get,
                     "#{url}/entries",
                     controller: "discussion_topics_api",
                     action: "entries",
                     format: "json",
                     course_id: @course.id.to_s,
                     topic_id: @topic.id.to_s)
          end
          expect(response).to have_http_status :ok
        end
      end
    end
  end
end

def create_attachment(context, opts = {})
  opts[:uploaded_data] ||= StringIO.new("attachment content")
  opts[:filename] ||= "content.txt"
  opts[:display_name] ||= opts[:filename]
  opts[:folder] ||= Folder.unfiled_folder(context)
  attachment = context.attachments.build(opts)
  attachment.save!
  attachment
end

def create_topic(context, opts = {})
  attachment = opts.delete(:attachment)
  opts[:user] ||= @user
  topic = context.discussion_topics.build(opts)
  topic.attachment = attachment if attachment
  topic.save!
  topic.publish if topic.unpublished?
  topic
end

def create_entry(topic, opts = {})
  attachment = opts.delete(:attachment)
  created_at = opts.delete(:created_at)
  opts[:user] ||= @user
  entry = topic.discussion_entries.build(opts)
  entry.attachment = attachment if attachment
  entry.created_at = created_at if created_at
  entry.save!
  entry
end

def create_reply(entry, opts = {})
  created_at = opts.delete(:created_at)
  opts[:user] ||= @user
  opts[:html] ||= opts.delete(:message)
  opts[:html] ||= "<p>This is a test message</p>"
  reply = entry.reply_from(opts)
  reply.created_at = created_at if created_at
  reply.save!
  reply
end
