#
# Copyright (C) 2011 Instructure, Inc.
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

  it "should infer the times if none given" do
    q = factory_with_protected_attributes(@course.quizzes, :title => "new quiz", :due_at => "Sep 3 2008 12:00am", :quiz_type => 'assignment', :workflow_state => 'available')
    q.due_at.should == Time.parse("Sep 3 2008 12:00am UTC")
    q.assignment.due_at.should == Time.parse("Sep 3 2008 12:00am UTC")
    q.infer_times
    q.save!
    q.due_at.should == Time.parse("Sep 3 2008 11:59pm UTC")
    q.assignment.due_at.should == Time.parse("Sep 3 2008 11:59pm UTC")
  end

  it "should set the due time to 11:59pm if only given a date" do
    params = { :quiz => { :title => "Test Quiz", :due_at => Time.zone.today.to_s } }
    q = @course.quizzes.create!(params[:quiz])
    q.due_at.should be_an_instance_of ActiveSupport::TimeWithZone
    q.due_at.time_zone.should == Time.zone
    q.due_at.hour.should eql 23
    q.due_at.min.should eql 59
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
    expected = "Fri Dec 30 19:00:00 UTC 2011"
    Time.zone = "Mountain Time (US & Canada)"
    quiz = @course.quizzes.create(:title => "sad quiz", :due_at => time_string, :lock_at => time_string, :unlock_at => time_string)
    quiz.due_at.utc.to_s.should == expected
    quiz.lock_at.utc.to_s.should == expected
    quiz.unlock_at.utc.to_s.should == expected
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
    q.quiz_questions.create!(:question_data => { :name => "test 1" }, :quiz_group => g)
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

  context 'statistics' do
    it 'should calculate mean/stddev as expected with no submissions' do
      stats = @course.quizzes.new.statistics
      stats[:submission_score_average].should be_nil
      stats[:submission_score_high].should be_nil
      stats[:submission_score_low].should be_nil
      stats[:submission_score_stdev].should be_nil
    end

    it 'should calculate mean/stddev as expected with a few submissions' do
      q = @course.quizzes.new
      q.save!
      @user1 = User.create! :name => "some_user 1"
      @user2 = User.create! :name => "some_user 2"
      @user3 = User.create! :name => "some_user 2"
      student_in_course :course => @course, :user => @user1
      student_in_course :course => @course, :user => @user2
      student_in_course :course => @course, :user => @user3
      sub = q.generate_submission(@user1)
      sub.workflow_state = 'complete'
      sub.submission_data = [{ :points => 15, :text => "", :correct => "undefined", :question_id => -1 }]
      sub.with_versioning(true, &:save!)
      stats = q.statistics
      stats[:submission_score_average].should == 15
      stats[:submission_score_high].should == 15
      stats[:submission_score_low].should == 15
      stats[:submission_score_stdev].should == 0
      sub = q.generate_submission(@user2)
      sub.workflow_state = 'complete'
      sub.submission_data = [{ :points => 17, :text => "", :correct => "undefined", :question_id => -1 }]
      sub.with_versioning(true, &:save!)
      stats = q.statistics
      stats[:submission_score_average].should == 16
      stats[:submission_score_high].should == 17
      stats[:submission_score_low].should == 15
      stats[:submission_score_stdev].should == 1
      sub = q.generate_submission(@user3)
      sub.workflow_state = 'complete'
      sub.submission_data = [{ :points => 20, :text => "", :correct => "undefined", :question_id => -1 }]
      sub.with_versioning(true, &:save!)
      stats = q.statistics
      stats[:submission_score_average].should be_close(17 + 1.0/3, 0.0000000001)
      stats[:submission_score_high].should == 20
      stats[:submission_score_low].should == 15
      stats[:submission_score_stdev].should be_close(Math::sqrt(4 + 2.0/9), 0.0000000001)
    end
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
  
  
end
