require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course catalog" do
  include_context "in-process server selenium tests"

  def catalog_url
    "/search/all_courses"
  end

  def get_catalog
    get catalog_url
    wait_for_ajaximations
  end

  def course_elements
    ff('#course_summaries > li')
  end

  def catalog_setup
    Account.default.enable_feature!(:course_catalog)
    @public_course = course
    @public_course.attributes = {
      name: 'Intro to Testing',
      public_description: 'An overview of testing with Selenium',
      is_public: true,
      indexed: true,
      self_enrollment: true,
    }
    @public_course.workflow_state = 'available'
    @public_course.save!
    @private_course = course
  end

  before do
    catalog_setup
    get_catalog
  end

  it "should list indexed courses" do
    courses = course_elements
    expect(courses.size).to eql 1
  end

  it "should work without course catalog" do
    Account.default.disable_feature!(:course_catalog)
    courses = course_elements
    expect(courses.size).to eql 1
  end
end
