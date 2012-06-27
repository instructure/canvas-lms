require File.expand_path(File.dirname(__FILE__) + '/../common')

shared_examples_for "rubric tests" do
  it_should_behave_like "in-process server selenium tests"
  before (:each) do
    who_to_login == 'teacher' ? course_with_teacher_logged_in : course_with_admin_logged_in
  end

  def create_rubric_with_criterion_points(points)
    get rubric_url

    f("#right-side-wrapper .add_rubric_link").click
    criterion_points = f("#criterion_1 .criterion_points")
    set_value(criterion_points, points.to_s)
    criterion_points.send_keys(:return)
    submit_form('#edit_rubric_form')
    wait_for_ajaximations
  end

  def edit_rubric_after_updating
    fj(".rubric .edit_rubric_link:visible").click
    driver.find_element(:tag_name, "body").click
  end

  # should be in editing mode before calling
  def split_ratings(idx)
    rating = ffj(".rubric .criterion:visible .rating")[idx]
    driver.action.move_to(rating).perform

    driver.execute_script <<-JS
            var $rating = $('.rubric .criterion:visible .rating:eq(#{idx})');
            $rating.addClass('add_column add_right');
            $rating.prev().addClass('add_left');
            $rating.click();
    JS
  end

  it "should edit a rubric" do
    edit_title = 'edited rubric'
    create_rubric_with_criterion_points "5"
    rubric = Rubric.last
    f('.edit_rubric_link').click
    replace_content(ff("#rubric_#{rubric.id} .rubric_title input")[1], edit_title)
    submit_form(ff("#rubric_#{rubric.id} #edit_rubric_form")[2])
    wait_for_ajaximations
    rubric.reload
    rubric.title.should == edit_title
    f('.rubric_title .title').text.should == edit_title
  end

  it "should delete a rubric" do
    create_rubric_with_criterion_points "5"
    f('.delete_rubric_link').click
    driver.switch_to.alert.accept
    wait_for_ajaximations
    Rubric.last.workflow_state.should == 'deleted'
    ff('#rubrics .rubric').each { |rubric| rubric.should_not be_displayed }
  end

  it "should allow fractional points" do
    create_rubric_with_criterion_points "5.5"
    fj(".rubric .criterion:visible .display_criterion_points").text.should == '5.5'
    fj(".rubric .criterion:visible .rating .points").text.should == '5.5'
  end

  it "should round to 2 decimal places" do
    create_rubric_with_criterion_points "5.249"
    fj(".rubric .criterion:visible .display_criterion_points").text.should == '5.25'
  end

  it "should round to an integer when splitting" do
    create_rubric_with_criterion_points "5.5"
    edit_rubric_after_updating

    split_ratings(1)

    ffj(".rubric .criterion:visible .rating .points")[1].text.should == '3'
  end

  it "should pick the lower value when splitting without room for an integer" do
    create_rubric_with_criterion_points "0.5"
    edit_rubric_after_updating

    split_ratings(1)

    ffj(".rubric .criterion:visible .rating .points").count.should == 3
    ffj(".rubric .criterion:visible .rating .points")[1].text.should == '0'
  end
end
