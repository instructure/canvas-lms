require_relative "../../common"
require_relative '../../helpers/public_courses_context'

describe "grades for a public course" do
  include_context "in-process server selenium tests"
  include_context "public course as a logged out user"

  it "should should prompt must be logged in when accessing /grades", priority: "1", test_id: 270031 do
    get "/grades"
    assert_flash_warning_message /You must be logged in to access this page/
    expect(driver.current_url).to eq app_url + "/login/canvas"
  end
end
