require_relative '../helpers/outcome_common'

describe "user outcome results page as a teacher" do
  include_context "in-process server selenium tests"
  include OutcomeCommon

  let(:outcome_url) { "/courses/#{@course.id}/outcomes/users/#{@student.id}" }

  before(:once) do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
  end

  before do
    user_session @teacher
    get outcome_url
  end

  it "should toggle show all artifacts after clicking button" do
    btn = f('#show_all_artifacts_link')
    expect(btn.text).to eq "Show All Artifacts"
    btn.click
    expect(btn.text).to eq "Hide All Artifacts"
    btn.click
    expect(btn.text).to eq "Show All Artifacts"
  end

end
