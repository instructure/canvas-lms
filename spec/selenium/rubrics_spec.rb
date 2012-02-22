require File.expand_path(File.dirname(__FILE__) + '/common')

describe "rubrics" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  def create_rubric_with_criterion_points(points)
    get "/courses/#{@course.id}/rubrics"

    driver.find_element(:css, "#right-side-wrapper .add_rubric_link").click
    driver.find_element(:css, "#criterion_1 .criterion_points").send_key :backspace
    driver.find_element(:css, "#criterion_1 .criterion_points").send_key points.to_s
    driver.find_element(:css, "#edit_rubric_form .save_button").click
    wait_for_ajaximations
  end

  def edit_rubric_after_updating
    find_with_jquery(".rubric .edit_rubric_link:visible").click
    driver.find_element(:tag_name, "body").click
  end

  # should be in editing mode before calling
  def split_ratings(idx, split_left)
    rating = find_all_with_jquery(".rubric .criterion:visible .rating")[idx]
    driver.action.move_to(rating).perform

    if split_left
      driver.execute_script <<-JS
        var $rating = $('.rubric .criterion:visible .rating:eq(#{idx})');
        $rating.addClass('add_column add_right');
        $rating.prev().addClass('add_left');
        $rating.click();
      JS
    else
      driver.execute_script <<-JS
        var $rating = $('.rubric .criterion:visible .rating:eq(#{idx})');
        $rating.addClass('add_column add_left');
        $rating.next().addClass('add_right');
        $rating.click();
      JS
    end
  end

  it "should allow fractional points" do
    create_rubric_with_criterion_points "5.5"
    find_with_jquery(".rubric .criterion:visible .display_criterion_points").text.should == '5.5'
    find_with_jquery(".rubric .criterion:visible .rating .points").text.should == '5.5'
  end

  it "should round to 2 decimal places" do
    create_rubric_with_criterion_points "5.249"
    find_with_jquery(".rubric .criterion:visible .display_criterion_points").text.should == '5.25'
  end

  it "should round to an integer when splitting" do
    create_rubric_with_criterion_points "5.5"
    edit_rubric_after_updating

    split_ratings(1, true)

    find_all_with_jquery(".rubric .criterion:visible .rating .points")[1].text.should == '3'
  end

  it "should pick the lower value when splitting without room for an integer" do
    create_rubric_with_criterion_points "0.5"
    edit_rubric_after_updating

    split_ratings(1, true)

    find_all_with_jquery(".rubric .criterion:visible .rating .points").count.should == 3
    find_all_with_jquery(".rubric .criterion:visible .rating .points")[1].text.should == '0'
  end

  it "should ignore outcome rubric lines when calculating total" do
    outcome_with_rubric
    @assignment = @course.assignments.create(:name => 'assignment with rubric')
    @association = @rubric.associate_with(@assignment, @course, :use_for_grading => true, :purpose => 'grading')
    @rubric.data[0][:ignore_for_scoring] = '1'
    @rubric.points_possible = 5
    @rubric.instance_variable_set('@outcomes_changed', true)
    @rubric.save!

    get "/courses/#{@course.id}/rubrics/#{@rubric.id}"
    driver.find_element(:css, '.rubric_total').should include_text "5"

    driver.find_element(:css, '.edit_rubric_link').click
    find_with_jquery(".criterion_points:visible").send_key :backspace
    find_with_jquery(".criterion_points:visible").send_key "10"
    driver.find_element(:css, "#edit_rubric_form .save_button").click
    wait_for_ajaximations
    driver.find_element(:css, '.rubric_total').should include_text "10"

    # check again after reload
    get "/courses/#{@course.id}/rubrics/#{@rubric.id}"
    driver.find_element(:css, '.rubric_total').should include_text "10"
  end

  context "importing" do
    it "should create a allow immediate editing when adding an imported rubric to a new assignment" do
      rubric_association_model(:user => @user, :context => @course, :purpose => "grading")

      @old_course = @course
      @course = nil
      course_with_teacher(:user => @user, :active_all => true)

      @course.merge_into_course(@old_course, :everything => true)
      @assignment = @course.assignments.create!(assignment_valid_attributes.merge({:title => "New Course Assignment"}))

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      driver.find_element(:css, "#right-side-wrapper .add_rubric_link").click
      find_with_jquery(".find_rubric_link:visible").click
      wait_for_ajaximations
      find_with_jquery(".select_rubric_link:visible").click
      wait_for_ajax_requests
      wait_for_animations(500)
      find_with_jquery(".edit_rubric_link:visible").click
      find_with_jquery(".rubric_custom_rating:visible").click
      find_with_jquery(".save_button:visible").click
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
end
