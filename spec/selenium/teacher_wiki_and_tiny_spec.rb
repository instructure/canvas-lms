require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Wiki pages and Tiny WYSIWYG editor" do
  include_examples "in-process server selenium tests"

  context "as a teacher" do

    before (:each) do
      course_with_teacher_logged_in
    end

    it "should add a quiz to the rce" do
      #create test quiz
      @context = @course
      quiz = quiz_model
      quiz.generate_quiz_data
      quiz.save!

      get "/courses/#{@course.id}/wiki"
      # add quiz to rce
      accordion = f('#pages_accordion')
      accordion.find_element(:link, I18n.t('links_to.quizzes', 'Quizzes')).click
      keep_trying_until { expect(accordion.find_element(:link, quiz.title)).to be_displayed }
      keep_trying_until do
        accordion.find_element(:link, quiz.title).click
        in_frame "wiki_page_body_ifr" do
          expect(f('#tinymce')).to include_text(quiz.title)
        end
      end

      submit_form('#new_wiki_page')
      wait_for_ajax_requests
      get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
      wait_for_ajax_requests

      expect(f('#wiki_body').find_element(:link, quiz.title)).to be_displayed
    end

    it "should add an assignment to the rce" do
      assignment_name = 'first assignment'
      @assignment = @course.assignments.create(:name => assignment_name)
      get "/courses/#{@course.id}/wiki"

      fj('.wiki_switch_views_link:visible').click
      clear_wiki_rce
      fj('.wiki_switch_views_link:visible').click
      #check assignment accordion
      accordion = f('#pages_accordion')
      accordion.find_element(:link, I18n.t('links_to.assignments', 'Assignments')).click
      keep_trying_until { expect(accordion.find_element(:link, assignment_name)).to be_displayed }
      accordion.find_element(:link, assignment_name).click
      in_frame "wiki_page_body_ifr" do
        expect(f('#tinymce')).to include_text(assignment_name)
      end

      submit_form('#new_wiki_page')
      wait_for_ajax_requests
      get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
      wait_for_ajax_requests
      expect(f('#wiki_body').find_element(:css, "a[title='#{assignment_name}']")).to be_displayed
    end

    ['Only Teachers', 'Teacher and Students', 'Anyone'].each_with_index do |permission, i|
      it "should validate correct permissions for #{permission}" do
        title = "test_page"
        title2 = "test_page2"
        unpublished = false
        edit_roles = "public"
        validations = ["teachers", "teachers,students", "teachers,students,public"]

        p = create_wiki_page(title, unpublished, edit_roles)
        get "/courses/#{@course.id}/wiki/#{p.title}"

        keep_trying_until { expect(f("#wiki_page_new")).to be_displayed }

        f('#wiki_page_new .new').click
        f('#right-side #wiki_page_title').send_keys(title2)
        submit_form("#add_wiki_page_form")

        keep_trying_until { expect(f("#wiki_page_editing_roles")).to be_displayed }

        click_option("#wiki_page_editing_roles", permission)
        #form id is set like this because the id iterator is in the form but im not sure how to grab it directly before committed to the DB with the save
        submit_form("#edit_wiki_page_#{p.id + 1}")
        wait_for_ajaximations
        expect(@course.wiki.wiki_pages.last.editing_roles).to eq validations[i]
      end
    end

    it "should take user to page history" do
      title = "test_page"
      unpublished = false
      edit_roles = "public"

      p = create_wiki_page(title, unpublished, edit_roles)
      #sets body
      p.update_attributes(:body => "test")

      get "/courses/#{@course.id}/wiki/#{p.title}"

      keep_trying_until { expect(f("#page_history")).to be_displayed }
      f('#page_history').click

      expect(ff('a[title]').length).to eq 2
    end


    it "should load the previous version of the page and roll-back page" do
      title = "test_page"
      unpublished = false
      edit_roles = "public"
      body = "test"

      p = create_wiki_page(title, unpublished, edit_roles)
      #sets body and then resets it for history verification
      p.update_attributes(:body => body)
      p.update_attributes(:body => "sample")

      get "/courses/#{@course.id}/wiki/#{p.title}"
      keep_trying_until { expect(f("#page_history")).to be_displayed }

      f('#page_history').click
      ff('a[title]')[1].click

      expect(f('#wiki_body').text).to eq body

      submit_form(".edit_version")
      wait_for_ajax_requests

      assert_flash_notice_message /successfully rolled-back/
      expect(f('#wiki_body').text).to eq body
    end

    it "should restore the latest version of the page" do
      title = "test_page"
      unpublished = false
      edit_roles = "public"

      p = create_wiki_page(title, unpublished, edit_roles)
      #sets body and then resets it for history verification
      p.update_attributes(:body => "test")
      p.update_attributes(:body => "sample")

      old_version = p.versions[2].id

      get "/courses/#{@course.id}/wiki/#{p.title}/revisions/#{old_version}"
      keep_trying_until { expect(f('.forward')).to be_displayed }

      #button to restore to most recent version
      f('.forward').click
      wait_for_ajax_requests

      expect(f('#wiki_body').text).to eq "sample"
    end

    it "should take user back to revision history" do
      title = "test_page"
      unpublished = false
      edit_roles = "public"

      p = create_wiki_page(title, unpublished, edit_roles)
      #sets body and then resets it for history verification
      p.update_attributes(:body => "test")
      version = p.versions[1].id

      get "/courses/#{@course.id}/wiki/#{p.title}/revisions/#{version}"
      keep_trying_until { expect(f('.history')).to be_displayed }

      f('.history').click
      wait_for_ajax_requests

      expect(ff('a[title]').length).to eq 2
    end
  end
end
