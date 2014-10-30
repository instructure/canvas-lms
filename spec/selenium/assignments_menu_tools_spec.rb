require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignments menu tools" do
  include_examples "in-process server selenium tests"

  context "as a teacher" do
    before do
      course_with_teacher_logged_in(:draft_state => true)
      Account.default.enable_feature!(:lor_for_account)

      @tool = Account.default.context_external_tools.new(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool.assignment_menu = {:url => "http://www.example.com", :text => "Export Assignment"}
      @tool.quiz_menu = {:url => "http://www.example.com", :text => "Export Quiz"}
      @tool.discussion_topic_menu = {:url => "http://www.example.com", :text => "Export DiscussionTopic"}
      @tool.save!

      @assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"], :points_possible => 20)
    end

    it "should show tool launch links in the gear for items on the index" do
      plain_assignment = @assignment

      quiz_assignment = assignment_model(:submission_types => "online_quiz", :course => @course)
      quiz_assignment.reload
      quiz = quiz_assignment.quiz

      topic_assignment = assignment_model(:course => @course, :submission_types => "discussion_topic", :updating_user => @teacher)
      topic_assignment.reload
      topic = topic_assignment.discussion_topic

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations

      gear = f("#assignment_#{plain_assignment.id} .al-trigger")
      gear.click
      link = f("#assignment_#{plain_assignment.id} li a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:assignment_menu))
      expect(link['href']).to eq course_external_tool_url(@course, @tool) + "?launch_type=assignment_menu&assignments[]=#{plain_assignment.id}"

      gear = f("#assignment_#{topic_assignment.id} .al-trigger")
      gear.click
      link = f("#assignment_#{topic_assignment.id} li a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:discussion_topic_menu))
      expect(link['href']).to eq course_external_tool_url(@course, @tool) + "?launch_type=discussion_topic_menu&discussion_topics[]=#{topic.id}"

      gear = f("#assignment_#{quiz_assignment.id} .al-trigger")
      gear.click
      link = f("#assignment_#{quiz_assignment.id} li a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:quiz_menu))
      expect(link['href']).to eq course_external_tool_url(@course, @tool) + "?launch_type=quiz_menu&quizzes[]=#{quiz.id}"
    end

    it "should show tool launch links in the gear for items on the show page" do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      wait_for_ajaximations

      gear = f("#assignment_show .al-trigger")
      gear.click
      link = f("#assignment_show li a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:assignment_menu))
      expect(link['href']).to eq course_external_tool_url(@course, @tool) + "?launch_type=assignment_menu&assignments[]=#{@assignment.id}"
    end
  end
end