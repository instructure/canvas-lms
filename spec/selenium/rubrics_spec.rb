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
    load_simulate_js

    rating = find_all_with_jquery(".rubric .criterion:visible .rating")[idx]
    driver.action.move_to(rating).perform

    if split_left
      driver.execute_script <<-JS
        $ratings = $('.rubric .criterion:visible .rating');
        $($ratings[#{idx}]).addClass('add_column');
        $($ratings[#{idx}]).addClass('add_right');
        $($ratings[#{idx - 1}]).addClass('add_left');
        $($ratings[#{idx}]).simulate("click", {});
      JS
    else
      driver.execute_script <<-JS
        $ratings = $('.rubric .criterion:visible .rating');
        $($ratings[#{idx}]).addClass('add_column');
        $($ratings[#{idx+1}]).addClass('add_right');
        $($ratings[#{idx}]).addClass('add_left');
        $($ratings[#{idx}]).simulate("click", {});
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
end
