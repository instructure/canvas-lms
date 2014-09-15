
require File.expand_path('../../spec_helper', File.dirname(__FILE__))


module Api::V1
  class GradebookHistoryHarness
    include GradebookHistory

    def course_assignment_url(course, assignment)
      'http://www.example.com'
    end

    def course_assignment_submission_url(course, assignment, submission, opts = {})
      'http://www.example.com'
    end

    def params
      {}
    end
  end

  describe GradebookHistory do
    let(:course) { stub }
    let(:controller) { stub(:params => {} , :request => stub(:query_parameters => {}), :response => stub(:headers => {}) )}
    let(:path) { '' }
    let(:user) { ::User.new }
    let(:session) { stub }
    let(:api_context) { ApiContext.new(controller, path, user, session) }
    let(:gradebook_history) { GradebookHistoryHarness.new }
    let(:now) { Time.now.in_time_zone }
    let(:yesterday) { (now - 24.hours).in_time_zone }

    before do
      ::Submission.any_instance.stubs(:grants_right?).with(user, :read_grade).returns(true)
    end

    def submit(assignment, student, day, grader)
      bare_submission_model(assignment, student, :graded_at => day, :grader_id => grader.try(:id))
    end

    describe '#days_json' do
      let_once(:course) { ::Course.create! }

      before :once do
        students = (1..3).inject([]) do |memo, idx|
          student = ::User.create!
          course.enroll_student(student)
          memo << student
        end
        @grader1 = ::User.create!(:name => 'grader 1')
        @grader2 = ::User.create!(:name => 'grader 2')
        @assignment1 = course.assignments.create!(:title => "some assignment")
        @assignment2 = course.assignments.create!(:title => "another assignment")
        submit(@assignment1, students[0], now, @grader1)
        submit(@assignment1, students[1], now, @grader2)
        submit(@assignment1, students[2], yesterday, @grader2)
        submit(@assignment2, students[0], yesterday, @grader2)
      end

      before :each do
        harness = GradebookHistoryHarness.new
        harness.instance_variable_set(:@domain_root_account, ::Account.default)
        @days = harness.days_json(course, api_context)
      end

      it 'has a top level key for each day represented' do
        dates = @days.map{|d| d[:date] }
        dates.size.should == 2
        dates.should include(now.to_date.as_json)
        dates.should include(24.hours.ago.in_time_zone.to_date.as_json)
      end

      it 'has a hash of graders for each day keyed by id' do
        graders_hash = @days.select{|d| d[:date] == yesterday.to_date.as_json }.first[:graders]
        grader = graders_hash.first
        grader[:id].should == @grader2.id
        grader[:name].should == @grader2.name
      end

      it 'puts an assignment list under each grader' do
        graders = @days.select{|d| d[:date] == yesterday.to_date.as_json }.first[:graders]
        grader2_assignments = graders.select { |g| g[:id] == @grader2.id }.first[:assignments]
        ids = grader2_assignments.map { |assignment| assignment['id'] }
        ids.should include(@assignment1.id)
        ids.should include(@assignment2.id)
      end

      it 'paginates' do
        api_context.per_page = 2
        api_context.page = 2
        harness = GradebookHistoryHarness.new
        harness.instance_variable_set(:@domain_root_account, ::Account.default)
        days = harness.days_json(course, api_context)
        days.map { |d| d[:date] }.first.should == yesterday.to_date.as_json
      end

    end

    describe '#json_for_date' do
      let_once(:course) { ::Course.create! }

      before :once do
        student1 = ::User.create!
        course.enroll_student(student1)
        student2 = ::User.create!
        course.enroll_student(student2)
        @grader1 = ::User.create!(:name => 'grader 1')
        @grader2 = ::User.create!(:name => 'grader 2')
        @assignment = course.assignments.create!(:title => "some assignment")
        submit(@assignment, student1, now, @grader1)
        submit(@assignment, student2, now, @grader2)
      end

      before :each do
        harness = GradebookHistoryHarness.new
        harness.instance_variable_set(:@domain_root_account, ::Account.default)
        @day_hash = harness.json_for_date(now, course, api_context)
      end

      it 'returns a grader hash for that day' do
        @day_hash.map{|g| g[:id] }.sort.should == [@grader1.id, @grader2.id].sort
      end

      it 'includes assignment data' do
        assignment_hash = @day_hash.select{|g| g[:id] == @grader1.id}.first[:assignments].first
        assignment_hash['id'].should == @assignment.id
        assignment_hash['name'].should == @assignment.title
      end
    end

    describe '#submissions_for' do
      before :once do
        @course = ::Course.create!
        student1 = ::User.create!
        @course.enroll_student(student1)
        @grader1 = ::User.create!(:name => 'grader 1')
        @grader2 = ::User.create!(:name => 'grader 2')
        @assignment = @course.assignments.create!(:title => "some assignment")
        @submission = @assignment.submit_homework(student1)
        @submission.update_attributes(graded_at: now, grader_id: @grader1.id)
        @submission.score = 90
        @submission.grade = '90'
        @submission.grader = @grader2
        @submission.save!
      end

      it 'should be an array of submissions' do
        harness = GradebookHistoryHarness.new
        submissions_hash = harness.submissions_for(@course, api_context, now, @grader2.id, @assignment.id)
        submissions_hash.first[:submission_id].should == @submission.id
      end

      it 'has the version hash' do
        harness = GradebookHistoryHarness.new
        submissions_hash = harness.submissions_for(@course, api_context, now, @grader2.id, @assignment.id)
        version1 = submissions_hash.first[:versions].first
        version1[:assignment_id].should == @assignment.id
        version1[:current_grade].should == "90"
        version1[:current_grader].should == 'grader 2'
        version1[:new_grade].should == "90"
      end

      it 'can find submissions with no grader' do
        student2 = ::User.create!
        @course.enroll_student(student2)
        submission = submit(@assignment, student2, now, nil)
        # yes, this is crazy.  autograded submissions have the grader_id of (quiz_id x -1)
        submission.grader_id = -987
        submission.save!

        submissions = GradebookHistoryHarness.new.submissions_for(@course, api_context, now, 0, @assignment.id)
        submissions.first[:submission_id].should == submission.id
      end

      it 'should properly set pervious_* attributes' do
        # regrade to get a second version
        @submission.score = 80
        @submission.score = '80'
        @submission.save!

        harness = GradebookHistoryHarness.new
        submissions = harness.submissions_for(@course, api_context, now, @grader2.id, @assignment.id)
        submissions.first[:versions][0][:grade].should == "80"
        submissions.first[:versions][0][:previous_grade].should == "90"
        submissions.first[:versions][1][:grade].should == "90"
        submissions.first[:versions][1][:previous_grade].should == nil
      end
    end

    describe '#day_string_for' do
      it 'builds a formatted date' do
        submission = stub(:graded_at => now)
        gradebook_history.day_string_for(submission).should =~ /\d{4}-\d{2}-\d{2}/
      end

      it 'gives a empty string if there is no time' do
        submission = stub(:graded_at => nil)
        gradebook_history.day_string_for(submission).should == ''
      end
    end

    describe '#submissions' do
      let_once(:course) { ::Course.create! }
      let_once(:assignment) { course.assignments.create! }
      let_once(:student) { ::User.create! }
      let(:submissions) { gradebook_history.submissions_set(course, api_context) }

      before :once do
        course.enroll_student(student)
        @submission = bare_submission_model(assignment, student)
      end

      context 'when the submission has been graded' do
        before :once do
          @submission.graded_at = Time.now.in_time_zone
          @submission.save!
        end

        def add_submission
          other_student = ::User.create!
          course.enroll_student(other_student)
          other_submission = bare_submission_model(assignment, other_student, graded_at: 2.hours.ago.in_time_zone)
          other_submission.save!
        end

        it 'includes the submission' do
          submissions.should include(@submission)
        end

        it 'orders submissions by graded timestamp' do
          add_submission
          submissions.first.should == @submission
        end

        it 'accepts a date option' do
          add_submission
          gradebook_history.submissions_set(course, api_context, :date => 3.days.ago.in_time_zone).should be_empty
          gradebook_history.submissions_set(course, api_context, :date => Time.now.in_time_zone).should_not be_empty
        end

      end

      it 'does not include ungraded submissions' do
        submissions.should_not include(@submission)
      end
    end

  end
end

