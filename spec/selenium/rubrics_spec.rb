require File.expand_path(File.dirname(__FILE__) + '/helpers/rubrics_specs')

describe "shared rubric specs" do
  let(:rubric_url) { "/courses/#{@course.id}/rubrics" }
  let(:who_to_login) { 'teacher' }
  it_should_behave_like "rubric tests"
end

describe "course rubrics" do
  it_should_behave_like "in-process server selenium tests"

  context "importing" do
    it "should create a allow immediate editing when adding an imported rubric to a new assignment" do
      course_with_teacher_logged_in
      rubric_association_model(:user => @user, :context => @course, :purpose => "grading")

      @old_course = @course
      @course = nil
      course_with_teacher(:user => @user, :active_all => true)

      @course.merge_into_course(@old_course, :everything => true)
      @assignment = @course.assignments.create!(assignment_valid_attributes.merge({:title => "New Course Assignment"}))

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f("#right-side-wrapper .add_rubric_link").click
      fj(".find_rubric_link:visible").click
      wait_for_ajaximations
      fj(".select_rubric_link:visible").click
      wait_for_ajax_requests
      wait_for_animations(500)
      fj(".edit_rubric_link:visible").click
      fj(".rubric_custom_rating:visible").click
      fj(".save_button:visible").click
      wait_for_ajax_requests

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      find_all_with_jquery(".custom_ratings:visible").size.should eql(1)
    end
  end

  it "should display free-form comments to the student" do
    assignment_model
    rubric_model(:context => @course, :free_form_criterion_comments => true)
    course_with_student(:course => @course, :active_all => true)
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
    comment = "Hi, please see www.example.com.\n\nThanks."
    @assessment = @association.assess({
                                          :user => @student,
                                          :assessor => @teacher,
                                          :artifact => @assignment.find_or_create_submission(@student),
                                          :assessment => {
                                              :assessment_type => 'grading',
                                              :criterion_crit1 => {
                                                  :points => 5,
                                                  :comments => comment,
                                              }
                                          }
                                      })
    user_logged_in(:user => @student)

    get "/courses/#{@course.id}/grades"
    f('.toggle_rubric_assessments_link').click
    wait_for_animations
    f('.rubric .criterion .custom_rating_comments').text.should == comment
    f('.rubric .criterion .custom_rating_comments a').attribute('href').should == 'http://www.example.com/'

    get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
    f('.assess_submission_link').click
    wait_for_animations
    f('.rubric .criterion .custom_rating_comments').text.should == comment
    f('.rubric .criterion .custom_rating_comments a').attribute('href').should == 'http://www.example.com/'
  end

  it "should ignore outcome rubric lines when calculating total" do
    course_with_teacher_logged_in
    outcome_with_rubric
    @assignment = @course.assignments.create(:name => 'assignment with rubric')
    @association = @rubric.associate_with(@assignment, @course, :use_for_grading => true, :purpose => 'grading')
    @rubric.data[0][:ignore_for_scoring] = '1'
    @rubric.points_possible = 5
    @rubric.instance_variable_set('@outcomes_changed', true)
    @rubric.save!

    get "/courses/#{@course.id}/rubrics/#{@rubric.id}"
    f('.rubric_total').should include_text "5"

    f('.edit_rubric_link').click
    criterion_points = fj(".criterion_points:visible")
    replace_content(criterion_points, "10")
    criterion_points.send_keys(:return)
    submit_form("#edit_rubric_form")
    wait_for_ajaximations
    fj('.rubric_total').should include_text "10"

    # check again after reload
    refresh_page
    fj('.rubric_total').should include_text "10" #avoid selenium caching
  end
end