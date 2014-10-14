require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe "public courses" do
  include_examples "in-process server selenium tests"

  def ensure_logged_out
    destroy_session(true)
  end

  def validate_selector_displayed(selector1, selector2)
    if public_course.feature_enabled?(:draft_state)
      expect(f(selector1)).to be_displayed
    else
      expect(f(selector2)).to be_displayed
    end
  end

  shared_examples_for 'a public course' do

    it "should display wiki content" do
      title = "foo"
      public_course.wiki.wiki_pages.create!(:title => title, :body => "bar")

      get "/courses/#{public_course.id}/wiki/#{title}"
      expect(f('.user_content')).not_to be_nil
    end

    it "should display course files" do
      get "/courses/#{public_course.id}/files"
      expect(f('#files_structure_list')).to be_displayed
    end

    it "should display course syllabus" do
      get "/courses/#{public_course.id}/assignments/syllabus"
      expect(f('#course_syllabus')).to be_displayed
    end

    it "should display assignments" do
      public_course.assignments.create!(:name => 'assignment 1')
      get "/courses/#{public_course.id}/assignments"
      validate_selector_displayed('.assignment.search_show', '#assignments_for_student')
    end

    it "should display modules list" do
      @module = public_course.context_modules.create!(:name => "module 1")
      @assignment = public_course.assignments.create!(:name => 'assignment 1', :assignment_group => @assignment_group)
      @module.add_item :type => 'assignment', :id => @assignment.id
      get "/courses/#{public_course.id}/modules"
      validate_selector_displayed('.item-group-container', '.item_name')
    end

    it "should display quizzes list" do
      course_quiz(active=true)
      get "/courses/#{public_course.id}/quizzes"
      validate_selector_displayed('#assignment-quizzes', '.quiz_list')
    end

    #this is currently broken - logged out users should not be able to access this page
    it "should goes to conferences page" do
      PluginSetting.create!(:name => "wimba", :settings =>
          {"domain" => "wimba.instructure.com"})
      get "/courses/#{public_course.id}/conferences"
      expect(f('#new-conference-list')).to be_displayed
    end

    #this is currently broken - logged out users should not be able to access this page
    it "should display collaborations list" do
      PluginSetting.new(:name => 'etherpad', :settings => {}).save!
      get "/courses/#{public_course.id}/collaborations"
      expect(f('#collaborations')).to be_displayed
    end

    it "should should prompt must be logged in message when accessing permission based pages" do
      get "/grades"
      assert_flash_warning_message /You must be logged in to access this page/
      expect(driver.current_url).to eq app_host + "/login"
    end

  end

  describe 'course' do
    before :each do
      ensure_logged_out
    end

    context 'with draft state disabled' do
      let!(:public_course) do
        course(active_course: true)
        @course.is_public = true
        @course.save!
        @course
      end

      include_examples 'a public course'
    end

    context 'with draft state enabled' do
      let!(:public_course) do
        course(active_course: true, draft_state: true)
        @course.is_public = true
        @course.save!
        @course
      end

      include_examples 'a public course'
    end
  end
end
