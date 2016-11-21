require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course catalog" do
  include_context "in-process server selenium tests"

  def catalog_url
    "/search/all_courses"
  end

  def visit_catalog
    get catalog_url
    wait_for_ajaximations
  end

  def course_elements
    ff('#course_summaries > li')
  end

  def catalog_setup
    Account.default.enable_feature!(:course_catalog)
    # create_courses factory returns id's of courses unless you specify return_type
    create_courses([ public_indexed_course_attrs ], {return_type: :record}).first
  end

  def public_indexed_course_attrs
     {
      name: 'Intro to Testing',
      public_description: 'An overview of testing with Selenium',
      is_public: true,
      indexed: true,
      self_enrollment: true,
      workflow_state: 'available'
    }
  end

  before do
    catalog_setup
    visit_catalog
  end

  it "should list indexed courses" do
    expect(course_elements.size).to eql 1
  end

  it "should work without course catalog" do
    Account.default.disable_feature!(:course_catalog)
    expect(course_elements.size).to eql 1
  end

  it "should list a next button when >12 courses are in the index and public", priority: "1", test_id: 2963672 do
      create_courses(13.times.map{ |i| public_indexed_course_attrs.merge(name: "#{i}") })
      refresh_page
      expect(f('#next-link').displayed?).to be(true)
  end
end
