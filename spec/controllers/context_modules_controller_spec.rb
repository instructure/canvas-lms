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

describe ContextModulesController do
  describe "GET 'index'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it "requires authorization" do
      get "index", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "redirects 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{ "id" => 10, "hidden" => true }])
      get "index", params: { course_id: @course.id }
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "assigns variables" do
      user_session(@teacher)
      get "index", params: { course_id: @course.id }
      expect(response).to be_successful
    end

    it "@combined_active_quizzes should return id, title, type for all classic and lti quizzes sorted by title" do
      user_session(@teacher)
      q1 = @course.quizzes.create!(title: "A")
      q2 = @course.quizzes.create!(title: "C")
      a1 = new_quizzes_assignment(course: @course, title: "B")
      get "index", params: { course_id: @course.id }
      combined_active_quizzes = controller.instance_variable_get(:@combined_active_quizzes)
      expect(combined_active_quizzes).to eq [
        [q1.id, "A", "quiz"],
        [a1.id, "B", "assignment"],
        [q2.id, "C", "quiz"]
      ]
    end

    it "@combined_active_quizzes_includes_both_types should return true when classic and new quizzes are included" do
      user_session(@teacher)
      @course.quizzes.create!(title: "A")
      @course.quizzes.create!(title: "C")
      new_quizzes_assignment(course: @course, title: "B")
      get "index", params: { course_id: @course.id }
      combined_active_quizzes_includes_both_types = controller.instance_variable_get(:@combined_active_quizzes_includes_both_types)
      expect(combined_active_quizzes_includes_both_types).to be true
    end

    it "@combined_active_quizzes_includes_both_types should return false when only classic quizzes are included" do
      user_session(@teacher)
      @course.quizzes.create!(title: "A")
      @course.quizzes.create!(title: "C")
      get "index", params: { course_id: @course.id }
      combined_active_quizzes_includes_both_types = controller.instance_variable_get(:@combined_active_quizzes_includes_both_types)
      expect(combined_active_quizzes_includes_both_types).to be false
    end

    it "@combined_active_quizzes_includes_both_types should return false when only new quizzes are included" do
      user_session(@teacher)
      new_quizzes_assignment(course: @course, title: "B")
      get "index", params: { course_id: @course.id }
      combined_active_quizzes_includes_both_types = controller.instance_variable_get(:@combined_active_quizzes_includes_both_types)
      expect(combined_active_quizzes_includes_both_types).to be false
    end

    it "touches modules if necessary" do
      time = 2.days.ago
      Timecop.freeze(time) do
        @mod1 = @course.context_modules.create!(unlock_at: 1.day.from_now)
        @mod2 = @course.context_modules.create!(unlock_at: 1.day.ago)
        expect(@mod1.updated_at.to_i).to eq time.to_i
      end
      user_session(@student)
      get "index", params: { course_id: @course.id }
      expect(response).to be_successful
      expect(@mod1.reload.updated_at.to_i).to_not eq time.to_i # should be touched in case view for old unlock time was cached
      expect(@mod2.reload.updated_at.to_i).to eq time.to_i # should not be touched since the unlock_at was already in the past the last time it was updated
    end

    context "unpublished modules" do
      before :once do
        @m1 = @course.context_modules.create(name: "unpublished oi")
        @m1.workflow_state = "unpublished"
        @m1.save!
        @m2 = @course.context_modules.create!(name: "published hey")
      end

      it "shows all modules for teachers" do
        user_session(@teacher)
        get "index", params: { course_id: @course.id }
        expect(assigns[:modules]).to eq [@m1, @m2]
      end

      it "does not show unpublished for students" do
        user_session(@student)
        get "index", params: { course_id: @course.id }
        expect(assigns[:modules]).to eq [@m2]
      end
    end

    context "default post to SIS" do
      before :once do
        @course.account.tap do |a|
          a.enable_feature! :new_sis_integrations
          a.settings[:sis_syncing] = { locked: false, value: true }
          a.settings[:sis_default_grade_export] = { locked: false, value: true }
          a.save!
        end
      end

      before do
        user_session(@teacher)
      end

      it "is true if account setting is on" do
        get "index", params: { course_id: @course.id }
        expect(controller.js_env[:DEFAULT_POST_TO_SIS]).to be true
      end

      it "is false if a due date is required" do
        @course.account.tap do |a|
          a.settings[:sis_require_assignment_due_date] = { locked: false, value: true }
          a.save!
        end
        get "index", params: { course_id: @course.id }
        expect(controller.js_env[:DEFAULT_POST_TO_SIS]).to be false
      end
    end

    context "tool definitions for placements" do
      subject { get "index", params: { course_id: @course.id } }

      let(:tool) do
        t = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        t.module_index_menu = { enabled: true, message_type: "LtiResourceLinkRequest" }
        t.module_index_menu_modal = { enabled: true, message_type: "LtiDeepLinkingRequest" }
        t.save!
        t
      end
      let(:tool_definitions) { controller.js_env[:MODULE_TOOLS] }

      before do
        user_session(@teacher)
        tool
        subject
      end

      it "sends tray placement tool definitions" do
        expect(tool_definitions[:module_index_menu].first[:id]).to eq tool.id
      end

      it "sends modal placement tool definitions" do
        expect(tool_definitions[:module_index_menu_modal].first[:definition_id]).to eq tool.id
      end

      context "when tool does not have placement configured" do
        let(:tool) do
          t = super()
          t.module_index_menu_modal = nil
          t.save
          t
        end

        it "is ignored" do
          expect(tool_definitions[:module_index_menu_modal]).to eq []
        end
      end
    end
  end

  describe "PUT 'update'" do
    before :once do
      course_with_teacher(active_all: true)
      @m1 = @course.context_modules.create(name: "unpublished")
      @m1.workflow_state = "unpublished"
      @m1.save!
      @m2 = @course.context_modules.create!(name: "published")
    end

    before do
      user_session(@teacher)
    end

    it "publishes modules" do
      put "update", params: { course_id: @course.id, id: @m1.id, publish: "1" }
      @m1.reload
      expect(@m1.active?).to be true
    end

    it "unpublishes modules" do
      put "update", params: { course_id: @course.id, id: @m2.id, unpublish: "1" }
      @m2.reload
      expect(@m2.unpublished?).to be true
    end

    it "updates the name" do
      put "update", params: { course_id: @course.id, id: @m1.id, context_module: { name: "new name" } }
      @m1.reload
      expect(@m1.name).to eq "new name"
    end
  end

  describe "GET 'module_redirect'" do
    it "skips leading and trailing sub-headers" do
      course_with_student_logged_in(active_all: true)
      @module = @course.context_modules.create!
      ag = @course.assignment_groups.create!
      assignment1 = ag.assignments.create!(context: @course)
      assignment2 = ag.assignments.create!(context: @course)

      @module.add_item type: "context_module_sub_header"
      assignmentTag1 = @module.add_item type: "assignment", id: assignment1.id
      assignmentTag2 = @module.add_item type: "assignment", id: assignment2.id
      @module.add_item type: "context_module_sub_header"

      get "module_redirect", params: { course_id: @course.id, context_module_id: @module.id, first: 1 }
      expect(response).to redirect_to course_assignment_url(@course.id, assignment1.id, module_item_id: assignmentTag1.id)

      get "module_redirect", params: { course_id: @course.id, context_module_id: @module.id, last: 1 }
      expect(response).to redirect_to course_assignment_url(@course.id, assignment2.id, module_item_id: assignmentTag2.id)

      assignmentTag1.destroy
      assignmentTag2.destroy

      get "module_redirect", params: { course_id: @course.id, context_module_id: @module.id, first: 1 }
      expect(response).to redirect_to course_context_modules_url(@course.id, anchor: "module_#{@module.id}")

      get "module_redirect", params: { course_id: @course.id, context_module_id: @module.id, last: 1 }
      expect(response).to redirect_to course_context_modules_url(@course.id, anchor: "module_#{@module.id}")
    end
  end

  describe "GET 'item_redirect'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it "requires authorization" do
      @module = @course.context_modules.create!
      ag = @course.assignment_groups.create!
      assignment1 = ag.assignments.create!(context: @course)

      assignmentTag1 = @module.add_item type: "assignment", id: assignment1.id

      get "item_redirect", params: { course_id: @course.id, id: assignmentTag1.id }
      assert_unauthorized
    end

    it "still redirects for unpublished modules if teacher" do
      user_session(@teacher)

      @module = @course.context_modules.create!
      ag = @course.assignment_groups.create!
      assignment1 = ag.assignments.create!(context: @course)

      assignmentTag1 = @module.add_item type: "assignment", id: assignment1.id

      assignmentTag1.unpublish

      get "item_redirect", params: { course_id: @course.id, id: assignmentTag1.id }
      expect(response).to be_redirect
      expect(response).to redirect_to course_assignment_url(@course, assignment1, module_item_id: assignmentTag1.id)
    end

    it "still redirects for unpublished modules if teacher and course is concluded" do
      user_session(@teacher)

      @module = @course.context_modules.create!
      ag = @course.assignment_groups.create!
      assignment1 = ag.assignments.create!(context: @course)

      assignmentTag1 = @module.add_item type: "assignment", id: assignment1.id

      assignmentTag1.unpublish
      @course.complete!

      get "item_redirect", params: { course_id: @course.id, id: assignmentTag1.id }
      expect(response).to be_redirect
      expect(response).to redirect_to course_assignment_url(@course, assignment1, module_item_id: assignmentTag1.id)
    end

    it "does not redirect for unpublished modules if student" do
      user_session(@student)

      @module = @course.context_modules.create!
      ag = @course.assignment_groups.create!
      assignment1 = ag.assignments.create!(context: @course)

      assignmentTag1 = @module.add_item type: "assignment", id: assignment1.id

      assignmentTag1.unpublish

      get "item_redirect", params: { course_id: @course.id, id: assignmentTag1.id }
      assert_unauthorized
    end

    context "ContextExternalTool" do
      it "finds a matching tool" do
        user_session(@student)

        @module = @course.context_modules.create!
        @tool1 = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @tool2 = @course.context_external_tools.create!(name: "b", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")

        tag1 = @module.add_item type: "context_external_tool", id: @tool1.id, url: @tool1.url
        expect(tag1.content_id).to eq @tool1.id
        tag1.publish if tag1.unpublished?
        tag2 = @module.add_item type: "context_external_tool", id: @tool2.id, url: @tool2.url
        expect(tag2.content_id).to eq @tool2.id
        tag2.publish if tag2.unpublished?

        get "item_redirect", params: { course_id: @course.id, id: tag1.id }
        expect(response).not_to be_redirect
        expect(assigns[:tool]).to eq @tool1

        get "item_redirect", params: { course_id: @course.id, id: tag2.id }
        expect(response).not_to be_redirect
        expect(assigns[:tool]).to eq @tool2
      end

      it "generate lti params" do
        user_session(@student)

        @module = @course.context_modules.create!
        @tool = @course.context_external_tools.create!(
          name: "a",
          url: "http://www.google.com",
          consumer_key: "12345",
          shared_secret: "secret",
          custom_fields: { "canvas_module_id" => "$Canvas.module.id", "canvas_module_item_id" => "$Canvas.moduleItem.id" }
        )

        tag = @module.add_item type: "context_external_tool", id: @tool.id, url: @tool.url
        tag.publish if tag.unpublished?

        get "item_redirect", params: { course_id: @course.id, id: tag.id }
        lti_launch = assigns[:lti_launch]
        expect(lti_launch.params["custom_canvas_module_id"]).to eq @module.id.to_s
        expect(lti_launch.params["custom_canvas_module_item_id"]).to eq tag.id.to_s
      end

      it "fails if there is no matching tool" do
        user_session(@student)

        @module = @course.context_modules.create!
        @tool1 = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")

        tag1 = @module.add_item type: "context_external_tool", id: @tool1.id, url: @tool1.url
        tag1.publish if tag1.unpublished?
        @tool1.update_attribute(:url, "http://www.example.com")

        get "item_redirect", params: { course_id: @course.id, id: tag1.id }
        expect(response).to be_redirect
        expect(assigns[:tool]).to be_nil
      end
    end

    it "redirects to an assignment page" do
      user_session(@student)

      @module = @course.context_modules.create!
      ag = @course.assignment_groups.create!
      assignment1 = ag.assignments.create!(context: @course)

      assignmentTag1 = @module.add_item type: "assignment", id: assignment1.id

      get "item_redirect", params: { course_id: @course.id, id: assignmentTag1.id }
      expect(response).to be_redirect
      expect(response).to redirect_to course_assignment_url(@course, assignment1, module_item_id: assignmentTag1.id)
    end

    it "redirects to a discussion page" do
      user_session(@student)

      @module = @course.context_modules.create!
      topic = @course.discussion_topics.create!

      topicTag = @module.add_item type: "discussion_topic", id: topic.id

      get "item_redirect", params: { course_id: @course.id, id: topicTag.id }
      expect(response).to be_redirect
      expect(response).to redirect_to course_discussion_topic_url(@course, topic, module_item_id: topicTag.id)
    end

    it "redirects to a wiki page" do
      user_session(@student)

      @module = @course.context_modules.create!
      page = wiki_page_model(course: @course)

      page_tag = @module.add_item type: "wiki_page", id: page.id

      get "item_redirect", params: { course_id: @course.id, id: page_tag.id }
      expect(response).to be_redirect
      expect(response).to redirect_to course_wiki_page_url(@course, page, module_item_id: page_tag.id)
    end

    it "redirects to a quiz page" do
      user_session(@student)

      @module = @course.context_modules.create!
      quiz = @course.quizzes.create!
      quiz.publish!

      tag = @module.add_item type: "quiz", id: quiz.id
      tag.publish if tag.unpublished?

      get "item_redirect", params: { course_id: @course.id, id: tag.id }
      expect(response).to be_redirect
      expect(response).to redirect_to course_quiz_url(@course, quiz, module_item_id: tag.id)
    end

    it "marks an external url item read" do
      user_session(@student)
      @module = @course.context_modules.create!
      tag = @module.add_item type: "external_url", url: "http://lolcats", title: "lol"
      tag.publish if tag.unpublished?
      @module.completion_requirements = { tag.id => { type: "must_view" } }
      @module.save!
      expect(@module.evaluate_for(@user)).to be_unlocked
      get "item_redirect", params: { course_id: @course.id, id: tag.id }
      requirements_met = @module.evaluate_for(@user).requirements_met
      expect(requirements_met[0][:type]).to eq "must_view"
      expect(requirements_met[0][:id]).to eq tag.id
    end

    it "does not mark a locked external url item read" do
      user_session(@student)
      @module = @course.context_modules.create! unlock_at: 1.week.from_now
      tag = @module.add_item type: "external_url", url: "http://lolcats", title: "lol"
      @module.completion_requirements = { tag.id => { type: "must_view" } }
      @module.save!
      expect(@module.evaluate_for(@user)).to be_locked
      get "item_redirect", params: { course_id: @course.id, id: tag.id }
      expect(@module.evaluate_for(@user).requirements_met).to be_blank
    end

    it "does not mark an unpublished external url item read" do
      user_session(@student)
      @module = @course.context_modules.create!
      @module.unpublish
      tag = @module.add_item type: "external_url", url: "http://lolcats", title: "lol"
      @module.completion_requirements = { tag.id => { type: "must_view" } }
      @module.save!
      expect(@module.evaluate_for(@user)).to be_locked
      get "item_redirect", params: { course_id: @course.id, id: tag.id }
      expect(@module.evaluate_for(@user).requirements_met).to be_blank
    end
  end

  describe "POST 'reorder'" do
    it "works" do
      course_with_teacher_logged_in(active_all: true)
      m1 = @course.context_modules.create!
      m2 = @course.context_modules.create!
      time = 1.minute.ago
      ContextModule.where(id: [m1, m2]).update_all(updated_at: time)

      post "reorder", params: { course_id: @course.id, order: "#{m2.id},#{m1.id}" }
      expect(response).to be_successful
      expect(m1.reload.position).to eq 2
      expect(m1.updated_at > time).to be_truthy
      expect(m2.reload.position).to eq 1
      expect(m2.updated_at > time).to be_truthy
    end

    it "fires the module_updated live event for any module with changed positions" do
      course_with_teacher_logged_in(active_all: true)
      m1 = @course.context_modules.create!(position: 1)
      m2 = @course.context_modules.create!(position: 2)
      m3 = @course.context_modules.create!(position: 3)
      time = 1.minute.ago
      ContextModule.where(id: [m1, m2, m3]).update_all(updated_at: time)

      expect(Canvas::LiveEvents).to receive(:module_updated).twice
      post "reorder", params: { course_id: @course.id, order: "#{m2.id},#{m1.id},#{m3.id}" }
      expect(response).to be_successful
    end

    context "course pacing" do
      before :once do
        course_with_teacher(active_all: true)
        @m1 = @course.context_modules.create!
        @m2 = @course.context_modules.create!
        time = 1.minute.ago
        ContextModule.where(id: [@m1, @m2]).update_all(updated_at: time)
        @course.account.enable_feature!(:course_paces)
        @course.enable_course_paces = true
        @course.save!
        @primary_pace = course_pace_model(course: @course)
        @section_pace = course_pace_model(course: @course, course_section: @course.course_sections.create!)
      end

      it "republishes all course paces when moving module items" do
        user_session(@teacher)
        post "reorder", params: { course_id: @course.id, order: "#{@m2.id},#{@m1.id}" }
        expect(Progress.find_by(context: @primary_pace)).to be_queued
        expect(Progress.find_by(context: @section_pace)).to be_queued
      end
    end
  end

  describe "POST 'reorder_items'" do
    def make_content_tag(assignment, course, mod)
      ct = ContentTag.new
      ct.content_id = assignment.id
      ct.content_type = "Assignment"
      ct.context_id = course.id
      ct.context_type = "Course"
      ct.title = "Assignment #{assignment.id}"
      ct.tag_type = "context_module"
      ct.context_module_id = mod.id
      ct.context_code = "course_#{course.id}"
      ct.save!
      ct
    end

    it "reorders items" do
      course_with_teacher_logged_in(active_all: true)

      ag = @course.assignment_groups.create!
      a1 = ag.assignments.create!(context: @course)
      a1.points_possible = 10
      a1.save
      a2 = ag.assignments.create!(context: @course)
      m1 = @course.context_modules.create!
      m2 = @course.context_modules.create!

      ct1 = make_content_tag(a1, @course, m1)
      ct2 = make_content_tag(a2, @course, m1)

      post "reorder_items", params: { course_id: @course.id, context_module_id: m2.id, order: ct2.id.to_s }
      ct2.reload
      expect(ct2.context_module).to eq m2
      ct1.reload
      expect(ct1.context_module).to eq m1
    end

    it "reorders unpublished items" do
      course_with_teacher_logged_in(active_all: true)
      pageA = @course.wiki_pages.create title: "pageA"
      pageA.workflow_state = "unpublished"
      pageA.save
      pageB = @course.wiki_pages.create! title: "pageB"
      m1 = @course.context_modules.create!
      tagB = m1.add_item({ type: "wiki_page", id: pageB.id }, nil, position: 1)
      expect(tagB).to be_published
      tagA = m1.add_item({ type: "wiki_page", id: pageA.id }, nil, position: 2)
      expect(tagA).to be_unpublished
      expect(m1.reload.content_tags.ordered.pluck(:id)).to eq [tagB.id, tagA.id]
      post "reorder_items", params: { course_id: @course.id, context_module_id: m1.id, order: "#{tagA.id},#{tagB.id}" }
      tags = m1.reload.content_tags.ordered.to_a
      expect(tags.map(&:position)).to eq [1, 2]
      expect(tags.map(&:id)).to eq [tagA.id, tagB.id]
    end

    it "only touches module once on reorder" do
      course_with_teacher_logged_in(active_all: true)
      assign_group = @course.assignment_groups.create!
      mod = @course.context_modules.create!

      tags = []
      5.times do
        assign = assign_group.assignments.create!(context: @course)
        tags << make_content_tag(assign, @course, mod)
      end

      expect(ContentTag).to receive(:touch_context_modules).once
      order = tags.reverse.map(&:id)
      post "reorder_items", params: { course_id: @course.id, context_module_id: mod.id, order: order.join(",") }
      expect(mod.reload.content_tags.map(&:id)).to eq order
    end
  end

  describe "POST 'add_item'" do
    before :once do
      course_with_teacher(active_all: true)
      @module = @course.context_modules.create!
    end

    before do
      user_session(@teacher)
    end

    it "sets position" do
      @module.add_item({ type: "context_module_sub_header", title: "foo!" }, nil, position: 1)
      post "add_item", params: { course_id: @course.id, context_module_id: @module.id, item: { type: "context_module_sub_header", title: "bar!", position: 3 } }
      expect(@module.content_tags.map { |tag| [tag.title, tag.position] }).to match_array([["foo!", 1], ["bar!", 3]])
    end

    it "does not duplicate an existing position" do
      @module.add_item({ type: "context_module_sub_header", title: "foo!" }, nil, position: 3)
      post "add_item", params: { course_id: @course.id, context_module_id: @module.id, item: { type: "context_module_sub_header", title: "bar!", position: 3 } }
      expect(@module.content_tags.map { |tag| [tag.title, tag.position] }).to match_array([["foo!", 3], ["bar!", 4]])
    end

    it "sets the launch dimensions of the iframe" do
      post "add_item", params: {
        course_id: @course.id,
        context_module_id: @module.id,
        item: {
          type: "context_external_tool",
          title: "new item",
          position: 1,
          iframe: {
            width: 123,
            height: 456
          }
        }
      }
      last_item_module = @module.content_tags.last
      expect(last_item_module.link_settings).to eq({ "selection_width" => "123", "selection_height" => "456" })
    end

    it "allows a user with only manage_course_content_add permissions to add a module item" do
      RoleOverride.create!(context: @course.account, permission: "manage_course_content_edit", role: teacher_role, enabled: false)
      assignment = @course.assignments.create! title: "An Assignment"
      post "add_item", params: { course_id: @course.id, context_module_id: @module.id, item: { type: "assignment", title: "Assignment", id: assignment.id } }
      expect(response).to be_successful
      assignment_item = ContentTag.last
      expect(assignment_item.content_id).to eq(assignment.id)
    end

    describe "update_module_link_default_tab" do
      it "updates the user preference value to true when external_url is added" do
        @teacher.set_preference(:module_links_default_new_tab, false)
        post "add_item", params: { course_id: @course.id, context_module_id: @module.id, item: { type: "external_url", title: "URL", url: "http://example.org", new_tab: 1 } }
        expect(@teacher.get_preference(:module_links_default_new_tab)).to be_truthy
      end

      it "updates the user preference value to false when external_url is added" do
        @teacher.set_preference(:module_links_default_new_tab, true)
        post "add_item", params: { course_id: @course.id, context_module_id: @module.id, item: { type: "external_url", title: "URL", url: "http://example.org", new_tab: 0 } }
        expect(@teacher.get_preference(:module_links_default_new_tab)).to be_falsey
      end

      it "updates the user preference value to true when context_external_tool is added" do
        @teacher.set_preference(:module_links_default_new_tab, false)
        post "add_item", params: { course_id: @course.id, context_module_id: @module.id, item: { type: "context_external_tool", title: "Example Tool", url: "http://example.com/tool", new_tab: 1 } }
        expect(@teacher.get_preference(:module_links_default_new_tab)).to be_truthy
      end

      it "does not update the user preference value when assignment is added" do
        @teacher.set_preference(:module_links_default_new_tab, false)
        assignment = @course.assignments.create! title: "An Assignment"
        post "add_item", params: { course_id: @course.id, context_module_id: @module.id, item: { type: "assignment", title: "Assignment", id: assignment.id, new_tab: 1 } }
        expect(@teacher.get_preference(:module_links_default_new_tab)).to be_falsey
      end
    end
  end

  describe "PUT 'update_item'" do
    before :once do
      course_with_teacher(active_all: true)
      @module = @course.context_modules.create!
      @assignment = @course.assignments.create! title: "An Assignment"
      @assignment_item = @module.add_item type: "assignment", id: @assignment.id
      @external_url_item = @module.add_item type: "external_url", title: "Example URL", url: "http://example.org"
      @external_tool_item = @module.add_item type: "context_external_tool", title: "Example Tool", url: "http://example.com/tool"
    end

    before do
      user_session(@teacher)
    end

    it "updates the tag title" do
      put "update_item", params: { course_id: @course.id, id: @assignment_item.id, content_tag: { title: "New Title" } }
      expect(@assignment_item.reload.title).to eq "New Title"
    end

    it "updates the asset title" do
      put "update_item", params: { course_id: @course.id, id: @assignment_item.id, content_tag: { title: "New Title" } }
      expect(@assignment.reload.title).to eq "New Title"
    end

    it "updates indent" do
      put "update_item", params: { course_id: @course.id, id: @external_url_item.id, content_tag: { indent: 2 } }
      expect(@external_url_item.reload.indent).to eq 2
    end

    it "updates the url for an external url item" do
      new_url = "http://example.org/new_url"
      put "update_item", params: { course_id: @course.id, id: @external_url_item.id, content_tag: { url: new_url } }
      expect(@external_url_item.reload.url).to eq new_url
    end

    it "updates the url for an external tool item" do
      new_url = "http://example.org/new_tool"
      put "update_item", params: { course_id: @course.id, id: @external_tool_item.id, content_tag: { url: new_url } }
      expect(@external_tool_item.reload.url).to eq new_url
    end

    it "does not change the content_id for an external tool item if the external url is changed to a tool that doesn't exist" do
      expect(@external_tool_item.content_id).not_to be_nil
      new_url = "http://example.org/new_tool"
      put "update_item", params: { course_id: @course.id, id: @external_tool_item.id, content_tag: { url: new_url } }
      @external_tool_item.reload
      expect(@external_tool_item.url).to eq new_url
      expect(@external_tool_item.content_id).not_to be_nil
    end

    it "sets the content_id for an external tool item if the url is changed to another tool" do
      new_url = "http://example.org/new_tool"
      tool = @course.context_external_tools.create!(name: "a", url: new_url, consumer_key: "12345", shared_secret: "secret")
      put "update_item", params: { course_id: @course.id, id: @external_tool_item.id, content_tag: { url: new_url } }
      @external_tool_item.reload
      expect(@external_tool_item.url).to eq new_url
      expect(@external_tool_item.content_id).to eq tool.id
    end

    it "does not change content_id for an external tool item if the url is not changed" do
      expect(@external_tool_item.content_id).not_to be_nil
      same_url = "http://example.com/tool"
      put "update_item", params: { course_id: @course.id, id: @external_tool_item.id, content_tag: { url: same_url } }
      @external_tool_item.reload
      expect(@external_tool_item.url).to eq same_url
      expect(@external_tool_item.content_id).not_to be_nil
    end

    it "ignores the url for a non-applicable type" do
      put "update_item", params: { course_id: @course.id, id: @assignment_item.id, content_tag: { url: "http://example.org/new_tool" } }
      expect(@assignment_item.reload.url).to be_nil
    end

    describe "update_module_link_default_tab" do
      it "updates the user preference value to true when external_url is updated" do
        @teacher.set_preference(:module_links_default_new_tab, false)
        put "update_item", params: { course_id: @course.id, id: @external_url_item.id, content_tag: { url: "http://newurl.org", new_tab: 1 } }
        expect(@teacher.get_preference(:module_links_default_new_tab)).to be_truthy
      end

      it "updates the user preference value to false when external_url is updated" do
        @teacher.set_preference(:module_links_default_new_tab, true)
        @external_tool_item.new_tab = true
        @external_tool_item.save!
        put "update_item", params: { course_id: @course.id, id: @external_url_item.id, content_tag: { url: "http://newurl.org", new_tab: 0 } }
        expect(@teacher.get_preference(:module_links_default_new_tab)).to be_falsey
      end

      it "updates the user preference value to true when context_external_tool is updated" do
        @teacher.set_preference(:module_links_default_new_tab, false)
        put "update_item", params: { course_id: @course.id, id: @external_tool_item.id, content_tag: { url: "http://newurl.org", new_tab: 1 } }
        expect(@teacher.get_preference(:module_links_default_new_tab)).to be_truthy
      end

      it "does not update the user preference value when assignment is updated" do
        @teacher.set_preference(:module_links_default_new_tab, false)
        put "update_item", params: { course_id: @course.id, id: @assignment_item.id, content_tag: { new_tab: 1 } }
        expect(@teacher.get_preference(:module_links_default_new_tab)).to be_falsey
      end
    end
  end

  describe "GET item_details" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      @m1 = @course.context_modules.create!(name: "first module")
      @m1.publish
      @m2 = @course.context_modules.create(name: "middle foo")
      @m2.workflow_state = "unpublished"
      @m2.save!
      @m3 = @course.context_modules.create!(name: "last module")
      @m3.publish

      @topic = @course.discussion_topics.create!
      @topicTag = @m1.add_item type: "discussion_topic", id: @topic.id
    end

    it "shows unpublished modules for teachers" do
      user_session(@teacher)
      get "item_details", params: { course_id: @course.id, module_item_id: @topicTag.id, id: "discussion_topic_#{@topic.id}" }
      json = json_parse(response.body)
      expect(json["next_module"]["context_module"]["id"]).to eq @m2.id
    end

    it "skips unpublished modules for students" do
      user_session(@student)
      get "item_details", params: { course_id: @course.id, module_item_id: @topicTag.id, id: "discussion_topic_#{@topic.id}" }
      json = json_parse(response.body)
      expect(json["next_module"]["context_module"]["id"]).to eq @m3.id
    end

    it "parses namespaced quiz as id" do
      user_session(@teacher)
      quiz = @course.quizzes.create!
      quiz.publish!

      quiz_tag = @m2.add_item type: "quiz", id: quiz.id

      get "item_details", params: { course_id: @course.id, module_item_id: quiz_tag.id, id: "quizzes:quiz_#{quiz.id}" }
      json = json_parse(response.body)
      expect(json["current_item"]["content_tag"]["content_type"]).to eq "Quizzes::Quiz"
    end
  end

  describe "GET progressions" do
    context "unauthenticated user in public course" do
      before(:once) do
        course_factory(is_public: true, active_all: true)
        @user = nil
        @mod1 = @course.context_modules.create!(name: "unlocked")
        @mod2 = @course.context_modules.create!(name: "locked", unlock_at: 1.week.from_now)
      end

      it "returns 'locked' progressions for modules locked by date" do
        get "progressions", params: { course_id: @course.id }, format: "json"
        json = json_parse(response.body)
        expect(json).to match_array(
          [{ "context_module_progression" =>
             { "context_module_id" => @mod1.id,
               "workflow_state" => "unlocked",
               "requirements_met" => [],
               "incomplete_requirements" => [] } },
           { "context_module_progression" =>
             { "context_module_id" => @mod2.id,
               "workflow_state" => "locked",
               "requirements_met" => [],
               "incomplete_requirements" => [] } }]
        )
      end

      it "does not error on public course" do
        assignment = @course.assignments.create!(title: "hello")
        @mod1.add_item(type: "assignment", id: assignment.id)
        get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json"
        expect(response).to have_http_status :ok
      end
    end

    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      @module = @course.context_modules.create!(name: "first module")
      @module.publish
      @wiki = @course.wiki_pages.create!(title: "wiki", body: "hi")

      @tag = @module.add_item(id: @wiki.id, type: "wiki_page")
      @module.completion_requirements = { @tag.id => { type: "must_view" } }
    end

    before do
      @progression = @module.update_for(@student, :read, @tag)
    end

    it "returns all student progressions to teacher" do
      user_session(@teacher)
      get "progressions", params: { course_id: @course.id }, format: "json"
      json = json_parse(response.body)
      expect(json.length).to eq 1
    end

    it "returns a single student progression" do
      user_session(@student)
      get "progressions", params: { course_id: @course.id }, format: "json"
      json = json_parse(response.body)
      expect(json.length).to eq 1
    end

    context "with large_roster" do
      before :once do
        @course.large_roster = true
        @course.save!
      end

      it "returns a single student progression" do
        user_session(@student)
        get "progressions", params: { course_id: @course.id }, format: "json"
        json = json_parse(response.body)
        expect(json.length).to eq 1
      end

      it "does not return any student progressions to teacher" do
        user_session(@teacher)
        get "progressions", params: { course_id: @course.id }, format: "json"
        json = json_parse(response.body)
        expect(json.length).to eq 0
      end
    end
  end

  describe "GET assignment_info" do
    it "returns updated due dates/points possible" do
      Timecop.freeze(1.minute.ago) do
        course_with_student_logged_in active_all: true
        @mod = @course.context_modules.create!
        @assign = @course.assignments.create! title: "WHAT", points_possible: 123
        @tag = @mod.add_item(type: "assignment", id: @assign.id)
      end
      enable_cache do
        get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json" # precache
        @assign.points_possible = 456
        @assign.save!
        get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json"
        json = json_parse(response.body)
        expect(json[@tag.id.to_s]["points_possible"].to_i).to be 456
      end
    end

    it "returns due dates for Differentiated Assignments" do
      course_with_teacher_logged_in(active_all: true)
      @mod = @course.context_modules.create!
      @assign = @course.assignments.create! title: "Differentiated Assignment", points_possible: 100, only_visible_to_overrides: true
      @tag = @mod.add_item(type: "assignment", id: @assign.id)

      new_section = @course.course_sections.create!(name: "Section 1")
      new_due_date = 1.week.from_now
      override = @assign.assignment_overrides.build
      override.set = new_section
      override.due_at = new_due_date
      override.due_at_overridden = true
      override.save!

      get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json"
      json = json_parse(response.body)
      expect(json[@tag.id.to_s]["due_date"].to_date).to eq(new_due_date.to_date)
    end

    it "returns only applicable date to student" do
      course_with_student_logged_in(active_all: true)
      section1 = @course.course_sections.create!(name: "Section 1")

      @mod = @course.context_modules.create!
      @assign = @course.assignments.create! title: "Differentiated Assignment", points_possible: 100
      @tag = @mod.add_item(type: "assignment", id: @assign.id)

      new_due_date = 1.week.from_now
      override = @assign.assignment_overrides.build
      override.set = section1
      override.due_at = new_due_date
      override.due_at_overridden = true
      override.save!

      # no date
      get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json"
      json = json_parse(response.body)
      expect(json[@tag.id.to_s]["due_date"]).to be_nil

      # overridden date for nonactive enrollment; "everyone" date on assignment gets used
      student1 = student_in_course(course: @course, section: section1).user
      user_session(student1)
      get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json"
      json = json_parse(response.body)
      expect(json[@tag.id.to_s]["due_date"]).to be_nil

      # overridden date for active enrollment; override gets used
      @course.enrollments.find_by(user: student1, course_section: section1).accept(:force)
      get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json"
      json = json_parse(response.body)
      expect(json[@tag.id.to_s]["due_date"].to_date).to eq new_due_date.to_date
    end

    it "returns too_many_overrides if applicable for assignments" do
      course_with_teacher_logged_in(active_all: true)
      @mod = @course.context_modules.create!
      @assign = @course.assignments.create! title: "WHAT", points_possible: 123
      @tag = @mod.add_item(type: "assignment", id: @assign.id)

      stub_const("Api::V1::Assignment::ALL_DATES_LIMIT", 1)

      2.times do
        student = student_in_course(course: @course, active_all: true).user
        override = assignment_override_model(assignment: @assign)
        override.assignment_override_students.create!(user: student)
      end

      expect(AssignmentOverrideApplicator).not_to receive(:overrides_for_assignment_and_user)

      get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json" # precache
      json = json_parse(response.body)
      expect(json[@tag.id.to_s]["vdd_tooltip"]).to be_nil
      expect(json[@tag.id.to_s]["has_many_overrides"]).to be_truthy
    end

    it "returns too_many_overrides if applicable for graded topics" do
      course_with_teacher_logged_in(active_all: true)
      @mod = @course.context_modules.create!
      @assign = assignment_model(course: @course, submission_types: "discussion_topic", title: "discuss")
      @topic = @assign.discussion_topic

      @tag = @mod.add_item(type: "discussion_topic", id: @topic.id)

      stub_const("Api::V1::Assignment::ALL_DATES_LIMIT", 1)

      2.times do
        student = student_in_course(course: @course, active_all: true).user
        override = assignment_override_model(assignment: @assign)
        override.assignment_override_students.create!(user: student)
      end

      get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json" # precache
      json = json_parse(response.body)
      expect(json[@tag.id.to_s]["vdd_tooltip"]).to be_nil
      expect(json[@tag.id.to_s]["has_many_overrides"]).to be_truthy
    end

    it "does not cache 'past_due'" do
      course_with_student_logged_in(active_all: true)
      @mod = @course.context_modules.create!
      @assign = @course.assignments.create!(title: "sad", due_at: 1.week.from_now, submission_types: "online_text_entry")
      @tag = @mod.add_item(type: "assignment", id: @assign.id)

      enable_cache do
        get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json" # precache
        json = json_parse(response.body)
        expect(json[@tag.id.to_s]["past_due"]).to be_nil

        Timecop.freeze(2.weeks.from_now) do
          get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json"
          json = json_parse(response.body)
          expect(json[@tag.id.to_s]["past_due"]).to be_truthy
        end
      end
    end

    it "returns multiple due date info for survey quizzes" do
      course_with_teacher_logged_in(active_all: true)
      @mod = @course.context_modules.create!
      @quiz = @course.quizzes.create!(title: "sad", due_at: 1.week.from_now, quiz_type: "survey")
      @tag = @mod.add_item(type: "quiz", id: @quiz.id)

      new_section = @course.course_sections.create!(name: "New Section")
      override = @quiz.assignment_overrides.build
      override.set = new_section
      override.due_at = 1.day.from_now
      override.due_at_overridden = true
      override.save!

      get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json" # precache
      json = json_parse(response.body)
      expect(json[@tag.id.to_s]["vdd_tooltip"]["due_dates"].count).to eq 2
    end

    it "returns too_many_overrides if applicable for survey quizzes" do
      course_with_teacher_logged_in(active_all: true)
      @mod = @course.context_modules.create!
      @quiz = @course.quizzes.create!(title: "sad", due_at: 1.week.from_now, quiz_type: "survey")
      @tag = @mod.add_item(type: "quiz", id: @quiz.id)

      stub_const("Api::V1::Assignment::ALL_DATES_LIMIT", 1)

      2.times do
        student = student_in_course(course: @course, active_all: true).user
        override = assignment_override_model(quiz: @quiz)
        override.assignment_override_students.create!(user: student)
      end

      get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json" # precache
      json = json_parse(response.body)
      expect(json[@tag.id.to_s]["vdd_tooltip"]).to be_nil
      expect(json[@tag.id.to_s]["has_many_overrides"]).to be_truthy
    end

    it "returns past_due if survey quiz is past due" do
      course_with_student_logged_in(active_all: true)
      @mod = @course.context_modules.create!
      @quiz = @course.quizzes.create!(title: "sad", due_at: 1.week.ago, quiz_type: "survey")
      @quiz.publish!
      @tag = @mod.add_item(type: "quiz", id: @quiz.id)

      get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json"
      json = json_parse(response.body)
      expect(json[@tag.id.to_s]["past_due"]).to be_present
    end

    it "does not return past_due if survey quiz is completed" do
      course_with_student_logged_in(active_all: true)
      @mod = @course.context_modules.create!
      @quiz = @course.quizzes.create!(title: "sad", due_at: 1.week.ago, quiz_type: "survey")
      @quiz.publish!
      @tag = @mod.add_item(type: "quiz", id: @quiz.id)

      @quiz.generate_submission(@student).complete!

      get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json" # precache
      json = json_parse(response.body)
      expect(json[@tag.id.to_s]["past_due"]).to be_blank
    end

    it "returns a todo date for an ungraded page with a todo_date" do
      course_with_teacher_logged_in(active_all: true)
      @mod = @course.context_modules.create!
      wiki_date = 1.day.from_now
      @wiki_page = @course.wiki_pages.build(title: "title", todo_date: wiki_date)
      @wiki_page.body = "hello world"
      @wiki_page.workflow_state = "active"
      @wiki_page.save!
      @tag = @mod.add_item(type: "WikiPage", id: @wiki_page.id)

      get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json" # precache
      json = json_parse(response.body)
      expect(Time.zone.parse(json[@tag.id.to_s]["todo_date"]).to_i).to eq wiki_date.to_i
    end

    it "returns external urls properly" do
      course_with_teacher_logged_in(active_all: true)
      @module = @course.context_modules.create!
      @module.add_item type: "external_url", url: "http://lolcats", title: "lol"
      get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json"
      expect(response).to be_successful
    end

    it "returns mastery connect objectives correctly" do
      ext_data = {
        key: "https://canvas.instructure.com/lti/mastery_connect_assessment",
        points: 10,
        objectives: "6.R.P.A.1, 6.R.P.A.2",
        trackerName: "My Tracker Name",
        studentCount: 15,
        trackerAlignment: "6th grade Math"
      }

      course_with_teacher_logged_in(active_all: true)
      @tool = factory_with_protected_attributes(@course.context_external_tools,
                                                url: "http://www.justanexamplenotarealwebsite.com/tool1",
                                                shared_secret: "test123",
                                                consumer_key: "test123",
                                                name: "mytool")
      @mod = @course.context_modules.create!
      @assign = @course.assignments.create! title: "WHAT",
                                            submission_types: "external_tool",
                                            external_tool_tag_attributes: { content: @tool, url: @tool.url, external_data: ext_data.to_json }
      @tag = @mod.add_item(type: "assignment", id: @assign.id)

      get "content_tag_assignment_data", params: { course_id: @course.id }, format: "json"
      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json[@tag.id.to_s]["mc_objectives"]).to eq(ext_data[:objectives])
    end
  end

  describe "GET show" do
    before :once do
      course_with_teacher(active_all: true)
    end

    it "redirects to the module on the index page" do
      @m2 = @course.context_modules.create!(name: "published hey")
      user_session(@teacher)
      get "show", params: { course_id: @course.id, id: @m2.id }
      expect(response).to redirect_to course_context_modules_url(course_id: @course.id, anchor: "module_#{@m2.id}")
    end

    it "unauthorizeds for students and unpublished modules" do
      @m1 = @course.context_modules.create(name: "unpublished oi")
      @m1.workflow_state = "unpublished"
      @m1.save!
      student_in_course active_all: true
      user_session(@student)
      get "show", params: { course_id: @course.id, id: @m1.id }
      assert_unauthorized
    end
  end

  describe "GET 'choose_mastery_path'" do
    before do
      allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(true)
    end

    before :once do
      course_with_student(active_all: true)
      @mod = @course.context_modules.create!
      ag = @course.assignment_groups.create!
      @assg = ag.assignments.create!(context: @course)
      @item = @mod.add_item type: "assignment", id: @assg.id
    end

    before do
      user_session @student
    end

    it "returns 404 if no rule matches item assignment" do
      user_session(@student)

      allow(ConditionalRelease::Service).to receive(:rules_for).and_return([])

      get "choose_mastery_path", params: { course_id: @course.id, id: @item.id }
      assert_response(:missing)
    end

    it "returns 404 if matching rule is unlocked but has one selected assignment set" do
      user_session(@student)

      allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
                                                                             {
                                                                               trigger_assignment: @assg.id,
                                                                               locked: false,
                                                                               selected_set_id: 99,
                                                                               assignment_sets: [{}],
                                                                             }
                                                                           ])

      get "choose_mastery_path", params: { course_id: @course.id, id: @item.id }
      assert_response(:missing)
    end

    it "redirects to context modules page with warning if matching rule is locked" do
      user_session(@student)

      allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
                                                                             {
                                                                               trigger_assignment: @assg.id,
                                                                               locked: true,
                                                                               assignment_sets: [],
                                                                             }
                                                                           ])

      get "choose_mastery_path", params: { course_id: @course.id, id: @item.id }
      assert(flash[:warning].present?)
      assert_redirected_to(controller: "context_modules", action: "index")
    end

    it "shows choose page if matches a rule that is unlocked and has more than two assignment sets" do
      user_session(@student)
      assg1, assg2 = create_assignments(@course.id, 2).map { |id| Assignment.find(id) }

      allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
                                                                             {
                                                                               trigger_assignment: @assg.id,
                                                                               locked: false,
                                                                               assignment_sets: [
                                                                                 { id: 1, assignments: [{ assignment_id: 1, model: assg1 }] },
                                                                                 { id: 2, assignments: [{ assignment_id: 2, model: assg2 }] }
                                                                               ]
                                                                             }
                                                                           ])

      get "choose_mastery_path", params: { course_id: @course.id, id: @item.id }
      assert_response(:success)
      mastery_path_data = controller.js_env[:CHOOSE_MASTERY_PATH_DATA]
      expect(mastery_path_data).to include({
                                             selectedOption: nil,
                                             courseId: @course.id,
                                             moduleId: @mod.id,
                                             itemId: @item.id.to_s
                                           })
      options = mastery_path_data[:options]
      expect(options.length).to eq 2
      expect(options[0][:setId]).to eq 1
      expect(options[1][:setId]).to eq 2
    end

    it "shows choose page if matching rule is unlocked and has one unselected assignment set" do
      user_session(@student)

      allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
                                                                             {
                                                                               trigger_assignment: @assg.id,
                                                                               locked: false,
                                                                               assignment_sets: [{ id: 1, assignments: [] }],
                                                                             }
                                                                           ])

      get "choose_mastery_path", params: { course_id: @course.id, id: @item.id }
      assert_response(:success)
      mastery_path_data = controller.js_env[:CHOOSE_MASTERY_PATH_DATA]
      expect(mastery_path_data).to include({
                                             selectedOption: nil
                                           })
      expect(mastery_path_data[:options].length).to eq 1
    end

    it "shows choose page if matches a rule that is unlocked and has more than two assignment sets even if multiple rules are present" do
      user_session(@student)
      assg1, assg2 = create_assignments(@course.id, 2).map { |id| Assignment.find(id) }

      allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
                                                                             {
                                                                               trigger_assignment: @assg.id + 1,
                                                                               locked: false,
                                                                               assignment_sets: [
                                                                                 { id: 1, assignments: [{ assignment_id: 1, model: assg1 }] },
                                                                                 { id: 2, assignments: [{ assignment_id: 2, model: assg2 }] }
                                                                               ]
                                                                             },
                                                                             {
                                                                               trigger_assignment: @assg.id,
                                                                               locked: false,
                                                                               assignment_sets: [
                                                                                 { id: 3, assignments: [{ assignment_id: 2, model: assg2 }] },
                                                                                 { id: 4, assignments: [{ assignment_id: 1, model: assg1 }] }
                                                                               ]
                                                                             }
                                                                           ])

      get "choose_mastery_path", params: { course_id: @course.id, id: @item.id }
      assert_response(:success)
      options = controller.js_env[:CHOOSE_MASTERY_PATH_DATA][:options]
      expect(options.length).to eq 2
      expect(options[0][:setId]).to eq 3
      expect(options[1][:setId]).to eq 4
    end
  end

  describe "GET item_redirect_mastery_paths" do
    before do
      course_with_teacher_logged_in active_all: true
      @mod = @course.context_modules.create!
    end

    it "redirects to assignment edit mastery paths page" do
      ag = @course.assignment_groups.create!
      assg = ag.assignments.create! context: @course
      item = @mod.add_item type: "assignment", id: assg.id

      get "item_redirect_mastery_paths", params: { course_id: @course.id, id: item.id }
      assert_redirected_to controller: "assignments", action: "edit", id: assg.id, anchor: "mastery-paths-editor"
    end

    it "redirects to quiz edit mastery paths page" do
      quiz = @course.quizzes.create!
      item = @mod.add_item type: "quiz", id: quiz.id

      get "item_redirect_mastery_paths", params: { course_id: @course.id, id: item.id }
      assert_redirected_to controller: "quizzes/quizzes", action: "edit", id: quiz.id, anchor: "mastery-paths-editor"
    end

    it "redirects to discussion edit mastery paths page" do
      topic = @course.discussion_topics.create!
      item = @mod.add_item type: "discussion_topic", id: topic.id

      get "item_redirect_mastery_paths", params: { course_id: @course.id, id: item.id }
      assert_redirected_to controller: "discussion_topics", action: "edit", id: topic.id, anchor: "mastery-paths-editor"
    end

    it "redirects to the assignment edit mastery paths page for new quizzes" do
      @course.context_external_tools.create! tool_id: ContextExternalTool::QUIZ_LTI,
                                             name: "Q.N",
                                             consumer_key: "1",
                                             shared_secret: "1",
                                             domain: "quizzes.example.com"
      assignment = @course.assignments.create!
      assignment.quiz_lti!
      assignment.save!
      item = @mod.add_item type: "assignment", id: assignment.id

      get "item_redirect_mastery_paths", params: { course_id: @course.id, id: item.id }
      assert_redirected_to controller: "assignments", action: "edit", id: assignment.id, anchor: "mastery-paths-editor"
    end

    it "404s if module item is not a graded type" do
      page = @course.wiki_pages.create title: "test"
      item = @mod.add_item type: "page", id: page.id

      get "item_redirect_mastery_paths", params: { course_id: @course.id, id: item.id }
      assert_response :missing
    end
  end

  describe "POST 'toggle_collapse_all'" do
    it "collapses all modules as teacher when passed collapse=1" do
      course_with_teacher_logged_in(active_all: true)
      page1 = @course.wiki_pages.create title: "test 1"
      page2 = @course.wiki_pages.create title: "test 2"
      module1 = @course.context_modules.create!
      module2 = @course.context_modules.create!
      module1.add_item type: "page", id: page1.id
      module2.add_item type: "page", id: page2.id

      post "toggle_collapse_all", params: { collapse: "1", course_id: @course.id }
      expect(response).to be_successful
      progression1 = module1.evaluate_for(@teacher)
      progression2 = module2.evaluate_for(@teacher)
      expect(progression1.collapsed).to be_truthy
      expect(progression2.collapsed).to be_truthy
    end

    it "expands all modules as student when passed collapse=0" do
      course_with_student_logged_in(active_all: true)
      page1 = @course.wiki_pages.create title: "test 1"
      page2 = @course.wiki_pages.create title: "test 2"
      module1 = @course.context_modules.create!
      module2 = @course.context_modules.create!
      module1.add_item type: "page", id: page1.id
      module2.add_item type: "page", id: page2.id

      post "toggle_collapse_all", params: { collapse: "0", course_id: @course.id }
      expect(response).to be_successful
      progression1 = module1.evaluate_for(@student)
      progression2 = module2.evaluate_for(@student)
      expect(progression1.collapsed).to be_falsey
      expect(progression2.collapsed).to be_falsey
    end

    it "works multiple times in a row as a student" do
      course_with_student_logged_in(active_all: true)
      page1 = @course.wiki_pages.create title: "test 1"
      module1 = @course.context_modules.create!
      module1.add_item type: "page", id: page1.id

      post "toggle_collapse_all", params: { collapse: "1", course_id: @course.id }
      post "toggle_collapse_all", params: { collapse: "0", course_id: @course.id }
      post "toggle_collapse_all", params: { collapse: "0", course_id: @course.id }
      expect(response).to be_successful
      progression1 = module1.evaluate_for(@student)
      expect(progression1.collapsed).to be_falsey
    end
  end
end
