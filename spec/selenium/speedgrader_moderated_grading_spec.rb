require File.expand_path(File.dirname(__FILE__) + '/helpers/speed_grader_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe "speed grader" do
  include_context "in-process server selenium tests"

  before (:each) do
    stub_kaltura

    course_with_teacher_logged_in
    @course.enable_feature!(:moderated_grading)
    outcome_with_rubric
    @assignment = @course.assignments.new(:name => 'assignment with rubric', :points_possible => 10)
    @assignment.moderated_grading = true
    @assignment.save!
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
    student_submission
  end

  it "should create rubric assessments for the provisional grade" do
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    keep_trying_until do
      f('.toggle_full_rubric').click
      expect(f('#rubric_full')).to be_displayed
    end
    f('#rubric_full tr.learning_outcome_criterion .criterion_comments img').click

    comment = "some silly comment"
    f('textarea.criterion_comments').send_keys(comment)
    f('#rubric_criterion_comments_dialog .save_button').click
    f('#rubric_full input.criterion_points').send_keys('3')
    f('#rubric_full .save_rubric_button').click
    wait_for_ajaximations

    ra = @association.rubric_assessments.first
    expect(ra.artifact).to be_a(ModeratedGrading::ProvisionalGrade)

    expect(ra.artifact.score).to eq 3
    expect(ra.data[0][:comments]).to eq comment
    
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    expect(f('#rubric_summary_container')).to include_text(@rubric.title)
    expect(f('#rubric_summary_container')).to include_text(comment)
  end
end
