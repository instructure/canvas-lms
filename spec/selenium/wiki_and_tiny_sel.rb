require File.expand_path(File.dirname(__FILE__) + '/common')

describe "Wiki pages and Tiny WYSIWYG editor" do
  # it_should_behave_like "forked server selenium tests"
  it_should_behave_like "in-process server selenium tests"

  before(:all) do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/wiki"
  end
  
  it "should not load the files or images until you click on the appropriate tabs in the wikiSidebar" do
    driver.find_element(:id, 'tree1').text.should be_empty
    driver.find_element(:css, '#editor_tabs_3 .image_list').attribute('class').should_not match(/initialized/)
    
    driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(2) a').click
    
    keep_trying_until { driver.find_element(:id, 'tree1').text }
    driver.find_element(:css, '#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
    driver.find_element(:css, '#editor_tabs_3 .image_list').attribute('class').should match(/initialized/)
  end
  
  it "should resize the WYSIWYG editor height gracefully" do
    wait_for_tiny(keep_trying_until { driver.find_element(:css, "form#new_wiki_page") })
    make_full_screen
    resizer = driver.find_element(:class, 'editor_box_resizer')
    # TODO: there's an issue where we can drag the box smaller than it's supposed to be on the first resize.
    # Until we can track that down, first we do a fake drag to make sure the rest of the resizing machinery
    # works.
    driver.action.drag_and_drop_by(resizer, 0, -1).perform
    # drag the resizer way up to the top of the screen (to make the wysiwyg the shortest it will go)
    driver.action.drag_and_drop_by(resizer, 0, -1500).perform
    keep_trying_until { driver.execute_script("return $('#wiki_page_body_ifr').height()").should eql(200) }
    resizer.attribute('style').should be_blank

    # now move it down 30px from 200px high
    resizer = driver.find_element(:class, 'editor_box_resizer')
    keep_trying_until { driver.action.drag_and_drop_by(resizer, 0, 30).perform; true }
    driver.execute_script("return $('#wiki_page_body_ifr').height()").should eql(230)
    resizer.attribute('style').should be_blank
  end
  
end

