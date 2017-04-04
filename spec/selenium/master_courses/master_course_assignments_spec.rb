require_relative '../common'

describe "master courses - assignment locking" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:master_courses)

    @course = course_factory(:active_all => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
    @assignment = @course.assignments.create!(:title => "blah", :description => "bloo")
    @tag = @template.create_content_tag_for!(@assignment)
  end

  before :each do
    user_session(@teacher)
  end

  it "should show unlocked button on index page for unlocked assignment" do
   get "/courses/#{@course.id}/assignments"
   expect(f('[data-view="lock-icon"] i.icon-unlock')).to be_displayed
  end

  it "should show locked button on index page for locked assignment" do
    # restrict something
    @tag.update_attribute(:restrictions, {:content => true})

    get "/courses/#{@course.id}/assignments"
    expect(f('[data-view="lock-icon"] i.icon-lock')).to be_displayed
  end
end
