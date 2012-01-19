require File.expand_path(File.dirname(__FILE__) + '/common')

describe "Wiki pages and Tiny WYSIWYG editor" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  it "should add bold and italic text to the rce" do
    skip_if_ie('Out of memory')
    get "/courses/#{@course.id}/wiki"

    wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
    driver.find_element(:css, '.mceIcon.mce_bold').click
    driver.find_element(:css, '.mceIcon.mce_italic').click
    first_text = 'This is my text.'

    type_in_tiny('#wiki_page_body', first_text)
    in_frame "wiki_page_body_ifr" do
      driver.find_element(:id, 'tinymce').should include_text(first_text)
    end
    #make sure each view uses the proper format
    driver.find_element(:css, '.wiki_switch_views_link').click
    driver.execute_script("return $('#wiki_page_body').val()").should include '<p><em><strong>'
    driver.find_element(:css, '.wiki_switch_views_link').click
    in_frame "wiki_page_body_ifr" do
      driver.find_element(:id, 'tinymce').should_not include_text('<p>')
    end

    driver.find_element(:id, 'wiki_page_submit').click
    wait_for_ajax_requests
    get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
    wait_for_ajax_requests

    driver.page_source.should match(/<p><em><strong>This is my text\./)
  end

  it "should add a quiz to the rce" do
    #create test quiz
    @context = @course
    quiz = quiz_model
    quiz.generate_quiz_data
    quiz.save!

    get "/courses/#{@course.id}/wiki"
    # add quiz to rce
    accordion = driver.find_element(:css, '#editor_tabs #pages_accordion')
    accordion.find_element(:link, I18n.t('links_to.quizzes', 'Quizzes')).click
    keep_trying_until { accordion.find_element(:link, quiz.title).should be_displayed }
    accordion.find_element(:link, quiz.title).click
    in_frame "wiki_page_body_ifr" do
      driver.find_element(:id, 'tinymce').should include_text(quiz.title)
    end

    driver.find_element(:id, 'wiki_page_submit').click
    wait_for_ajax_requests
    get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
    wait_for_ajax_requests

    driver.find_element(:css, '#wiki_body').find_element(:link, quiz.title).should be_displayed
  end

  it "should add an assignment to the rce" do
    assignment_name = 'first assignment'
    @assignment = @course.assignments.create(:name => assignment_name)
    get "/courses/#{@course.id}/wiki"

    driver.find_element(:css, '.wiki_switch_views_link').click
    clear_rce
    driver.find_element(:css, '.wiki_switch_views_link').click
    #check assigment accordion
    accordion = driver.find_element(:css, '#editor_tabs #pages_accordion')
    accordion.find_element(:link, I18n.t('links_to.assignments', 'Assignments')).click
    keep_trying_until { accordion.find_element(:link, assignment_name).should be_displayed }
    accordion.find_element(:link, assignment_name).click
    in_frame "wiki_page_body_ifr" do
      driver.find_element(:id, 'tinymce').should include_text(assignment_name)
    end

    driver.find_element(:id, 'wiki_page_submit').click
    wait_for_ajax_requests
    get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
    wait_for_ajax_requests

    driver.find_element(:css, '#wiki_body').find_element(:link, assignment_name).should be_displayed
  end

  it "should add an equation to the rce" do
    skip_if_ie('Out of memory')
    get "/courses/#{@course.id}/wiki"

    driver.find_element(:css, '.mce_instructure_equation').click
    wait_for_animations
    driver.find_element(:id, 'instructure_equation_prompt')
    misc_tab = driver.find_element(:css, '.mathquill-tab-bar > li:last-child a')
    driver.action.move_to(misc_tab).perform
    driver.find_element(:css, '#Misc_tab li:nth-child(35) a').click
    basic_tab = driver.find_element(:css, '.mathquill-tab-bar > li:first-child a')
    driver.action.move_to(basic_tab).perform
    driver.find_element(:css, '#Basic_tab li:nth-child(27) a').click
    driver.find_element(:id, 'instructure_equation_prompt_form').submit
    in_frame "wiki_page_body_ifr" do
      driver.find_element(:css, '#tinymce img').should be_displayed
    end

    driver.find_element(:id, 'wiki_page_submit').click
    wait_for_ajax_requests
    get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
    wait_for_ajax_requests

    check_image(driver.find_element(:css, '#wiki_body img'))
  end

  it "should display record video dialog" do
    skip_if_ie('Out of memory')
    stub_kaltura
    get "/courses/#{@course.id}/wiki"

    driver.find_element(:css, '.mce_instructure_record').click
    keep_trying_until { driver.find_element(:id, 'record_media_tab').should be_displayed }
    driver.find_element(:css, '#media_comment_dialog a[href="#upload_media_tab"]').click
    driver.find_element(:css, '#media_comment_dialog #audio_upload').should be_displayed
    close_visible_dialog
    driver.find_element(:id, 'media_comment_dialog').should_not be_displayed
  end

  it "should resize the WYSIWYG editor height gracefully" do
    skip_if_ie('Out of memory')
    wiki_page_tools_file_tree_setup
    wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
    make_full_screen
    # TODO: there's an issue where we can drag the box smaller than it's supposed to be on the first resize.
    # Until we can track that down, first we do a fake drag to make sure the rest of the resizing machinery
    # works.
    driver.action.drag_and_drop_by(driver.find_element(:class, 'editor_box_resizer'), 0, -1).perform
    resizer_to = 1 - driver.find_element(:class, 'editor_box_resizer').location.y
    # drag the resizer way up to the top of the screen (to make the wysiwyg the shortest it will go)
    keep_trying_until do
      driver.action.drag_and_drop_by(driver.find_element(:class, 'editor_box_resizer'), 0, resizer_to).perform
      sleep 3
      driver.execute_script("return $('#wiki_page_body_ifr').height()").should eql(200)
    end
    driver.find_element(:class, 'editor_box_resizer').attribute('style').should be_blank

    # now move it down 30px from 200px high
    keep_trying_until { driver.action.drag_and_drop_by(driver.find_element(:class, 'editor_box_resizer'), 0, 30).perform; true }
    driver.execute_script("return $('#wiki_page_body_ifr').height()").should be_close(230, 5)
    driver.find_element(:class, 'editor_box_resizer').attribute('style').should be_blank
    resize_screen_to_default
  end

  it "should handle table borders correctly" do
    skip_if_ie('Out of memory')
    get "/courses/#{@course.id}/wiki"

    def check_table(attributes = {})
      # clear out whatever is in the editor
      driver.execute_script("$('#wiki_page_body_ifr')[0].contentDocument.body.innerHTML =''")

      # this is the only way I know to actually trigger the insert table dialog to open
      # listening to the click events on the button in the menu did not work
      driver.execute_script("$('#wiki_page_body').editorBox('execute', 'mceInsertTable')")

      # the iframe will be created with an id of mce_<some number>_ifr
      table_iframe_id = keep_trying_until { driver.find_elements(:css, 'iframe').map { |f| f['id'] }.detect { |w| w =~ /mce_\d+_ifr/ } }
      table_iframe_id.should_not be_nil
      in_frame(table_iframe_id) do
        attributes.each do |attribute, value|
          tab_to_show = attribute == :bordercolor ? 'advanced' : 'general'
          keep_trying_until do
            driver.execute_script "mcTabs.displayTab('#{tab_to_show}_tab', '#{tab_to_show}_panel')"
            set_value(driver.find_element(:id, attribute), value)
            true
          end
        end
        driver.find_element(:id, 'insert').click
      end
      in_frame "wiki_page_body_ifr" do
        table = driver.find_element(:css, 'table')
        attributes.each do |attribute, value|
          (table[attribute].should == value.to_s) if (value && (attribute != :bordercolor))
        end
        [:width, :color].each do |part|
          [:top, :right, :bottom, :left].each do |side|
            expected_value = attributes[{:width => :border, :color => :bordercolor}[part]] || {:width => 1, :color => '#888888'}[part]
            if expected_value.is_a?(Numeric)
              expected_value = 1 if expected_value == 0
              expected_value = "#{expected_value}px"
            end
            table.style("border-#{side}-#{part}").should == expected_value
          end
        end
      end
      # TODO: test how it looks after page is saved.
      # driver.find_element(:id, :wiki_page_submit).click

    end

    # check with default settings
    check_table()

    check_table(
        :align => 'center',
        :cellpadding => 5,
        :cellspacing => 6,
        :border => 7,
        :bordercolor => '#ff0000'
    )
    check_table(
        :align => 'center',
        :cellpadding => 0,
        :cellspacing => 0,
        :border => 0
    )
  end
end
