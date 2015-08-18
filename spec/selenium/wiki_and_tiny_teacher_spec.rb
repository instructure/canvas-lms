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

      get "/courses/#{@course.id}/pages/front-page/edit"
      # add quiz to rce
      accordion = f('#pages_accordion')
      accordion.find_element(:link, I18n.t('links_to.quizzes', 'Quizzes')).click
      keep_trying_until { expect(accordion.find_element(:link, quiz.title)).to be_displayed }
      keep_trying_until do
        accordion.find_element(:link, quiz.title).click
        in_frame wiki_page_body_ifr_id do
          expect(f('#tinymce')).to include_text(quiz.title)
        end
      end

      f('form.edit-form button.submit').click
      wait_for_ajax_requests

      expect(f('#wiki_page_show').find_element(:link, quiz.title)).to be_displayed
    end

    it "should add an assignment to the rce" do
      assignment_name = 'first assignment'
      @assignment = @course.assignments.create(:name => assignment_name)
      get "/courses/#{@course.id}/pages/front-page/edit"

      fj('a.switch_views:visible').click
      clear_wiki_rce
      fj('a.switch_views:visible').click
      #check assignment accordion
      accordion = f('#pages_accordion')
      accordion.find_element(:link, I18n.t('links_to.assignments', 'Assignments')).click
      keep_trying_until { expect(accordion.find_element(:link, assignment_name)).to be_displayed }
      accordion.find_element(:link, assignment_name).click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce')).to include_text(assignment_name)
      end

      f('form.edit-form button.submit').click
      wait_for_ajax_requests
      expect(f('#wiki_page_show').find_element(:css, "a[title='#{assignment_name}']")).to be_displayed
    end

    ['Only teachers', 'Teachers and students', 'Anyone'].each_with_index do |permission, i|
      it "should validate correct permissions for #{permission}" do
        title = "test_page"
        unpublished = false
        edit_roles = "public"
        validations = ["teachers", "teachers,students", "teachers,students,public"]

        p = create_wiki_page(title, unpublished, edit_roles)
        get "/courses/#{@course.id}/pages/#{p.title}/edit"

        keep_trying_until { expect(f("form.edit-form .edit-content")).to be_displayed }

        click_option("select[name=\"editing_roles\"]", permission)
        #form id is set like this because the id iterator is in the form but im not sure how to grab it directly before committed to the DB with the save
        f('form.edit-form button.submit').click

        wait_for_ajaximations
        p.reload
        expect(p.editing_roles).to eq validations[i]
      end
    end

    it "should take user to page history" do
      title = "test_page"
      unpublished = false
      edit_roles = "public"

      p = create_wiki_page(title, unpublished, edit_roles)
      #sets body
      p.update_attributes(:body => "test")

      get "/courses/#{@course.id}/pages/#{p.title}"

      wait_for_ajaximations

      f('.header-bar-right .al-trigger').click
      expect_new_page_load { f('.view_page_history').click }

      expect(ff('.revision').length).to eq 2
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

      get "/courses/#{@course.id}/pages/#{p.title}/revisions"
      wait_for_ajaximations

      ff('.revision')[1].click
      wait_for_ajaximations

      expect(f('.show-content').text).to include body

      f('.revision .restore-link').click
      wait_for_ajaximations

      p.reload
      expect(p.body).to eq body
    end
  end
end
