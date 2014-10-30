require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe "quizzes" do

  include AssignmentOverridesSeleniumHelper
  include_examples "quizzes selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    @course.update_attributes(:name => 'teacher course')
    @course.save!
    @course.reload
    course_with_teacher_logged_in
    Account.default.enable_feature!(:lor_for_account)

    @tool = Account.default.context_external_tools.new(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
    @tool.quiz_menu = {:url => "http://www.example.com", :text => "Export Quiz"}
    @tool.save!

    @quiz = @course.quizzes.create!(:title => "score 10")
  end

  it "should show tool launch links in the gear for items on the index" do
    get "/courses/#{@course.id}/quizzes"
    wait_for_ajaximations

    gear = f("#summary_quiz_#{@quiz.id} .al-trigger")
    gear.click
    link = f("#summary_quiz_#{@quiz.id} li a.menu_tool_link")
    expect(link).to be_displayed
    expect(link.text).to match_ignoring_whitespace(@tool.label_for(:quiz_menu))
    expect(link['href']).to eq course_external_tool_url(@course, @tool) + "?launch_type=quiz_menu&quizzes[]=#{@quiz.id}"
  end

  it "should show tool launch links in the gear for items on the show page" do
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    wait_for_ajaximations

    gear = f("#quiz_show .al-trigger")
    gear.click
    link = f("#quiz_show li a.menu_tool_link")
    expect(link).to be_displayed
    expect(link.text).to match_ignoring_whitespace(@tool.label_for(:quiz_menu))
    expect(link['href']).to eq course_external_tool_url(@course, @tool) + "?launch_type=quiz_menu&quizzes[]=#{@quiz.id}"
  end

end
