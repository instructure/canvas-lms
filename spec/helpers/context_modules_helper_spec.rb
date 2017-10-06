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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ContextModulesHelper do
  include ContextModulesHelper

  let_once(:t_course) { course_factory(active_all: true) }
  let_once(:t_module) { t_course.context_modules.create! name: "test module" }

  describe "module_item_unpublishable?" do
    it "should return true for a nil item" do
      expect(module_item_unpublishable?(nil)).to be_truthy
    end

    it "should return true for an itemless item like a subheader" do
      item = t_module.add_item(type: 'context_module_sub_header')
      expect(module_item_unpublishable?(item)).to be_truthy
    end

    it "should return true for an item that doesn't respond to can_unpublish?" do
      tag = t_module.content_tags.build
      tag.tag_type = 'context_module'
      tag.content = Thumbnail.new
      expect(module_item_unpublishable?(tag)).to be_truthy
    end

    it "should return the content's can_unpublish?" do
      topic = t_course.discussion_topics.create
      topic.workflow_state = 'active'
      topic.save!
      student_in_course(:course => t_course)
      item = t_module.add_item(type: 'discussion_topic', id: topic.id)
      expect(module_item_unpublishable?(item)).to be_truthy
      item.reload
      topic.discussion_entries.create!(:user => @student)
      expect(module_item_unpublishable?(item)).to be_falsey
    end
  end

  describe "module_item_translated_content_type" do
    it 'returns "" for nil item' do
      expect(module_item_translated_content_type(nil)).to eq ''
    end

    it 'returns a string for a recognized content type' do
      item = t_module.add_item(type: 'context_module_sub_header')
      expect(module_item_translated_content_type(item)).to eq 'Context Module Sub Header'
    end

    it 'returns unknown if the content_type is not recognized' do
      item = t_module.add_item(type: 'context_module_sub_header')
      ContentTag.where(id: item).update_all(content_type: 'Blah')
      expect(module_item_translated_content_type(item.reload)).to eq 'Unknown Content Type'
    end
  end

  describe "process_module_data" do
    let_once(:assg) { t_course.assignments.create }
    let_once(:item) { t_module.add_item(type: 'assignment', id: assg.id) }

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

    it "should not set mastery_paths if cyoe is disabled" do
      allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(false)
      expect(ConditionalRelease::Service).to receive(:rules_for).never
      module_data = process_module_data(t_module, true, @student, @session)
      item_data = module_data[:items_data][item.id]
      expect(item_data[:mastery_paths]).to be nil
    end

    describe "show_cyoe_placeholder with cyoe enabled" do
      before do
        allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(true)
      end

      it "should set mastery_paths for a cyoe trigger assignment module item" do
        module_data = process_module_data(t_module, true, @student, @session)
        item_data = module_data[:items_data][item.id]
        expect(item_data[:mastery_paths][:locked]).to eq false
        expect(item_data[:mastery_paths][:assignment_sets]).to eq [{}, {}]
      end

      it "should return the correct choose_url for a cyoe trigger assignment module item" do
        module_data = process_module_data(t_module, true, @student, @session)
        item_data = module_data[:items_data][item.id]
        expect(item_data[:choose_url]).to eq context_url(t_course, :context_url) + '/modules/items/' + item.id.to_s + '/choose'
      end

      it "should be true if no set has been selected and the rule is locked" do
        allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
          {
            trigger_assignment: assg.id,
            locked: true,
            assignment_sets: [],
          }
        ])
        module_data = process_module_data(t_module, true, @student, @session)
        item_data = module_data[:items_data][item.id]
        expect(item_data[:show_cyoe_placeholder]).to eq true
      end

      it "should be true if no set has been selected and sets are available" do
        module_data = process_module_data(t_module, true, @student, @session)
        item_data = module_data[:items_data][item.id]
        expect(item_data[:show_cyoe_placeholder]).to eq true
      end

      it "should be true if still processing results" do
        allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
          {
            trigger_assignment: assg.id,
            locked: false,
            assignment_sets: [],
            still_processing: true
          }
        ])
        module_data = process_module_data(t_module, true, @student, @session)
        item_data = module_data[:items_data][item.id]
        expect(item_data[:show_cyoe_placeholder]).to eq false
      end

      it "should be false if no set has been selected and no sets are available" do
        allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
          {
            trigger_assignment: assg.id,
            locked: false,
            assignment_sets: [],
          }
        ])
        module_data = process_module_data(t_module, true, @student, @session)
        item_data = module_data[:items_data][item.id]
        expect(item_data[:show_cyoe_placeholder]).to eq false

      end

      it "should be false if set has been selected for a cyoe trigger assignment module item" do
        allow(ConditionalRelease::Service).to receive(:rules_for).and_return([
          {
            selected_set_id: 1,
            trigger_assignment: assg.id,
            locked: false,
            assignment_sets: [{}, {}],
          }
        ])

        module_data = process_module_data(t_module, true, @student, @session)
        item_data = module_data[:items_data][item.id]
        expect(item_data[:show_cyoe_placeholder]).to eq false
      end
    end
  end

  describe "add_mastery_paths_to_cache_key" do
    before do
      allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(true)
      allow(ConditionalRelease::Service).to receive(:rules_for).and_return([1, 2, 3])
      allow(ConditionalRelease::Service).to receive(:active_rules).and_return([1, 2, 3])
    end

    it "does not affect cache keys unless mastery paths enabled" do
      allow(ConditionalRelease::Service).to receive(:enabled_in_context?).and_return(false)
      student_in_course(course: t_course, active_all: true)
      cache = add_mastery_paths_to_cache_key('foo', t_course, t_module, @student)
      expect(cache).to eq 'foo'
    end

    it "creates the same key for the same mastery paths rules for a student" do
      s1 = student_in_course(course: t_course, active_all: true)
      s2 = student_in_course(course: t_course, active_all: true)
      cache1 = add_mastery_paths_to_cache_key('foo', t_course, t_module, s1.user)
      cache2 = add_mastery_paths_to_cache_key('foo', t_course, t_module, s2.user)
      expect(cache1).not_to eq 'foo'
      expect(cache1).to eq cache2
    end

    it "creates different keys for different mastery paths rules for a student" do
      s1 = student_in_course(course: t_course, active_all: true)
      s2 = student_in_course(course: t_course, active_all: true)
      cache1 = add_mastery_paths_to_cache_key('foo', t_course, t_module, s1.user)
      allow(ConditionalRelease::Service).to receive(:rules_for).and_return([3, 2, 1])
      cache2 = add_mastery_paths_to_cache_key('foo', t_course, t_module, s2.user)
      expect(cache1).not_to eq cache2
    end

    it "creates the same key for the same mastery paths rules for a teacher" do
      t1 = teacher_in_course(course: t_course)
      t2 = teacher_in_course(course: t_course)
      cache1 = add_mastery_paths_to_cache_key('foo', t_course, t_module, t1.user)
      cache2 = add_mastery_paths_to_cache_key('foo', t_course, t_module, t2.user)
      expect(cache1).not_to eq 'foo'
      expect(cache1).to eq cache2
    end

    it "creates different keys for different mastery paths rules for a teacher" do
      t1 = teacher_in_course(course: t_course)
      t2 = teacher_in_course(course: t_course)
      cache1 = add_mastery_paths_to_cache_key('foo', t_course, t_module, t1.user)
      allow(ConditionalRelease::Service).to receive(:active_rules).and_return([3, 2, 1])
      cache2 = add_mastery_paths_to_cache_key('foo', t_course, t_module, t2.user)
      expect(cache1).not_to eq cache2
    end
  end

  describe "cyoe_able?" do
    before do
      @mod = @course.context_modules.create!
    end

    it "should return true for a graded assignment module item" do
      ag = @course.assignment_groups.create!
      assg = ag.assignments.create! context: @course, submission_types: 'online_text_entry'
      item = @mod.add_item type: 'assignment', id: assg.id

      expect(cyoe_able?(item)).to eq true
    end

    it "should return false for a ungraded assignment module item" do
      ag = @course.assignment_groups.create!
      assg = ag.assignments.create! context: @course, submission_types: 'not_graded'
      item = @mod.add_item type: 'assignment', id: assg.id

      expect(cyoe_able?(item)).to eq false
    end

    it "should return true for a assignment quiz module item" do
      quiz = @course.quizzes.create! quiz_type: 'assignment'
      item = @mod.add_item type: 'quiz', id: quiz.id

      expect(cyoe_able?(item)).to eq true
    end

    it "should return false for a non-assignment quiz module item" do
      quiz = @course.quizzes.create! quiz_type: 'survey'
      item = @mod.add_item type: 'quiz', id: quiz.id

      expect(cyoe_able?(item)).to eq false
    end

    it "should return true for a graded discussion module item" do
      ag = @course.assignment_groups.create!
      assg = ag.assignments.create! context: @course, submission_types: 'discussion_topic'
      topic = @course.discussion_topics.create! assignment: assg
      item = @mod.add_item type: 'discussion_topic', id: topic.id

      expect(cyoe_able?(item)).to eq true
    end

    it "should return false for a non-graded discussion module item" do
      topic = @course.discussion_topics.create!
      item = @mod.add_item type: 'discussion_topic', id: topic.id

      expect(cyoe_able?(item)).to eq false
    end
  end
end
