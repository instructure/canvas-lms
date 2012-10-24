require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Wiki pages and Tiny WYSIWYG editor Files" do
  it_should_behave_like "wiki and tiny selenium tests"

  def add_file_to_rce
    wiki_page_tools_file_tree_setup
    wait_for_tiny(keep_trying_until { f("#new_wiki_page") })
    f('.wiki_switch_views_link').click
    wiki_page_body = clear_wiki_rce
    f('.wiki_switch_views_link').click
    f('#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
    root_folders = @tree1.find_elements(:css, 'li.folder')
    root_folders.first.find_element(:css, '.sign.plus').click
    wait_for_ajaximations
    root_folders.first.find_elements(:css, '.file.text').length.should == 1
    root_folders.first.find_elements(:css, '.file.text span').first.click

    in_frame "wiki_page_body_ifr" do
      f('#tinymce').should include_text('txt')
    end
    f('.wiki_switch_views_link').click
    find_css_in_string(wiki_page_body[:value], '.instructure_file_link').should_not be_empty
    submit_form('#new_wiki_page')
    wait_for_ajax_requests
    get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
    wait_for_ajax_requests
  end


  context "wiki and tiny files as a student" do
    before (:each) do
      course(:active_all => true, :name => 'wiki course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      @teacher = user_with_pseudonym(:active_user => true, :username => 'teacher@example.com', :name => 'teacher@example.com', :password => 'asdfasdf')
      @course.enroll_student(@student).accept
      @course.enroll_teacher(@teacher).accept
    end

    it "should add a file to the page and validate a student can see it" do
      login_as(@teacher.name)

      add_file_to_rce
      login_as(@student.name)
      get "/courses/#{@course.id}/wiki"
      fj('a[title="text_file.txt"]').should be_displayed
      #check_file would be good to do here but the src on the file in the wiki body is messed up
    end
  end
end
