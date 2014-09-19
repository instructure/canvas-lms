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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/canvas/draft_state_validations_spec.rb')

describe Quizzes::Quiz do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  before :once do
    course
  end

  describe ".mark_quiz_edited" do
    it "should mark a quiz as having unpublished changes" do
      quiz = nil
      Timecop.freeze(5.minutes.ago) do
        quiz = @course.quizzes.create! :title => "hello"
        quiz.published_at = Time.now
        quiz.publish!
        expect(quiz.unpublished_changes?).to be_falsey
      end

      Quizzes::Quiz.mark_quiz_edited(quiz.id)
      expect(quiz.reload.unpublished_changes?).to be_truthy
    end
  end

  describe "#mark_edited!" do
    it "should mark a quiz as having unpublished changes" do
      quiz = nil
      Timecop.freeze(5.minutes.ago) do
        quiz = @course.quizzes.create! :title => "hello"
        quiz.published_at = Time.now
        quiz.publish!
        expect(quiz.unpublished_changes?).to be_falsey
      end

      quiz.mark_edited!
      expect(quiz.reload.unpublished_changes?).to be_truthy
    end
  end

  describe "#publish!" do
    it "sets the workflow state to available and save!s the quiz" do
      quiz = @course.quizzes.build :title => "hello"
      quiz.expects(:generate_quiz_data).once
      quiz.publish!
      expect(quiz.workflow_state).to eq 'available'
    end

    it "regenerates quiz data when quiz published at date changes with draft state off" do
      quiz = @course.quizzes.build :title => "hello"
      quiz.workflow_state = 'available'
      quiz.save!

      quiz.expects(:generate_quiz_data).once
      quiz.publish!
      expect(quiz.workflow_state).to eq 'available'
    end
  end

  describe "#unpublish!" do
    it "sets the workflow state to unpublished and save!s the quiz" do
      quiz = @course.quizzes.build :title => "hello"
      quiz.expects(:save!).once
      quiz.publish!
      expect(quiz.workflow_state).to eq 'available'

      quiz.expects(:save!).once
      quiz.unpublish!
      expect(quiz.workflow_state).to eq 'unpublished'
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
      expect(quiz.published?).to be_falsey
    end
  end

  it_should_behave_like 'Canvas::DraftStateValidations'

  it "should infer the times if none given" do
    q = factory_with_protected_attributes(@course.quizzes,
                                          :title => "new quiz",
                                          :due_at => "Sep 3 2008 12:00am",
                                          :lock_at => "Sep 3 2008 12:00am",
                                          :unlock_at => "Sep 3 2008 12:00am",
                                          :quiz_type => 'assignment',
                                          :workflow_state => 'available')
    due_at = q.due_at
    expect(q.due_at).to eq Time.parse("Sep 3 2008 12:00am UTC")
    lock_at = q.lock_at
    unlock_at = q.unlock_at
    expect(q.lock_at).to eq Time.parse("Sep 3 2008 12:00am UTC")
    expect(q.assignment.due_at).to eq Time.parse("Sep 3 2008 12:00am UTC")
    q.infer_times
    q.save!
    expect(q.due_at).to eq due_at.end_of_day
    expect(q.assignment.due_at).to eq due_at.end_of_day
    expect(q.lock_at).to eq lock_at.end_of_day
    expect(q.assignment.lock_at).to eq lock_at.end_of_day
    # Unlock at should not be fudged so teacher's can say this assignment
    # is available at 12 am.
    expect(q.unlock_at).to eq unlock_at.midnight
    expect(q.assignment.unlock_at).to eq unlock_at.midnight
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
    expect(q.due_at).to be_an_instance_of ActiveSupport::TimeWithZone
    expect(q.due_at.time_zone).to eq Time.zone
    expect(q.due_at.hour).to eql 23
    expect(q.due_at.min).to eql 59
    expect(q.lock_at.time_zone).to eq Time.zone
    expect(q.lock_at.hour).to eql 23
    expect(q.lock_at.min).to eql 59
    # Unlock at should not be fudged so teacher's can say this assignment
    # is available at 12 am.
    expect(q.unlock_at.time_zone).to eq Time.zone
    expect(q.unlock_at.hour).to eql 0
    expect(q.unlock_at.min).to eql 0
  end

  it "should not set the due time to 11:59pm if passed a time of midnight" do
    params = { :quiz => { :title => "Test Quiz", :due_at => "Jan 1 2011 12:00am" } }
    q = @course.quizzes.create!(params[:quiz])
    expect(q.due_at.hour).to eql 0
    expect(q.due_at.min).to eql 0
  end

  it "should convert a date object to a time and set the time to 11:59pm" do
    Time.zone = 'Alaska'
    params = { :quiz => { :title => 'Test Quiz', :due_at => Time.zone.today } }
    quiz = @course.quizzes.create!(params[:quiz])
    expect(quiz.due_at).to be_an_instance_of ActiveSupport::TimeWithZone
    expect(quiz.due_at.zone).to eql Time.zone.now.dst? ? 'AKDT' : 'AKST'
    expect(quiz.due_at.hour).to eql 23
    expect(quiz.due_at.min).to eql 59
  end

  it "should set the due date time correctly" do
    time_string = "Dec 30, 2011 12:00 pm"
    expected = "2011-12-30 19:00:00 #{Time.now.utc.strftime("%Z")}"
    Time.zone = "Mountain Time (US & Canada)"
    quiz = @course.quizzes.create(:title => "sad quiz", :due_at => time_string, :lock_at => time_string, :unlock_at => time_string)
    expect(quiz.due_at.utc.strftime("%Y-%m-%d %H:%M:%S %Z")).to eq expected
    expect(quiz.lock_at.utc.strftime("%Y-%m-%d %H:%M:%S %Z")).to eq expected
    expect(quiz.unlock_at.utc.strftime("%Y-%m-%d %H:%M:%S %Z")).to eq expected
    Time.zone = nil
  end

  it "should initialize with default settings" do
    q = @course.quizzes.create!(:title => "new quiz")
    expect(q.shuffle_answers).to eql(false)
    expect(q.show_correct_answers).to eql(true)
    expect(q.allowed_attempts).to eql(1)
    expect(q.scoring_policy).to eql('keep_highest')
  end

  it "should update the assignment it is associated with" do
    a = @course.assignments.create!(:title => "some assignment", :points_possible => 5, :only_visible_to_overrides => false)
    expect(a.points_possible).to eql(5.0)
    expect(a.submission_types).not_to eql("online_quiz")
    q = @course.quizzes.build(:assignment_id => a.id, :title => "some quiz", :points_possible => 10, :only_visible_to_overrides => true)
    q.workflow_state = 'available'
    q.save
    expect(q).to be_available
    expect(q.assignment_id).to eql(a.id)
    expect(q.assignment).to eql(a)
    a.reload
    expect(a.quiz).to eql(q)
    expect(q.title).to eq "some quiz"
    expect(q.assignment.submission_types).to eql("online_quiz")
    expect(q.assignment.title).to eq "some quiz"

    g = @course.assignment_groups.create!(:name => "new group")
    q.assignment_group_id = g.id
    q.save
    q.reload
    a.reload
    expect(a.assignment_group).to eql(g)
    expect(q.assignment_group_id).to eql(g.id)

    g2 = @course.assignment_groups.create!(:name => "new group2")
    a.assignment_group = g2
    a.save
    a.reload
    q.reload
    expect(q.assignment_group_id).to eql(g2.id)
    expect(a.assignment_group).to eql(g2)
  end

  it "shouldn't create a new assignment on every edit" do
    a_count = Assignment.count
    a = @course.assignments.create!(:title => "some assignment")
    expect(a.submission_types).not_to eql("online_quiz")
    q = @course.quizzes.build(:title => "some quiz")
    q.workflow_state = 'available'
    q.assignment_id = a.id
    q.save
    q.quiz_type = 'assignment'
    q.save
    expect(q).to be_available
    expect(q.assignment_id).to eql(a.id)
    expect(q.assignment).to eql(a)
    a.reload
    expect(a.quiz).to eql(q)
    expect(q.title).to eq "some quiz"
    expect(a.title).to eq 'some quiz'
    expect(a.submission_types).to eql("online_quiz")
    expect(Assignment.count).to eql(a_count + 1)
  end

  it "should not send a message if notify_of_update is blank" do
    Notification.create!(:name => 'Assignment Changed')
    @course.offer
    a = @course.assignments.create!(:title => "some assignment", :points_possible => 5)
    expect(a.points_possible).to eql(5.0)
    expect(a.submission_types).not_to eql("online_quiz")
    a.update_attribute(:created_at, Time.now - (40 * 60))
    q = @course.quizzes.build(:assignment_id => a.id, :title => "some quiz", :points_possible => 10)
    q.workflow_state = 'available'
    q.assignment.expects(:save_without_broadcasting!).at_least_once
    q.save
    expect(q.assignment.messages_sent).to be_empty
  end

  it "should send a message if notify_of_update is set" do
    Notification.create!(:name => 'Assignment Changed')
    @course.offer
    a = @course.assignments.create!(:title => "some assignment", :points_possible => 5)
    expect(a.points_possible).to eql(5.0)
    expect(a.submission_types).not_to eql("online_quiz")
    a.update_attribute(:created_at, Time.now - (40 * 60))
    q = @course.quizzes.build(:assignment_id => a.id, :title => "some quiz", :points_possible => 10)
    q.workflow_state = 'available'
    q.notify_of_update = 1
    q.assignment.expects(:save_without_broadcasting!).never
    q.save
    expect(q.assignment.messages_sent).to include('Assignment Changed')
  end

  it "should delete the assignment if the quiz is no longer graded" do
    a = @course.assignments.create!(:title => "some assignment", :points_possible => 5)
    expect(a.points_possible).to eql(5.0)
    expect(a.submission_types).not_to eql("online_quiz")
    q = @course.quizzes.build(:assignment_id => a.id, :title => "some quiz", :points_possible => 10)
    q.workflow_state = 'available'
    q.save
    expect(q).to be_available
    expect(q.assignment_id).to eql(a.id)
    expect(q.assignment).to eql(a)
    a.reload
    expect(a.quiz).to eql(q)
    expect(q.assignment.submission_types).to eql("online_quiz")
    q.quiz_type = "practice_quiz"
    q.save
    expect(q.assignment_id).to eql(nil)
  end

  it "should not create an assignment for ungraded quizzes" do
    g = @course.assignment_groups.create!(:name => "new group")
    q = @course.quizzes.build(:title => "some quiz", :quiz_type => "survey", :assignment_group_id => g.id)
    q.workflow_state = 'available'
    q.save!
    expect(q).to be_available
    expect(q.assignment_id).to be_nil
  end

  it "should always have an assignment" do
    g = @course.assignment_groups.create!(:name => "new group")
    q = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment", :assignment_group_id => g.id)
    q.save!
    expect(q).not_to be_available
    expect(q.assignment_id).not_to be_nil
    expect(q.assignment_group_id).to eql(g.id)
  end

  it "should update assignment published?" do
    g = @course.assignment_groups.create!(:name => "new group")
    q = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment", :assignment_group_id => g.id)
    q.save!
    expect(q).not_to be_available
    expect(q.assignment_id).not_to be_nil
    expect(q.assignment.published?).to be false
    expect(q.assignment_group_id).to eql(g.id)
    q.publish!
    expect(q.assignment.published?).to be true
  end

  it "should send a message when quiz is published" do
    Notification.create!(:name => 'Assignment Created')
    @course.offer

    q = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment")
    q.save!
    expect(q).not_to be_available

    expect(q.assignment_id).not_to be_nil
    expect(q.assignment.published?).to be false
    q.assignment.expects(:save_without_broadcasting!).never

    q.publish!

    expect(q.assignment.published?).to be true
    expect(q.assignment.messages_sent).to include('Assignment Created')
  end

  it "should create the assignment if created in published state" do
    g = @course.assignment_groups.create!(:name => "new group")
    q = @course.quizzes.build(:title => "some quiz", :quiz_type => "assignment", :assignment_group_id => g.id)
    q.workflow_state = 'available'
    q.save!
    expect(q).to be_available
    expect(q.assignment_id).not_to be_nil
    expect(q.assignment_group_id).to eql(g.id)
    expect(q.assignment.assignment_group_id).to eql(g.id)
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
    expect(q.question_count).to eql(0)
    expect(q.unpublished_question_count).to eql(3)
  end

  it "should return an available question count for unpublished questions" do
    q = @course.quizzes.create!(:title => "new quiz")
    q.quiz_questions.create!
    q.quiz_questions.create!
    q.save

    expect(q.reload.available_question_count).to eql(2)
  end

  it "should return an available question count for published questions" do
    q = @course.quizzes.create!(:title => "new quiz")
    q.quiz_questions.create!
    q.quiz_questions.create!
    q.publish!

    expect(q.reload.available_question_count).to eql(2)
  end

  it "should return processed root entries for each question/group" do
    q = @course.quizzes.create!(:title => "new quiz")
    g = q.quiz_groups.create!(:name => "group 1", :pick_count => 1, :question_points => 2)

    qq1 = q.quiz_questions.create!(:question_data => { :name => "test 1" }, :quiz_group => g)
    # make sure we handle sorting with nil positions
    Quizzes::QuizQuestion.where(:id => qq1).update_all(:position => nil)

    q.quiz_questions.create!(:question_data => { :name => "test 2" }, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 3" })
    q.quiz_questions.create!(:question_data => { :name => "test 4" })
    q.save
    expect(q.active_quiz_questions.size).to eql(4)
    expect(q.quiz_groups.length).to eql(1)
    expect(g.quiz_questions(true).active.size).to eql(2)

    entries = q.root_entries(true)
    expect(entries.length).to eql(3)
    expect(entries[0][:questions]).not_to be_nil
    expect(entries[1][:answers]).not_to be_nil
    expect(entries[2][:answers]).not_to be_nil
  end

  it "should generate valid quiz data" do
    q = @course.quizzes.create!(:title => "new quiz")
    g = q.quiz_groups.create!(:name => "group 1", :pick_count => 1, :question_points => 2)
    q.quiz_questions.create!(:question_data => { :name => "test 1" }, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 2" }, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 3" })
    q.quiz_questions.create!(:question_data => { :name => "test 4" })
    expect(q.quiz_data).to be_nil
    q.generate_quiz_data
    q.save
    expect(q.quiz_data).not_to be_nil
    data = q.quiz_data rescue nil
    expect(data).not_to be_nil
  end

  it "should return quiz data once the quiz is generated" do
    q = @course.quizzes.create!(:title => "new quiz")
    g = q.quiz_groups.create!(:name => "group 1", :pick_count => 1, :question_points => 2)
    q.quiz_questions.create!(:question_data => { :name => "test 1", }, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 2", }, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 3", })
    q.quiz_questions.create!(:question_data => { :name => "test 4", })
    expect(q.quiz_data).to be_nil
    q.generate_quiz_data
    q.save

    data = q.stored_questions
    expect(data.length).to eql(3)
    expect(data[0][:questions]).not_to be_nil
    expect(data[1][:answers]).not_to be_nil
    expect(data[2][:answers]).not_to be_nil
  end

  it "should shuffle answers for the questions" do
    q = @course.quizzes.create!(:title => "new quiz", :shuffle_answers => true)
    q.quiz_questions.create!(:question_data => {:name => 'test 3', 'question_type' => 'multiple_choice_question',
      'answers' => [{'answer_text' => '1'}, {'answer_text' => '2'}, {'answer_text' => '3'}, {'answer_text' => '4'},
                    {'answer_text' => '5'}, {'answer_text' => '6'}, {'answer_text' => '7'}, {'answer_text' => '8'},
                    {'answer_text' => '9'}, {'answer_text' => '10'}]})
    expect(q.quiz_data).to be_nil
    q.generate_quiz_data
    q.save

    data = q.stored_questions
    expect(data.length).to eql(1)
    expect(data[0][:answers]).not_to be_empty
    same = true
    found = []
    data[0][:answers].each{|a| found << a[:text] }
    expect(found.uniq.length).to eql(10)
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
    expect(same).to eql(false)
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
    expect(q.quiz_data).to be_nil
    q.reload
    q.generate_quiz_data
    q.save

    data = q.stored_questions
    expect(data.length).to eql(1)
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
    expect(same).to eql(false)
  end

  it "should consider the number of questions in a group when determining the question count" do
    q = @course.quizzes.create!(:title => "new quiz")
    g = q.quiz_groups.create!(:name => "group 1", :pick_count => 10, :question_points => 2)
    q.quiz_questions.create!(:question_data => { :name => "test 1", }, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 2", }, :quiz_group => g)
    q.quiz_questions.create!(:question_data => { :name => "test 3", })
    q.quiz_questions.create!(:question_data => { :name => "test 4", })
    expect(q.quiz_data).to be_nil
    q.generate_quiz_data
    q.save

    data = q.stored_questions
    expect(data.length).to eql(3)
    expect(data[0][:questions]).not_to be_nil
    expect(data[1][:answers]).not_to be_nil
    expect(data[2][:answers]).not_to be_nil
  end

  describe "#generate_submission" do
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
      expect(q.quiz_data).to be_nil
      q.generate_quiz_data
      q.save

      s = q.generate_submission(u)
      expect(s.state).to eql(:untaken)
      expect(s.attempt).to eql(1)
      expect(s.quiz_data).not_to be_nil
      expect(s.quiz_version).to eql(q.version_number)
      expect(s.finished_at).to be_nil
      expect(s.submission_data).to eql({})

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
        expect(s.end_at).to eq lock_at
      end
    end

    it "should not set end_at to lock_at if a submission is manually unlocked" do
      lock_at = 1.day.ago
      u = User.create!(:name => "Fred Colon")
      q = @course.quizzes.create!(:title => "locked yesterday", :lock_at => lock_at)
      sub = Quizzes::SubmissionManager.new(q).find_or_create_submission(u, nil, 'settings_only')
      sub.manually_unlocked = true
      sub.save!
      sub2 = q.generate_submission(u)
      expect(sub2.end_at).to be_nil
    end
    it 'should not set end_at to due_at' do
      due_at = 1.day.from_now
      u = User.create!(:name => "Fred Colon")
      q = @course.quizzes.create!(:title => "locked tomorrow", :due_at => due_at)
      sub2 = q.generate_submission(u)
      expect(sub2.end_at).not_to eq due_at
    end
    it "should set end_at for course end dates" do
      deadline = 1.day.from_now
      @course.restrict_enrollments_to_course_dates = true
      @course.conclude_at = deadline
      @course.save!
      u = User.create!(:name => "Fred Colon")
      q = @course.quizzes.create!(:title => "locked tomorrow")
      sub2 = q.generate_submission(u)
      expect(sub2.end_at).to eq deadline
    end
    it "should set end_at for enrollment end dates" do
      # when course.end_at doesn't exist
      deadline = 1.day.from_now
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      @course.enrollment_term.end_at = deadline
      @course.enrollment_term.save!
      u = User.create!(:name => "Fred Colon")
      q = @course.quizzes.create!(:title => "locked tomorrow")
      sub2 = q.generate_submission(u)
      expect(sub2.end_at).to eq deadline
    end

    it "should shuffle submission questions" do
      u1 = User.create!(:name => "user 1")
      u2 = User.create!(:name => "user 2")
      u3 = User.create!(:name => "user 3")

      quiz = @course.quizzes.create!(:title => "some quiz")

      # create a bunch of questions to make it more likely that they'll shuffle randomly
      group = quiz.quiz_groups.create!(:name => "group 1", :pick_count => 4, :question_points => 2)
      quiz.quiz_questions.create!(:question_data => { :question_text => "test 1" }, :quiz_group => group)
      quiz.quiz_questions.create!(:question_data => { :question_text => "test 2" }, :quiz_group => group)
      quiz.quiz_questions.create!(:question_data => { :question_text => "test 3" }, :quiz_group => group)
      quiz.quiz_questions.create!(:question_data => { :question_text => "test 4" }, :quiz_group => group)
      quiz.quiz_questions.create!(:question_data => { :question_text => "test 5" }, :quiz_group => group)
      quiz.quiz_questions.create!(:question_data => { :question_text => "test 6" }, :quiz_group => group)
      quiz.quiz_questions.create!(:question_data => { :question_text => "test 7" }, :quiz_group => group)
      quiz.quiz_questions.create!(:question_data => { :question_text => "test 8" }, :quiz_group => group)
      quiz.quiz_questions.create!(:question_data => { :question_text => "test 9" }, :quiz_group => group)
      quiz.quiz_questions.create!(:question_data => { :question_text => "test 10" }, :quiz_group => group)
      expect(quiz.quiz_data).to be_nil
      quiz.generate_quiz_data
      quiz.save

      original = quiz.quiz_questions.map {|q| q.question_data["question_text"] }

      selected1 = quiz.generate_submission(u1).questions.map {|q| q["question_text"] }
      selected2 = quiz.generate_submission(u2).questions.map {|q| q["question_text"] }

      # make sure at least one is shuffled
      is_shuffled1 = (original != selected1)
      is_shuffled2 = (original != selected2)

      # it's possible but unlikely that shuffled version is same as original
      expect(is_shuffled1 || is_shuffled2).to be_truthy
    end
  end

  it "should return a default title if the quiz is untitled" do
    q = @course.quizzes.create!
    expect(q.quiz_title).to eql("Unnamed Quiz")
  end

  it "should return the assignment title if the quiz is linked to an assignment" do
    a = @course.assignments.create!(:title => "some assignment")
    q = @course.quizzes.create!(:assignment_id => a.id)
    a.reload
    expect(q.quiz_title).to eql(a.title)
  end

  it "should delete the associated assignment if it is deleted" do
    a = @course.assignments.create!(:title => "some assignment")
    q = @course.quizzes.create!(:assignment_id => a.id, :quiz_type => "assignment")
    expect(q.assignment_id).to eql(a.id)
    q.reload
    q.assignment_id = nil
    q.quiz_type = "practice_quiz"
    q.save!
    expect(q.assignment_id).to eql(nil)
    a.reload
    expect(a).to be_deleted
  end

  it "should reattach existing graded quiz submissions to the new assignment after a graded -> ungraded -> graded transition" do
    # create a quiz
    q = @course.quizzes.new
    q.quiz_type = "assignment"
    q.workflow_state = "available"
    q.save! && q.reload
    expect(q.assignment).not_to be_nil
    expect(q.quiz_submissions.size).to eq 0

    # create a graded submission
    Quizzes::SubmissionGrader.new(q.generate_submission(User.create!(:name => "some_user"))).grade_submission
    q.reload

    expect(q.quiz_submissions.size).to eq 1
    expect(q.quiz_submissions.first.submission).not_to be_nil
    expect(q.quiz_submissions.first.submission.assignment).to eq q.assignment

    # switch to ungraded
    q.quiz_type = "practice_quiz"
    q.save! && q.reload
    expect(q.assignment).to be_nil
    expect(q.quiz_submissions.size).to eq 1

    # switch back to graded
    q.quiz_type = "assignment"
    q.save! && q.reload
    expect(q.assignment).not_to be_nil
    expect(q.quiz_submissions.size).to eq 1
    expect(q.quiz_submissions.first.submission).not_to be_nil
    expect(q.quiz_submissions.first.submission.assignment).to eq q.assignment
  end

  describe "Quiz with QuestionGroup pointing to QuestionBank" do
    before(:once) do
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
      expect(submission.quiz_data.length).to eq 3
      texts = submission.quiz_data.map{|q|q[:question_text]}
      expect(texts.member?('gq1')).to be_truthy
      expect(texts.member?('gq2')).to be_truthy
      expect(texts.member?('qq1')).to be_truthy
    end

    it "should get the correct points possible" do
      expect(@quiz.current_points_possible).to eq 15
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
      expect(submission.quiz_data.length).to eq 3
      texts = submission.quiz_data.map{|q|q[:question_text]}
      expect(texts.member?('gq1')).to be_truthy
      expect(texts.member?('gq2')).to be_truthy
      expect(texts.member?('qq1')).to be_truthy
    end

  end

  it "should ignore lockdown-browser setting if that plugin is not enabled" do
    q = @course.quizzes.build(:title => "some quiz")
    q1 = @course.quizzes.build(:title => "some quiz", :require_lockdown_browser => true, :require_lockdown_browser_for_results => false, :require_lockdown_browser_monitor => false)
    q2 = @course.quizzes.build(:title => "some quiz", :require_lockdown_browser => true, :require_lockdown_browser_for_results => true, :require_lockdown_browser_monitor => true)

    # first, disable any lockdown browsers that might be configured already
    Canvas::Plugin.all_for_tag(:lockdown_browser).each { |p| p.settings[:enabled] = false }

    # nothing should be restricted
    expect(Quizzes::Quiz.lockdown_browser_plugin_enabled?).to be_falsey
    [q, q1, q2].product([:require_lockdown_browser, :require_lockdown_browser?, :require_lockdown_browser_for_results, :require_lockdown_browser_for_results?, :require_lockdown_browser_monitor, :require_lockdown_browser_monitor?]).
        each { |qs| expect(qs[0].send(qs[1])).to be_falsey }

    # register a plugin
    Canvas::Plugin.register(:example_spec_lockdown_browser, :lockdown_browser, {
        :settings => {:enabled => false}})

    # nothing should change yet
    expect(Quizzes::Quiz.lockdown_browser_plugin_enabled?).to be_falsey
    [q, q1, q2].product([:require_lockdown_browser, :require_lockdown_browser?, :require_lockdown_browser_for_results, :require_lockdown_browser_for_results?, :require_lockdown_browser_monitor, :require_lockdown_browser_monitor?]).
        each { |qs| expect(qs[0].send(qs[1])).to be_falsey }

    # now actually enable the plugin
    setting = PluginSetting.create!(name: 'example_spec_lockdown_browser')
    setting.settings = {:enabled => true}
    setting.save!

    # now the restrictions should take effect
    expect(Quizzes::Quiz.lockdown_browser_plugin_enabled?).to be_truthy
    [:require_lockdown_browser, :require_lockdown_browser?, :require_lockdown_browser_for_results, :require_lockdown_browser_for_results?, :require_lockdown_browser_monitor, :require_lockdown_browser_monitor?].
        each { |s| expect(q.send(s)).to be_falsey }
    [:require_lockdown_browser, :require_lockdown_browser?].
        each { |s| expect(q1.send(s)).to be_truthy }
    [:require_lockdown_browser_for_results, :require_lockdown_browser_for_results?, :require_lockdown_browser_monitor, :require_lockdown_browser_monitor?].
        each { |s| expect(q1.send(s)).to be_falsey }
    [:require_lockdown_browser, :require_lockdown_browser?, :require_lockdown_browser_for_results, :require_lockdown_browser_for_results?, :require_lockdown_browser_monitor, :require_lockdown_browser_monitor?].
        each { |s| expect(q2.send(s)).to be_truthy }
  end

  it 'should not report LDB to be required for viewing results if LDB is not required to take the quiz' do
    Quizzes::Quiz.expects(:lockdown_browser_plugin_enabled?).twice.returns(true)

    q = @course.quizzes.build
    q.require_lockdown_browser_for_results = true
    expect(q.require_lockdown_browser_for_results).to be_falsey
    q.require_lockdown_browser = true
    q.require_lockdown_browser_for_results = true
    expect(q.require_lockdown_browser_for_results).to be_truthy
  end

  describe "non_shuffled_questions" do
    subject { Quizzes::Quiz.non_shuffled_questions }

    it { is_expected.to include "true_false_question" }
    it { is_expected.to include "matching_question" }
    it { is_expected.to include "fill_in_multiple_blanks_question" }
    it { is_expected.not_to include "multiple_choice_question" }
  end

  describe "prepare_answers" do
    let(:quiz) { Quizzes::Quiz.new }
    let(:question) { { :answers => answers } }
    let(:answers) { ['a', 'b', 'c'] }

    context "on a shuffle answers question" do
      before { quiz.stubs(:shuffle_answers).returns(true) }

      context "on a non-shuffleable question type" do
        before { Quizzes::Quiz.stubs(:shuffleable_question_type?).returns(false) }

        it "doesn't shuffle" do
          expect(quiz.prepare_answers(question)).to eq answers
        end
      end

      context "on a shuffleable question type" do
        before { Quizzes::Quiz.stubs(:shuffleable_question_type?).returns(true) }

        it "returns the same answers, not necessarily in the same order" do
          expect(quiz.prepare_answers(question).sort).to eq answers.sort
        end

        it "shuffles" do
          answers.expects(:sort_by)
          quiz.prepare_answers(question)
        end
      end
    end

    context "on a non-shuffle answers question" do
      it "doesn't shuffle" do
        expect(quiz.prepare_answers(question)).to eq answers
      end
    end
  end

  describe "prepare_matches" do
    let(:quiz) { Quizzes::Quiz.new }
    let(:question) { { :matches => matches } }
    let(:matches) { ['a', 'b', 'c'] }

    it "shuffles matches for a matching question" do
      quiz.stubs(:shuffle_answers).returns(true)
      matches.expects(:sort_by)
      quiz.prepare_matches(question)
    end

    it "still shuffles even if shuffle_answers option is off" do
      quiz.stubs(:shuffle_answers).returns(false)
      matches.expects(:sort_by)
      quiz.prepare_matches(question)
    end
  end

  describe "shuffleable_question_type?" do
    specify { expect(Quizzes::Quiz.shuffleable_question_type?("true_false_question")).to be_falsey }
    specify { expect(Quizzes::Quiz.shuffleable_question_type?("multiple_choice_question")).to be_truthy }
  end

  describe '#has_student_submissions?' do
    before :once do
      course = Course.create!
      @quiz = Quizzes::Quiz.create!(:context => course)
      @user = User.create!
      @enrollment = @user.student_enrollments.create!(:course => course)
      @enrollment.update_attribute(:workflow_state, 'active')
      @submission = Quizzes::QuizSubmission.create!(:quiz => @quiz, :user => @user)
      @submission.update_attribute(:workflow_state, 'untaken')
    end

    it 'returns true if the submission is not settings_only and its user is part of this course' do
      expect(@submission.settings_only?).to be_falsey
      expect(@quiz.context.students.include?(@user)).to be_truthy
      expect(@quiz.has_student_submissions?).to be_truthy
    end

    it 'is false if the submission is settings_only' do
      @submission.update_attribute(:workflow_state, 'settings_only')
      expect(@quiz.has_student_submissions?).to be_falsey
    end

    it 'is false if there are no submissions' do
      @quiz.quiz_submissions.scoped.delete_all
      expect(@quiz.has_student_submissions?).to be_falsey
    end

    it 'is true if only one submission of many matches the conditions' do
      Quizzes::QuizSubmission.create!(:quiz => @quiz, :user => User.create!)
      expect(@quiz.has_student_submissions?).to be_truthy
    end
  end

  describe "#group_category_id" do

    it "returns the assignment's group category id if it has an assignment" do
      quiz = Quizzes::Quiz.new(:title => "Assignment Group Category Quizzes::Quiz")
      quiz.expects(:assignment).returns stub(:group_category_id => 1)
      expect(quiz.group_category_id).to eq 1
    end

    it "returns nil if it doesn't have an assignment" do
      quiz = Quizzes::Quiz.new(:title => "Quizzes::Quiz w/o assignment")
      expect(quiz.group_category_id).to be_nil
    end

  end

  describe "linking overrides with assignments" do
    let_once(:course) { course_model }
    let_once(:quiz) { quiz_model(:course => course, :due_at => 5.days.from_now).reload }
    let_once(:override) do
      override = assignment_override_model(:quiz => quiz)
      override.override_due_at(7.days.from_now)
      override.save!
      override
    end
    let_once(:override_student) do
      student_in_course(:course => course)
      override_student = override.assignment_override_students.build
      override_student.user = @student
      override_student.save!
      override_student
    end

    context "before the quiz has an assignment" do
      context "override" do
        it "has a quiz" do
          expect(override.quiz).to eq quiz
        end

        it "has a nil assignment" do
          expect(override.assignment).to be_nil
        end
      end

      context "override student" do
        it "has a quiz" do
          expect(override_student.quiz).to eq quiz
        end

        it "has a nil assignment" do
          expect(override_student.assignment).to be_nil
        end
      end
    end

    context "once the quiz is published" do
      before :once do
        # publish the quiz
        quiz.workflow_state = 'available'
        quiz.save!
        override.reload
        override_student.reload
        quiz.assignment.reload
      end

      context "override" do
        it "has a quiz" do
          expect(override.quiz).to eq quiz
        end

        it "has the quiz's assignment" do
          expect(override.assignment).to eq quiz.assignment
        end

        it "has the quiz's assignment's version number" do
          expect(override.assignment_version).to eq quiz.assignment.version_number
        end

        it "has the quiz's version number" do
          expect(override.quiz_version).to eq quiz.version_number
        end

      end

      context "override student" do
        it "has a quiz" do
          expect(override_student.quiz).to eq quiz
        end

        it "has the quiz's assignment" do
          expect(override_student.assignment).to eq quiz.assignment
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
    context "changinging quiz points" do
      it "should not allow quiz points higher than allowable by postgres" do
        q = Quizzes::Quiz.new(:points_possible => 2000000001)
        expect(q.valid?).to eq false
        expect(Array(q.errors[:points_possible])).to eq ["must be less than or equal to 2000000000"]
      end
    end

    context "quiz_type" do
      it "should not save an invalid quiz_type" do
        quiz = @course.quizzes.create! :title => "test quiz"
        quiz.quiz_type = "totally_invalid_quiz_type"
        expect(quiz.save).to be_falsey
        expect(quiz.errors["invalid_quiz_type"]).to be_present
      end

      it "should not validate quiz_type if not changed" do
        quiz = @course.quizzes.build :title => "test quiz", :quiz_type => 'invalid'
        quiz.workflow_state = 'created'
        expect(quiz.save(:validate => false)).to be_truthy  # save without validation
        quiz.reload
        expect(quiz.save).to be_truthy
        expect(quiz.errors).to be_blank
        expect(quiz.quiz_type).to eq 'invalid'
      end
    end

    context "ip_filter" do
      it "should not save an invalid ip_filter" do
        quiz = @course.quizzes.create! :title => "test quiz"
        quiz.ip_filter = "999.999.1942.489"
        expect(quiz.save).to be_falsey
        expect(quiz.errors["invalid_ip_filter"]).to be_present
      end

      it "should not validate ip_filter if not changed" do
        quiz = @course.quizzes.build :title => "test quiz", :ip_filter => '123.fourfivesix'
        quiz.workflow_state = 'created'
        expect(quiz.save(:validate => false)).to be_truthy  # save without validation
        quiz.reload
        expect(quiz.save).to be_truthy
        expect(quiz.errors).to be_blank
        expect(quiz.ip_filter).to eq '123.fourfivesix'
      end
    end

    context "workflow_state" do
      it "won't validate unpublishing a quiz if there are already submissions" do
        quiz = @course.quizzes.build title: 'test quiz'
        quiz.publish!
        quiz.stubs(:has_student_submissions?).returns true
        quiz.workflow_state = 'unpublished'
        quiz.save
        expect(quiz).not_to be_valid
        expect(quiz.reload).to be_published
      end

      it "will allow unpublishing if no student submissions" do
        quiz = @course.quizzes.build title: 'test quiz'
        quiz.publish!
        quiz.stubs(:has_student_submissions?).returns false
        quiz.workflow_state = 'unpublished'
        quiz.save
        expect(quiz).to be_valid
        expect(quiz).to be_unpublished
      end
    end

    context "hide_results" do
      it "should not save an invalid hide_results" do
        quiz = @course.quizzes.create! :title => "test quiz"
        quiz.hide_results = "totally_invalid_value"
        expect(quiz.save).to be_falsey
        expect(quiz.errors["invalid_hide_results"]).to be_present
      end

      it "should not validate hide_results if not changed" do
        quiz = @course.quizzes.build :title => "test quiz", :hide_results => 'invalid'
        quiz.workflow_state = 'created'
        expect(quiz.save(:validate => false)).to be_truthy  # save without validation
        quiz.reload
        expect(quiz.save).to be_truthy
        expect(quiz.errors).to be_blank
        expect(quiz.hide_results).to eq 'invalid'
      end
    end
  end

  describe "#has_file_upload_question?" do

    let(:quiz) { @course.quizzes.build title: 'File Upload Quiz' }

    it "returns false unless there is quiz data for a quiz" do
      quiz.stubs(:quiz_data).returns nil
      expect(quiz.has_file_upload_question?).to be_falsey
    end

    it "returns true when there is a file upload question" do
      quiz.stubs(:quiz_data).returns [
        {question_type: 'file_upload_question'}
      ]
      expect(quiz.has_file_upload_question?).to be_truthy
    end

    it "returns false when there isn't a file upload question" do
      quiz.stubs(:quiz_data).returns [
        {question_type: 'multiple_choice_question'}
      ]
      expect(quiz.has_file_upload_question?).to be_falsey
    end
  end

  describe "#unpublished?" do
    before do
      @quiz = @course.quizzes.build title: 'Test Quiz'
    end

    it "returns true when workflow_state is unpublished" do
      @quiz.workflow_state = 'unpublished'
      expect(@quiz).to be_unpublished
    end

    it "returns false when quiz has 'available' state" do
      @quiz.workflow_state = 'available'
      expect(@quiz).not_to be_unpublished
    end
  end

  describe "#active?" do
    before do
      @quiz = @course.quizzes.build title: 'Test Quiz'
    end

    it "returns true if workflow_state is available" do
      @quiz.workflow_state = 'available'
      expect(@quiz).to be_active
    end

    it "returns false when workflow_state isn't available" do
      @quiz.workflow_state = 'deleted'
      expect(@quiz).not_to be_active
      @quiz.workflow_state = 'unpublished'
      expect(@quiz).not_to be_active
    end

  end

  describe "#published?" do
    before do
      @quiz = @course.quizzes.build title: 'Test Quiz'
    end

    it "is just an alias for active?" do
      @quiz.workflow_state = 'available'
      expect(@quiz).to be_published
      @quiz.workflow_state = 'unpublished'
      expect(@quiz).not_to be_published
      @quiz.workflow_state = 'deleted'
      expect(@quiz).not_to be_published
    end
  end

  describe '#needs_republish?' do
    subject { @course.quizzes.create!(title: 'Test Quiz') }

    it 'should be true if publish! was manually called' do
      expect(subject.needs_republish?).to be_falsey

      # intercepting the call to save! and running our expectations there
      # because by the time it's saved, #needs_republish? will be reset
      subject.expects(:save!).with { |*args|
        expect(subject.needs_republish?).to be_truthy
        true
      }

      subject.publish!
    end

    it 'should be true if the workflow_state has changed' do
      subject.workflow_state = 'deleted'
      subject.save!
      subject.reload
      subject.workflow_state = 'available'
      expect(subject.needs_republish?).to be_truthy
    end
  end

  describe "#current_regrade" do

    before(:once) { @quiz = @course.quizzes.create! title: 'Test Quiz' }

    it "returns the regrade for the quiz and quiz version" do
      course_with_teacher_logged_in(active_all: true, course: @course)
      question = @quiz.quiz_questions.create(question_data: { question_text: "test 1" })

      regrade = Quizzes::QuizRegrade.create!(quiz: @quiz, quiz_version: @quiz.version_number, user: @teacher)
      regrade.quiz_question_regrades.create(quiz_question_id: question.id, regrade_option: "current_correct_only")
      expect(@quiz.current_regrade).to eq regrade
    end

    it "should not return disabled regrade options" do
      course_with_teacher_logged_in(active_all: true, course: @course)
      question = @quiz.quiz_questions.create(question_data: { question_text: "test 1" })

      regrade = Quizzes::QuizRegrade.create!(quiz: @quiz, quiz_version: @quiz.version_number, user: @teacher)
      regrade.quiz_question_regrades.create(quiz_question_id: question.id, regrade_option: "disabled")
      expect(@quiz.current_regrade).to be_nil
    end
  end

  describe "#current_regrade_question_ids" do

    before { @quiz = @course.quizzes.create! title: 'Test Quiz' }

    it "returns the correct question ids" do
      course_with_teacher_logged_in(active_all: true, course: @course)
      q = @quiz.quiz_questions.create!
      regrade = Quizzes::QuizRegrade.create!(quiz: @quiz, quiz_version: @quiz.version_number, user: @teacher)
      rq = regrade.quiz_question_regrades.create! quiz_question_id: q.id, regrade_option: 'current_correct_only'
      expect(@quiz.current_quiz_question_regrades).to eq [rq]
    end
  end

  describe "#regrade_if_published" do

    it "queues a job to regrade if there are current question regrades" do
      course_with_teacher_logged_in(course: @course, active_all: true)
      quiz = @course.quizzes.create!
      q = quiz.quiz_questions.create!
      regrade = Quizzes::QuizRegrade.create!(quiz: quiz, quiz_version: quiz.version_number, user: @teacher)
      regrade.quiz_question_regrades.create!(
        quiz_question_id: q.id,
        regrade_option: 'current_correct_only')
      Quizzes::QuizRegrader::Regrader.expects(:send_later).once.
        with(:regrade!, quiz: quiz, version_number: quiz.version_number)
      quiz.save!
    end

    it "does not queue a job to regrade when no current question regrades" do
      course_with_teacher_logged_in(course: @course, active_all: true)
      Quizzes::QuizRegrader::Regrader.expects(:send_later).never
      quiz = @course.quizzes.create!
      quiz.save!
    end
  end

  describe "#questions_regraded_since" do
    before :once do
      course_with_teacher_logged_in(active_all: true)
      @quiz = @course.quizzes.create!
    end

    it "should count how many questions have been regraded since the given date" do
      first_regrade_time = 1.hour.ago
      Timecop.freeze(first_regrade_time) do
        # regrade once
        regrade1 = Quizzes::QuizRegrade.create!(quiz: @quiz, quiz_version: @quiz.version_number, user: @teacher)
        regrade1.quiz_question_regrades.create(:quiz_question_id => @quiz.quiz_questions.create.id, :regrade_option => 'current_correct_only')
      end

      # regrade twice
      regrade2 = Quizzes::QuizRegrade.create!(quiz: @quiz, quiz_version: @quiz.version_number - 1, user: @teacher)
      regrade2.quiz_question_regrades.create(:quiz_question_id => @quiz.quiz_questions.create.id, :regrade_option => 'current_correct_only')
      regrade2.quiz_question_regrades.create(:quiz_question_id => @quiz.quiz_questions.create.id, :regrade_option => 'current_correct_only')

      # find all
      count = @quiz.questions_regraded_since(first_regrade_time - 10.minutes)
      expect(count).to eq 3

      # only find those after the first regrade
      count = @quiz.questions_regraded_since(first_regrade_time)
      expect(count).to eq 2
    end

    it "should not count disabled questions regraded" do
      first_regrade_time = 1.hour.ago
      Timecop.freeze(first_regrade_time) do
        # regrade once
        regrade1 = Quizzes::QuizRegrade.create!(quiz: @quiz, quiz_version: @quiz.version_number, user: @teacher)
        regrade1.quiz_question_regrades.create(:quiz_question_id => @quiz.quiz_questions.create.id, :regrade_option => 'current_correct_only')
      end

      # regrade twice
      regrade2 = Quizzes::QuizRegrade.create!(quiz: @quiz, quiz_version: @quiz.version_number - 1, user: @teacher)
      regrade2.quiz_question_regrades.create(:quiz_question_id => @quiz.quiz_questions.create.id, :regrade_option => 'disabled')
      regrade2.quiz_question_regrades.create(:quiz_question_id => @quiz.quiz_questions.create.id, :regrade_option => 'current_correct_only')

      # find all
      count = @quiz.questions_regraded_since(first_regrade_time - 10.minutes)
      expect(count).to eq 2

      # only find those after the first regrade
      count = @quiz.questions_regraded_since(first_regrade_time)
      expect(count).to eq 1
    end
  end

  describe "#destroy" do
    it "should logical delete published quiz" do
      quiz = @course.quizzes.create(title: 'test quiz')
      quiz.stubs(:has_student_submissions? => true)
      quiz.publish!
      quiz.assignment.stubs(:has_student_submissions? => true)

      quiz.destroy
      expect(quiz.deleted?).to be_truthy
    end

    it "should logical delete the published quiz's associated assignment" do
      quiz = @course.quizzes.create(title: 'test quiz')
      quiz.stubs(:has_student_submissions?).returns true
      quiz.publish!
      assignment = quiz.assignment
      assignment.stubs(:has_student_submissions?).returns true

      quiz.destroy
      expect(assignment.deleted?).to be_truthy
    end
    it 'should raise an error on validation error' do
      quiz = Quizzes::Quiz.new
      expect {quiz.destroy}.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  it "updates the assignment's workflow state" do
    @quiz = @course.quizzes.create!(title: 'Test Quiz')
    @quiz.publish!
    @quiz.unpublish!
    expect(@quiz.assignment).not_to be_published
    @quiz.publish!
    expect(@quiz.assignment).to be_published
  end

  describe "#restrict_answers_for_concluded_course?" do
    let(:account){Account.new}
    let(:enrollment_term){EnrollmentTerm.new}
    let(:course){Course.new(conclude_at: conclude_at, enrollment_term: enrollment_term, restrict_enrollments_to_course_dates: true)}
    let(:quiz){Quizzes::Quiz.new(context: course)}

    before {account.settings[:restrict_quiz_questions] = restrict_quiz_settings}
    before {enrollment_term.stubs(root_account: account)}
    before {course.stubs(root_account: account)}

    context 'When account setting is true' do
      let(:restrict_quiz_settings){true}

      context 'and the course has concluded' do
        let(:conclude_at){10.minutes.ago}

        it "should be true" do
          expect(quiz.restrict_answers_for_concluded_course?).to be(true)
        end
      end

      context 'and the course has not concluded' do
        let(:conclude_at){10.minutes.from_now}

        it "should be false" do
          expect(quiz.restrict_answers_for_concluded_course?).to be_falsey
        end
      end

      context 'and the course does not have a conclude_at date but has a concluded enrollment_term' do
        let(:enrollment_term){EnrollmentTerm.new(end_at: 10.minutes.ago)}
        let(:conclude_at){nil}

        it "should be true" do
          expect(quiz.restrict_answers_for_concluded_course?).to be(true)
        end
      end
    end

    context 'When account setting is false and the course has concluded' do
      let(:restrict_quiz_settings){false}
      let(:conclude_at){10.minutes.ago}

      it "should be false" do
        expect(quiz.restrict_answers_for_concluded_course?).to be_falsey
      end
    end
  end

  context "show_correct_answers" do
    it "totally hides the correct answers" do
      quiz = @course.quizzes.create!({
        title: 'test quiz',
        show_correct_answers: false
      })

      quiz.publish!

      submission = quiz.generate_submission(@user)

      expect(quiz.show_correct_answers?(@user, submission)).to be_falsey
    end

    it "shows the correct answers immediately" do
      quiz = @course.quizzes.create!({
        title: 'test quiz',
        show_correct_answers: true
      })

      quiz.publish!

      submission = quiz.generate_submission(@user)

      expect(quiz.show_correct_answers?(@user, submission)).to be_truthy
    end

    it "shows the correct answers after a certain date" do
      quiz = @course.quizzes.create!({
        title: 'test quiz',
        show_correct_answers: true,
        show_correct_answers_at: 10.minutes.from_now
      })

      quiz.publish!

      submission = quiz.generate_submission(@user)

      expect(quiz.show_correct_answers?(@user, submission)).to be_falsey

      quiz.show_correct_answers_at = 2.minutes.ago
      quiz.save!
      quiz.reload

      expect(quiz.show_correct_answers?(@user, submission)).to be_truthy
    end

    it "hides the correct answers after a certain date" do
      quiz = @course.quizzes.create!({
        title: 'test quiz',
        show_correct_answers: true
      })

      quiz.publish!

      submission = quiz.generate_submission(@user)

      expect(quiz.show_correct_answers?(@user, submission)).to be_truthy

      quiz.hide_correct_answers_at = 2.minutes.ago
      quiz.save!
      quiz.reload

      expect(quiz.show_correct_answers?(@user, submission)).to be_falsey
    end

    it "nullifies related fields when turned off" do
      quiz = @course.quizzes.create({
        title: 'test quiz',
        show_correct_answers: false,
        show_correct_answers_at: 2.days.from_now,
        hide_correct_answers_at: 5.days.from_now
      })

      expect(quiz.show_correct_answers_at).to be_nil
      expect(quiz.hide_correct_answers_at).to be_nil

      quiz.update_attributes({
        show_correct_answers: true,
        show_correct_answers_at: 2.days.from_now,
        hide_correct_answers_at: 5.days.from_now
      })

      expect(quiz.show_correct_answers_at).not_to be_nil
      expect(quiz.hide_correct_answers_at).not_to be_nil

      quiz.update_attributes({
        show_correct_answers: false
      })

      expect(quiz.show_correct_answers_at).to be_nil
      expect(quiz.hide_correct_answers_at).to be_nil
    end

    it "doesn't consider dates when one_time_results is on" do
      quiz = @course.quizzes.create!({
        title: 'test quiz',
        show_correct_answers: true,
        show_correct_answers_at: 10.minutes.from_now,
        one_time_results: false
      })

      quiz.publish!

      submission = quiz.generate_submission(@user)

      expect(quiz.show_correct_answers?(@user, submission)).to be_falsey

      quiz.update_attributes({ one_time_results: true })
      expect(quiz.show_correct_answers?(@user, submission)).to be_truthy
    end

    context "show_correct_answers_last_attempt is true" do
      let(:user) { User.create! }

      it "shows the correct answers on last attempt" do
        quiz = @course.quizzes.create!({
          title: 'test quiz',
          show_correct_answers: true,
          show_correct_answers_last_attempt: true,
          allowed_attempts: 1
        })

        quiz.publish!

        submission = quiz.generate_submission(user)

        expect(quiz.show_correct_answers?(user, submission)).to be_truthy
      end

      it "hides the correct answers on last attempt" do
        quiz = @course.quizzes.create!({
          title: 'test quiz',
          show_correct_answers: true,
          show_correct_answers_last_attempt: true,
          allowed_attempts: 2
        })

        quiz.publish!

        submission = quiz.generate_submission(user)

        expect(quiz.show_correct_answers?(user, submission)).to be_falsey
      end
    end
  end

  context "permissions" do
    before :once do
      @course.workflow_state = 'available'
      @course.save!
      course_quiz(course: @course)
      student_in_course(course: @course, active_all: true)
      teacher_in_course(course: @course, active_all: true)
    end

    it "doesn't let student read/submit quizzes that are unpublished" do
      @quiz.unpublish!.reload
      expect(@quiz.grants_right?(@student, :read)).to eq false
      expect(@quiz.grants_right?(@student, :submit)).to eq false
      expect(@quiz.grants_right?(@teacher, :read)).to eq true
    end

    it "does let students read/submit quizzes that are published" do
      @quiz.publish!
      expect(@quiz.grants_right?(@student, :read)).to eq true
      expect(@quiz.grants_right?(@student, :submit)).to eq true
      expect(@quiz.grants_right?(@teacher, :read)).to eq true
    end
  end

  describe "#available?" do
    before :once do
      @quiz = @course.quizzes.create!(title: 'Test Quiz')
    end

    it "returns true if quiz is published" do
      @quiz.publish!
      expect(@quiz).to be_available
      @quiz.unpublish!
      expect(@quiz).not_to be_available
    end
  end

  describe "restore" do
    before do
      course
    end

    it "should restore to published state if there are student submissions" do
      @quiz = @course.quizzes.create!(title: 'Test Quiz')
      @quiz.stubs(:has_student_submissions?).returns true

      @quiz.destroy
      @quiz.restore
      expect(@quiz.reload).to be_published
    end

    it "should restore to unpublished state if no student submissions" do
      @quiz = @course.quizzes.create!(title: 'Test Quiz')
      @quiz.destroy
      @quiz.restore
      expect(@quiz.reload).to be_unpublished
    end

    it "works for practice quizzes" do
      @quiz = @course.quizzes.create!(title: 'Test Quiz', quiz_type: 'practice_quiz')
      @quiz.destroy
      @quiz.restore
      expect(@quiz.reload).to be_unpublished
    end
  end

  describe '#generate_submission_for_participant' do
    let :participant do
      Quizzes::QuizParticipant.new(User.new, 'foobar')
    end

    it 'should link the generated QS to a user' do
      subject.expects(:generate_submission).with(participant.user, false)

      subject.generate_submission_for_participant(participant)
    end

    it 'should link the generated QS to a temporary user code' do
      subject.expects(:generate_submission).with(participant.user_code, false)

      participant.stubs(:anonymous?).returns true
      subject.generate_submission_for_participant(participant)
    end
  end

  describe '.class_names' do
    it 'returns an array of all acceptable class names' do
      expect(Quizzes::Quiz.class_names).to eq ['Quiz', 'Quizzes::Quiz']
    end
  end

  context 'with versioning' do
    let_once(:quiz) { @course.quizzes.create! title: 'Test Quiz' }
    describe "#versions" do
      it "finds the versions of both namespaced and non-namespaced quizzes" do
        quiz.title = "Renamed Test Quiz"
        quiz.save
        expect(quiz.versions.count).to eq 2

        Version.update_all("versionable_type='Quiz'","versionable_id=#{quiz.id} AND versionable_type='Quizzes::Quiz'")

        expect(Quizzes::Quiz.find(quiz).versions.count).to eq 2
      end
    end
  end

  describe '#context_module_tags' do
    it "finds both namespaced and non-namespaced content tags" do
      quiz = @course.quizzes.create! title: 'Test Quiz'
      mod = @course.context_modules.create! name: 'Test Module'
      tag1 = mod.add_item id: quiz.id, type: 'quiz'
      tag2 = mod.add_item id: quiz.id, type: 'quiz'
      tag3 = mod.add_item id: quiz.id, type: 'quiz'
      ContentTag.where(id: tag2).update_all(content_type: 'Quiz')
      tag3.destroy
      expect(quiz.context_module_tags.pluck(:id).sort).to eql [tag1.id, tag2.id].sort
    end

    it "should act like an association" do
      quiz = @course.quizzes.create! title: 'Test Quiz'
      expect { quiz.context_module_tags.loaded? }.not_to raise_error
    end
  end

  describe 'differentiated assignments' do
    context 'visible_to_user?' do
      before :once do
        course_with_teacher(active_all: true, course: @course)
        @course_section = @course.course_sections.create
        @student1, @student2 = create_users(2, return_type: :record)
        @quiz = Quizzes::Quiz.create!({
          context: @course,
          description: 'descript foo',
          only_visible_to_overrides: true,
          points_possible: rand(1000),
          title: "I am a quiz"
        })
        @quiz.publish
        @quiz.save!
        @assignment = @quiz.assignment
        @course.enroll_student(@student2, :enrollment_state => 'active')
        @section = @course.course_sections.create!(name: "test section")
        @section2 = @course.course_sections.create!(name: "second test section")
        student_in_section(@section, user: @student1)
        create_section_override_for_assignment(@assignment, {course_section: @section})
        @course.reload
      end

      context 'DA feature on' do
        before { @course.enable_feature!(:differentiated_assignments) }

        context 'student with override' do
          it 'should show the quiz if there is an override' do
            expect(@quiz.visible_to_user?(@student1)).to be_truthy
          end
          it "should grant submit rights" do
            @course.stubs(:grants_right?).with(@student1, nil, :participate_as_student).returns(true)
            @course.stubs(:grants_right?).with(@student1, nil, :manage_assignments).returns(false)
            @course.stubs(:grants_right?).with(@student1, nil, :manage_grades).returns(false)
            expect(@quiz.grants_right?(@student1, :submit)).to eq true
            @course.unstub(:grants_right?)
          end
        end

        context 'student without override' do
          it 'should hide the quiz there is no override' do
            expect(@quiz.visible_to_user?(@student2)).to be_falsey
          end
          it 'should show the quiz if it is not only visible to overrides' do
            @quiz.only_visible_to_overrides = false
            @quiz.save!
            expect(@quiz.visible_to_user?(@student2)).to be_truthy
          end
          it 'should not grant submit rights' do
            @course.stubs(:grants_right?).with(@student2, nil, :participate_as_student).returns(true)
            @course.stubs(:grants_right?).with(@student2, nil, :manage_assignments).returns(false)
            @course.stubs(:grants_right?).with(@student2, nil, :manage_grades).returns(false)
            expect(@quiz.grants_right?(@student2, :submit)).to eq false
          end
        end

        context 'observer' do
          before do
            @observer = User.create
            @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section2, :enrollment_state => 'active', :allow_multiple_enrollments => true)
          end

          context 'with students' do
            it 'should show the quiz if there is an override' do
              @observer_enrollment.update_attribute(:associated_user_id, @student1.id)
              expect(@quiz.visible_to_user?(@observer)).to be_truthy
            end
            it 'should hide the quiz there is no override' do
              @observer_enrollment.update_attribute(:associated_user_id, @student2.id)
              expect(@quiz.visible_to_user?(@observer)).to be_falsey
            end
            it 'should show the quiz if it is not only visible to overrides' do
              @quiz.only_visible_to_overrides = false
              @quiz.save!
              @observer_enrollment.update_attribute(:associated_user_id, @student2.id)
              expect(@quiz.visible_to_user?(@observer)).to be_truthy
            end
          end

          context 'without students' do
            it 'should show the quiz if there is an override' do
              expect(@quiz.visible_to_user?(@observer)).to be_truthy
            end
            it 'should show the quiz even if there is no override' do
              expect(@quiz.visible_to_user?(@observer)).to be_truthy
            end
          end
        end

        context 'teacher' do
          it 'should show the quiz' do
            expect(@quiz.visible_to_user?(@teacher)).to be_truthy
          end
        end
      end

      context 'DA feature off' do
        before {@course.disable_feature!(:differentiated_assignments)}

        context 'student' do
          it 'should show the quiz even if there is no override' do
            expect(@quiz.visible_to_user?(@student1)).to be_truthy
            expect(@quiz.visible_to_user?(@student2)).to be_truthy
          end
        end

        context 'observer' do
          before do
            @observer = User.create
            @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section2, :enrollment_state => 'active', :allow_multiple_enrollments => true)
          end

          context 'with students' do
            it 'should show the quiz even if there is no override' do
              @observer_enrollment.update_attribute(:associated_user_id, @student2.id)
              expect(@quiz.visible_to_user?(@observer)).to be_truthy
            end
          end

          context 'without students' do
            it 'should show the quiz' do
              expect(@quiz.visible_to_user?(@observer)).to be_truthy
            end
          end
        end

        context 'teacher' do
          it 'should show the quiz' do
            expect(@quiz.visible_to_user?(@teacher)).to be_truthy
          end
        end
      end
    end
  end
end
