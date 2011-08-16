require File.expand_path(File.dirname(__FILE__) + '/common')

describe "eportfolios" do
  it_should_behave_like "in-process server selenium tests"

  it "should have a working flickr search dialog" do
    course_with_student_logged_in
    
    get "/dashboard/eportfolios"
    driver.find_element(:css, ".add_eportfolio_link").click
    sleep 1
    driver.find_element(:id, "eportfolio_submit").click
    wait_for_ajax_requests
    keep_trying_until { 
      driver.find_element(:css, "#page_list a.page_url").click
      driver.find_element(:css, "#page_sidebar .edit_content_link")
    }.click
    wait_for_tiny(driver.find_element(:css, 'textarea.edit_section'))
    driver.find_element(:css, "img[alt='Embed Image']").click
    driver.find_element(:css, ".flickr_search_link").click
    driver.find_element(:id, "instructure_image_search").should_not be_nil
  end
end
