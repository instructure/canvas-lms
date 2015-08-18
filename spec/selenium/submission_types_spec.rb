require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignments_common')

describe "assignments" do
  include_examples "in-process server selenium tests"

  def click_away_accept_alert
    f('#section-tabs .home').click
    driver.switch_to.alert.accept # doing this step and the step above to avoid the alert from failing other selenium specs
  end

  def update_assignment_attributes(assignment, attribute, values, click_submit_link = true)
    assignment.update_attributes(attribute => values)
    get "/courses/#{@course.id}/assignments/#{assignment.id}"
    f('.submit_assignment_link').click if click_submit_link
  end

  context "as a student" do
    before (:each) do
      course_with_student_logged_in
    end

    before do
      @due_date = Time.now.utc + 2.days
      @assignment = @course.assignments.create!(:title => 'default assignment', :name => 'default assignment', :due_at => @due_date)
    end

    it "should validate an assignment created with the type of discussion" do
      @assignment.update_attributes(:submission_types => 'discussion_topic')

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(driver.current_url).to match %r{/courses/\d+/discussion_topics/\d+}
      expect(f('h1.discussion-title')).to include_text(@assignment.title)
    end

    it "should validate an assignment created with the type of not graded" do
      @assignment.update_attributes(:submission_types => 'not_graded')
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(f('.submit_assignment_link')).to be_nil
    end

    it "should validate on paper submission assignment type" do
      update_assignment_attributes(@assignment, :submission_types, 'on_paper', false)
      expect(f('.submit_assignment_link')).to be_nil
    end

    it "should validate no submission assignment type" do
      update_assignment_attributes(@assignment, :submission_types, nil, false)
      expect(f('.submit_assignment_link')).to be_nil
    end

    it "should validate that website url submissions are allowed" do
      update_assignment_attributes(@assignment, :submission_types, 'online_url')
      expect(f('#submission_url')).to be_displayed
    end

    it "should validate that text entry submissions are allowed" do
      update_assignment_attributes(@assignment, :submission_types, 'online_text_entry')
      expect(f('.submit_online_text_entry_option')).to be_displayed
    end

    it "should allow an assignment with all 3 online submission types" do
      update_assignment_attributes(@assignment, :submission_types, 'online_text_entry, online_url, online_upload')
      expect(f('.submit_online_text_entry_option')).to be_displayed
      expect(f('.submit_online_url_option')).to be_displayed
      expect(f('.submit_online_upload_option')).to be_displayed
    end

    it "should validate an assignment created with the type of external tool" do
      t1 = factory_with_protected_attributes(@course.context_external_tools, :url => "http://www.example.com/", :shared_secret => 'test123', :consumer_key => 'test123', :name => 'tool 1')
      external_tool_assignment = assignment_model(:course => @course, :title => "test2", :submission_types => 'external_tool')
      external_tool_assignment.create_external_tool_tag(:url => t1.url)
      external_tool_assignment.external_tool_tag.update_attribute(:content_type, 'ContextExternalTool')
      get "/courses/#{@course.id}/assignments/#{external_tool_assignment.id}"

      expect(f('#tool_content')).to be_displayed
    end
  end

end