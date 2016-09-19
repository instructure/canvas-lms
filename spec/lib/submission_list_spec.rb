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

describe SubmissionList do
  it "should initialize with a course" do
    course_model
    expect{@sl = SubmissionList.new(@course)}.not_to raise_error
    expect(@sl).to be_is_a(SubmissionList)
    expect(@sl.course).to eql(@course)

    expect{@sl = SubmissionList.new(-1)}.to raise_error(ArgumentError, "Must provide a course.")
  end

  it "should provide a dictionary in 'list'" do
    course_model
    expect(SubmissionList.new(@course).list).to be_is_a(Dictionary)
  end

  it "should create keys in the data when versions of submissions existed" do
    interesting_submission_list
    expect(@sl.list.keys).to eql([Date.parse(Time.now.utc.to_s)])
  end

  it "should take the time zone into account when dividing grading history into days" do
    course_with_teacher(:active_all => true)
    course_with_student(:course => @course, :active_all => true)

    @assignment1 = @course.assignments.create!(:title => 'one', :points_possible => 10)
    @assignment2 = @course.assignments.create!(:title => 'two', :points_possible => 10)
    @assignment3 = @course.assignments.create!(:title => 'three', :points_possible => 10)

    # Get a date to perform this test on, we will do today and yesterday.
    Time.zone = 'Alaska'
    today = Date.today
    yesterday = today - 1.day
    Time.stubs(:now).returns(Time.utc(yesterday.year, yesterday.mon, yesterday.mday, 23, 0))   # yesterday 14:00 local time
    @assignment1.grade_student(@student, {:grade => 10, :grader => @teacher})
    Time.stubs(:now).returns(Time.utc(today.year, today.mon, today.mday, 1, 0))      # yesterday 16:00 local time
    @assignment2.grade_student(@student, {:grade => 10, :grader => @teacher})
    Time.stubs(:now).returns(Time.utc(today.year, today.mon, today.mday, 10, 0))     #  today 01:00 local time
    @assignment3.grade_student(@student, {:grade => 10, :grader => @teacher})
    Time.unstub(:now)

    @days = SubmissionList.new(@course).days
    expect(@days.size).to eq 2
    expect(@days[0].date).to eq Date.new(today.year, today.mon, today.mday)
    expect(@days[0].graders[0].assignments.size).to eq 1
    expect(@days[1].date).to eq Date.new(yesterday.year, yesterday.mon, yesterday.mday)
    expect(@days[1].graders[0].assignments.size).to eq 2
  end

  it "handles excused assignments" do
    course_with_teacher(:active_all => true)
    course_with_student(:course => @course, :active_all => true)

    @some_assignment = @course.assignments.create!(:title => 'one', :points_possible => 10)
    subs = @some_assignment.grade_student(@student, {grade: 8, grader: @teacher})
    subs.each { |s| s.created_at = 3.days.ago; s.updated_at = 3.days.ago; s.save }
    @some_assignment.grade_student(@student, {excuse: true, grader: @teacher})
    @days = SubmissionList.days(@course)
    submissions = @days[0].graders[0].assignments[0].submissions
    submissions.each do |sub|
      expect(sub.current_grade).to eq("EX")
      expect(sub.new_grade).to eq("EX")
    end
  end

  context "named loops" do

    before do
      interesting_submission_data
    end

    it "should be able to loop on days" do
      available_keys = [:graders, :date]
      SubmissionList.days(@course).each do |day|
        expect(day).to be_is_a(OpenStruct)
        expect(day.send(:table).keys.size).to eql(available_keys.size)
        available_keys.each {|k| expect(day.send(:table)).to be_include(k)}
        expect(day.graders).to be_is_a(Array)
        expect(day.date).to be_is_a(Date)
      end
    end

    it "should be able to loop on graders" do
      available_keys = [:grader_id, :assignments, :name]
      SubmissionList.days(@course).each do |day|
        day.graders.each do |grader|
          expect(grader).to be_is_a(OpenStruct)
          expect(grader.send(:table).keys.size).to eql(available_keys.size)
          available_keys.each {|k| expect(grader.send(:table).keys).to be_include(k)}
          expect(grader.grader_id).to be_is_a(Numeric)
          expect(grader.assignments).to be_is_a(Array)
          expect(grader.name).to be_is_a(String)
          expect(grader.assignments[0].submissions[0].grader).to eql(grader.name)
          expect(grader.assignments[0].submissions[0].grader_id).to eql(grader.grader_id)
        end
      end
    end

    it "should only keep one diff per grader per day" do
      SubmissionList.days(@course).each do |day|
        day.graders.each do |grader|
          grader.assignments.each do |assignment|
            expect(assignment.submissions.length).to eql assignment.submissions.map(&:student_name).uniq.length
          end
        end
      end
    end

    it "should be able to loop on assignments" do
      available_keys = [:submission_count, :name, :submissions, :assignment_id]
      SubmissionList.days(@course).each do |day|
        day.graders.each do |grader|
          grader.assignments.each do |assignment|
            expect(assignment).to be_is_a(OpenStruct)
            expect(assignment.send(:table).keys.size).to eql(available_keys.size)
            available_keys.each {|k| expect(assignment.send(:table).keys).to be_include(k)}
            expect(assignment.submission_count).to eql(assignment.submissions.size)
            expect(assignment.name).to be_is_a(String)
            expect(assignment.name).to eql(assignment.submissions[0].assignment_name)
            expect(assignment.submissions).to be_is_a(Array)
            expect(assignment.assignment_id).to eql(assignment.submissions[0].assignment_id)
          end
        end
      end
    end

    it "should be able to loop on submissions" do
      available_keys = [
        :assignment_id, :assignment_name, :current_grade, :current_graded_at,
        :current_grader, :graded_at, :graded_on, :grader, :new_grade, :grader_id,
        :new_graded_at, :new_grader, :previous_grade, :previous_graded_at,
        :previous_grader, :student_user_id, :submission_id, :student_name, :user_id
      ]

      SubmissionList.days(@course).each do |day|
        day.graders.each do |grader|
          grader.assignments.each do |assignment|
            assignment.submissions.each do |submission|
              expect(submission).to be_is_a(OpenStruct)
              expect(submission.send(:table).keys.size).to eql(available_keys.size)
              available_keys.each {|k| expect(submission.send(:table).keys).to be_include(k)}
            end
          end
        end
      end
    end

  end

  context "real data inspection" do
    before do
      course_model
      sl = SubmissionList.new(@course)
      @full_hash_list = YAML.load_file(
        File.expand_path(
          File.join(
            File.dirname(__FILE__),
            "..",
            "fixtures",
            "submission_list_full_hash_list.yml"
            )
          )
        )
    end
  end
  # Regrading info is not used in the controller or view.  Consequentely, it has
  # been pulled from the library.  Tests specifically related to regrading have
  # been commented out.
  context "regrading" do
    it 'should include regrade events in the final data' do
      # Figure out how to manually regrade a test piece of data
      interesting_submission_data
      @assignment = @course.assignments.create!(title: 'some_assignment')
      @quiz = Quizzes::Quiz.create!({:context => @course, title: "quiz time", points_possible: 10, assignment_id: @assignment.id, quiz_type: "assignment"})
      @quiz.workflow_state = 'published'
      @quiz.quiz_data = [multiple_choice_question_data]
      @quiz.save!
      @qs = @quiz.generate_submission(@student)

      @points = 15.0

      @question = stub(:id => 1, :question_data => {:id => 1,
          :regrade_option => 'full_credit',
          :points_possible => @points},
          :quiz_group => nil )

      @question_regrade = stub(:quiz_question  => @question,
        :regrade_option => "full_credit" )

      @answer = { :question_id => 1, :points => @points, :text => ""}

      @wrapper = Quizzes::QuizRegrader::Answer.new(@answer, @question_regrade)
      Quizzes::SubmissionGrader.new(@qs).grade_submission
      @qs.score_before_regrade = 5.0
      @qs.score = 4.0
      @qs.attempt = 1
      @qs.with_versioning(true, &:save!)
      @qs.save!

      #expect(@qs.score_before_regrade).to eq 5.0
      expect(@qs.score).to eq 4.0


      @sl = SubmissionList.days(@course)
      regrades = []
      @sl.each do |day|
        day.graders.each do |grader|
          grader.assignments.each do |assignment|
            assignment.submissions.each do |submission|
              regrades.push submission.score_before_regrade if submission
            end
          end
        end
      end

      #expect(regrades.include?(5.0)).to be_truthy
    end
  end

  context "remembers the most recent grade change" do
    let(:grader)  { User.create name: 'some_grader' }
    let(:student) { User.create name: "some student", workflow_state: "registered" }
    let(:course)  { Course.create name: "some course", workflow_state: "available" }
    let(:list)    { SubmissionList.new course }

    let(:assignment) do
      course.assignments.create title: "some assignment",
      points_possible: 10,
      workflow_state: "published"
    end

    let(:submission) do
      list.days.first.
        graders.first.
        assignments.first.
        submissions.first
    end

    let!(:enroll_teacher_and_student) do
      course.enroll_teacher(grader).accept
      course.enroll_student student
    end

    context "when the grade is not blank" do
      let!(:grade_assignment) do
        assignment.grade_student student, {grade: 5, grader: grader}
        assignment.grade_student student, {grade: 3, grader: grader}
      end

      it "remembers the 'Before' grade " do
        expect(submission.previous_grade).to eq "5"
      end
      it "remembers the 'After' grade" do
        expect(submission.new_grade).to eq "3"
      end
      it "remembers the 'Current' grade" do
        expect(submission.current_grade).to eq "3"
      end
    end

    context "when the grade is blank" do
      let!(:grade_assignment) do
        assignment.grade_student student, {grade: 6, grader: grader}
        assignment.grade_student student, {grade: 7, grader: grader}
        assignment.grade_student student, {grade: "", grader: grader}
      end

      it "remembers the 'Before' grade" do
       expect(submission.previous_grade).to eq "7"
      end
      it "remembers the 'After' grade" do
       expect(submission.new_grade).to be_blank
      end
      it "remembers the 'Current' grade" do
       expect(submission.current_grade).to be_blank
      end
    end
  end

end

def interesting_submission_list(opts={})
  interesting_submission_data(opts)
  @course.reload
  @sl = SubmissionList.new(@course)
end

def interesting_submission_data(opts={})
  opts[:grader] ||= {}
  opts[:user] ||= {}
  opts[:course] ||= {}
  opts[:assignment] ||= {}
  opts[:submission] ||= {}

  @grader = user_model({:name => 'some_grader'}.merge(opts[:grader]))
  @grader2 = user_model({:name => 'another_grader'}.merge(opts[:grader]))
  @student = factory_with_protected_attributes(User, {:name => "some student", :workflow_state => "registered"}.merge(opts[:user]))
  @course = factory_with_protected_attributes(Course, {:name => "some course", :workflow_state => "available"}.merge(opts[:course]))
  [@grader, @grader2].each do |grader|
    e = @course.enroll_teacher(grader)
    e.accept
  end
  @course.enroll_student(@student)
  @assignment = @course.assignments.new({
    :title => "some assignment",
    :points_possible => 10
  }.merge(opts[:assignment]))
  @assignment.workflow_state = "published"
  @assignment.save!
  @assignment.grade_student(@student, {:grade => 1.5, :grader => @grader}.merge(opts[:submission]))
  @assignment.grade_student(@student, {:grade => 3, :grader => @grader}.merge(opts[:submission]))
  @assignment.grade_student(@student, {:grade => 5, :grader => @grader2}.merge(opts[:submission]))
  @student = user_model(:name => 'another student')
  @course.enroll_student(@student)
  @assignment.reload
  @assignment.grade_student(@student, {:grade => 8, :grader => @grader}.merge(opts[:submission]))
  @student = user_model(:name => 'smart student')
  @course.enroll_student(@student)
  @assignment.reload
  @assignment.grade_student(@student, {:grade => 10, :grader => @grader}.merge(opts[:submission]))
  @assignment = @course.assignments.create({
    :title => "another assignment",
    :points_possible => 10
  })
  @assignment.workflow_state = "published"
  @assignment.save!
  @assignment.grade_student(@student, {:grade => 10, :grader => @grader}.merge(opts[:submission]))
end
