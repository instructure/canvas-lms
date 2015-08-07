require File.expand_path(File.dirname(__FILE__) + '/common')

describe "dashboard" do
  include_context "in-process server selenium tests"

  context "as a student" do

    before (:each) do
      course_with_student_logged_in(:active_all => true)
    end

    it "should limit the number of visible items in the to do list", priority: "1", test_id: 216405 do
      due_date = Time.now.utc + 2.days
      20.times do
        assignment_model :due_at => due_date, :course => @course, :submission_types => 'online_text_entry'
      end

      get "/"

      keep_trying_until { expect(ffj(".to-do-list li:visible").size).to eq 5 + 1 } # +1 is the see more link
      f(".more_link").click
      wait_for_ajaximations
      expect(ffj(".to-do-list li:visible").size).to eq 20
    end

    it "should display assignments to do in to do list for a student", priority: "1", test_id: 216406 do
      notification_model(:name => 'Assignment Due Date Changed')
      notification_policy_model(:notification_id => @notification.id)
      assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
      assignment.due_at = Time.now + 60
      assignment.created_at = 1.month.ago
      assignment.save!

      get "/"

      #verify assignment changed notice is in messages
      f('.stream-assignment .stream_header').click
      expect(f('#assignment-details')).to include_text('Assignment Due Date Changed')
      #verify assignment is in to do list
      expect(f('.to-do-list > li')).to include_text(assignment.submission_action_string)
      expect(f('.coming_up')).to include_text(assignment.title)
    end

    it "should not display assignments for soft-concluded courses in to do list for a student", priority: "1", test_id: 216407 do
      notification_model(:name => 'Assignment Due Date Changed')
      notification_policy_model(:notification_id => @notification.id)
      assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
      assignment.due_at = Time.now + 60
      assignment.created_at = 1.month.ago
      assignment.save!

      Timecop.freeze(1.hour.ago) do
        @course.soft_conclude!
        @course.save!
      end

      get "/"

      expect(f('.to-do-list')).to be_nil
      expect(f('.coming_up')).to_not include_text(assignment.title)
    end

    it "should allow to do list items to be ignored", priority: "1", test_id: 216408 do
      notification_model(:name => 'Assignment Due Date Changed')
      notification_policy_model(:notification_id => @notification.id)
      assignment = assignment_model({:submission_types => 'online_text_entry', :course => @course})
      assignment.due_at = Time.now + 60
      assignment.created_at = 1.month.ago
      assignment.save!

      get "/"

      expect(f('.to-do-list > li')).to include_text(assignment.submission_action_string)
      f('.to-do-list .disable_item_link').click
      wait_for_ajaximations
      expect(f('.to-do-list > li')).to be_nil

      get "/"

      expect(f('.to-do-list')).to be_nil
    end

  end
end