require_relative '../helpers/outcome_common'

describe "outcomes as a student" do
  include_context "in-process server selenium tests"
  include OutcomeCommon

  let(:who_to_login) { 'student' }
  let(:outcome_url) { "/courses/#{@course.id}/outcomes" }

  before(:each) do
    course_with_student_logged_in
  end

  context "initial state" do
    it "should not display outcome instructions" do
      course_bulk_outcome_groups_course(2, 2)
      get outcome_url
      wait_for_ajaximations
      expect(f('.outcomes-content')).not_to include_text "Setting up Outcomes"
    end

    it "should select the first outcome from the list if there are no outcome groups" do
      course_outcome 2
      get outcome_url
      expect(f('.outcomes-content .title')).to include_text "outcome 0"
    end

    it "should select the first outcome group from the list if there are outcome groups" do
      course_bulk_outcome_groups_course(2, 2)
      get outcome_url
      expect(f('.outcomes-content .title')).to include_text "group 0"
    end
  end
end
