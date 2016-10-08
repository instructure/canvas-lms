require File.expand_path(File.dirname(__FILE__) + '/common')

describe "layout" do
  include_context "in-process server selenium tests"

  before (:each) do
    course_with_student_logged_in
    @user.update_attribute(:name, "</script><b>evil html & name</b>")
    get "/"
  end

  it "should have ENV available to the JavaScript from js_env" do
    expect(driver.execute_script("return ENV.current_user_id")).to eq @user.id.to_s
  end

  it "should escape JSON injected directly into the view" do
    expect(driver.execute_script("return ENV.current_user.display_name")).to eq  "</script><b>evil html & name</b>"
  end
end
