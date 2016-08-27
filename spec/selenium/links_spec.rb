require File.expand_path(File.dirname(__FILE__) + '/common')

describe "links", priority: "2" do
  include_context "in-process server selenium tests"

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
      expect_new_page_load { fln('Home').click }
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

    context "right side links" do

      it "should navigate user to conversations page after inbox link is clicked" do
        expect_new_page_load { fj(ENV['CANVAS_FORCE_USE_NEW_STYLES'] ? '#global_nav_conversations_link' : '#identity a:contains("Inbox")').click}
        expect(f("i.icon-email")).to be_displayed
      end

      it "should navigate user to user settings page after settings link is clicked" do
        expect_new_page_load {
          if ENV['CANVAS_FORCE_USE_NEW_STYLES']
            f('#global_nav_profile_link').click
            fj('a.ic-NavMenu-list-item__link:contains("Settings")').click
          else
            fj('#identity a:contains("Settings")').click
          end
        }
        expect(f("a.edit_settings_link")).to be_displayed
      end
    end

    context "global nav links" do

      it "should navigate user to main page after canvas logo link is clicked" do
        expect_new_page_load { f(ENV['CANVAS_FORCE_USE_NEW_STYLES'] ? '#header .ic-app-header__logomark' : '#header-logo').click }
        expect(driver.current_url).to eq dashboard_url
      end

      it "should navigate user to gradebook page after grades link is clicked" do
        skip('there is no global "grades" link in the header in NewUI') if ENV['CANVAS_FORCE_USE_NEW_STYLES']
        validate_breadcrumb_link(f('#grades_menu_item a'), 'Grades')
      end

      it "should navigate user to the calendar page after calender link is clicked" do
        expect_new_page_load { fln('Calendar').click }
        expect(f('.calendar_header')).to be_displayed
      end
    end
  end
end
