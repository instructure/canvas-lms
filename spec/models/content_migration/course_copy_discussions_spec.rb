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
                                                   :require_initial_post => true)
      topic.posted_at = 2.days.ago
      topic.position = 2
      topic.save!

      run_course_copy

      expect(@copy_to.discussion_topics.count).to eq 1
      new_topic = @copy_to.discussion_topics.first

      attrs = ["title", "message", "discussion_type", "type", "pinned", "position", "require_initial_post"]
      expect(topic.attributes.slice(*attrs)).to eq new_topic.attributes.slice(*attrs)

      expect(new_topic.last_reply_at.to_i).to eq new_topic.posted_at.to_i
      expect(topic.posted_at.to_i).to eq new_topic.posted_at.to_i
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

  end
end
