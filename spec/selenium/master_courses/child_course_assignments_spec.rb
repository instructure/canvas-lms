require_relative '../common'

describe "master courses - child courses - assignment locking" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:master_courses)

    @copy_from = course_factory(:active_all => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    @original_assmt = @copy_from.assignments.create!(:title => "blah", :description => "bloo")
    @tag = @template.create_content_tag_for!(@original_assmt)

    course_with_teacher(:active_all => true)
    @copy_to = @course
    @assmt_copy = @copy_to.assignments.new(:title => "blah", :description => "bloo") # just create a copy directly instead of doing a real migration
    @assmt_copy.migration_id = @tag.migration_id
    @assmt_copy.save!
  end

  before :each do
    user_session(@teacher)
  end

  it "should not show the cog-menu options on the index when locked" do
    @tag.update_attribute(:restrictions, {:content => true, :settings => true})

    get "/courses/#{@copy_to.id}/assignments"

    expect(f('.master-course-cell')).to contain_css('.icon-lock')

    expect(f('.assignment')).to_not contain_css('.al-trigger')
  end

  it "should show the cog-menu options on the index when not locked" do
    get "/courses/#{@copy_to.id}/assignments"

    expect(f('.master-course-cell')).to contain_css('.icon-unlock')

    expect(f('.assignment')).to contain_css('.al-trigger')
  end

  it "should not show the edit/delete options on the show page when locked" do
    @tag.update_attribute(:restrictions, {:content => true, :settings => true})

    get "/courses/#{@copy_to.id}/assignments/#{@assmt_copy.id}"

    expect(f('#content')).to_not contain_css('.edit_assignment_link')
  end

  it "should show the edit/delete cog-menu options on the show when not locked" do
    get "/courses/#{@copy_to.id}/assignments/#{@assmt_copy.id}"

    expect(f('#content')).to contain_css('.edit_assignment_link')
  end
end
