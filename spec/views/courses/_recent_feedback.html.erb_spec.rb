require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/courses/_recent_feedback" do
  before do
    course_with_student(active_all: true)
    assigns[:current_user] = @user
    submission_model
  end

  it 'shows the context when asked to' do
    @assignment.grade_student(@user, grade: 7, grader: @teacher)
    @submission.reload

    render partial: "courses/recent_feedback", object: @submission, locals: {is_hidden: false, show_context: true}

    expect(response.body).to include(@course.short_name)
  end

  it "doesn't show the context when not asked to" do
    @assignment.grade_student(@user, grade: 7, grader: @teacher)
    @submission.reload

    render partial: "courses/recent_feedback", contexts: [@course], object: @submission, locals: {is_hidden: false}

    expect(response.body).to_not include(@course.name)
  end

  it 'shows the comment' do
    @assignment.update_submission(@user, comment: 'bunch of random stuff', commenter: @teacher)
    @submission.reload

    render partial: "courses/recent_feedback", object: @submission, locals: {is_hidden: false}

    expect(response.body).to include('bunch of random stuff')
  end

  it 'shows the grade' do
    @assignment.grade_student(@user, grade: 5782394, grader: @teacher)
    @submission.reload

    render :partial => "courses/recent_feedback", object: @submission, locals: {is_hidden: false}

    expect(response.body).to include("5782394 out of #{@assignment.points_possible}")
  end

  it 'shows the grade and the comment' do
    @assignment.grade_student(@user, grade: 25734, grader: @teacher)
    @assignment.update_submission(@user, comment: 'something different', commenter: @teacher)
    @submission.reload

    render :partial => "courses/recent_feedback", object: @submission, locals: {is_hidden: false}

    expect(response.body).to include("25734 out of #{@assignment.points_possible}")
    expect(response.body).to include('something different')
  end
end
