require_relative '../common'

describe "master courses - pages locking" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:master_courses)

    @course = course_factory(:active_all => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
    @page = @course.wiki.wiki_pages.create!(title: 'Page1')
    @tag = @template.create_content_tag_for!(@page)
  end

  before :each do
    user_session(@teacher)
  end

  it "should show unlocked button on index page for unlocked page" do
   get "/courses/#{@course.id}/pages"
   expect(f('.master-content-lock-cell i.icon-unlock')).to be_displayed
  end

  it "should show locked button on index page for locked page" do
    # restrict something
    @tag.update_attribute(:restrictions, {:content => true})

    get "/courses/#{@course.id}/pages"
    expect(f('.master-content-lock-cell i.icon-lock')).to be_displayed
  end
end
