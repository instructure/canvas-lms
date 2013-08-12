#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Quiz do
  before(:each) do
    course
  end

  describe ".mark_quiz_edited" do
    it "should mark a quiz as having unpublished changes" do
      quiz = @course.quizzes.create! :title => "hello"
      quiz.published_at = Time.now
      quiz.publish!
      quiz.unpublished_changes?.should be_false

      Quiz.mark_quiz_edited(quiz.id)
      quiz.reload.unpublished_changes?.should be_true
    end
  end

  describe "#publish!" do
    it "sets the workflow state to available and save!s the quiz" do
      quiz = Quiz.new(:title => "hello")
      quiz.expects(:generate_quiz_data).once
      quiz.expects(:save!).once
      quiz.publish!
      quiz.workflow_state.should == 'available'
    end
  end

  describe "#unpublish!" do
    it "sets the workflow state to unpublished and save!s the quiz" do
      quiz = Quiz.new(:title => "hello")
      quiz.expects(:save!).once
      quiz.publish!
      quiz.workflow_state.should == 'available'

      quiz.expects(:save!).once
      quiz.unpublish!
      quiz.workflow_state.should == 'unpublished'
    end

    it "should fail validation with student submissions" do
      quiz = @course.quizzes.build title: 'test quiz'
      quiz.publish!
      quiz.stubs(:has_student_submissions?).returns true

      expect { quiz.unpublish! }.to raise_exception(ActiveRecord::RecordInvalid)
    end

    it "should pass validation without student submissions" do
      quiz = @course.quizzes.build title: 'test quiz'
      quiz.publish!
      quiz.stubs(:has_student_submissions?).returns false

      quiz.unpublish!
      quiz.published?.should be_false
    end
  end

  it "should infer the times if none given" do
    q = factory_with_protected_attributes(@course.quizzes,
                                          :title => "new quiz",
                                          :due_at => "Sep 3 2008 12:00am",
                                          :lock_at => "Sep 3 2008 12:00am",
                                          :unlock_at => "Sep 3 2008 12:00am",
                                          :quiz_type => 'assignment',
                                          :workflow_state => 'available')
    due_at = q.due_at
    q.due_at.should == Time.parse("Sep 3 2008 12:00am UTC")
    lock_at = q.lock_at
    unlock_at = q.unlock_at
    q.lock_at.should == Time.parse("Sep 3 2008 12:00am UTC")
    q.assignment.due_at.should == Time.parse("Sep 3 2008 12:00am UTC")
    q.infer_times
    q.save!
    q.due_at.should == due_at.end_of_day
    q.assignment.due_at.should == due_at.end_of_day
    q.lock_at.should == lock_at.end_of_day
    q.assignment.lock_at.should == lock_at.end_of_day
    # Unlock at should not be fudged so teacher's can say this assignment
    # is available at 12 am.
    q.unlock_at.should == unlock_at.midnight
    q.assignment.unlock_at.should == unlock_at.midnight
  end

  it "should set the due time to 11:59pm if only given a date" do
    params = { :quiz => {
      :title => "Test Quiz",
      :due_at => Time.zone.today.to_s,
      :lock_at => Time.zone.today.to_s,
      :unlock_at => Time.zone.today.to_s
      }
    }
    q = @course.quizzes.create!(params[:quiz])
    q.infer_times
    q.due_at.should be_an_instance_of ActiveSupport::TimeWithZone
    q.due_at.time_zone.should == Time.zone
    q.due_at.hour.should eql 23
    q.due_at.min.should eql 59
    q.lock_at.time_zone.should == Time.zone
    q.lock_at.hour.should eql 23
    q.lock_at.min.should eql 59
    # Unlock at should not be fudged so teacher's can say this assignment
    # is available at 12 am.
    q.unlock_at.time_zone.should == Time.zone
    q.unlock_at.hour.should eql 0
    q.unlock_at.min.should eql 0
  end

  it "should not set the due time to 11:59pm if passed a time of midnight" do
    params = { :quiz => { :title => "Test Quiz", :due_at => "Jan 1 2011 12:00am" } }
    q = @course.quizzes.create!(params[:quiz])
    q.due_at.hour.should eql 0
    q.due_at.min.should eql 0
  end

  it "should convert a date object to a time and set the time to 11:59pm" do
    Time.zone = 'Alaska'
    params = { :quiz => { :title => 'Test Quiz', :due_at => Time.zone.today } }
    quiz = @course.quizzes.create!(params[:quiz])
    quiz.due_at.should be_an_instance_of ActiveSupport::TimeWithZone
    quiz.due_at.zone.should eql Time.zone.now.dst? ? 'AKDT' : 'AKST'
    quiz.due_at.hour.should eql 23
    quiz.due_at.min.should eql 59
  end

  it "should set the due date time correctly" do
    time_string = "Dec 30, 2011 12:00 pm"
    expected = "2011-12-30 19:00:00 #{Time.now.utc.strftime("%Z")}"
    Time.zone = "Mountain Time (US & Canada)"
    quiz = @course.quizzes.create(:title => "sad quiz", :due_at => time_string, :lock_at => time_string, :unlock_at => time_string)
    quiz.due_at.utc.strftime("%Y-%m-%d %H:%M:%S %Z").should == expected
    quiz.lock_at.utc.strftime("%Y-%m-%d %H:%M:%S %Z").should == expected
    quiz.unlock_at.utc.strftime("%Y-%m-%d %H:%M:%S %Z").should == expected
    Time.zone = nil
  end

  it "should initialize with default settings" do
    q = @course.quizzes.create!(:title => "new quiz")
    q.shuffle_answers.should eql(false)
    q.show_correct_answers.should eql(true)
    q.allowed_attempts.should eql(1)
    q.scoring_policy.should eql('keep_highest')
  end

  it "should update the assignment it is associated with" do
    a = @course.assignments.create!(:title => "some assignment", :points_possible => 5)
    a.points_possible.should eql(5.0)
    a.submission_types.should_not eql("online_quiz")
    q = @course.quizzes.build(:assignment_id => a.id, :title => "some quiz", :points_possible => 10)
    q.workflow_state = 'available'
    q.save
    q.should be_available
    q.assignment_id.should eql(a.id)
    q.assignment.should eql(a)
    a.reload
    a.quiz.should eql(q)
    q.points_possible.should eql(10.0)
    q.assignment.submission_types.should eql("online_quiz")
    q.assignment.points_possible.should eql(10.0)

    g = @course.assignment_groups.create!(:name => "new group")
    q.assignment_group_id = g.id
    q.save
    q.reload
    a.reload
    a.assignment_group.should eql(g)
    q.assignment_group_id.should eql(g.id)

    g2 = @course.assignment_groups.create!(:name => "new group2")
    a.assignment_group = g2
    a.save
    a.reload
    q.reload
    q.assignment_group_id.should eql(g2.id)
    a.assignment_group.should eql(g2)
  end

  it "shouldn't create a new assignment on every edit" do
    a_count = Assignment.count
    a = @course.assignments.create!(:title => "some assignment", :points_possible => 5)
    a.points_possible.should eql(5.0)
    a.submission_types.should_not eql("online_quiz")
    q = @course.quizzes.build(:title => "some quiz", :points_possible => 10)
    q.workflow_state = 'available'
    q.assignment_id = a.id
    q.save
    q.quiz_type = 'assignment'
    q.save
    q.should be_available
    q.assignment_id.should eql(a.id)
    q.assignment.should eql(a)
    a.reload
    a.quiz.should eql(q)
    q.points_possible.should eql(10.0)
    a.submission_types.should eql("online_quiz")
    a.points_possible.should eql(10.0)
    Assignment.count.should eql(a_count + 1)
  end

  it "should not send a message if notify_of_update is blank" do
    Notification.create!(:name => 'Assignment Changed')
    @course.offer
    a = @course.assignments.create!(:title => "some assignment", :points_possible => 5)
    a.points_possible.should eql(5.0)
    a.submission_types.should_not eql("online_quiz")
    a.update_attribute(:created_at, Time.now - (40 * 60))
    q = @course.quizzes.build(:assignment_id => a.id, :title => "some quiz", :points_possible => 10)
    q.workflow_state = 'available'
    q.assignment.expects(:save_without_broadcasting!).at_least_once
    q.save
    q.assignment.messages_sent.should be_empty
  end

  it "should send a message if notify_of_update is set" do
    Notification.create!(:name => 'Assignment Changed')
    @course.offer
    a = @course.assignments.create!(:title => "some assignment", :points_possible => 5)
    a.points_possible.should eql(5.0)
    a.submission_types.should_not eql("online_quiz")
    a.update_attribute(:created_at, Time.now - (40 * 60))
    q = @course.quizzes.build(:assignment_id => a.id, :title => "some quiz", :points_possible => 10)
    q.workflow_state = 'available'
    q.notify_of_update = 1
    q.assignment.expects(:save_without_broadcasting!).never
    q.save
    q.assignment.messages_sent.should include('Assignment Changed')
  end

  it "should delete the assignment if the quiz is no longer graded" do
    a = @course.assignments.create!(:title => "some assignment", :points_possible => 5)
    a.points_possible.should eql(5.0)
    a.submission_types.should_not eql("online_quiz")
    q = @course.quizzes.build(:assignment_id => a.id, :title => "some quiz", :points_possible => 10)
    q.workflow_state = 'available'
    q.save
    q.should be_available
    q.assignment_id.should eql(a.id)
    q.assignment.should eql(a)
    a.reload
    a.quiz.should eql(q)
    q.points_possible.should eql(10.0)
    q.assignment.submission_types.should eql("online_quiz")
    q.assignment.points_possible.should eql(10.0)
    q.quiz_type = "practice_quiz"
    q.save
    q.assignment_id.should eql(nil)
  end

  it "should not create an assignment for ungraded quizzes" do
    g = @course.assignment_groups.create!(:name => "new group")
    q = @course.quizzes.build(:title => "some quiz", :quiz_type => "survey", :assignment_group_id => g.id)
    q.workflow_state = 'available'
    q.save!
    q.should be_available
    q.assignment_id.should be_nil
  end

  it "should not create the assignment if unpublished" do
    g = @course.assignment_groups.create!(:name => "new group")
    q = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment", :assignment_group_id => g.id)
    q.save!
    q.should_not be_available
    q.assignment_id.should be_nil
    q.assignment_group_id.should eql(g.id)
  end

  it "should create the assignment if created in published state" do
    g = @course.assignment_groups.create!(:name => "new group")
    q = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment", :assignment_group_id => g.id)
    q.workflow_state = 'available'
    q.save!
    q.should be_available
    q.assignment_id.should_not be_nil
    q.assignment_group_id.should eql(g.id)
    q.assignment.assignment_group_id.should eql(g.id)
  end

  it "should create the assignment if published after being created" do
    g = @course.assignment_groups.create!(:name => "new group")
    q = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment", :assignment_group_id => g.id)
    q.save!
    q.should_not be_available
    q.assignment_id.should be_nil
    q.assignment_group_id.should eql(g.id)
    q.workflow_state = 'available'
    q.save!
    q.should be_available
    q.assignment_id.should_not be_nil
    q.assignment_group_id.should eql(g.id)
    q.assignment.assignment_group_id.should eql(g.id)
  end

  it "should return a zero question count but valid unpublished question count until the quiz is generated" do
    q = @course.quizzes.create!(:title => "new quiz")
    g = q.quiz_groups.create!(:name => "group 1", :pick_count => 1)
    q.quiz_questions.create!(:quiz_group => g)
    q.quiz_questions.create!(:quiz_group => g)
    q.quiz_questions.create!()
    q.quiz_questions.create!()
    # this is necessary because of some caching that happens on the quiz object, that is not a factor in production
    q.root_entries(true)
    q.save
    q.question_count.should eql(0)
    q.unpublished_question_count.should eql(3)
  end

  it "should return processed root entries for each question/group" do
    q = @course.quizzes.create!(:title => "new quiz")
    g = q.quiz_groups.create!(:name => "group 1", :pick_count => 1, :question_points => 2)

    qq1 = q.quiz_questions.create!(:question_data => { :name => "test 1" }, :quiz_group => g)
    # make sure we handle sorting with nil positions
    QuizQuestion.where(:id => qq1).update_all(:position => nil)

    q.quiz_questions.create!(:question_data => { :name => "test 2" }, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 3" })
    q.quiz_questions.create!(:question_data => { :name => "test 4" })
    q.save
    q.quiz_questions.length.should eql(4)
    q.quiz_groups.length.should eql(1)
    g.quiz_questions(true).length.should eql(2)

    entries = q.root_entries(true)
    entries.length.should eql(3)
    entries[0][:questions].should_not be_nil
    entries[1][:answers].should_not be_nil
    entries[2][:answers].should_not be_nil
  end

  it "should generate valid quiz data" do
    q = @course.quizzes.create!(:title => "new quiz")
    g = q.quiz_groups.create!(:name => "group 1", :pick_count => 1, :question_points => 2)
    q.quiz_questions.create!(:question_data => { :name => "test 1" }, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 2" }, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 3" })
    q.quiz_questions.create!(:question_data => { :name => "test 4" })
    q.quiz_data.should be_nil
    q.generate_quiz_data
    q.save
    q.quiz_data.should_not be_nil
    data = q.quiz_data rescue nil
    data.should_not be_nil
  end

  it "should return quiz data once the quiz is generated" do
    q = @course.quizzes.create!(:title => "new quiz")
    g = q.quiz_groups.create!(:name => "group 1", :pick_count => 1, :question_points => 2)
    q.quiz_questions.create!(:question_data => { :name => "test 1", }, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 2", }, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 3", })
    q.quiz_questions.create!(:question_data => { :name => "test 4", })
    q.quiz_data.should be_nil
    q.generate_quiz_data
    q.save

    data = q.stored_questions
    data.length.should eql(3)
    data[0][:questions].should_not be_nil
    data[1][:answers].should_not be_nil
    data[2][:answers].should_not be_nil
  end

  it "should shuffle answers for the questions" do
    q = @course.quizzes.create!(:title => "new quiz", :shuffle_answers => true)
    q.quiz_questions.create!(:question_data => {:name => 'test 3', 'question_type' => 'multiple_choice_question', 'answers' => {'answer_0' => {'answer_text' => '1'}, 'answer_1' => {'answer_text' => '2'}, 'answer_2' => {'answer_text' => '3'},'answer_3' => {'answer_text' => '4'},'answer_4' => {'answer_text' => '5'},'answer_5' => {'answer_text' => '6'},'answer_6' => {'answer_text' => '7'},'answer_7' => {'answer_text' => '8'},'answer_8' => {'answer_text' => '9'},'answer_9' => {'answer_text' => '10'}}})
    q.quiz_data.should be_nil
    q.generate_quiz_data
    q.save

    data = q.stored_questions
    data.length.should eql(1)
    data[0][:answers].should_not be_empty
    same = true
    found = []
    data[0][:answers].each{|a| found << a[:text] }
    found.uniq.length.should eql(10)
    same = false if data[0][:answers][0][:text] != '1'
    same = false if data[0][:answers][1][:text] != '2'
    same = false if data[0][:answers][2][:text] != '3'
    same = false if data[0][:answers][3][:text] != '4'
    same = false if data[0][:answers][4][:text] != '5'
    same = false if data[0][:answers][5][:text] != '6'
    same = false if data[0][:answers][6][:text] != '7'
    same = false if data[0][:answers][7][:text] != '8'
    same = false if data[0][:answers][8][:text] != '9'
    same = false if data[0][:answers][9][:text] != '10'
    same.should eql(false)
  end

  it "should shuffle questions for the quiz groups" do
    q = @course.quizzes.create!(:title => "new quiz")
    g = q.quiz_groups.create!(:name => "some group", :pick_count => 10, :question_points => 10)
    q.quiz_questions.create!(:question_data => { :name => "test 1", 'answers' => []}, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 2", 'answers' => []}, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 3", 'answers' => []}, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 4", 'answers' => []}, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 5", 'answers' => []}, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 6", 'answers' => []}, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 7", 'answers' => []}, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 8", 'answers' => []}, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 9", 'answers' => []}, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 10", 'answers' => []}, :quiz_group => g)
    q.quiz_data.should be_nil
    q.reload
    q.generate_quiz_data
    q.save

    data = q.stored_questions
    data.length.should eql(1)
    data = data[0][:questions]
    same = true
    same = false if data[0][:name] != "test 1"
    same = false if data[1][:name] != "test 2"
    same = false if data[2][:name] != "test 3"
    same = false if data[3][:name] != "test 4"
    same = false if data[4][:name] != "test 5"
    same = false if data[5][:name] != "test 6"
    same = false if data[6][:name] != "test 7"
    same = false if data[7][:name] != "test 8"
    same = false if data[8][:name] != "test 9"
    same = false if data[9][:name] != "test 10"
    same.should eql(false)
  end

  it "should consider the number of questions in a group when determining the question count" do
    q = @course.quizzes.create!(:title => "new quiz")
    g = q.quiz_groups.create!(:name => "group 1", :pick_count => 10, :question_points => 2)
    q.quiz_questions.create!(:question_data => { :name => "test 1", }, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 2", }, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 3", })
    q.quiz_questions.create!(:question_data => { :name => "test 4", })
    q.quiz_data.should be_nil
    q.generate_quiz_data
    q.save

    data = q.stored_questions
    data.length.should eql(3)
    data[0][:questions].should_not be_nil
    data[1][:answers].should_not be_nil
    data[2][:answers].should_not be_nil
  end

  context "#generate_submission" do

    it "should generate a valid submission for a given user" do
      u = User.create!(:name => "some user")
      q = @course.quizzes.create!(:title => "some quiz")
      q = @course.quizzes.create!(:title => "new quiz")
      g = q.quiz_groups.create!(:name => "group 1", :pick_count => 1, :question_points => 2)
      q.quiz_questions.create!(:question_data => { :name => "test 1", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 2", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 3", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 4", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 5", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 6", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 7", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 8", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 9", })
      q.quiz_questions.create!(:question_data => { :name => "test 10", })
      q.quiz_data.should be_nil
      q.generate_quiz_data
      q.save

      s = q.generate_submission(u)
      s.state.should eql(:untaken)
      s.attempt.should eql(1)
      s.quiz_data.should_not be_nil
      s.quiz_version.should eql(q.version_number)
      s.finished_at.should be_nil
      s.submission_data.should eql({})

    end

    it "sets end_at to lock_at when end_at is nil or after lock_at" do
      lock_at = 1.minute.from_now
      u = User.create!(:name => "some user")
      q = @course.quizzes.create!(:title => "some quiz", :lock_at => lock_at)
      # [nil, after lock_at]
      [1.minute.ago, 2.minutes.from_now].each do |due_at|
        q.due_at = due_at
        # when
        s = q.generate_submission(u)
        # expect
        s.end_at.should == lock_at
      end
    end

    it "should not set end_at to lock_at if a submission is manually unlocked" do
      lock_at = 1.day.ago
      u = User.create!(:name => "Fred Colon")
      q = @course.quizzes.create!(:title => "locked yesterday", :lock_at => lock_at)
      sub = q.find_or_create_submission(u, nil, 'settings_only')
      sub.manually_unlocked = true
      sub.save!
      sub2 = q.generate_submission(u)
      sub2.end_at.should be_nil
    end
  end

  it "should return a default title if the quiz is untitled" do
    q = @course.quizzes.create!
    q.quiz_title.should eql("Unnamed Quiz")
  end

  it "should return the assignment title if the quiz is linked to an assignment" do
    a = @course.assignments.create!(:title => "some assignment")
    q = @course.quizzes.create!(:assignment_id => a.id)
    a.reload
    q.quiz_title.should eql(a.title)
  end

  it "should delete the associated assignment if it is deleted" do
    a = @course.assignments.create!(:title => "some assignment")
    q = @course.quizzes.create!(:assignment_id => a.id, :quiz_type => "assignment")
    q.assignment_id.should eql(a.id)
    q.reload
    q.assignment_id = nil
    q.quiz_type = "practice_quiz"
    q.save!
    q.assignment_id.should eql(nil)
    a.reload
    a.should be_deleted
  end

  it "should reattach existing graded quiz submissions to the new assignment after a graded -> ungraded -> graded transition" do
    # create a quiz
    q = @course.quizzes.new
    q.quiz_type = "assignment"
    q.workflow_state = "available"
    q.save! && q.reload
    q.assignment.should_not be_nil
    q.quiz_submissions.size.should == 0

    # create a graded submission
    q.generate_submission(User.create!(:name => "some_user")).grade_submission
    q.reload

    q.quiz_submissions.size.should == 1
    q.quiz_submissions.first.submission.should_not be_nil
    q.quiz_submissions.first.submission.assignment.should == q.assignment

    # switch to ungraded
    q.quiz_type = "practice_quiz"
    q.save! && q.reload
    q.assignment.should be_nil
    q.quiz_submissions.size.should == 1

    # switch back to graded
    q.quiz_type = "assignment"
    q.save! && q.reload
    q.assignment.should_not be_nil
    q.quiz_submissions.size.should == 1
    q.quiz_submissions.first.submission.should_not be_nil
    q.quiz_submissions.first.submission.assignment.should == q.assignment
  end

  context "clone_for" do
    it "should clone for other contexts" do
      u = User.create!(:name => "some user")
      q = @course.quizzes.create!(:title => "some quiz")
      q = @course.quizzes.create!(:title => "new quiz")
      g = q.quiz_groups.create!(:name => "group 1", :pick_count => 1, :question_points => 2)
      q.quiz_questions.create!(:question_data => { :name => "test 1", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 2", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 3", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 4", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 5", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 6", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 7", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 8", }, :quiz_group => g)
      q.quiz_questions.create!(:question_data => { :name => "test 9", })
      q.quiz_questions.create!(:question_data => { :name => "test 10", })
      q.quiz_data.should be_nil
      q.generate_quiz_data
      q.save
      course
      new_q = q.clone_for(@course)
      new_q.context.should eql(@course)
      new_q.context.should_not eql(q.context)
      new_q.title.should eql(q.title)
      new_q.quiz_groups.length.should eql(q.quiz_groups.length)
      new_q.quiz_questions.length.should eql(q.quiz_questions.length)
      new_q.quiz_questions.first.question_data[:id].should be_nil
      new_q.quiz_questions.first.data[:id].should == new_q.quiz_questions.first.id
    end

    it "should set the related assignment's group correctly" do
      ag = @course.assignment_groups.create!(:name => 'group')
      a = @course.assignments.create!(:title => "some assignment", :points_possible => 5, :assignment_group => ag)
      a.points_possible.should eql(5.0)
      a.submission_types.should_not eql("online_quiz")
      q = @course.quizzes.build(:assignment_id => a.id, :title => "some quiz", :points_possible => 10)
      q.workflow_state = 'available'
      q.save

      course
      new_q = q.clone_for(@course)
      new_q.context.should eql(@course)
      new_q.context.should_not eql(q.context)
      new_q.assignment.assignment_group.should_not eql(ag)
      new_q.assignment.assignment_group.context.should eql(@course)
    end

    it "should not blow up when a quiz question has a link to the quiz it's in" do
      q = @course.quizzes.create!(:title => "some quiz")
      question_text = "<a href='/courses/#{@course.id}/quizzes/#{q.id}/edit'>hi</a>"
      q.quiz_questions.create!(:question_data => { :name => "test 1", :question_text => question_text })
      q.generate_quiz_data
      q.save
      course
      new_q = q.clone_for(@course)
      new_q.quiz_questions.first.question_data[:question_text].should match /\/courses\/#{@course.id}\/quizzes\/#{new_q.id}\/edit/
    end

    it "should only create one associated assignment for a graded quiz" do
      q = @course.quizzes.create!(:title => "graded quiz", :quiz_type => 'assignment')
      q.workflow_state = 'available'
      q.save
      course
      expect {
        new_q = q.clone_for(@course)
      }.to change(@course.assignments, :count).by(1)
    end
  end

  describe "Quiz with QuestionGroup pointing to QuestionBank" do
    before(:each) do
      course_with_student
      @bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
      @bank.assessment_questions.create!(:question_data => {'name' => 'Group Question 1', :question_type=>'essay_question', :question_text=>'gq1', 'answers' => []})
      @bank.assessment_questions.create!(:question_data => {'name' => 'Group Question 2', :question_type=>'essay_question', :question_text=>'gq2', 'answers' => []})
      @quiz = @course.quizzes.create!(:title => "i'm tired quiz")
      @quiz.quiz_questions.create!(:question_data => { :name => "Quiz Question 1", :question_type=>'essay_question', :question_text=>'qq1', 'answers' => [], :points_possible=>5.0})
      @group = @quiz.quiz_groups.create!(:name => "question group", :pick_count => 3, :question_points => 5.0)
      @group.assessment_question_bank = @bank
      @group.save!
      @quiz.generate_quiz_data
      @quiz.save!
      @quiz.reload
    end

    it "should create a submission" do
      submission = @quiz.generate_submission(@user)
      submission.quiz_data.length.should == 3
      texts = submission.quiz_data.map{|q|q[:question_text]}
      texts.member?('gq1').should be_true
      texts.member?('gq2').should be_true
      texts.member?('qq1').should be_true
    end

    it "should get the correct points possible" do
      @quiz.current_points_possible.should == 15
    end

    it "should omit top level questions when selecting from a question bank" do
      questions = @bank.assessment_questions
      # add the first question directly onto the quiz, so it shouldn't get "randomly" selected from the group
      linked_question = @quiz.quiz_questions.build(:question_data => questions[0].question_data)
      linked_question.assessment_question_id = questions[0].id
      linked_question.save!
      @quiz.generate_quiz_data
      @quiz.save!
      @quiz.reload

      submission = @quiz.generate_submission(@user)
      submission.quiz_data.length.should == 3
      texts = submission.quiz_data.map{|q|q[:question_text]}
      texts.member?('gq1').should be_true
      texts.member?('gq2').should be_true
      texts.member?('qq1').should be_true
    end

  end

  it "should ignore lockdown-browser setting if that plugin is not enabled" do
    q = @course.quizzes.build(:title => "some quiz")
    q1 = @course.quizzes.build(:title => "some quiz", :require_lockdown_browser => true, :require_lockdown_browser_for_results => false)
    q2 = @course.quizzes.build(:title => "some quiz", :require_lockdown_browser => true, :require_lockdown_browser_for_results => true)

    # first, disable any lockdown browsers that might be configured already
    Canvas::Plugin.all_for_tag(:lockdown_browser).each { |p| p.settings[:enabled] = false }

    # nothing should be restricted
    Quiz.lockdown_browser_plugin_enabled?.should be_false
    [q, q1, q2].product([:require_lockdown_browser, :require_lockdown_browser?, :require_lockdown_browser_for_results, :require_lockdown_browser_for_results?]).
        each { |qs| qs[0].send(qs[1]).should be_false }

    # register a plugin
    Canvas::Plugin.register(:example_spec_lockdown_browser, :lockdown_browser, {
        :settings => {:enabled => false}})

    # nothing should change yet
    Quiz.lockdown_browser_plugin_enabled?.should be_false
    [q, q1, q2].product([:require_lockdown_browser, :require_lockdown_browser?, :require_lockdown_browser_for_results, :require_lockdown_browser_for_results?]).
        each { |qs| qs[0].send(qs[1]).should be_false }

    # now actually enable the plugin
    setting = PluginSetting.find_or_create_by_name('example_spec_lockdown_browser')
    setting.settings = {:enabled => true}
    setting.save!

    # now the restrictions should take effect
    Quiz.lockdown_browser_plugin_enabled?.should be_true
    [:require_lockdown_browser, :require_lockdown_browser?, :require_lockdown_browser_for_results, :require_lockdown_browser_for_results?].
        each { |s| q.send(s).should be_false }
    [:require_lockdown_browser, :require_lockdown_browser?].
        each { |s| q1.send(s).should be_true }
    [:require_lockdown_browser_for_results, :require_lockdown_browser_for_results?].
        each { |s| q1.send(s).should be_false }
    [:require_lockdown_browser, :require_lockdown_browser?, :require_lockdown_browser_for_results, :require_lockdown_browser_for_results?].
        each { |s| q2.send(s).should be_true }
  end

  describe "non_shuffled_questions" do
    subject { Quiz.non_shuffled_questions }

    it { should include "true_false_question" }
    it { should include "matching_question" }
    it { should include "fill_in_multiple_blanks_question" }
    it { should_not include "multiple_choice_question" }
  end

  describe "prepare_answers" do
    let(:quiz) { Quiz.new }
    let(:question) { { :answers => answers } }
    let(:answers) { ['a', 'b', 'c'] }

    context "on a shuffle answers question" do
      before { quiz.stubs(:shuffle_answers).returns(true) }

      context "on a non-shuffleable question type" do
        before { Quiz.stubs(:shuffleable_question_type?).returns(false) }

        it "doesn't shuffle" do
          quiz.prepare_answers(question).should == answers
        end
      end

      context "on a shuffleable question type" do
        before { Quiz.stubs(:shuffleable_question_type?).returns(true) }

        it "returns the same answers, not necessarily in the same order" do
          quiz.prepare_answers(question).sort.should == answers.sort
        end

        it "shuffles" do
          answers.expects(:sort_by)
          quiz.prepare_answers(question)
        end
      end
    end

    context "on a non-shuffle answers question" do
      it "doesn't shuffle" do
        quiz.prepare_answers(question).should == answers
      end
    end
  end

  describe "shuffleable_question_type?" do
    specify { Quiz.shuffleable_question_type?("true_false_question").should be_false }
    specify { Quiz.shuffleable_question_type?("multiple_choice_question").should be_true }
  end

  describe '#has_student_submissions?' do
    before do
      course = Course.create!
      @quiz = Quiz.create!(:context => course)
      @user = User.create!
      @enrollment = @user.student_enrollments.create!(:course => course)
      @enrollment.update_attribute(:workflow_state, 'active')
      @submission = QuizSubmission.create!(:quiz => @quiz, :user => @user)
      @submission.update_attribute(:workflow_state, 'untaken')
    end

    it 'returns true if the submission is not settings_only and its user is part of this course' do
      @submission.settings_only?.should be_false
      @quiz.context.students.include?(@user).should be_true
      @quiz.has_student_submissions?.should be_true
    end

    it 'is false if the submission is settings_only' do
      @submission.update_attribute(:workflow_state, 'settings_only')
      @quiz.has_student_submissions?.should be_false
    end

    it 'is false if the user is not part of this course' do
      @user.student_enrollments.delete_all
      @quiz.has_student_submissions?.should be_false
    end

    it 'is false if there are no submissions' do
      @quiz.quiz_submissions.delete_all
      @quiz.has_student_submissions?.should be_false
    end

    it 'is true if only one submission of many matches the conditions' do
      QuizSubmission.create!(:quiz => @quiz, :user => User.create!)
      @quiz.has_student_submissions?.should be_true
    end
  end

  describe "#group_category_id" do

    it "returns the assignment's group category id if it has an assignment" do
      quiz = Quiz.new(:title => "Assignment Group Category Quiz")
      quiz.expects(:assignment).returns stub(:group_category_id => 1)
      quiz.group_category_id.should == 1
    end

    it "returns nil if it doesn't have an assignment" do
      quiz = Quiz.new(:title => "Quiz w/o assignment")
      quiz.group_category_id.should be_nil
    end

  end

  describe "linking overrides with assignments" do
    let(:course) { course_model }
    let(:quiz) { quiz_model(:course => course, :due_at => 5.days.from_now).reload }
    let(:override) { assignment_override_model(:quiz => quiz) }
    let(:override_student) { override.assignment_override_students.build }

    before do
      override.override_due_at(7.days.from_now)
      override.save!

      student_in_course(:course => course)
      override_student.user = @student
      override_student.save!
    end

    context "before the quiz has an assignment" do
      context "override" do
        it "has a quiz" do
          override.quiz.should == quiz
        end

        it "has a nil assignment" do
          override.assignment.should be_nil
        end
      end

      context "override student" do
        it "has a quiz" do
          override_student.quiz.should == quiz
        end

        it "has a nil assignment" do
          override_student.assignment.should be_nil
        end
      end
    end

    context "once the quiz is published" do
      before do
        # publish the quiz
        quiz.workflow_state = 'available'
        quiz.save
        override.reload
        override_student.reload
        quiz.assignment.reload
      end

      context "override" do
        it "has a quiz" do
          override.quiz.should == quiz
        end

        it "has the quiz's assignment" do
          override.assignment.should == quiz.assignment
        end

        it "has the quiz's assignment's version number" do
          override.assignment_version.should == quiz.assignment.version_number
        end

        it "has the quiz's version number" do
          override.quiz_version.should == quiz.version_number
        end

      end

      context "override student" do
        it "has a quiz" do
          override_student.quiz.should == quiz
        end

        it "has the quiz's assignment" do
          override_student.assignment.should == quiz.assignment
        end
      end
    end

    context "when the assignment ID doesn't change" do
      it "doesn't update overrides" do
        quiz.expects(:link_assignment_overrides).once
        # publish the quiz
        quiz.workflow_state = 'available'
        quiz.save
        quiz.expects(:link_assignment_overrides).never
        quiz.save
      end
    end

    context "when the assignment ID changes" do
      it "links overrides" do
        quiz.expects(:link_assignment_overrides).once
        quiz.workflow_state = 'available'
        quiz.save!
        quiz.expects(:link_assignment_overrides).once
        quiz.assignment = nil
        quiz.assignment_id = 345
        quiz.save!
      end
    end
  end

  context "custom validations" do
    context "quiz_type" do
      it "should not save an invalid quiz_type" do
        quiz = @course.quizzes.create! :title => "test quiz"
        quiz.quiz_type = "totally_invalid_quiz_type"
        quiz.save.should be_false
        quiz.errors["invalid_quiz_type"].should be_present
      end

      it "should not validate quiz_type if not changed" do
        quiz = @course.quizzes.build :title => "test quiz", :quiz_type => 'invalid'
        quiz.save(false).should be_true  # save without validation
        quiz.reload
        quiz.save.should be_true
        quiz.errors.should be_blank
        quiz.quiz_type.should == 'invalid'
      end
    end

    context "ip_filter" do
      it "should not save an invalid ip_filter" do
        quiz = @course.quizzes.create! :title => "test quiz"
        quiz.ip_filter = "999.999.1942.489"
        quiz.save.should be_false
        quiz.errors["invalid_ip_filter"].should be_present
      end

      it "should not validate ip_filter if not changed" do
        quiz = @course.quizzes.build :title => "test quiz", :ip_filter => '123.fourfivesix'
        quiz.save(false).should be_true  # save without validation
        quiz.reload
        quiz.save.should be_true
        quiz.errors.should be_blank
        quiz.ip_filter.should == '123.fourfivesix'
      end
    end

    context "workflow_state" do
      it "won't validate unpublishing a quiz if there are already submissions" do
        quiz = @course.quizzes.build title: 'test quiz'
        quiz.publish!
        quiz.stubs(:has_student_submissions?).returns true
        quiz.workflow_state = 'unpublished'
        quiz.save
        quiz.should_not be_valid
        quiz.reload.should be_published
      end

      it "will allow unpublishing if no student submissions" do
        quiz = @course.quizzes.build title: 'test quiz'
        quiz.publish!
        quiz.stubs(:has_student_submissions?).returns false
        quiz.workflow_state = 'unpublished'
        quiz.save
        quiz.should be_valid
        quiz.should be_unpublished
      end
    end

    context "hide_results" do
      it "should not save an invalid hide_results" do
        quiz = @course.quizzes.create! :title => "test quiz"
        quiz.hide_results = "totally_invalid_value"
        quiz.save.should be_false
        quiz.errors["invalid_hide_results"].should be_present
      end

      it "should not validate hide_results if not changed" do
        quiz = @course.quizzes.build :title => "test quiz", :hide_results => 'invalid'
        quiz.save(false).should be_true  # save without validation
        quiz.reload
        quiz.save.should be_true
        quiz.errors.should be_blank
        quiz.hide_results.should == 'invalid'
      end
    end
  end

  describe "#has_file_upload_question?" do

    let(:quiz) { @course.quizzes.build title: 'File Upload Quiz' }

    it "returns false unless there is quiz data for a quiz" do
      quiz.stubs(:quiz_data).returns nil
      quiz.has_file_upload_question?.should be_false
    end

    it "returns true when there is a file upload question" do
      quiz.stubs(:quiz_data).returns [
        {question_type: 'file_upload_question'}
      ]
      quiz.has_file_upload_question?.should be_true
    end

    it "returns false when there isn't a file upload question" do
      quiz.stubs(:quiz_data).returns [
        {question_type: 'multiple_choice_question'}
      ]
      quiz.has_file_upload_question?.should be_false
    end
  end
  context "#unpublished?" do
    before do
      @quiz = @course.quizzes.build title: 'Test Quiz'
    end

    it "returns true when workflow_state is unpublished" do
      @quiz.workflow_state = 'unpublished'
      @quiz.should be_unpublished
    end

    it "returns false when quiz has 'available' state" do
      @quiz.workflow_state = 'available'
      @quiz.should_not be_unpublished
    end
  end

  context "#active?" do
    before do
      @quiz = @course.quizzes.build title: 'Test Quiz'
    end

    it "returns true if workflow_state is available" do
      @quiz.workflow_state = 'available'
      @quiz.should be_active
    end

    it "returns false when workflow_state isn't available" do
      @quiz.workflow_state = 'deleted'
      @quiz.should_not be_active
      @quiz.workflow_state = 'unpublished'
      @quiz.should_not be_active
    end

  end

  context "#published?" do
    before do
      @quiz = @course.quizzes.build title: 'Test Quiz'
    end

    it "is just an alias for active?" do
      @quiz.workflow_state = 'available'
      @quiz.should be_published
      @quiz.workflow_state = 'unpublished'
      @quiz.should_not be_published
      @quiz.workflow_state = 'deleted'
      @quiz.should_not be_published
    end
  end
end
