require_relative '../../../spec_helper.rb'

class AssignmentApiHarness
  include Api::V1::Assignment
  def api_user_content(description, course, user, opts)
    return "api_user_content(#{description}, #{course.id}, #{user.id})"
  end

  def course_assignment_url(context_id, assignment)
    "assignment/url/#{context_id}/#{assignment.id}"
  end

  def session
    Object.new
  end
end

describe "Api::V1::Assignment" do

  describe "#assignment_json" do
    let(:api) { AssignmentApiHarness.new }

    before do
      @assignment = assignment_model
      @user = user_model
      @assignment.stubs(:grants_right?).returns(true)
      @session = Object.new
    end

    it "returns json" do
      json = api.assignment_json(@assignment, @user, @session, {override_dates: false})
      expect(json).to be_a(Hash)
      expect(json["needs_grading_count"]).to eq(0)
      expect(json["needs_grading_count_by_section"]).to be_nil
    end

    it "includes section-based counts when grading flag is passed" do
      json = api.assignment_json(@assignment, @user, @session,
               {override_dates: false, needs_grading_count_by_section: true})
      expect(json).to be_a(Hash)
      expect(json["needs_grading_count"]).to eq(0)
      expect(json["needs_grading_count_by_section"]).to eq []
    end

    it "includes all assignment overrides fields when an assignment_override exists" do
      @assignment.assignment_overrides.create(:workflow_state => 'active')
      overrides = @assignment.assignment_overrides
      json = api.assignment_json(@assignment, @user, @session, {overrides: overrides})
      expect(json).to be_a(Hash)
      expect(json["overrides"].first.keys.sort).to eq ["assignment_id","id", "title", "student_ids"].sort
    end
  end
end
