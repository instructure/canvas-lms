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
  subject(:api) { AssignmentApiHarness.new }
  let(:assignment) { assignment_model }

  describe "#assignment_json" do
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

  describe "#assignment_editable_fields_valid?" do
    let(:user) { Object.new }
    let(:course) { Course.new }
    let(:assignment) do
      Assignment.new do |a|
        a.title = 'foo'
        a.submission_types = 'online'
        a.course = course
      end
    end

    context "given a user who is an admin" do
      before do
        course.expects(:account_membership_allows).returns(true)
      end

      it "is valid when user is an account admin" do
        is_expected.to be_assignment_editable_fields_valid(assignment, user)
      end
    end

    context "given a user who is not an admin" do
      before do
        assignment.course.expects(:account_membership_allows).returns(false)
      end

      it "is valid when not in a closed grading period" do
        assignment.expects(:in_closed_grading_period?).returns(false)
        is_expected.to be_assignment_editable_fields_valid(assignment, user)
      end

      context "in a closed grading period" do
        let(:course) { Course.create! }
        let(:assignment) do
          course.assignments.create!(title: 'First Title', submission_types: 'online_quiz')
        end

        before do
          assignment.expects(:in_closed_grading_period?).returns(true)
        end

        it "is valid when it was not gradeable and is still not gradeable " \
          "(!gradeable_was? && !gradeable?)" do
          assignment.update!(submission_types: 'not_gradeable')
          assignment.submission_types = 'wiki_page'
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is invalid when it was gradeable and is now not gradeable" do
          assignment.update!(submission_types: 'online')
          assignment.title = 'Changed Title'
          assignment.submission_types = 'not_graded'
          expect(api).not_to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is invalid when it was not gradeable and is now gradeable" do
          assignment.update!(submission_types: 'not_gradeable')
          assignment.title = 'Changed Title'
          assignment.submission_types = 'online_quiz'
          expect(api).not_to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is invalid when it was gradeable and is still gradeable" do
          assignment.update!(submission_types: 'on_paper')
          assignment.title = 'Changed Title'
          assignment.submission_types = 'online_upload'
          expect(api).not_to be_assignment_editable_fields_valid(assignment, user)
        end

        it "detects changes to title and responds with those errors on the name field" do
          assignment.title = 'Changed Title'
          expect(api).not_to be_assignment_editable_fields_valid(assignment, user)
          expect(assignment.errors).to include :name
        end

        it "is valid if description changed" do
          assignment.description = "changing the description is allowed!"
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
          expect(assignment.errors).to be_empty
        end

        it "is valid if submission_types changed" do
          assignment.submission_types = 'on_paper'
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is valid if peer_reviews changed" do
          assignment.toggle(:peer_reviews)
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is valid if peer_review_count changed" do
          assignment.peer_review_count = 500
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is valid if anonymous_peer_reviews changed" do
          assignment.toggle(:anonymous_peer_reviews)
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is valid if peer_reviews_due_at changed" do
          assignment.peer_reviews_due_at = Time.zone.now
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is valid if automatic_peer_reivews changed" do
          assignment.toggle(:automatic_peer_reviews)
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end

        it "is valid if allowed_extensions changed" do
          assignment.allowed_extensions = ["docx"]
          expect(api).to be_assignment_editable_fields_valid(assignment, user)
        end
      end
    end
  end
end
