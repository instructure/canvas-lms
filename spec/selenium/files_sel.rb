require File.expand_path(File.dirname(__FILE__) + '/common')

describe "files view" do
  it_should_behave_like "in-process server selenium tests"

  it "should show students link to download zip of folder" do
    course_with_student_logged_in
    get "/courses/#{@course.id}/files"
    link = keep_trying_until { driver.find_element(:css, "div.links a.download_zip_link") }
    link.should be_displayed
    link.attribute('href').should match(%r"/courses/#{@course.id}/folders/\d+/download")
  end
end
