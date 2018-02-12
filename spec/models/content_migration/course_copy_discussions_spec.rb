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

require File.expand_path(File.dirname(__FILE__) + '/course_copy_helper.rb')

describe ContentMigration do
  context "course copy discussions" do
    include_examples "course copy"

    def graded_discussion_topic
      @topic = @copy_from.discussion_topics.build(:title => "topic")
      @assignment = @copy_from.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title)
      @assignment.infer_times
      @assignment.saved_by = :discussion_topic
      @topic.assignment = @assignment
      @topic.save
    end

    it "should copy discussion topic attributes" do
      topic = @copy_from.discussion_topics.create!(:title => "topic", :message => "<p>bloop</p>",
                                                   :pinned => true, :discussion_type => "threaded",
                                                   :require_initial_post => true, :locked => true)
      todo_date = 1.day.from_now
      topic.todo_date = todo_date
      topic.posted_at = 2.days.ago
      topic.position = 2
      topic.save!

      run_course_copy

      expect(@copy_to.discussion_topics.count).to eq 1
      new_topic = @copy_to.discussion_topics.first

      attrs = ["title", "message", "discussion_type", "type", "pinned", "position", "require_initial_post", "locked"]
      expect(new_topic.attributes.slice(*attrs)).to eq topic.attributes.slice(*attrs)

      expect(new_topic.last_reply_at).to be_nil
      expect(new_topic.allow_rating).to eq false
      expect(new_topic.posted_at).to be_nil
      expect(new_topic.todo_date.to_i).to eq todo_date.to_i
    end

    it "copies rating settings" do
      topic1 = @copy_from.discussion_topics.create!(:title => "blah", :message => "srsly",
                                                    :allow_rating => true, :only_graders_can_rate => true,
                                                    :sort_by_rating => false)
      topic2 = @copy_from.discussion_topics.create!(:title => "bleh", :message => "srsly",
                                                    :allow_rating => true, :only_graders_can_rate => false,
                                                    :sort_by_rating => true)
      run_course_copy

      new_topic1 = @copy_to.discussion_topics.where(migration_id: mig_id(topic1)).first
      expect(new_topic1.allow_rating).to eq true
      expect(new_topic1.only_graders_can_rate).to eq true
      expect(new_topic1.sort_by_rating).to eq false

      new_topic2 = @copy_to.discussion_topics.where(migration_id: mig_id(topic2)).first
      expect(new_topic2.allow_rating).to eq true
      expect(new_topic2.only_graders_can_rate).to eq false
      expect(new_topic2.sort_by_rating).to eq true
    end

    it "should copy group setting" do
      group_category = @copy_from.group_categories.create!(name: 'blah')
      topic = @copy_from.discussion_topics.create! group_category: group_category

      run_course_copy

      new_topic = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      expect(new_topic).to be_has_group_category
      expect(new_topic.group_category.name).to eq "Project Groups"
    end

    it "assigns group discussions to a group with a matching name in the destination course" do
      group_category = @copy_from.group_categories.create!(name: 'blah')
      topic = @copy_from.discussion_topics.create! group_category: group_category
      target_group = @copy_to.group_categories.create!(name: 'blah')

      run_course_copy

      new_topic = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      expect(new_topic).to be_has_group_category
      expect(new_topic.group_category.name).to eq "blah"
    end

    it "should copy a discussion topic when assignment is selected" do
      graded_discussion_topic

      # Should not fail if the destination has a group
      @copy_to.groups.create!(:name => 'some random group of people')

      @cm.copy_options = {
              :assignments => {mig_id(@assignment) => "1"},
              :discussion_topics => {mig_id(@topic) => "0"},
      }
      @cm.save!

      run_course_copy

      expect(@copy_to.discussion_topics.where(migration_id: mig_id(@topic)).first).not_to be_nil
    end

    it "should properly copy selected delayed announcements" do
      from_time = 1.hour.from_now
      until_time = 25.hours.from_now
      from_ann = @copy_from.announcements.create!(:message => "goodbye", :title => "goodbye announcement", delayed_post_at: from_time, lock_at: until_time)
      from_ann.workflow_state = "post_delayed"
      from_ann.save!

      @cm.copy_options = { :announcements => {mig_id(from_ann) => "1"}}
      @cm.save!

      run_course_copy

      to_ann = @copy_to.announcements.where(migration_id: mig_id(from_ann)).first
      expect(to_ann.workflow_state).to eq "post_delayed"
      expect(to_ann.delayed_post_at.to_i).to eq from_time.to_i
      expect(to_ann.lock_at.to_i).to eq until_time.to_i

      Timecop.freeze(2.hours.from_now) do
        run_jobs
        to_ann.reload
        expect(to_ann.workflow_state).to eq 'active'
      end

      Timecop.freeze(26.hours.from_now) do
        run_jobs
        to_ann.reload
        expect(to_ann.locked).to be_truthy
      end
    end

    it "should properly copy selected delayed announcements even if they've already posted and locked" do
      from_ann = @copy_from.announcements.create!(:message => "goodbye", :title => "goodbye announcement", delayed_post_at: 5.days.ago, lock_at: 2.days.ago )
      from_ann.save!
      run_jobs
      from_ann.reload

      expect(from_ann.workflow_state).to eq "active"
      expect(from_ann.locked).to be_truthy

      @cm.copy_options = {
        :everything => true,
        :shift_dates => true,
        :old_start_date => 7.days.ago.to_s,
        :old_end_date => Time.now.to_s,
        :new_start_date => Time.now.to_s,
        :new_end_date => 7.days.from_now.to_s
      }
      @cm.save!

      run_course_copy

      to_ann = @copy_to.announcements.where(migration_id: mig_id(from_ann)).first
      expect(to_ann.workflow_state).to eq "post_delayed"
      expect(to_ann.locked).to be_falsey

      Timecop.freeze(3.days.from_now) do
        run_jobs
        to_ann.reload
        expect(to_ann.workflow_state).to eq 'active'
      end

      Timecop.freeze(6.days.from_now) do
        run_jobs
        to_ann.reload
        expect(to_ann.locked).to be_truthy
      end
    end

    it "should not copy announcements if not selected" do
      ann = @copy_from.announcements.create!(:message => "howdy", :title => "announcement title")

      @cm.copy_options = {
          :all_discussion_topics => "1", :all_announcements => "0"
      }
      @cm.save!

      run_course_copy

      expect(@copy_to.announcements.where(migration_id: mig_id(ann)).first).to be_nil
    end

    it "should implicitly copy files attached to topics" do
      att = Attachment.create!(:filename => 'test.txt', :display_name => "testing.txt", :uploaded_data => StringIO.new('file'),
        :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      topic = @copy_from.discussion_topics.new(:message => "howdy", :title => "title")
      topic.attachment = att
      topic.save!

      @cm.copy_options = {:all_discussion_topics => "1"}
      @cm.save!

      run_course_copy

      att_copy = @copy_to.attachments.where(migration_id: mig_id(att)).first
      expect(att_copy).to be_present

      topic_copy = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      expect(topic_copy.attachment).to eq att_copy
    end

    it "should not copy deleted assignment attached to topic" do
      graded_discussion_topic
      @assignment.workflow_state = 'deleted'
      @assignment.save!

      @topic.reload
      expect(@topic.active?).to eq true

      run_course_copy

      expect(@copy_to.discussion_topics.where(migration_id: mig_id(@topic)).first).not_to be_nil
      expect(@copy_to.assignments.where(migration_id: mig_id(@assignment)).first).to be_nil
    end

    it "should copy the assignment group and grading standard in complete copy" do
      graded_discussion_topic
      gs = make_grading_standard(@copy_from, title: 'One')
      group = @copy_from.assignment_groups.create!(:name => "new group")
      @assignment.assignment_group = group
      @assignment.grading_standard = gs
      @assignment.save!
      run_course_copy
      new_topic = @copy_to.discussion_topics.where(migration_id: mig_id(@topic)).first
      expect(new_topic.assignment).to be_present
      expect(new_topic.assignment.assignment_group.migration_id).to eql mig_id(group)
      expect(new_topic.assignment.grading_standard.migration_id).to eql mig_id(gs)
    end

    it "should copy the grading standard (but not assignment group) in selective copy" do
      graded_discussion_topic
      gs = make_grading_standard(@copy_from, title: 'One')
      group = @copy_from.assignment_groups.create!(:name => "new group")
      @assignment.assignment_group = group
      @assignment.grading_standard = gs
      @assignment.save!
      @cm.copy_options = { 'everything' => '0', 'discussion_topics' => { mig_id(@topic) => "1" } }
      run_course_copy
      new_topic = @copy_to.discussion_topics.where(migration_id: mig_id(@topic)).first
      expect(new_topic.assignment).to be_present
      expect(new_topic.assignment.assignment_group.migration_id).to be_nil
      expect(new_topic.assignment.grading_standard.migration_id).to eql mig_id(gs)
    end

    it "should not copy the assignment group and grading standard in selective export" do
      graded_discussion_topic
      gs = make_grading_standard(@copy_from, title: 'One')
      group = @copy_from.assignment_groups.create!(:name => "new group")
      @assignment.assignment_group = group
      @assignment.grading_standard = gs
      @assignment.save!
      # test that we neither export nor reference the grading standard and assignment group
      decoy_gs = make_grading_standard(@copy_to, title: 'decoy')
      decoy_gs.update_attribute :migration_id, mig_id(gs)
      decoy_ag = @copy_to.assignment_groups.create! name: 'decoy'
      decoy_ag.update_attribute :migration_id, mig_id(group)
      run_export_and_import do |export|
        export.selected_content = { 'discussion_topics' => { mig_id(@topic) => "1" } }
      end
      new_topic = @copy_to.discussion_topics.where(migration_id: mig_id(@topic)).first
      expect(new_topic.assignment).to be_present
      expect(new_topic.assignment.grading_standard).to be_nil
      expect(new_topic.assignment.assignment_group.migration_id).not_to eql mig_id(@group)
      expect(decoy_gs.reload.title).not_to eql gs.title
      expect(decoy_ag.reload.name).not_to eql group.name
    end

    it "should copy references to locked discussions even if manage_content is not true" do
      @role = Account.default.roles.build :name => 'SuperTeacher'
      @role.base_role_type = 'TeacherEnrollment'
      @role.save!
      @copy_to.enroll_user(@user, 'TeacherEnrollment', :role => @role)

      Account.default.role_overrides.create!(:permission => "manage_content", :role => teacher_role, :enabled => false)

      topic = @copy_from.discussion_topics.build(:title => "topic")
      topic.locked = true
      topic.save!

      @copy_from.syllabus_body = "<p><a href=\"/courses/#{@copy_from.id}/discussion_topics/#{topic.id}\">link</a></p>"
      @copy_from.save!

      run_course_copy

      topic2 = @copy_to.discussion_topics.where(:migration_id => mig_id(topic)).first

      @copy_to.reload
      expect(@copy_to.syllabus_body).to be_include("/courses/#{@copy_to.id}/discussion_topics/#{topic2.id}")
    end

    it "should not copy lock_at directly when on assignment" do
      graded_discussion_topic
      @assignment.update_attribute(:lock_at, 3.days.from_now)

      run_course_copy

      topic2 = @copy_to.discussion_topics.where(:migration_id => mig_id(@topic)).first
      expect(topic2.assignment.lock_at.to_i).to eq @assignment.lock_at.to_i
      expect(topic2.lock_at).to be_nil
    end
  end
end
