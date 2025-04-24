# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe ContextModulesHelper do
  include ContextModulesHelper

  let_once(:t_course) { course_factory(active_all: true) }
  let_once(:t_module) { t_course.context_modules.create! name: "test module" }

  describe "module_item_unpublishable?" do
    it "returns true for a nil item" do
      expect(module_item_unpublishable?(nil)).to be_truthy
    end

    it "returns true for an itemless item like a subheader" do
      item = t_module.add_item(type: "context_module_sub_header")
      expect(module_item_unpublishable?(item)).to be_truthy
    end

    it "returns true for an item that doesn't respond to can_unpublish?" do
      tag = t_module.content_tags.build
      tag.tag_type = "context_module"
      tag.content = Thumbnail.new
      expect(module_item_unpublishable?(tag)).to be_truthy
    end

    it "returns the content's can_unpublish?" do
      topic = t_course.discussion_topics.create
      topic.workflow_state = "active"
      topic.save!
      student_in_course(course: t_course)
      item = t_module.add_item(type: "discussion_topic", id: topic.id)
      expect(module_item_unpublishable?(item)).to be_truthy
      item.reload
      topic.discussion_entries.create!(user: @student)
      expect(module_item_unpublishable?(item)).to be_falsey
    end
  end

  describe "module_item_publishable?" do
    it "returns true for an itemless item like a subheader" do
      item = t_module.add_item(type: "context_module_sub_header")
      expect(module_item_publishable?(item)).to be_truthy
    end

    it "returns true for an item that doesn't respond to can_publish?" do
      tag = t_module.content_tags.build
      tag.tag_type = "context_module"
      tag.content = Thumbnail.new
      expect(module_item_publishable?(tag)).to be_truthy
    end

    it "returns the content's can_publish?" do
      assignment = t_course.assignments.create(workflow_state: "unpublished")
      student_in_course(course: t_course)
      item = t_module.add_item(type: "assignment", id: assignment.id)
      expect(assignment.can_publish?).to be_truthy
      expect(module_item_publishable?(item)).to be_truthy
      assignment.publish!
      item.content.reload
      item.reload
      expect(assignment.can_publish?).to be_truthy
      expect(module_item_publishable?(item)).to be_truthy
      assignment.workflow_state = "duplicating"
      assignment.save!
      item.content.reload
      item.reload
      expect(assignment.can_publish?).to be_falsey
      expect(module_item_publishable?(item)).to be_falsey
    end
  end

  describe "module_item_translated_content_type" do
    it 'returns "" for nil item' do
      expect(module_item_translated_content_type(nil)).to eq ""
    end

    it "returns New Quiz for lti-quiz type" do
      tool = t_course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      assignment = t_course.assignments.create(
        submission_types: "external_tool",
        external_tool_tag_attributes: {
          content: tool
        }
      )
      item = t_module.add_item(type: "assignment", id: assignment.id)
      expect(module_item_translated_content_type(item)).to eq "New Quiz"
    end

    it "returns Quiz for lti-quiz type if is_student" do
      tool = t_course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      assignment = t_course.assignments.create(
        submission_types: "external_tool",
        external_tool_tag_attributes: {
          content: tool
        }
      )
      item = t_module.add_item(type: "assignment", id: assignment.id)
      expect(module_item_translated_content_type(item, student: true)).to eq "Quiz"
    end

    it "returns a string for a recognized content type" do
      item = t_module.add_item(type: "context_module_sub_header")
      expect(module_item_translated_content_type(item)).to eq "Context Module Sub Header"
    end

    it "returns unknown if the content_type is not recognized" do
      item = t_module.add_item(type: "context_module_sub_header")
      ContentTag.where(id: item).update_all(content_type: "Blah")
      expect(module_item_translated_content_type(item.reload)).to eq "Unknown Content Type"
    end
  end

  describe "process_module_data" do
    let_once(:assg) { t_course.assignments.create }
    let_once(:item) { t_module.add_item(type: "assignment", id: assg.id) }

    before do
      @context = t_course
      allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
                                                                             {
                                                                               trigger_assignment: assg.id,
                                                                               locked: false,
                                                                               assignment_sets: [{}, {}],
                                                                             }
                                                                           ])
    end

    it "does not set mastery_paths if cyoe is disabled" do
      allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(false)
      expect(ConditionalRelease::Service).not_to receive(:rules_for)
      module_data = process_module_data(t_module, @student, @session, student: true)
      item_data = module_data[:items_data][item.id]
      expect(item_data[:mastery_paths]).to be_nil
    end

    describe "show_cyoe_placeholder with cyoe enabled" do
      before do
        allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(true)
      end

      it "sets mastery_paths for a cyoe trigger assignment module item" do
        module_data = process_module_data(t_module, @student, @session, student: true)
        item_data = module_data[:items_data][item.id]
        expect(item_data[:mastery_paths][:locked]).to be false
        expect(item_data[:mastery_paths][:assignment_sets]).to eq [{}, {}]
      end

      it "returns the correct choose_url for a cyoe trigger assignment module item" do
        module_data = process_module_data(t_module, @student, @session, student: true)
        item_data = module_data[:items_data][item.id]
        expect(item_data[:choose_url]).to eq context_url(t_course, :context_url) + "/modules/items/" + item.id.to_s + "/choose"
      end

      it "is true if no set has been selected and the rule is locked" do
        allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
                                                                               {
                                                                                 trigger_assignment: assg.id,
                                                                                 locked: true,
                                                                                 assignment_sets: [],
                                                                               }
                                                                             ])
        module_data = process_module_data(t_module, @student, @session, student: true)
        item_data = module_data[:items_data][item.id]
        expect(item_data[:show_cyoe_placeholder]).to be true
      end

      it "is true if no set has been selected and sets are available" do
        module_data = process_module_data(t_module, @student, @session, student: true)
        item_data = module_data[:items_data][item.id]
        expect(item_data[:show_cyoe_placeholder]).to be true
      end

      it "is true if still processing results" do
        allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
                                                                               {
                                                                                 trigger_assignment: assg.id,
                                                                                 locked: false,
                                                                                 assignment_sets: [],
                                                                                 still_processing: true
                                                                               }
                                                                             ])
        module_data = process_module_data(t_module, @student, @session, student: true)
        item_data = module_data[:items_data][item.id]
        expect(item_data[:show_cyoe_placeholder]).to be false
      end

      it "is false if no set has been selected and no sets are available" do
        allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
                                                                               {
                                                                                 trigger_assignment: assg.id,
                                                                                 locked: false,
                                                                                 assignment_sets: [],
                                                                               }
                                                                             ])
        module_data = process_module_data(t_module, @student, @session, student: true)
        item_data = module_data[:items_data][item.id]
        expect(item_data[:show_cyoe_placeholder]).to be false
      end

      it "is false if set has been selected for a cyoe trigger assignment module item" do
        allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
                                                                               {
                                                                                 selected_set_id: 1,
                                                                                 trigger_assignment: assg.id,
                                                                                 locked: false,
                                                                                 assignment_sets: [{}, {}],
                                                                               }
                                                                             ])

        module_data = process_module_data(t_module, @student, @session, student: true)
        item_data = module_data[:items_data][item.id]
        expect(item_data[:show_cyoe_placeholder]).to be false
      end
    end

    it "does not return items that are hide_on_modules_view? == true" do
      course = course_factory(active_all: true)
      test_module = course.context_modules.create! name: "test module"
      hidden_assignment = course.assignments.create!(workflow_state: "failed_to_duplicate")
      test_module.add_item(type: "assignment", id: hidden_assignment.id)

      module_data = process_module_data(test_module, @student, @session, student: true)

      expect(module_data[:items]).to be_empty
    end

    context "feature flag modules_page_hide_blueprint_lock_icon_for_children" do
      context "is on" do
        before(:once) do
          t_course.account.feature_flags.create!(feature: "modules_page_hide_blueprint_lock_icon_for_children", state: "on")
        end

        it "returns blueprinit item restrictions for a teacher in a child course" do
          @is_child_course = true
          module_data = process_module_data(t_module, @teacher, @session)

          expect(module_data[:items_restrictions]).not_to be_nil
        end

        it "does not return blueprinit item restrictions for a student in a child course" do
          @is_child_course = true
          module_data = process_module_data(t_module, @student, @session, student: true)

          expect(module_data[:items_restrictions]).to be_nil
        end

        it "does not return blueprinit item restrictions for a teacher if not a blueprint child" do
          @is_child_course = nil
          module_data = process_module_data(t_module, @teacher, @session)

          expect(module_data[:items_restrictions]).to be_nil
        end
      end

      context "is off" do
        it "does not return blueprinit item restrictions for a teacher in a child course" do
          @is_child_course = true
          module_data = process_module_data(t_module, @teacher, @session)

          expect(module_data[:items_restrictions]).to be_nil
        end

        it "does not return blueprinit item restrictions for a student in a child course" do
          @is_child_course = true
          module_data = process_module_data(t_module, @student, @session, student: true)

          expect(module_data[:items_restrictions]).to be_nil
        end
      end
    end

    describe "process_module_items_data" do
      it "works with module items input" do
        module_data = process_module_items_data([item], t_module, @student, @session, student: true)

        expect(module_data[:items].length).to eq(1)
        expect(module_data[:items].first).to eq(item)
      end
    end

    describe "load_content_tags" do
      let(:visible_content_tag_mock) { double("ContentTag1", content: double("Content1", hide_on_modules_view?: false)) }
      let(:hidden_content_tag_mock) { double("ContentTag2", content: double("Content2", hide_on_modules_view?: true)) }

      before do
        allow(t_module)
          .to receive(:content_tags_visible_to)
          .with(@current_user)
          .and_return(content_tags_mock)
      end

      context "when content_tags is NOT empty" do
        let(:content_tags_mock) { [visible_content_tag_mock, hidden_content_tag_mock] }

        it "returns content tags visible to the current user" do
          expect(load_content_tags(t_module, @current_user).size).to eq(1)
        end
      end

      context "when content_tags is empty" do
        let(:content_tags_mock) { [] }

        it "returns empty array" do
          expect(load_content_tags(t_module, @current_user).size).to eq(0)
        end
      end
    end
  end

  describe "add_mastery_paths_to_cache_key" do
    before do
      @rules = [
        { id: 27, assignment_sets: [{ id: 45 }, { id: 36 }] },
        { id: 28, assignment_sets: [] }
      ]
      allow(ConditionalRelease::Service).to receive_messages(enabled_in_context?: true, rules_for: @rules, active_rules: [1, 2, 3])
    end

    it "does not affect cache keys unless mastery paths enabled" do
      allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(false)
      student_in_course(course: t_course, active_all: true)
      cache = add_mastery_paths_to_cache_key("foo", t_course, @student)
      expect(cache).to eq "foo"
    end

    it "creates different keys for different mastery paths rules for a student" do
      s1 = student_in_course(course: t_course, active_all: true)
      s2 = student_in_course(course: t_course, active_all: true)
      cache1 = add_mastery_paths_to_cache_key("foo", t_course, s1.user)
      allow(ConditionalRelease::Service).to receive(:rules_for).and_return(@rules.reverse)
      cache2 = add_mastery_paths_to_cache_key("foo", t_course, s2.user)
      expect(cache1).not_to eq cache2
    end

    it "includes student's AssignmentSetActions in cache key" do
      s1 = student_in_course(course: t_course, active_all: true)
      cache1 = add_mastery_paths_to_cache_key("foo", t_course, s1.user)
      cache2 = add_mastery_paths_to_cache_key("foo", t_course, s1.user)
      expect(cache1).to eq cache2
      allow_any_instance_of(CyoeHelper).to receive(:assignment_set_action_ids).and_return([11, 22])
      cache3 = add_mastery_paths_to_cache_key("foo", t_course, s1.user)
      expect(cache3).not_to eq cache1
    end

    it "creates the same key for the same mastery paths rules for a teacher" do
      t1 = teacher_in_course(course: t_course)
      t2 = teacher_in_course(course: t_course)
      cache1 = add_mastery_paths_to_cache_key("foo", t_course, t1.user)
      cache2 = add_mastery_paths_to_cache_key("foo", t_course, t2.user)
      expect(cache1).not_to eq "foo"
      expect(cache1).to eq cache2
    end

    it "creates different keys for different mastery paths rules for a teacher" do
      t1 = teacher_in_course(course: t_course)
      t2 = teacher_in_course(course: t_course)
      cache1 = add_mastery_paths_to_cache_key("foo", t_course, t1.user)
      allow(ConditionalRelease::Service).to receive(:active_rules).and_return([3, 2, 1])
      cache2 = add_mastery_paths_to_cache_key("foo", t_course, t2.user)
      expect(cache1).not_to eq cache2
    end
  end

  describe "cyoe_able?" do
    before do
      @mod = @course.context_modules.create!
    end

    it "returns true for a graded assignment module item" do
      ag = @course.assignment_groups.create!
      assg = ag.assignments.create! context: @course, submission_types: "online_text_entry"
      item = @mod.add_item type: "assignment", id: assg.id

      expect(cyoe_able?(item)).to be true
    end

    it "returns false for a ungraded assignment module item" do
      ag = @course.assignment_groups.create!
      assg = ag.assignments.create! context: @course, submission_types: "not_graded"
      item = @mod.add_item type: "assignment", id: assg.id

      expect(cyoe_able?(item)).to be false
    end

    it "returns true for a assignment quiz module item" do
      quiz = @course.quizzes.create! quiz_type: "assignment"
      item = @mod.add_item type: "quiz", id: quiz.id

      expect(cyoe_able?(item)).to be true
    end

    it "returns false for a non-assignment quiz module item" do
      quiz = @course.quizzes.create! quiz_type: "survey"
      item = @mod.add_item type: "quiz", id: quiz.id

      expect(cyoe_able?(item)).to be false
    end

    it "returns true for a graded discussion module item" do
      ag = @course.assignment_groups.create!
      assg = ag.assignments.create! context: @course, submission_types: "discussion_topic"
      topic = @course.discussion_topics.create! assignment: assg
      item = @mod.add_item type: "discussion_topic", id: topic.id

      expect(cyoe_able?(item)).to be true
    end

    it "returns false for a non-graded discussion module item" do
      topic = @course.discussion_topics.create!
      item = @mod.add_item type: "discussion_topic", id: topic.id

      expect(cyoe_able?(item)).to be false
    end
  end

  describe "module_performance_improvement_is_enabled?" do
    subject { module_performance_improvement_is_enabled?(context, current_user) }

    context "when provided context and user are falsey" do
      let(:context) { nil }
      let(:current_user) { nil }

      it { is_expected.to be_falsey }
    end

    context "when provided context is falsey" do
      let(:context) { nil }
      let(:current_user) { double }

      it { is_expected.to be_falsey }
    end

    context "when provided current_user is falsey" do
      let(:context) { double }
      let(:current_user) { nil }

      it { is_expected.to be_falsey }
    end

    context "when provided context and user exist" do
      let(:current_user) { double("current_user") }
      let(:visible_items) { double("count_mock", count: items_count) }
      let(:items_count) { 100 }
      let(:context) do
        course = course_model
        allow(course).to receive(:module_items_visible_to).with(current_user).and_return(visible_items)
        course
      end

      context "when modules_perf FF is on" do
        before { allow(context.account).to receive(:feature_enabled?).with(:modules_perf).and_return(true) }

        it "should call the module_items_visible_to" do
          expect(context).to receive(:module_items_visible_to).with(current_user)

          subject
        end

        it "should call the Settings.get with correct key and default value" do
          expect(Setting).to receive(:get).with("module_perf_threshold", 100)

          subject
        end

        context "when there is more than 100 modules" do
          let(:items_count) { 101 }

          it { is_expected.to be_truthy }
        end

        context "when there is less than 100 modules" do
          let(:items_count) { 99 }

          it { is_expected.to be_falsey }
        end

        context "when there are 100 modules" do
          let(:items_count) { 100 }

          it { is_expected.to be_falsey }
        end
      end

      context "when modules_perf FF is off" do
        before { allow(context.account).to receive(:feature_enabled?).with(:modules_perf).and_return(false) }

        it { is_expected.to be_falsey }

        it "should not call the module_items_visible_to" do
          expect(context).to_not receive(:module_items_visible_to).with(current_user)

          subject
        end
      end
    end
  end

  describe "cache_if_no_module_perf_enabled" do
    let(:context) { double("Context", account: double("Account")) }
    let(:user) { double("User") }
    let(:cache_key) { "test_cache_key" }

    before do
      allow(context.account).to receive(:feature_enabled?).with(:modules_perf).and_return(false)
    end

    it "yields when module performance improvement is enabled" do
      allow(helper).to receive(:module_performance_improvement_is_enabled?).with(context, user).and_return(true)

      expect(helper).to_not receive(:cache).with(cache_key, {}).and_yield
      expect { |b| helper.cache_if_no_module_perf_enabled(cache_key, context, user, &b) }.to yield_control
    end

    it "caches when module performance improvement is not enabled" do
      allow(helper).to receive(:module_performance_improvement_is_enabled?).with(context, user).and_return(false)

      expect(helper).to receive(:cache).with(cache_key, {}).and_yield
      expect { |b| helper.cache_if_no_module_perf_enabled(cache_key, context, user, &b) }.to yield_control
    end
  end

  describe "cache_if_module" do
    subject { helper.cache_if_module(nil, true, true, true, true, true, true, user, context, &proc {}) }

    let(:context_module) { double("ContextModule", cache_key: "context_module_key", id: 1) }
    let(:user) { double("User", learning_object_visibilities: %w[assignment1 assignment2]) }
    let(:context) { double("Context") }
    let(:cache_key) { "test_cache_key" }

    before do
      allow(helper).to receive_messages(
        add_menu_tools_to_cache_key: cache_key,
        add_mastery_paths_to_cache_key: cache_key,
        cache: proc { |&block| block.call }
      )
    end

    context "when context_module is present and module performance improvement is not enabled" do
      before do
        allow(helper).to receive(:module_performance_improvement_is_enabled?).with(context, user).and_return(false)
      end

      it "caches the result with the correct cache key" do
        expect(helper).to receive(:cache).with(cache_key, {}).and_yield
        expect { |b| helper.cache_if_module(context_module, true, true, true, true, true, true, user, context, &b) }.to yield_control
      end
    end

    context "when context_module is present and module performance improvement is enabled" do
      before do
        allow(helper).to receive(:module_performance_improvement_is_enabled?).with(context, user).and_return(true)
      end

      it "does not cache and directly yields" do
        expect(helper).not_to receive(:cache)
        expect { |b| helper.cache_if_module(context_module, true, true, true, true, true, true, user, context, &b) }.to yield_control
      end
    end

    context "when context_module is not present" do
      it "does not cache and directly yields" do
        expect(helper).not_to receive(:cache)
        expect { |b| helper.cache_if_module(nil, true, true, true, true, true, true, user, context, &b) }.to yield_control
      end
    end
  end
end
