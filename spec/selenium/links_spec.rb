require File.expand_path(File.dirname(__FILE__) + '/common')

describe "links", :priority => "2" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  describe "course links" do
    before (:each) do
      get "/courses/#{@course.id}"
    end

    def find_link(link_css)
      link_section = f('#section-tabs')
      link_element = link_section.find_element(:css, link_css)
      link_element
    end

    it "should navigate user to home page after home link is clicked" do
      expect_new_page_load { driver.find_element(:link, 'Home').click }
			expect(f("#course_home_content")).to be_displayed
    end

    it "should navigate user to announcements page after announcements link is clicked" do
      link = find_link('.announcements')
      validate_breadcrumb_link(link, 'Announcements')
    end

    it "should navigate user to assignments page after assignments link is clicked" do
      link = find_link('.assignments')
      validate_breadcrumb_link(link, 'Assignments')
    end

    it "should navigate user to discussions page after discussions link is clicked" do
      link = find_link('.discussions')
      validate_breadcrumb_link(link, 'Discussions')
    end

    it "should navigate user to gradebook page after grades link is clicked" do
      link = find_link('.grades')
      validate_breadcrumb_link(link, 'Grades')
    end

    it "should navigate user to users page after people link is clicked" do
      link = find_link('.people')
      validate_breadcrumb_link(link, 'People')
    end

    it "should navigate user to wiki page after pages link is clicked" do
      link = find_link('.pages')
      validate_breadcrumb_link(link, 'Pages')
    end

    it "should navigate user to files page after files link is clicked" do
      link = find_link('.files')
      validate_breadcrumb_link(link, 'Files')
    end

    it "should navigate user to syllabus page after syllabus link is clicked" do
      link = find_link('.syllabus')
      validate_breadcrumb_link(link, 'Syllabus')
    end

    it "should navigate user to outcomes page after outcomes link is clicked" do
      link = find_link('.outcomes')
      validate_breadcrumb_link(link, 'Outcomes')
    end

    it "should navigate user to quizzes page after quizzes link is clicked" do
      link = find_link('.quizzes')
      validate_breadcrumb_link(link, 'Quizzes')
    end

    it "should navigate user to modules page after modules link is clicked" do
      link = find_link('.modules')
      validate_breadcrumb_link(link, 'Modules')
    end

    it "should navigate user to settings page after settings link is clicked" do
      link = find_link('.settings')
      validate_breadcrumb_link(link, 'Settings')
    end
  end

  describe "dashboard links" do
    before (:each) do
      get "/"
    end

    def find_dashboard_link(link_holder_css, link_text)
      link_section = f(link_holder_css)
      link_element = link_section.find_element(:link, link_text)
      link_element
    end

    describe "right side links" do

      it "should navigate user to conversations page after inbox link is clicked" do
        expect_new_page_load { find_dashboard_link('#identity', 'Inbox').click }
      end

      it "should navigate user to user settings page after settings link is clicked" do
        link = find_dashboard_link('#identity', 'Settings')
        expect_new_page_load { link.click }
      end
    end

    describe "left side links" do

      it "should navigate user to main page after canvas logo link is clicked" do
        f('#header-logo')
        expect_new_page_load { f('#header-logo').click }
        expect(driver.current_url).to eq f('#header-logo').attribute('href')
      end

      it "should navigate user to assignments page after assignments link is clicked" do
        validate_breadcrumb_link(f('#assignments_menu_item a'), 'Assignments')
      end

      it "should navigate user to gradebook page after grades link is clicked" do
        validate_breadcrumb_link(f('#grades_menu_item a'), 'Grades')
      end

      it "should navigate user to the calendar page after calender link is clicked" do
        expect_new_page_load { driver.find_element(:link, 'Calendar').click }
				expect(f('.calendar_header')).to be_displayed
			end
		end
  end
end
