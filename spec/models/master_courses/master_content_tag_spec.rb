# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require 'spec_helper'

describe MasterCourses::MasterContentTag do
  before :once do
    course_factory
    @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
  end

  describe "#migration_id" do
    it "should match the generated migration_ids from CCHelper" do
      ann = @course.announcements.create!(:message => "blah")
      topic = @course.discussion_topics.create!
      page = @course.wiki_pages.create!(:title => "blah")

      [ann, topic, page].each do |content|
        expect(@template.create_content_tag_for!(content).migration_id).to eq @template.migration_id_for(content)
      end
    end
  end

  describe "#touch_content_if_restrictions_tightened" do
    before :once do
      course_factory
      @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      @topic = @course.discussion_topics.create!
      @time = 42.seconds.ago
      DiscussionTopic.where(:id => @topic).update_all(:updated_at => @time)
    end

    it "should not touch when the tag is created" do
      tag = @template.create_content_tag_for!(@topic, :restrictions => {:content => true})
      expect(@topic.reload.updated_at.to_i).to eq @time.to_i
    end

    it "should touch when the tag has any restriction tighted" do
      tag = @template.create_content_tag_for!(@topic, :restrictions => {:content => true})
      tag.update_attribute(:restrictions, {:lock_settings => true})
      expect(@topic.reload.updated_at.to_i).to_not eq @time.to_i
    end

    it "should not touch when the tag has restrictions loosened" do
      tag = @template.create_content_tag_for!(@topic, :restrictions => {:content => true, :settings => true})
      tag.update_attribute(:restrictions, {:lock_settings => false})
      expect(@topic.reload.updated_at.to_i).to eq @time.to_i
    end
  end

  describe "fetch_module_item_restrictions_for_child" do
    it "should fetch restrictions for module items in a most fancy fashion" do
      @copy_from = course_factory
      @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
      topic = @copy_from.discussion_topics.create!
      topic_master_tag = @template.create_content_tag_for!(topic)
      expect(topic_master_tag.root_account).to eq @copy_from.root_account
      assmt = @copy_from.assignments.create!
      restrictions = {:all => true}
      assmt_master_tag = @template.create_content_tag_for!(assmt, {:restrictions => restrictions})

      @copy_to = course_factory
      sub = @template.add_child_course!(@copy_to)
      copied_topic = @copy_to.discussion_topics.create!(:migration_id => topic_master_tag.migration_id)
      copied_assmt = @copy_to.assignments.create!(:migration_id => assmt_master_tag.migration_id)
      [copied_topic, copied_assmt].each{|obj| sub.create_content_tag_for!(obj)}

      mod = @copy_to.context_modules.create!(:name => "something")
      tag1 = mod.add_item(:id => copied_topic.id, :type => "discussion_topic")
      tag2 = mod.add_item(:id => copied_assmt.id, :type => "assignment")

      item_restriction_map = MasterCourses::MasterContentTag.fetch_module_item_restrictions_for_child([tag1.id, tag2.id])
      expect(item_restriction_map).to eq({tag1.id => {}, tag2.id => restrictions})
    end
  end

  describe "fetch_module_item_restrictions_for_master" do
    it "should fetch restrictions for module items on the master-side" do
      @copy_from = course_factory
      @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
      topic = @copy_from.discussion_topics.create!
      topic_master_tag = @template.create_content_tag_for!(topic)
      assmt = @copy_from.assignments.create!
      restrictions = {:content => true}
      assmt_master_tag = @template.create_content_tag_for!(assmt, {:restrictions => restrictions})

      mod = @copy_from.context_modules.create!(:name => "something")
      tag1 = mod.add_item(:id => topic.id, :type => "discussion_topic")
      tag2 = mod.add_item(:id => assmt.id, :type => "assignment")

      item_restriction_map = MasterCourses::MasterContentTag.fetch_module_item_restrictions_for_master([tag1.id, tag2.id])
      expect(item_restriction_map).to eq({tag1.id => {}, tag2.id => restrictions})
    end
  end
end
