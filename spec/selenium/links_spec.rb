require File.expand_path(File.dirname(__FILE__) + '/common')

describe "links" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  describe "course links" do
    before (:each) do
      get "/courses/#{@course.id}"
    end

    def find_link(link_css)
      link_section = driver.find_element(:id, 'section-tabs')
      link_element = link_section.find_element(:css, link_css)
      link_element
    end

    it "should navigate user to home page after home link is clicked" do
      expect_new_page_load { driver.find_element(:link, 'Home').click }
      driver.find_element(:id, 'breadcrumbs').should include_text('Unnamed')
    end

    it "should navigate user to announcements page after announcements link is clicked" do
      link = find_link('.announcements')
      validate_link(link, 'Announcements')
    end

    it "should navigate user to assignments page after assignments link is clicked" do
      link = find_link('.assignments')
      validate_link(link, 'Assignments')
    end

    it "should navigate user to discussions page after discussions link is clicked" do
      link = find_link('.discussions')
      validate_link(link, 'Discussions')
    end

    it "should navigate user to gradebook page after grades link is clicked" do
      link = find_link('.grades')
      validate_link(link, 'Grades')
    end

    it "should navigate user to users page after people link is clicked" do
      link = find_link('.people')
      validate_link(link, 'People')
    end

    it "should navigate user to wiki page after pages link is clicked" do
      link = find_link('.pages')
      validate_link(link, 'Pages')
    end

    it "should navigate user to files page after files link is clicked" do
      link = find_link('.files')
      validate_link(link, 'Files')
    end

    it "should navigate user to syllabus page after syllabus link is clicked" do
      link = find_link('.syllabus')
      validate_link(link, 'Syllabus')
    end

    it "should navigate user to outcomes page after outcomes link is clicked" do
      link = find_link('.outcomes')
      validate_link(link, 'Outcomes')
    end

    it "should navigate user to quizzes page after quizzes link is clicked" do
      link = find_link('.quizzes')
      validate_link(link, 'Quizzes')
    end

    it "should navigate user to modules page after modules link is clicked" do
      link = find_link('.modules')
      validate_link(link, 'Modules')
    end

    it "should navigate user to settings page after settings link is clicked" do
      link = find_link('.settings')
      validate_link(link, 'Settings')
    end
  end

  describe "dashboard links" do
    before (:each) do
      get "/"
    end

    def find_dashboard_link(link_holder_css, link_text)
      link_section = driver.find_element(:css, link_holder_css)
      link_element = link_section.find_element(:link, link_text)
      link_element
    end

    describe "right side links" do

      it "should navigate user to conversations page after inbox link is clicked" do
        link = find_dashboard_link('#identity', 'Inbox')
        validate_link(link, 'Conversations')
      end

      it "should navigate user to user profile page after profile link is clicked" do
        link = find_dashboard_link('#identity', 'Profile')
        expect_new_page_load { link.click }
      end
    end

    describe "left side links" do

      it "should navigate user to main page after canvas logo link is clicked" do
        driver.find_element(:id, 'header-logo')
        expect_new_page_load { driver.find_element(:id, 'header-logo').click }
        driver.current_url.should == driver.find_element(:id, 'header-logo').attribute('href')
      end

      it "should navigate user to assignments page after assignments link is clicked" do
        validate_link(driver.find_element(:css, '#assignments_menu_item a'), 'Assignments')
      end

      it "should navigate user to gradebook page after grades link is clicked" do
        validate_link(driver.find_element(:css, '#grades_menu_item a'), 'Grades')
      end

      it "should navigate user to the calendar page after calender link is clicked" do
        validate_link(driver.find_element(:css, '#calendar_menu_item a'), 'My Calendar')
      end
    end
  end
end