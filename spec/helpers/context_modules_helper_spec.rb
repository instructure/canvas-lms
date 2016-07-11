#
# Copyright (C) 2014 Instructure, Inc.
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

  let_once(:t_course) { course(active_all: true) }
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
      ConditionalRelease::Service.stubs(:rules_for).returns([
        {
          trigger_assignment: assg.id,
          locked: false,
          assignment_sets: [{}, {}],
        }
      ])
    end

    it "should not set mastery_paths if cyoe is disabled" do
      ConditionalRelease::Service.expects(:rules_for).never
      module_data = process_module_data(t_module, true, false, @student, @session)
      item_data = module_data[:items_data][item.id]
      expect(item_data[:mastery_paths]).to be nil
    end

    it "should set mastery_paths for a cyoe trigger assignment module item" do
      module_data = process_module_data(t_module, true, true, @student, @session)
      item_data = module_data[:items_data][item.id]
      expect(item_data[:mastery_paths][:locked]).to eq false
      expect(item_data[:mastery_paths][:assignment_sets]).to eq [{}, {}]
    end

    it "should return the correct choose_url for a cyoe trigger assignment module item" do
      module_data = process_module_data(t_module, true, true, @student, @session)
      item_data = module_data[:items_data][item.id]
      expect(item_data[:choose_url]).to eq context_url(t_course, :context_url) + '/modules/items/' + item.id.to_s + '/choose'
    end

    it "should set show_cyoe_placeholder to true if no set has been selected for a cyoe trigger assignment module item" do
      module_data = process_module_data(t_module, true, true, @student, @session)
      item_data = module_data[:items_data][item.id]
      expect(item_data[:show_cyoe_placeholder]).to eq true
    end

    it "should set show_cyoe_placeholder to false if set has been selected for a cyoe trigger assignment module item" do
      ConditionalRelease::Service.stubs(:rules_for).returns([
        {
          selected_set_id: 1,
          trigger_assignment: assg.id,
          locked: false,
          assignment_sets: [{}, {}],
        }
      ])

      module_data = process_module_data(t_module, true, true, @student, @session)
      item_data = module_data[:items_data][item.id]
      expect(item_data[:show_cyoe_placeholder]).to eq false
    end
  end

  describe "add_mastery_paths_to_cache_key" do
    before do
      ConditionalRelease::Service.stubs(:enabled_in_context?).returns(true)
      ConditionalRelease::Service.stubs(:rules_for).returns([1, 2, 3])
    end

    it "does not affect cache keys unless mastery paths enabled" do
      ConditionalRelease::Service.stubs(:enabled_in_context?).returns(false)
      student_in_course(course: t_course, active_all: true)
      cache = add_mastery_paths_to_cache_key('foo', t_course, t_module, @student)
      expect(cache).to eq 'foo'
    end

    it "does not affect cache keys for teachers" do
      t = teacher_in_course(course: t_course)
      cache = add_mastery_paths_to_cache_key('foo', t_course, t_module, @teacher)
      expect(cache).to eq 'foo'
    end

    it "creates the same key for the same mastery paths rules" do
      s1 = student_in_course(course: t_course, active_all: true)
      s2 = student_in_course(course: t_course, active_all: true)
      cache1 = add_mastery_paths_to_cache_key('foo', t_course, t_module, s1.user)
      cache2 = add_mastery_paths_to_cache_key('foo', t_course, t_module, s2.user)
      expect(cache1).not_to eq 'foo'
      expect(cache1).to eq cache2
    end

    it "creates different keys for different mastery paths rules" do
      s1 = student_in_course(course: t_course, active_all: true)
      s2 = student_in_course(course: t_course, active_all: true)
      cache1 = add_mastery_paths_to_cache_key('foo', t_course, t_module, s1.user)
      ConditionalRelease::Service.stubs(:rules_for).returns([3, 2, 1])
      cache2 = add_mastery_paths_to_cache_key('foo', t_course, t_module, s2.user)
      expect(cache1).not_to eq cache2
    end
  end
end
