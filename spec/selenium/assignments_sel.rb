require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignment selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should properly show rubric criterion details for learning outcomes" do
    course_with_student_logged_in
    
    @assignment = @course.assignments.create(:name => 'assignment with rubric')
    @outcome = @course.learning_outcomes.create!(:description => '<p>This is <b>awesome</b>.</p>')
    @rubric = Rubric.new(:context => @course)
    @rubric.data = [
      {
        :points => 3,
        :description => "Outcome row",
        :long_description => @outcome.description,
        :id => 1,
        :ratings => [
          {
            :points => 3,
            :description => "Rockin'",
            :criterion_id => 1,
            :id => 2
          },
          {
            :points => 0,
            :description => "Lame",
            :criterion_id => 1,
            :id => 3
          }
        ],
        :learning_outcome_id => @outcome.id
      }
    ]
    @rubric.instance_variable_set('@outcomes_changed', true)
    @rubric.save!
    
    @rubric.associate_with(@assignment, @course, :purpose => 'grading')
    
    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    
    driver.find_element(:css, ".criterion_description .long_description_link").click
    el = driver.find_element(:css, ".ui-dialog div.long_description").text.should == "This is awesome."
  end
end
