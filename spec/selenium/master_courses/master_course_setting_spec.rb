require_relative '../common'

describe "master courses - settings" do
  include_context "in-process server selenium tests"

  before :once do
    @account = Account.default
    @account.enable_feature!(:master_courses)
    @test_course = course_factory(active_all: true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@test_course)
  end

  before :each do
    admin_logged_in
  end

  it "blueprint course selected in settings", priority: "1", test_id: 3097363 do
    get "/courses/#{@test_course.id}/settings"
    expect(f('#course_blueprint').attribute('checked')).to eq("true")
  end

  it "leaves box unchecked for non-blueprint course", priority: "1", test_id: 3138089 do
    MasterCourses::MasterTemplate.remove_as_master_course(@test_course)
    get "/courses/#{@test_course.id}/settings"
    expect(f('#course_blueprint').attribute('checked')).to be_nil
  end

  it "includes Blueprint Courses permission for local admin", priority: "1", test_id: 3138086 do
    get "/accounts/#{@account.id}/permissions"
    f('#account_role_link.ui-tabs-anchor').click()
    expect(driver.find_element(:xpath, "//th[text()[contains(., 'Blueprint')]]")).not_to be nil
  end
end
