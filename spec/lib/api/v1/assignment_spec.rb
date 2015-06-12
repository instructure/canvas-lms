require_relative '../../../spec_helper.rb'

class AssignmentApiHarness
  include Api::V1::Assignment

  def api_user_content(description, course, user, _)
    "api_user_content(#{description}, #{course.id}, #{user.id})"
  end

  def course_assignment_url(context_id, assignment)
    "assignment/url/#{context_id}/#{assignment.id}"
  end

  def session
    Object.new
  end

  def course_assignment_submissions_url(course, assignment, _options)
    "/course/#{course.id}/assignment/#{assignment.id}/submissions?zip=1"
  end

  def course_quiz_quiz_submissions_url(course, quiz, _options)
    "/course/#{course.id}/quizzes/#{quiz.id}/submissions?zip=1"
  end
end

describe "Api::V1::Assignment" do

  describe "#assignment_json" do
    let(:api) { AssignmentApiHarness.new }
    let(:assignment) { assignment_model }
    let(:user) { user_model }
    let(:session) { Object.new }

    it "returns json" do
      assignment.stubs(:grants_right?).returns(true)
      json = api.assignment_json(assignment, user, session, {override_dates: false})
      expect(json["needs_grading_count"]).to eq(0)
      expect(json["needs_grading_count_by_section"]).to be_nil
    end

    it "includes section-based counts when grading flag is passed" do
      assignment.stubs(:grants_right?).returns(true)
      json = api.assignment_json(assignment, user, session,
                                 {override_dates: false, needs_grading_count_by_section: true})
      expect(json["needs_grading_count"]).to eq(0)
      expect(json["needs_grading_count_by_section"]).to eq []
    end

    context "for an assignment" do
      it "provides a submissions download URL" do
        json = api.assignment_json(assignment, user, session)

        expect(json['submissions_download_url']).to eq "/course/#{@course.id}/assignment/#{assignment.id}/submissions?zip=1"
      end
    end

    context "for a quiz" do
      before do
        @assignment = assignment_model
        @assignment.submission_types = 'online_quiz'
        @quiz = quiz_model(course: @course)
        @assignment.quiz = @quiz
      end

      it "provides a submissions download URL" do
        json = api.assignment_json(@assignment, user, session)

        expect(json['submissions_download_url']).to eq "/course/#{@course.id}/quizzes/#{@quiz.id}/submissions?zip=1"
      end
    end


    it "includes all assignment overrides fields when an assignment_override exists" do
      assignment.assignment_overrides.create(:workflow_state => 'active')
      overrides = assignment.assignment_overrides
      json = api.assignment_json(assignment, user, session, {overrides: overrides})
      expect(json).to be_a(Hash)
      expect(json["overrides"].first.keys.sort).to eq ["assignment_id","id", "title", "student_ids"].sort
    end

    it "excludes descriptions when exclude_description flag is passed" do
      assignment.description = "Foobers"
      json = api.assignment_json(assignment, user, session,
                                 {override_dates: false})
      expect(json).to be_a(Hash)
      expect(json).to have_key "description"
      expect(json['description']).to eq(api.api_user_content("Foobers", @course, user, {}))


      json = api.assignment_json(assignment, user, session,
                                 {override_dates: false, exclude_description: true})
      expect(json).to be_a(Hash)
      expect(json).to_not have_key "description"

      json = api.assignment_json(assignment, user, session,
                                 {override_dates: false})
      expect(json).to be_a(Hash)
      expect(json).to have_key "description"
      expect(json['description']).to eq(api.api_user_content("Foobers", @course, user, {}))
    end
  end
end
