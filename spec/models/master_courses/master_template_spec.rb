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

describe MasterCourses::MasterTemplate do
  before :once do
    course_factory
  end

  describe "set_as_master_course" do
    it "should add a template to a course" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      expect(template.course).to eq @course
      expect(template.full_course).to eq true

      expect(MasterCourses::MasterTemplate.set_as_master_course(@course)).to eq template # should not create a copy
      expect(MasterCourses::MasterTemplate.full_template_for(@course)).to eq template
    end

    it "should restore deleted templates" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      template.destroy!

      expect(template).to be_deleted

      template2 = MasterCourses::MasterTemplate.set_as_master_course(@course)
      expect(template2).to eq template
      expect(template2).to be_active
    end
  end

  describe "remove_as_master_course" do
    it "should remove a template from a course" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      other_course = Course.create!
      sub = template.add_child_course!(other_course)
      expect(template.workflow_state).to eq "active"
      expect(template.active?).to eq true

      expect{MasterCourses::MasterTemplate.remove_as_master_course(@course)}.to change{template.reload.workflow_state}.from("active").to("deleted")
      expect(MasterCourses::MasterTemplate.full_template_for(@course)).to be_nil
      expect(sub.reload).to be_deleted
    end

    it "should ignore deleted templates" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      template.destroy
      expect(template).to be_deleted

      MasterCourses::MasterTemplate.remove_as_master_course(@course)

      expect(template).to receive(:destroy).never
      expect(template).to be_deleted
    end
  end

  describe "is_master_course?" do
    def check
      MasterCourses::MasterTemplate.is_master_course?(@course)
    end

    it "should cache the result" do
      enable_cache do
        expect(check).to be_falsey
        expect(@course).to receive(:master_course_templates).never
        expect(check).to be_falsey
        expect(MasterCourses::MasterTemplate.is_master_course?(@course.id)).to be_falsey # should work with ids too
      end
    end

    it "should invalidate the cache when set as master course" do
      enable_cache do
        expect(check).to be_falsey
        template = MasterCourses::MasterTemplate.set_as_master_course(@course) # invalidate on create
        expect(check).to be_truthy
        template.destroy! # and on workflow_state change
        expect(check).to be_falsey
      end
    end
  end

  describe "content_tag_for" do
    before :once do
      @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      @assignment = @course.assignments.create!
    end

    it "should create tags for course content" do
      tag = @template.content_tag_for(@assignment)
      expect(tag.reload.content).to eq @assignment
    end

    it "should find tags" do
      tag = @template.create_content_tag_for!(@assignment)
      expect(@template).to receive(:create_content_tag_for!).never # don't try to recreate
      expect(@template.content_tag_for(@assignment)).to eq tag
    end

    it "should not fail on double-create" do
      tag = @template.create_content_tag_for!(@assignment)
      expect(@template.create_content_tag_for!(@assignment)).to eq tag # should retry on unique constraint failure
    end

    it "should be able to load tags for fast searching" do
      tag = @template.create_content_tag_for!(@assignment)
      @template.load_tags!

      old_tag_id = tag.id
      tag.destroy! # delete in the db - proves that we cached them

      expect(@template.content_tag_for(@assignment).id).to eq old_tag_id

      # should still create a tag even if it's not found in the index
      @page = @course.wiki_pages.create!(:title => "title")
      page_tag = @template.content_tag_for(@page)
      expect(page_tag.reload.content).to eq @page
    end

    it "should be able to load tags selectively" do
      graded_topic = @course.discussion_topics.new
      graded_topic.assignment = @course.assignments.build
      graded_topic.save!
      topic_assmt = graded_topic.assignment.reload
      normal_topic = @course.discussion_topics.create!
      other_assmt = @course.assignments.create!

      objects = [topic_assmt, normal_topic, @assignment]
      objects.each {|o| @template.content_tag_for(o)}
      @template.load_tags!(objects)
      objects.each do |o|
        expect(@template.cached_content_tag_for(o)).to be_present
      end
      expect(@template.cached_content_tag_for(graded_topic)).to be_present # should load the submittable
      expect(@template.cached_content_tag_for(other_assmt)).to be_nil
    end
  end

  describe "default restriction syncing" do
    before :once do
      @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
    end

    it "should keep content tag restrictions up to date" do
      tag1 = @template.create_content_tag_for!(@course.discussion_topics.create!, :use_default_restrictions => true)
      tag2 = @template.create_content_tag_for!(@course.discussion_topics.create!, :use_default_restrictions => false)
      old_default = tag2.restrictions

      new_default = {:content => true, :points => true}
      @template.update_attribute(:default_restrictions, new_default)
      expect(tag1.reload.restrictions).to eq new_default
      expect(tag2.reload.restrictions).to eq old_default
    end

    it "should keep tags up to date when default restrictions are set by object type" do
      topic_tag1 = @template.create_content_tag_for!(@course.discussion_topics.create!, :use_default_restrictions => true)
      topic_tag2 = @template.create_content_tag_for!(@course.discussion_topics.create!, :use_default_restrictions => false)
      assmt_tag1 = @template.create_content_tag_for!(@course.assignments.create!, :use_default_restrictions => true)
      assmt_tag2 = @template.create_content_tag_for!(@course.assignments.create!, :use_default_restrictions => false)

      assmt_restricts = {:content => true, :points => true}
      topic_restricts = {:content => true}
      @template.update_attribute(:default_restrictions_by_type,
        {'Assignment' => assmt_restricts, 'DiscussionTopic' => topic_restricts})

      expect(topic_tag1.reload.restrictions).to be_blank # shouldn't have updated yet because it's not configured to use per-object defaults
      expect(assmt_tag1.reload.restrictions).to be_blank

      @template.update_attribute(:use_default_restrictions_by_type, true)

      expect(topic_tag1.reload.restrictions).to eq topic_restricts
      expect(assmt_tag1.reload.restrictions).to eq assmt_restricts

      expect(topic_tag2.reload.restrictions).to be_blank # shouldn't have updated because use_default_restrictions is not set
      expect(assmt_tag2.reload.restrictions).to be_blank

      @template.update_attribute(:default_restrictions_by_type, {})

      expect(topic_tag1.reload.restrictions).to be_blank
      expect(assmt_tag1.reload.restrictions).to be_blank
    end

    it "should touch content when tightening default_restrictions" do
      @template.update_attribute(:default_restrictions, {:content => true, :points => true})
      old_time = 1.minute.ago
      Timecop.freeze(old_time) do
        @quiz1 = @course.quizzes.create!
        @quiz2 = @course.quizzes.create!
        @template.create_content_tag_for!(@quiz1, :use_default_restrictions => true)
        @template.create_content_tag_for!(@quiz2, :use_default_restrictions => false)
      end
      @template.update_attribute(:default_restrictions, {:content => true})
      # shouldn't need to update
      expect(@quiz1.reload.updated_at.to_i).to eq old_time.to_i

      @template.update_attribute(:default_restrictions, {:content => true, :due_dates => true})
      # now should update
      expect(@quiz1.reload.updated_at.to_i).to_not eq old_time.to_i
      expect(@quiz2.reload.updated_at.to_i).to eq old_time.to_i # has custom restrictions
    end

    it "should touch content when tightening default_restrictions_by_type" do
      @template.update_attributes(:use_default_restrictions_by_type => true,
        :default_restrictions_by_type => {
          'Assignment' => {:content => true, :points => true},
          'DiscussionTopic' => {:content => true},
          'Quizzes::Quiz' => {:content => true}
        })

      old_time = 1.minute.ago
      Timecop.freeze(old_time) do
        @assmt = @course.assignments.create!
        @topic = @course.discussion_topics.create!
        @quiz = @course.quizzes.create!
        [@assmt, @topic, @quiz].each do |obj|
          @template.create_content_tag_for!(obj, :use_default_restrictions => true)
        end
      end
      @template.update_attributes(:default_restrictions_by_type => {
        'Assignment' => {:content => true}, # lessened restrictions
        'DiscussionTopic' => {:content => true, :points => true},
        'Quizzes::Quiz' => {:content => true, :due_dates => true}
      })
      expect(@assmt.reload.updated_at.to_i).to eq old_time.to_i
      expect(@topic.reload.updated_at.to_i).to_not eq old_time.to_i
      expect(@quiz.reload.updated_at.to_i).to_not eq old_time.to_i
    end
  end

  describe "child subscriptions" do
    it "should be able to add other courses as 'child' courses" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      new_course = course_factory
      sub = template.add_child_course!(new_course)
      expect(sub.child_course).to eq new_course
      expect(sub.master_template).to eq template
      expect(sub).to be_active
      expect(sub.use_selective_copy).to be_falsey # should default to false - we'll set it to true later after the first import

      expect(template.child_subscriptions.active.count).to eq 1
      sub.destroy!

      # can re-add
      new_sub = template.add_child_course!(new_course)
      expect(new_sub).to eq sub # should restore the old one
      expect(new_sub).to be_active
    end

    it "should require child courses to belong to the same root account" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      new_root_account = Account.create!
      new_course = course_factory(:account => new_root_account)
      expect { template.add_child_course!(new_course) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "master_migrations" do
    it "should be able to create a migration" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      mig = template.master_migrations.create!
      expect(mig.master_template).to eq template
    end
  end

  describe "preload_index_data" do
    it "should preload child subscription counts and last_export_completed_at" do
      t1 = MasterCourses::MasterTemplate.set_as_master_course(@course)
      t2 = MasterCourses::MasterTemplate.set_as_master_course(Course.create!)
      t3 = MasterCourses::MasterTemplate.set_as_master_course(Course.create!)

      t1.add_child_course!(Course.create!)
      3.times do
        t2.add_child_course!(Course.create!)
      end

      time1 = 2.days.ago
      time2 = 1.day.ago
      t1.master_migrations.create!(:imports_completed_at => time1, :workflow_state => 'completed')
      t1.master_migrations.create!(:imports_completed_at => time2, :workflow_state => 'completed')
      t2.master_migrations.create!(:imports_completed_at => time1, :workflow_state => 'completed')

      MasterCourses::MasterTemplate.preload_index_data([t1, t2, t3])

      expect(t1.child_course_count).to eq 1
      expect(t2.child_course_count).to eq 3
      expect(t3.child_course_count).to eq 0

      expect(t1.instance_variable_get(:@last_export_completed_at)).to eq time2
      expect(t2.instance_variable_get(:@last_export_completed_at)).to eq time1
      expect(t3.instance_variable_defined?(:@last_export_completed_at)).to be_truthy
      expect(t3.instance_variable_get(:@last_export_completed_at)).to be_nil
    end

    it "should not count deleted courses" do
      t = MasterCourses::MasterTemplate.set_as_master_course(@course)
      t.add_child_course!(Course.create!)
      t.add_child_course!(Course.create!(:workflow_state => 'deleted'))

      MasterCourses::MasterTemplate.preload_index_data([t])

      expect(t.child_course_count).to eq 1
    end
  end

  describe "#master_course_for_child_course" do
    it "should load a master course" do
      t = MasterCourses::MasterTemplate.set_as_master_course(@course)
      c2 = Course.create!
      sub = t.add_child_course!(c2)
      expect(MasterCourses::MasterTemplate.master_course_for_child_course(c2)).to eq @course
      sub.destroy!
      expect(MasterCourses::MasterTemplate.master_course_for_child_course(c2)).to eq nil
    end
  end
end
