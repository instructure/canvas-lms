require_relative '../common'

describe "master courses - child courses - wiki page locking" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:master_courses)

    @copy_from = course_factory(:active_all => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    @original_page = @copy_from.wiki.wiki_pages.create!(:title => "blah", :body => "bloo")
    @tag = @template.create_content_tag_for!(@original_page)

    course_with_teacher(:active_all => true)
    @copy_to = @course
    @page_copy = @copy_to.wiki.wiki_pages.new(:title => "blah", :body => "bloo") # just create a copy directly instead of doing a real migraiton
    @page_copy.migration_id = @tag.migration_id
    @page_copy.save!
  end

  before :each do
    user_session(@teacher)
  end

  it "should not show the edit/delete cog-menu options on the index when locked" do
    @tag.update_attribute(:restrictions, {:content => true, :settings => true})

    get "/courses/#{@copy_to.id}/pages"

    f('.al-trigger').click
    expect(f('.al-options')).to_not contain_css('.edit-menu-item')
    expect(f('.al-options')).to_not contain_css('.delete-menu-item')
  end

  it "should show the edit/delete cog-menu options on the index when not locked" do
    get "/courses/#{@copy_to.id}/pages"

    f('.al-trigger').click
    expect(f('.al-options')).to contain_css('.edit-menu-item')
    expect(f('.al-options')).to contain_css('.delete-menu-item')
  end

  it "should not show the edit/delete options on the show page when locked" do
    @tag.update_attribute(:restrictions, {:content => true, :settings => true})

    get "/courses/#{@copy_to.id}/pages/#{@page_copy.url}"

    expect(f('#content')).to_not contain_css('.edit-wiki')
    f('.al-trigger').click
    expect(f('.al-options')).to_not contain_css('.delete_page')
  end

  it "should show the edit/delete cog-menu options on the index when not locked" do
    get "/courses/#{@copy_to.id}/pages/#{@page_copy.url}"

    expect(f('#content')).to contain_css('.edit-wiki')
    f('.al-trigger').click
    expect(f('.al-options')).to contain_css('.delete_page')
  end
end
