require File.expand_path(File.dirname(__FILE__) + '/course_copy_helper.rb')

describe ContentMigration do
  context "course copy discussions" do
    include_examples "course copy"

    it "should copy discussion topic attributes" do
      topic = @copy_from.discussion_topics.create!(:title => "topic", :message => "<p>bloop</p>",
                                                   :pinned => true, :discussion_type => "threaded",
                                                   :require_initial_post => true)
      topic.posted_at = 2.days.ago
      topic.position = 2
      topic.save!

      run_course_copy

      @copy_to.discussion_topics.count.should == 1
      new_topic = @copy_to.discussion_topics.first

      attrs = ["title", "message", "discussion_type", "type", "pinned", "position", "require_initial_post"]
      topic.attributes.slice(*attrs).should == new_topic.attributes.slice(*attrs)

      new_topic.last_reply_at.to_i.should == new_topic.posted_at.to_i
      topic.posted_at.to_i.should == new_topic.posted_at.to_i
    end

    it "should copy a discussion topic when assignment is selected" do
      topic = @copy_from.discussion_topics.build(:title => "topic")
      assignment = @copy_from.assignments.build(:submission_types => 'discussion_topic', :title => topic.title)
      assignment.infer_times
      assignment.saved_by = :discussion_topic
      topic.assignment = assignment
      topic.save

      # Should not fail if the destination has a group
      @copy_to.groups.create!(:name => 'some random group of people')

      @cm.copy_options = {
              :assignments => {mig_id(assignment) => "1"},
              :discussion_topics => {mig_id(topic) => "0"},
      }
      @cm.save!

      run_course_copy

      @copy_to.discussion_topics.find_by_migration_id(mig_id(topic)).should_not be_nil
    end

    it "should properly copy selected delayed announcements" do
      from_ann = @copy_from.announcements.create!(:message => "goodbye", :title => "goodbye announcement", delayed_post_at: 1.hour.from_now)
      from_ann.workflow_state = "post_delayed"
      from_ann.save!

      @cm.copy_options = { :announcements => {mig_id(from_ann) => "1"}}
      @cm.save!

      run_course_copy

      to_ann = @copy_to.announcements.find_by_migration_id(mig_id(from_ann))
      to_ann.workflow_state.should == "post_delayed"
    end

    it "should not copy announcements if not selected" do
      ann = @copy_from.announcements.create!(:message => "howdy", :title => "announcement title")

      @cm.copy_options = {
          :all_discussion_topics => "1", :all_announcements => "0"
      }
      @cm.save!

      run_course_copy

      @copy_to.announcements.find_by_migration_id(mig_id(ann)).should be_nil
    end

    it "should not copy deleted assignment attached to topic" do
      topic = @copy_from.discussion_topics.build(:title => "topic")
      assignment = @copy_from.assignments.build(:submission_types => 'discussion_topic', :title => topic.title)
      assignment.infer_times
      assignment.saved_by = :discussion_topic
      topic.assignment = assignment
      topic.save!
      assignment.workflow_state = 'deleted'
      assignment.save!

      topic.reload
      topic.active?.should == true

      run_course_copy

      @copy_to.discussion_topics.find_by_migration_id(mig_id(topic)).should_not be_nil
      @copy_to.assignments.find_by_migration_id(mig_id(assignment)).should be_nil
    end
  end
end
