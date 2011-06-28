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
    make_full_screen
    resizer = driver.find_element(:class, 'editor_box_resizer')
    # drag the resizer way up to the top of the screen (to make the wysiwyg the shortest it will go)
    resizer.drag_and_drop_by(0, -99999999)
    resizer.drag_and_drop_by(0, -99999999)
    driver.execute_script("return $('#wiki_page_body_ifr').height()").should eql(200)
    resizer.attribute('style').should be_blank

    # now move it down 300px from 200px high
    resizer.drag_and_drop_by(0, 300)
    driver.execute_script("return $('#wiki_page_body_ifr').height()").should eql(500)
    resizer.attribute('style').should be_blank
  end
  
end

