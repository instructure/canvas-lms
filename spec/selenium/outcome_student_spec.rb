require File.expand_path(File.dirname(__FILE__) + '/helpers/outcome_common')

describe "outcomes as a student" do
  include_examples "in-process server selenium tests"
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
      expect(ff('.outcomes-content').first.text).not_to include "Setting up Outcomes"
    end

    it "should select the first outcome from the list if there are no outcome groups" do
      course_outcome 2
      get outcome_url
      wait_for_ajaximations
      keep_trying_until { expect(ff('.outcomes-content .title').first.text).to include "outcome 0" }
    end

    it "should select the first outcome group from the list if there are outcome groups" do
      course_bulk_outcome_groups_course(2, 2)
      get outcome_url
      wait_for_ajaximations
      keep_trying_until { expect(ff('.outcomes-content .title').first.text).to include "group 0" }
    end
  end
end