require File.expand_path('../../spec_helper', File.dirname(__FILE__))

class GradebookHistoryHarness
  include Api::V1::GradebookHistory

  def course_assignment_url(*)
    'http://www.example.com'
  end

  def course_assignment_submissions_url(*)
    'http://www.example.com'
  end

  def course_assignment_submission_url(*)
    'http://www.example.com'
  end

  def params
    {}
  end
end

describe Api::V1::GradebookHistory do
  subject(:gradebook_history) { GradebookHistoryHarness.new }
  let(:course) { double }
  let(:controller) do
    stub(
      :params => {},
      :request => stub(:query_parameters => {}),
      :response => stub(:headers => {})
    )
  end
  let(:path) { '' }
  let(:user) { User.new }
  let(:session) { stub }
  let(:api_context) { Api::V1::ApiContext.new(controller, path, user, session) }
  let(:now) { Time.now.in_time_zone }
  let(:yesterday) { (now - 24.hours).in_time_zone }

  before do
    Submission.any_instance.stubs(:user_can_read_grade?).with(user, session).returns(true)
  end

  def submit(assignment, student, day, grader)
    bare_submission_model(assignment, student, :graded_at => day, :grader_id => grader.try(:id))
  end

  describe '#days_json' do
    let_once(:course) { Course.create! }

    before :once do
      students = (1..3).map do |_idx|
        student = User.create!
        course.enroll_student(student)
        student
      end
      @grader1 = User.create!(:name => 'grader 1')
      @grader2 = User.create!(:name => 'grader 2')
      @assignment1 = course.assignments.create!(:title => "some assignment")
      @assignment2 = course.assignments.create!(:title => "another assignment")
      submit(@assignment1, students[0], now, @grader1)
      submit(@assignment1, students[1], now, @grader2)
      submit(@assignment1, students[2], yesterday, @grader2)
      submit(@assignment2, students[0], yesterday, @grader2)
    end

    before :each do
      harness = GradebookHistoryHarness.new
      harness.instance_variable_set(:@domain_root_account, Account.default)
      @days = harness.days_json(course, api_context)
    end

    it 'has a top level key for each day represented' do
      dates = @days.map{|d| d[:date] }
      expect(dates.size).to eq 2
      expect(dates).to include(now.to_date.as_json)
      expect(dates).to include(24.hours.ago.in_time_zone.to_date.as_json)
    end

    it 'has a hash of graders for each day keyed by id' do
      graders_hash = @days.find{|d| d[:date] == yesterday.to_date.as_json }[:graders]
      grader = graders_hash.first
      expect(grader[:id]).to eq @grader2.id
      expect(grader[:name]).to eq @grader2.name
    end

    it 'puts an assignment list under each grader' do
      graders = @days.find { |d| d[:date] == yesterday.to_date.as_json }[:graders]
      grader2_assignments = graders.find { |g| g[:id] == @grader2.id }[:assignments]
      ids = grader2_assignments.map { |assignment| assignment['id'] }
      expect(ids).to include(@assignment1.id)
      expect(ids).to include(@assignment2.id)
    end

    it 'paginates' do
      api_context.per_page = 2
      api_context.page = 2
      harness = GradebookHistoryHarness.new
      harness.instance_variable_set(:@domain_root_account, Account.default)
      days = harness.days_json(course, api_context)
      expect(days.map { |d| d[:date] }.first).to eq yesterday.to_date.as_json
    end

  end

  describe '#json_for_date' do
    let_once(:course) { Course.create! }

    before :once do
      student1 = User.create!
      course.enroll_student(student1)
      student2 = User.create!
      course.enroll_student(student2)
      @grader1 = User.create!(:name => 'grader 1')
      @grader2 = User.create!(:name => 'grader 2')
      @assignment = course.assignments.create!(:title => "some assignment")
      submit(@assignment, student1, now, @grader1)
      submit(@assignment, student2, now, @grader2)
    end

    before :each do
      harness = GradebookHistoryHarness.new
      harness.instance_variable_set(:@domain_root_account, Account.default)
      @day_hash = harness.json_for_date(now, course, api_context)
    end

    it 'includes assignment data' do
      assignment_hash = @day_hash.find{|g| g[:id] == @grader1.id}[:assignments].first
      expect(assignment_hash['id']).to eq @assignment.id
      expect(assignment_hash['name']).to eq @assignment.title
    end

    it 'returns a grader hash for that day' do
      expect(@day_hash.map{|g| g[:id] }.sort).to eq [@grader1.id, @grader2.id].sort
    end

    it 'includes assignment data' do
      assignment_hash = @day_hash.find{|g| g[:id] == @grader1.id}[:assignments].first
      expect(assignment_hash['id']).to eq @assignment.id
      expect(assignment_hash['name']).to eq @assignment.title
    end
  end

  describe '#submissions_for' do
    before :once do
      @course = Course.create!
      student1 = User.create!
      @course.enroll_student(student1)
      @grader1 = User.create!(:name => 'grader 1')
      @grader2 = User.create!(:name => 'grader 2')
      @course.enroll_teacher(@grader2)
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
      expect(submissions_hash.first[:submission_id]).to eq @submission.id
    end

    it 'has the version hash' do
      harness = GradebookHistoryHarness.new
      submissions_hash = harness.submissions_for(@course, api_context, now, @grader2.id, @assignment.id)
      version1 = submissions_hash.first[:versions].first
      expect(version1[:assignment_id]).to eq @assignment.id
      expect(version1[:current_grade]).to eq "90"
      expect(version1[:current_grader]).to eq 'grader 2'
      expect(version1[:new_grade]).to eq "90"
    end

    it 'can find submissions with no grader' do
      student2 = User.create!
      @course.enroll_student(student2)
      submission = submit(@assignment, student2, now, nil)
      # yes, this is crazy.  autograded submissions have the grader_id of (quiz_id x -1)
      submission.grader_id = -987
      submission.save!

      submissions = GradebookHistoryHarness.new.submissions_for(@course, api_context, now, 0, @assignment.id)
      expect(submissions.first[:submission_id]).to eq submission.id
    end

    it 'should properly set pervious_* attributes' do
      # regrade to get a second version
      @submission.score = '80'
      @submission.with_versioning(:explicit => true) { @submission.save! }

      harness = GradebookHistoryHarness.new
      submissions = harness.submissions_for(@course, api_context, now, @grader2.id, @assignment.id)
      expect(submissions.first[:versions][0][:grade]).to eq "80"
      expect(submissions.first[:versions][0][:previous_grade]).to eq "90"
      expect(submissions.first[:versions][1][:grade]).to eq "90"
      expect(submissions.first[:versions][1][:previous_grade]).to eq nil
    end
  end

  describe '#day_string_for' do
    it 'builds a formatted date' do
      submission = stub(:graded_at => now)
      expect(gradebook_history.day_string_for(submission)).to match(/\d{4}-\d{2}-\d{2}/)
    end

    it 'gives a empty string if there is no time' do
      submission = stub(:graded_at => nil)
      expect(gradebook_history.day_string_for(submission)).to eq ''
    end
  end

  describe '#submissions' do
    let_once(:course) { Course.create! }
    let_once(:assignment) { course.assignments.create! }
    let_once(:student) { User.create! }
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
        other_student = User.create!
        course.enroll_student(other_student)
        other_submission = bare_submission_model(assignment, other_student, graded_at: 2.hours.ago.in_time_zone)
        other_submission.save!
      end

      it 'includes the submission' do
        expect(submissions).to include(@submission)
      end

      it 'orders submissions by graded timestamp' do
        add_submission
        expect(submissions.first).to eq @submission
      end

      it 'accepts a date option' do
        add_submission
        expect(gradebook_history.submissions_set(course, api_context, :date => 3.days.ago.in_time_zone)).to be_empty
        expect(gradebook_history.submissions_set(course, api_context, :date => Time.now.in_time_zone)).not_to be_empty
      end

    end

    it 'does not include ungraded submissions' do
      expect(submissions).not_to include(@submission)
    end
  end

end
