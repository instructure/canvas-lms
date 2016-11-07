require_relative '../../../spec_helper.rb'

class AssignmentApiHarness
  include Api::V1::Assignment

  def value_to_boolean(value)
    Canvas::Plugin.value_to_boolean(value)
  end

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
      assignment.context.stubs(:grants_right?).returns(true)
      json = api.assignment_json(assignment, user, session, {override_dates: false})
      expect(json["needs_grading_count"]).to eq(0)
      expect(json["needs_grading_count_by_section"]).to be_nil
    end

    it "includes section-based counts when grading flag is passed" do
      assignment.context.stubs(:grants_right?).returns(true)
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

    it "excludes descriptions when exclude_response_fields flag is passed and includes 'description'" do
      assignment.description = "Foobers"
      json = api.assignment_json(assignment, user, session,
                                 {override_dates: false})
      expect(json).to be_a(Hash)
      expect(json).to have_key "description"
      expect(json['description']).to eq(api.api_user_content("Foobers", @course, user, {}))


      json = api.assignment_json(assignment, user, session,
                                 {override_dates: false, exclude_response_fields: ['description']})
      expect(json).to be_a(Hash)
      expect(json).not_to have_key "description"

      json = api.assignment_json(assignment, user, session,
                                 {override_dates: false})
      expect(json).to be_a(Hash)
      expect(json).to have_key "description"
      expect(json['description']).to eq(api.api_user_content("Foobers", @course, user, {}))
    end

    it "excludes needs_grading_counts when exclude_response_fields flag is " \
    "passed and includes 'needs_grading_count'" do
      params = { override_dates: false, exclude_response_fields: ['needs_grading_count'] }
      json = api.assignment_json(assignment, user, session, params)
      expect(json).not_to have_key "needs_grading_count"
    end
  end

  describe "*_settings_hash methods" do
    let(:assignment) { AssignmentApiHarness.new }
    let(:test_params) do
      ActionController::Parameters.new({
        "turnitin_settings" => {},
        "vericite_settings" => {}
      })
    end

    it "#turnitin_settings_hash returns a Hash with indifferent access" do
      turnitin_hash = assignment.turnitin_settings_hash(test_params)
      expect(turnitin_hash).to be_instance_of(HashWithIndifferentAccess)
    end

    it "#vericite_settings_hash returns a Hash with indifferent access" do
      vericite_hash = assignment.vericite_settings_hash(test_params)
      expect(vericite_hash).to be_instance_of(HashWithIndifferentAccess)
    end
  end
end
